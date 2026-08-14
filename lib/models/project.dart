enum ProjectStatus {
  idea,
  development,
  paused,
  completed,
  archived;

  static ProjectStatus fromJson(String value) => ProjectStatus.values.firstWhere(
        (s) => s.name.toUpperCase() == value,
        orElse: () => ProjectStatus.idea,
      );

  String get toJson => name.toUpperCase();

  String get label {
    switch (this) {
      case ProjectStatus.idea:
        return 'Idea';
      case ProjectStatus.development:
        return 'Development';
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
