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

  /// The param values as of the last run — set when [runJob] fires the
  /// request and left untouched by further edits to the form, so the
  /// result card keeps reflecting what was actually run (e.g. switching
  /// the media type dropdown after a result already came back doesn't
  /// retag it). Null until the job has been run at least once.
  Map<String, String?>? paramValues;

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
    this.paramValues,
  });

  bool get hasParams => params.isNotEmpty;

  /// The param fields' current live values, as edited in the form right
  /// now — used to build requests and to decide which dependent fields
  /// (e.g. Fandom) are visible. Distinct from [paramValues], which only
  /// updates once a run actually happens.
  Map<String, String?> get liveParamValues =>
      {for (final p in params) p.key: p.currentValue};

  List<JobParam> get visibleParams {
    final values = liveParamValues;
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
