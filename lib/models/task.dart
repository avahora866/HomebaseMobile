enum TaskStatus {
  todo,
  inProgress,
  done;

  static TaskStatus fromJson(String value) => TaskStatus.values.firstWhere(
        (s) => s.wireName == value,
        orElse: () => TaskStatus.todo,
      );

  String get wireName {
    switch (this) {
      case TaskStatus.todo:
        return 'TODO';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.done:
        return 'DONE';
    }
  }

  String get toJson => wireName;

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

enum TaskPriority {
  high,
  medium,
  low;

  static TaskPriority? fromJson(String? value) {
    if (value == null) return null;
    return TaskPriority.values.firstWhere((p) => p.name.toUpperCase() == value);
  }

  String get toJson => name.toUpperCase();

  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String get shortLabel {
    switch (this) {
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.medium:
        return 'MED';
      case TaskPriority.low:
        return 'LOW';
    }
  }
}

class Subtask {
  final int? id;
  final String title;
  final bool done;

  Subtask({this.id, required this.title, required this.done});

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as int?,
        title: json['title'] as String,
        done: json['done'] as bool,
      );

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(id: id, title: title ?? this.title, done: done ?? this.done);
}

class Task {
  final int id;
  final int projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority? priority;
  final List<Subtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    this.priority,
    required this.subtasks,
    required this.createdAt,
    required this.updatedAt,
  });

  int get subtasksDone => subtasks.where((s) => s.done).length;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        projectId: json['projectId'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: TaskStatus.fromJson(json['status'] as String),
        priority: TaskPriority.fromJson(json['priority'] as String?),
        subtasks: (json['subtasks'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(Subtask.fromJson)
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
