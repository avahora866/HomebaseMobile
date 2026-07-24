import 'job_param.dart';

export 'job_param.dart';

enum JobStatus { idle, loading, success, error }

/// Section a [Job] is grouped under on the home screen.
enum JobCategory {
  media,
  interestingFact,
  cs;

  String get label {
    switch (this) {
      case JobCategory.media:
        return 'Media';
      case JobCategory.interestingFact:
        return 'Interesting Fact';
      case JobCategory.cs:
        return 'CS';
    }
  }
}

class Job {
  final String id;
  final String name;
  final String description;
  final String endpoint;
  final String method;
  final JobCategory category;

  final Map<String, dynamic>? staticBody;

  /// Query-string params that are always appended for GET requests,
  /// before any user-supplied params (e.g. action=random, secret=xxx).
  final Map<String, String> staticParams;

  final List<JobParam> params;

  JobStatus status;
  dynamic result;
  String? errorMessage;

  /// True once this job has been run successfully at least once — drives
  /// the home-screen list dot (accent once run, divider until then).
  bool hasRun;

  /// Snapshot of [paramValues] taken at the moment this job was last run —
  /// so the result card reflects what was actually run, not whatever the
  /// param fields have since been changed to (e.g. switching the media
  /// type dropdown after a result already came back).
  Map<String, String?>? lastRunParamValues;

  Job({
    required this.id,
    required this.name,
    required this.description,
    required this.endpoint,
    required this.category,
    this.method = 'GET',
    this.staticBody,
    this.staticParams = const {},
    this.params = const [],
    this.status = JobStatus.idle,
    this.result,
    this.errorMessage,
    this.hasRun = false,
    this.lastRunParamValues,
  });

  bool get hasParams => params.isNotEmpty;

  Map<String, String?> get paramValues =>
      {for (final p in params) p.key: p.currentValue};

  List<JobParam> get visibleParams {
    final values = paramValues;
    return params.where((p) => p.isVisible(values)).toList();
  }

  String get queryString {
    final parts = <String>[];
    // Static params always appear first (e.g. action=random, secret=xxx)
    staticParams.forEach((key, value) {
      parts.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
    });
    for (final p in visibleParams) {
      if (!p.hasValue) continue;
      if (p.inputType == ParamInputType.multiSelectDropdown) {
        // Comma-separated: fandom=A,B,C
        parts.add(
            '${Uri.encodeComponent(p.key)}=${Uri.encodeComponent(p.commaSeparatedValues)}');
      } else {
        parts.add(
            '${Uri.encodeComponent(p.key)}=${Uri.encodeComponent(p.currentValue!)}');
      }
    }
    return parts.isEmpty ? '' : '?${parts.join('&')}';
  }

  String get resolvedEndpoint =>
      method.toUpperCase() == 'GET' ? '$endpoint$queryString' : endpoint;

  Map<String, dynamic> get resolvedBody {
    final paramBody = <String, dynamic>{};
    for (final p in visibleParams) {
      if (!p.hasValue) continue;
      if (p.inputType == ParamInputType.multiSelectDropdown) {
        paramBody[p.key] = p.commaSeparatedValues;
      } else {
        paramBody[p.key] = p.currentValue!;
      }
    }
    return {...?staticBody, ...paramBody};
  }

  String? validate() {
    for (final p in visibleParams) {
      if (p.required && !p.hasValue) {
        return '${p.label} is required.';
      }
    }
    return null;
  }
}
