enum ProjectStatus {
  idea,
  inProgress,
  paused,
  completed,
  archived;

  static ProjectStatus fromJson(String value) => ProjectStatus.values.firstWhere(
        (s) => s.wireName == value,
        orElse: () => ProjectStatus.idea,
      );

  String get wireName {
    switch (this) {
      case ProjectStatus.idea:
        return 'IDEA';
      case ProjectStatus.inProgress:
        return 'IN_PROGRESS';
      case ProjectStatus.paused:
        return 'PAUSED';
      case ProjectStatus.completed:
        return 'COMPLETED';
      case ProjectStatus.archived:
        return 'ARCHIVED';
    }
  }

  String get toJson => wireName;

  // "In Progress" rather than the software-specific "Development" — this
  // status just means the project is actively being worked on, whatever
  // kind of project it is (a research paper counts as much as an app).
  String get label {
    switch (this) {
      case ProjectStatus.idea:
        return 'Idea';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.paused:
        return 'Paused';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }
}

class ProjectCategory {
  final int id;
  final String name;

  ProjectCategory({required this.id, required this.name});

  factory ProjectCategory.fromJson(Map<String, dynamic> json) =>
      ProjectCategory(id: json['id'] as int, name: json['name'] as String);
}

class Project {
  final int id;
  final String name;
  final String? description;
  final ProjectStatus status;
  final int categoryId;
  final String categoryName;
  final int taskCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.categoryId,
    required this.categoryName,
    required this.taskCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        status: ProjectStatus.fromJson(json['status'] as String),
        categoryId: json['categoryId'] as int,
        categoryName: json['categoryName'] as String,
        taskCount: json['taskCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
