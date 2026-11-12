import 'package:flutter/foundation.dart';
import '../models/learning.dart';
import '../models/project.dart';
import '../services/api_service.dart';

enum LearningStatus { idle, loading, success, error }

/// Owns Learning Path state: the fields overview plus each opened
/// specialisation's full detail, cached by id. Every topic-level write on
/// the server returns the whole refreshed specialisation, which replaces the
/// cached copy and patches that specialisation's summary on its field card —
/// so going back to the overview shows the new rollup without a re-fetch.
///
/// Write methods return null on success or a message to show on failure.
class LearningProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  LearningStatus status = LearningStatus.idle;
  String? errorMessage;
  List<LearningField> fields = [];

  final Map<int, SpecialisationDetail> _details = {};
  final Map<int, String> _detailErrors = {};

  SpecialisationDetail? detail(int specialisationId) => _details[specialisationId];
  String? detailError(int specialisationId) => _detailErrors[specialisationId];

  /// Seeds the overview directly as a successful load, bypassing the
  /// network — for widget tests.
  @visibleForTesting
  void seedFieldsForTest(List<LearningField> fields) {
    status = LearningStatus.success;
    errorMessage = null;
    this.fields = fields;
    notifyListeners();
  }

  /// Seeds a specialisation's detail directly, bypassing the network — for
  /// widget tests.
  @visibleForTesting
  void seedDetailForTest(SpecialisationDetail detail) {
    _detailErrors.remove(detail.id);
    _applyDetail(detail);
  }

  // ── Fields ──────────────────────────────────────────────────────────

  Future<void> loadFields() async {
    status = LearningStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/learning/fields');
      if (response['success'] == true) {
        fields = (response['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(LearningField.fromJson)
            .toList();
        status = LearningStatus.success;
      } else {
        status = LearningStatus.error;
        errorMessage = _errorText(response);
      }
    } catch (e) {
      status = LearningStatus.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// The server creates the field's capabilities and its Basic specialisation alongside it.
  Future<String?> createField(String name, FieldCapabilities capabilities) =>
      _fieldWrite(() => _api.post('/learning/fields', {'name': name, 'capabilities': capabilities.toJson()}));

  /// Refused (with a message naming every conflict) if existing data depends
  /// on a capability being switched off.
  Future<String?> updateField(int id, String name, FieldCapabilities capabilities) =>
      _fieldWrite(() => _api.put('/learning/fields/$id', {'name': name, 'capabilities': capabilities.toJson()}));

  Future<String?> deleteField(int id) => _fieldWrite(() => _api.delete('/learning/fields/$id'));

  Future<String?> createSpecialisation(int fieldId, String name) =>
      _fieldWrite(() => _api.post('/learning/fields/$fieldId/specialisations', {'name': name}));

  Future<String?> deleteSpecialisation(int id) async {
    final error = await _fieldWrite(() => _api.delete('/learning/specialisations/$id'));
    if (error == null) _details.remove(id);
    return error;
  }

  /// Field-level writes change which specialisations exist, so the overview
  /// is reloaded rather than patched.
  Future<String?> _fieldWrite(Future<Map<String, dynamic>> Function() call) async {
    try {
      final response = await call();
      if (response['success'] != true) return _errorText(response);
    } catch (e) {
      return e.toString();
    }
    await loadFields();
    return null;
  }

  // ── Specialisations ─────────────────────────────────────────────────

  Future<void> loadSpecialisation(int id) async {
    _detailErrors.remove(id);
    try {
      final response = await _api.get('/learning/specialisations/$id');
      if (response['success'] == true) {
        _applyDetail(SpecialisationDetail.fromJson(response['data'] as Map<String, dynamic>));
        return;
      }
      _detailErrors[id] = _errorText(response);
    } catch (e) {
      _detailErrors[id] = e.toString();
    }
    notifyListeners();
  }

  Future<String?> renameSpecialisation(int id, String name) =>
      _detailWrite(() => _api.put('/learning/specialisations/$id', {'name': name}));

  // ── Topics ──────────────────────────────────────────────────────────

  Future<String?> createTopic(int specialisationId, String name, {int? parentTopicId}) =>
      _detailWrite(() => _api.post('/learning/specialisations/$specialisationId/topics', {
            'name': name,
            'parentTopicId': parentTopicId,
            'suggestedOrder': null,
            'confidenceRating': null,
          }));

  /// The server's topic PUT is a full replace, so anything not passed keeps
  /// its stored value. Pass [clearOrder] / [clearRating] to set those to null.
  Future<String?> updateTopic(
    Topic topic, {
    String? name,
    int? suggestedOrder,
    bool clearOrder = false,
    int? confidenceRating,
    bool clearRating = false,
  }) =>
      _detailWrite(() => _api.put('/learning/topics/${topic.id}', {
            'name': name ?? topic.name,
            'parentTopicId': topic.parentTopicId,
            'suggestedOrder': clearOrder ? null : (suggestedOrder ?? topic.suggestedOrder),
            'confidenceRating': clearRating ? null : (confidenceRating ?? topic.confidenceRating),
          }));

  /// Tapping the dot that matches the current rating clears it back to unrated.
  Future<String?> rateTopic(Topic topic, int rating) => topic.confidenceRating == rating
      ? updateTopic(topic, clearRating: true)
      : updateTopic(topic, confidenceRating: rating);

  Future<String?> deleteTopic(int topicId) => _detailWrite(() => _api.delete('/learning/topics/$topicId'));

  Future<String?> addPrerequisite(int topicId, int requiresTopicId) => _detailWrite(
      () => _api.post('/learning/topics/$topicId/prerequisites', {'requiresTopicId': requiresTopicId}));

  Future<String?> removePrerequisite(int topicId, int requiresTopicId) =>
      _detailWrite(() => _api.delete('/learning/topics/$topicId/prerequisites/$requiresTopicId'));

  Future<String?> addLog(int topicId, String note) =>
      _detailWrite(() => _api.post('/learning/topics/$topicId/logs', {'note': note}));

  Future<String?> deleteLog(int topicId, int logId) =>
      _detailWrite(() => _api.delete('/learning/topics/$topicId/logs/$logId'));

  // ── Project links ───────────────────────────────────────────────────

  /// Projects to offer when linking — straight from the project tracker.
  Future<List<Project>> loadProjects() async {
    final response = await _api.get('/projects');
    if (response['success'] != true) throw Exception(_errorText(response));
    return (response['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(Project.fromJson).toList();
  }

  /// Links to a topic when [topicId] is given, otherwise to the specialisation itself.
  Future<String?> linkProject(int projectId, {int? topicId, int? specialisationId}) =>
      _detailWrite(() => _api.post('/learning/project-links', {
            'projectId': projectId,
            'topicId': topicId,
            'specialisationId': topicId == null ? specialisationId : null,
          }));

  /// Removes the link only — the project itself is never touched.
  Future<String?> unlinkProject(int linkId) => _detailWrite(() => _api.delete('/learning/project-links/$linkId'));

  // ── Internals ───────────────────────────────────────────────────────

  Future<String?> _detailWrite(Future<Map<String, dynamic>> Function() call) async {
    try {
      final response = await call();
      if (response['success'] != true) return _errorText(response);
      _applyDetail(SpecialisationDetail.fromJson(response['data'] as Map<String, dynamic>));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void _applyDetail(SpecialisationDetail detail) {
    _details[detail.id] = detail;
    fields = [
      for (final f in fields)
        if (f.id == detail.fieldId)
          f.copyWith(specialisations: [
            for (final s in f.specialisations)
              if (s.id == detail.id)
                SpecialisationSummary(
                  id: s.id,
                  name: detail.name,
                  basic: s.basic,
                  rollupRating: detail.rollupRating,
                  ratedLeafCount: detail.ratedLeafCount,
                  leafCount: detail.leafCount,
                )
              else
                s,
          ])
        else
          f,
    ];
    notifyListeners();
  }

  /// The server sends Learning Path errors as problem+json — the reason
  /// (e.g. which data blocks a capability change) is in `detail`.
  static String _errorText(Map<String, dynamic> response) {
    final error = response['error'];
    if (error is Map) return (error['detail'] ?? error['message'] ?? error['error'] ?? error).toString();
    return (error ?? 'Unknown error (${response['status']})').toString();
  }
}
