import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../config/job_registry.dart';

class JobProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  late List<Job> jobs;

  JobProvider() {
    jobs = List.from(jobRegistry);
  }

  // ── Param helpers ──────────────────────────────────────────────────

  /// Update a param value. If the changed param triggers a dependent
  /// dropdown that needs remote options, fetches them automatically.
  Future<void> setParamValue(String jobId, String paramKey, String? value) async {
    final job = _findJob(jobId);
    if (job == null) return;

    final param = job.params.firstWhere((p) => p.key == paramKey,
        orElse: () => throw StateError('Param $paramKey not found'));
    param.currentValue = value;

    // Clear values of params that are now hidden
    final currentValues = job.liveParamValues;
    for (final p in job.params) {
      if (!p.isVisible(currentValues)) {
        p.currentValue = null;
      }
    }

    notifyListeners();

    // ── Auto-fetch fandom options when fanfiction is selected ─────────
    if (jobId == 'random_media' && paramKey == 'media' && value == 'fanfiction') {
      await _fetchFandomOptions(job);
    }
  }

  // ── Job option initialisation (called when a job screen opens) ────

  /// Fetches any options that should be available as soon as the job screen
  /// opens — i.e. options that are not triggered by a param value change.
  Future<void> initJobOptions(String jobId) async {
    final job = _findJob(jobId);
    if (job == null) return;

    if (jobId == 'random_trunk') {
      await _fetchTrunkCategories(job);
    }
    if (jobId == 'random_media') {
      await _fetchMediaCounts(job);
    }
  }

  /// Toggle a value in a multiSelectDropdown param.
  void toggleMultiSelectValue(String jobId, String paramKey, String value) {
    final job = _findJob(jobId);
    if (job == null) return;
    final param = job.params.firstWhere((p) => p.key == paramKey);
    final current = List<String>.from(param.selectedValues);
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    param.selectedValues = current;
    notifyListeners();
  }

  // ── Fandom options fetch ───────────────────────────────────────────

  Future<void> _fetchFandomOptions(Job job) async {
    final fandomParam = _fandomParam(job);
    if (fandomParam == null) return;

    // Show loading spinner in the dropdown
    fandomParam.isLoadingOptions = true;
    fandomParam.options = [];
    fandomParam.optionCounts = {};
    fandomParam.currentValue = null;
    notifyListeners();

    try {
      final response = await _api.get('/media/fandomOptions');

      if (response['success'] == true) {
        final data = response['data'];
        // Each entry is {"name": "...", "unreadCount": n}
        final entries = (data as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .where((e) => (e['name'] as String?)?.isNotEmpty == true);
        fandomParam.options = entries.map((e) => e['name'] as String).toList();
        fandomParam.optionCounts = {
          for (final e in entries)
            e['name'] as String: (e['unreadCount'] as num?)?.toInt() ?? 0,
        };
      } else {
        // Fall back to empty — user will see "no options" state
        fandomParam.options = [];
        fandomParam.optionCounts = {};
      }
    } catch (_) {
      fandomParam.options = [];
      fandomParam.optionCounts = {};
    } finally {
      fandomParam.isLoadingOptions = false;
      notifyListeners();
    }
  }

  JobParam? _fandomParam(Job job) {
    try {
      return job.params.firstWhere((p) => p.key == 'fandom');
    } catch (_) {
      return null;
    }
  }

  // ── Media type remaining-counts fetch ────────────────────────────────

  /// Fetches the remaining count for each media type independently (one
  /// request per type, in parallel) so a slow type — fanfiction, which
  /// scans every to-be-read entry — can't hold up the others from showing
  /// up as soon as they resolve.
  Future<void> _fetchMediaCounts(Job job) async {
    final mediaParam = _mediaParam(job);
    if (mediaParam == null) return;

    mediaParam.optionCounts = {};
    mediaParam.isLoadingOptionCounts = true;
    notifyListeners();

    await Future.wait(mediaParam.options.map((type) async {
      try {
        final response = await _api
            .get('/media/mediaCount?media=${Uri.encodeComponent(type)}');
        if (response['success'] == true) {
          final data = response['data'];
          if (data is Map) {
            final count = (data['remainingCount'] as num?)?.toInt();
            if (count != null) {
              mediaParam.optionCounts[type] = count;
              notifyListeners();
            }
          }
        }
      } catch (_) {
        // Leave this type's count unresolved — dropdown falls back to a
        // plain label for it.
      }
    }));

    mediaParam.isLoadingOptionCounts = false;
    notifyListeners();
  }

  JobParam? _mediaParam(Job job) {
    try {
      return job.params.firstWhere((p) => p.key == 'media');
    } catch (_) {
      return null;
    }
  }

  // ── Trunk category options fetch ───────────────────────────────────

  Future<void> _fetchTrunkCategories(Job job) async {
    final categoryParam = _categoryParam(job);
    if (categoryParam == null) return;
    // Guard: skip if options are already loaded
    if (categoryParam.options.isNotEmpty) return;

    categoryParam.isLoadingOptions = true;
    notifyListeners();

    final url =
        '${AppConfig.gasUrl}?action=categories&secret=${Uri.encodeComponent(AppConfig.gasSecret)}';

    try {
      final response = await _api.getAbsolute(url);
      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['categories'] is List) {
          categoryParam.options = (data['categories'] as List)
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } else {
        categoryParam.options = [];
      }
    } catch (_) {
      categoryParam.options = [];
    } finally {
      categoryParam.isLoadingOptions = false;
      notifyListeners();
    }
  }

  JobParam? _categoryParam(Job job) {
    try {
      return job.params.firstWhere((p) => p.key == 'category');
    } catch (_) {
      return null;
    }
  }

  // ── Job execution ──────────────────────────────────────────────────

  Future<String?> runJob(String jobId) async {
    final index = jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return 'Job not found.';

    final validationError = jobs[index].validate();
    if (validationError != null) return validationError;

    jobs[index].status = JobStatus.loading;
    jobs[index].result = null;
    jobs[index].errorMessage = null;
    // Snapshot the params as they are right now — the request below is
    // built from them, and the result card must keep reflecting this run
    // even if the user changes the fields afterwards.
    jobs[index].paramValues = jobs[index].liveParamValues;
    notifyListeners();

    try {
      final job = jobs[index];
      Map<String, dynamic> response;

      switch (job.method.toUpperCase()) {
        case 'POST':
          response = await _api.post(job.endpoint, job.resolvedBody);
          break;
        case 'PUT':
          response = await _api.put(job.endpoint, job.resolvedBody);
          break;
        case 'DELETE':
          response = await _api.delete(job.endpoint);
          break;
        case 'GET':
        default:
          final resolvedUrl = job.resolvedEndpoint;
          if (resolvedUrl.startsWith('http://') ||
              resolvedUrl.startsWith('https://')) {
            response = await _api.getAbsolute(resolvedUrl);
          } else {
            response = await _api.get(resolvedUrl);
          }
          break;
      }

      if (response['success'] == true) {
        jobs[index].status = JobStatus.success;
        jobs[index].result = response['data'];
        jobs[index].hasRun = true;
      } else {
        jobs[index].status = JobStatus.error;
        jobs[index].errorMessage = response['error'].toString();
      }
    } catch (e) {
      jobs[index].status = JobStatus.error;
      jobs[index].errorMessage = e.toString();
    }

    notifyListeners();
    return null;
  }

  // ── Reset ──────────────────────────────────────────────────────────

  void resetJob(String jobId) {
    final job = _findJob(jobId);
    if (job == null) return;
    job.status = JobStatus.idle;
    job.result = null;
    job.errorMessage = null;
    job.paramValues = null;
    // Clear all param values and reset options appropriately per job type
    final fandom = _fandomParam(job);
    if (fandom != null) {
      // Fandom options are fetched on demand (when fanfiction is selected),
      // so clear them fully so they re-load next time.
      fandom.options = [];
      fandom.optionCounts = {};
      fandom.currentValue = null;
      fandom.selectedValues = [];
    }
    final category = _categoryParam(job);
    if (category != null) {
      // Category options are fetched on screen open and are stable,
      // so preserve them — only clear the selected value.
      category.currentValue = null;
      category.selectedValues = [];
    }
    for (final p in job.params) {
      if (p.key == 'fandom' || p.key == 'category') continue;
      p.currentValue = null;
      p.selectedValues = [];
    }
    notifyListeners();
  }

  void resetAll() {
    for (final job in jobs) {
      job.status = JobStatus.idle;
      job.result = null;
      job.errorMessage = null;
      job.hasRun = false;
      job.paramValues = null;
      for (final p in job.params) {
        p.currentValue = null;
        p.selectedValues = [];
      }
      final fandom = _fandomParam(job);
      if (fandom != null) {
        fandom.options = [];
        fandom.optionCounts = {};
        fandom.selectedValues = [];
      }
    }
    notifyListeners();
  }

  // ── Private ────────────────────────────────────────────────────────

  Job? _findJob(String jobId) {
    try {
      return jobs.firstWhere((j) => j.id == jobId);
    } catch (_) {
      return null;
    }
  }
}
