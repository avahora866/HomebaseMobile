import 'project.dart';

/// A field's rules — what its topics may use. Mirrors the server's
/// `FieldCapabilities`, which enforces every one of these on write.
class FieldCapabilities {
  final bool allowsPrerequisites;
  final bool allowsSuggestedOrder;
  final bool allowsLogs;
  final bool allowsProjectLinks;

  /// null = unlimited, 0 = flat (topics can't have subtopics), n = n levels
  /// below a top-level topic.
  final int? maxNestingDepth;

  const FieldCapabilities({
    required this.allowsPrerequisites,
    required this.allowsSuggestedOrder,
    required this.allowsLogs,
    required this.allowsProjectLinks,
    required this.maxNestingDepth,
  });

  factory FieldCapabilities.fromJson(Map<String, dynamic> json) => FieldCapabilities(
        allowsPrerequisites: json['allowsPrerequisites'] as bool,
        allowsSuggestedOrder: json['allowsSuggestedOrder'] as bool,
        allowsLogs: json['allowsLogs'] as bool,
        allowsProjectLinks: json['allowsProjectLinks'] as bool,
        maxNestingDepth: json['maxNestingDepth'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'allowsPrerequisites': allowsPrerequisites,
        'allowsSuggestedOrder': allowsSuggestedOrder,
        'allowsLogs': allowsLogs,
        'allowsProjectLinks': allowsProjectLinks,
        'maxNestingDepth': maxNestingDepth,
      };

  /// The tags shown on a field's card.
  List<String> get labels => [
        if (allowsPrerequisites) 'prerequisites',
        if (allowsSuggestedOrder) 'suggested order',
        if (allowsLogs) 'logs',
        if (allowsProjectLinks) 'project links',
        maxNestingDepth == null
            ? 'nesting: unlimited'
            : maxNestingDepth == 0
                ? 'nesting: flat'
                : 'nesting: $maxNestingDepth',
      ];
}

class SpecialisationSummary {
  final int id;
  final String name;
  final bool basic;

  /// Decimal average of the top-level topics; null = nothing rated yet.
  final double? rollupRating;
  final int ratedLeafCount;
  final int leafCount;

  const SpecialisationSummary({
    required this.id,
    required this.name,
    required this.basic,
    required this.rollupRating,
    required this.ratedLeafCount,
    required this.leafCount,
  });

  factory SpecialisationSummary.fromJson(Map<String, dynamic> json) => SpecialisationSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        basic: json['basic'] as bool,
        rollupRating: (json['rollupRating'] as num?)?.toDouble(),
        ratedLeafCount: json['ratedLeafCount'] as int,
        leafCount: json['leafCount'] as int,
      );
}

class LearningField {
  final int id;
  final String name;
  final FieldCapabilities capabilities;
  final List<SpecialisationSummary> specialisations;

  const LearningField({
    required this.id,
    required this.name,
    required this.capabilities,
    required this.specialisations,
  });

  factory LearningField.fromJson(Map<String, dynamic> json) => LearningField(
        id: json['id'] as int,
        name: json['name'] as String,
        capabilities: FieldCapabilities.fromJson(json['capabilities'] as Map<String, dynamic>),
        specialisations: (json['specialisations'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(SpecialisationSummary.fromJson)
            .toList(),
      );

  LearningField copyWith({List<SpecialisationSummary>? specialisations}) => LearningField(
        id: id,
        name: name,
        capabilities: capabilities,
        specialisations: specialisations ?? this.specialisations,
      );
}

/// A project-tracker project placed under a topic or specialisation — a
/// link, not a copy, so status always comes from the project itself.
class ProjectLink {
  final int id;
  final int projectId;
  final String projectName;
  final ProjectStatus projectStatus;

  const ProjectLink({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.projectStatus,
  });

  factory ProjectLink.fromJson(Map<String, dynamic> json) => ProjectLink(
        id: json['id'] as int,
        projectId: json['projectId'] as int,
        projectName: json['projectName'] as String,
        projectStatus: ProjectStatus.fromJson(json['projectStatus'] as String),
      );
}

class TopicLog {
  final int id;
  final DateTime createdAt;
  final String note;

  const TopicLog({required this.id, required this.createdAt, required this.note});

  factory TopicLog.fromJson(Map<String, dynamic> json) => TopicLog(
        id: json['id'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        note: json['note'] as String,
      );
}

class Topic {
  final int id;
  final int? parentTopicId;
  final String name;
  final int? suggestedOrder;

  /// The stored 1–5 rating — only ever set on a leaf.
  final int? confidenceRating;

  /// What to display: a leaf's own rating, or the decimal average derived
  /// from its subtopics. null = unrated.
  final double? effectiveRating;

  /// Has subtopics, so the rating is read-only.
  final bool derived;
  final int depth;
  final List<int> prerequisiteIds;

  /// Newest first.
  final List<TopicLog> logs;
  final List<ProjectLink> projectLinks;
  final DateTime createdAt;

  const Topic({
    required this.id,
    required this.parentTopicId,
    required this.name,
    required this.suggestedOrder,
    required this.confidenceRating,
    required this.effectiveRating,
    required this.derived,
    required this.depth,
    required this.prerequisiteIds,
    required this.logs,
    required this.projectLinks,
    required this.createdAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as int,
        parentTopicId: json['parentTopicId'] as int?,
        name: json['name'] as String,
        suggestedOrder: json['suggestedOrder'] as int?,
        confidenceRating: json['confidenceRating'] as int?,
        effectiveRating: (json['effectiveRating'] as num?)?.toDouble(),
        derived: json['derived'] as bool,
        depth: json['depth'] as int,
        prerequisiteIds: (json['prerequisiteIds'] as List<dynamic>).cast<int>(),
        logs: (json['logs'] as List<dynamic>).cast<Map<String, dynamic>>().map(TopicLog.fromJson).toList(),
        projectLinks: (json['projectLinks'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ProjectLink.fromJson)
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Everything the specialisation screen needs. Every topic-level write on
/// the server returns this whole payload, because a single rating change
/// moves every derived rating above it and the rollup too.
class SpecialisationDetail {
  final int id;
  final int fieldId;
  final String fieldName;
  final String name;
  final bool basic;
  final FieldCapabilities capabilities;
  final double? rollupRating;
  final int ratedLeafCount;
  final int leafCount;

  /// Depth-first, siblings in display order.
  final List<Topic> topics;

  /// Links on the specialisation itself — topic links are on each topic.
  final List<ProjectLink> projectLinks;

  const SpecialisationDetail({
    required this.id,
    required this.fieldId,
    required this.fieldName,
    required this.name,
    required this.basic,
    required this.capabilities,
    required this.rollupRating,
    required this.ratedLeafCount,
    required this.leafCount,
    required this.topics,
    required this.projectLinks,
  });

  factory SpecialisationDetail.fromJson(Map<String, dynamic> json) => SpecialisationDetail(
        id: json['id'] as int,
        fieldId: json['fieldId'] as int,
        fieldName: json['fieldName'] as String,
        name: json['name'] as String,
        basic: json['basic'] as bool,
        capabilities: FieldCapabilities.fromJson(json['capabilities'] as Map<String, dynamic>),
        rollupRating: (json['rollupRating'] as num?)?.toDouble(),
        ratedLeafCount: json['ratedLeafCount'] as int,
        leafCount: json['leafCount'] as int,
        topics: (json['topics'] as List<dynamic>).cast<Map<String, dynamic>>().map(Topic.fromJson).toList(),
        projectLinks: (json['projectLinks'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ProjectLink.fromJson)
            .toList(),
      );

  Topic? topic(int id) {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Direct children of [parentId] (null = top level), in display order.
  List<Topic> childrenOf(int? parentId) => topics.where((t) => t.parentTopicId == parentId).toList();

  /// Root first, not including [topic] itself.
  List<Topic> ancestorsOf(Topic topic) {
    final out = <Topic>[];
    for (var id = topic.parentTopicId; id != null;) {
      final t = this.topic(id);
      if (t == null) break;
      out.insert(0, t);
      id = t.parentTopicId;
    }
    return out;
  }

  int descendantCount(int topicId) =>
      childrenOf(topicId).fold(0, (n, child) => n + 1 + descendantCount(child.id));

  /// Whether [topic] may take a subtopic under this field's nesting limit.
  bool canNestUnder(Topic topic) {
    final max = capabilities.maxNestingDepth;
    return max == null || topic.depth + 1 <= max;
  }
}

/// One decimal place (derived ratings are averages); an em dash for unrated.
String formatRating(double? value) {
  if (value == null) return '—';
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.truncateToDouble() ? rounded.toInt().toString() : rounded.toString();
}

enum DotFill { full, partial, empty }

/// Five dots: full within a quarter of the dot's value, partial for anything
/// above the previous one.
List<DotFill> dotFills(double? value) => [
      for (var i = 1; i <= 5; i++)
        if (value == null)
          DotFill.empty
        else if (value >= i - 0.25)
          DotFill.full
        else if (value > i - 1)
          DotFill.partial
        else
          DotFill.empty,
    ];

/// Rollup with coverage, so one high rating on a barely-started
/// specialisation doesn't read as mastery. Coverage counts leaf topics —
/// the only ones rated by hand.
String rollupLabel(double? rating, int rated, int total, {String empty = 'no topics yet'}) =>
    total == 0 ? empty : '${formatRating(rating)} avg · $rated of $total rated';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// `12 Sep 2026` — hand-rolled like [formatMoney] rather than pulling in `intl`.
String formatLogDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';
