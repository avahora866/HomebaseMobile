import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/api_service.dart';

enum ProjectTrackerStatus { idle, loading, success, error }

/// Owns the Project Tracker's projects + categories list, and caches each
/// open project's tasks by project id so navigating back to Tracker Home
/// and back into a project doesn't force a re-fetch.
class ProjectProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  ProjectTrackerStatus status = ProjectTrackerStatus.idle;
  String? errorMessage;
  List<Project> projects = [];
  List<ProjectCategory> categories = [];

  final Map<int, List<Task>> _tasksByProject = {};
  final Map<int, bool> _tasksLoading = {};

  List<Task> tasksFor(int projectId) => _tasksByProject[projectId] ?? [];
  bool tasksLoading(int projectId) => _tasksLoading[projectId] ?? false;

  /// Seeds the task cache directly, bypassing the network call — for widget
  /// tests that need a project's tasks without a live API.
  @visibleForTesting
  void seedTasksForTest(int projectId, List<Task> tasks) {
    _tasksByProject[projectId] = tasks;
    notifyListeners();
  }

  /// Seeds projects + categories directly as a successful load, bypassing
  /// the network call — for widget tests. Safe to call after the screen's
  /// own (network-less, failing) `load()` has already run once.
  @visibleForTesting
  void seedProjectsForTest({required List<ProjectCategory> categories, required List<Project> projects}) {
    status = ProjectTrackerStatus.success;
    errorMessage = null;
    this.categories = categories;
    this.projects = projects;
    notifyListeners();
  }

  Future<void> load() async {
    status = ProjectTrackerStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([_api.get('/projects'), _api.get('/categories')]);
      final projectsResponse = results[0];
      final categoriesResponse = results[1];

      if (projectsResponse['success'] == true && categoriesResponse['success'] == true) {
        projects = (projectsResponse['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Project.fromJson)
            .toList();
        categories = (categoriesResponse['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ProjectCategory.fromJson)
            .toList();
        status = ProjectTrackerStatus.success;
      } else {
        status = ProjectTrackerStatus.error;
        errorMessage =
            (projectsResponse['error'] ?? categoriesResponse['error'] ?? 'Unknown error').toString();
      }
    } catch (e) {
      status = ProjectTrackerStatus.error;
      errorMessage = e.toString();
    }

    notifyListeners();
  }

  // ── Categories ──────────────────────────────────────────────────────

  /// Returns the new category on success, or an error message on failure.
  Future<Object> createCategory(String name) async {
    final response = await _api.post('/categories', {'name': name});
    if (response['success'] == true) {
      final category = ProjectCategory.fromJson(response['data'] as Map<String, dynamic>);
      categories = [...categories, category]..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return category;
    }
    return response['error'].toString();
  }

  // ── Projects ────────────────────────────────────────────────────────

  Future<String?> createProject({
    required String name,
    String? description,
    required ProjectStatus status,
    required int categoryId,
  }) async {
    final response = await _api.post('/projects', {
      'name': name,
      'description': description,
      'status': status.toJson,
      'categoryId': categoryId,
    });
    if (response['success'] == true) {
      projects = [Project.fromJson(response['data'] as Map<String, dynamic>), ...projects];
      notifyListeners();
      return null;
    }
    return response['error'].toString();
  }

  Future<String?> updateProject(
    int id, {
    required String name,
    String? description,
    required ProjectStatus status,
    required int categoryId,
  }) async {
    final response = await _api.put('/projects/$id', {
      'name': name,
      'description': description,
      'status': status.toJson,
      'categoryId': categoryId,
    });
    if (response['success'] == true) {
      final updated = Project.fromJson(response['data'] as Map<String, dynamic>);
      projects = [for (final p in projects) if (p.id == id) updated else p];
      notifyListeners();
      return null;
    }
    return response['error'].toString();
  }

  /// [confirm] must be true when the project has tasks — the UI shows a
  /// confirmation dialog first in that case (driven off [Project.taskCount],
  /// no separate probe needed).
  Future<String?> deleteProject(int id, {bool confirm = false}) async {
    final response = await _api.delete('/projects/$id${confirm ? '?confirm=true' : ''}');
    if (response['success'] == true) {
      projects = projects.where((p) => p.id != id).toList();
      _tasksByProject.remove(id);
      notifyListeners();
      return null;
    }
    return response['error'].toString();
  }

  // ── Tasks ───────────────────────────────────────────────────────────

  Future<void> loadTasks(int projectId) async {
    _tasksLoading[projectId] = true;
    notifyListeners();

    final response = await _api.get('/projects/$projectId/tasks');
    if (response['success'] == true) {
      _tasksByProject[projectId] = (response['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    }
    _tasksLoading[projectId] = false;
    notifyListeners();
  }

  Future<String?> createTask(
    int projectId, {
    required String title,
    String? description,
    required TaskStatus status,
    TaskPriority? priority,
    required List<Subtask> subtasks,
  }) async {
    final response = await _api.post('/projects/$projectId/tasks', {
      'title': title,
      'description': description,
      'status': status.toJson,
      'priority': priority?.toJson,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    });
    if (response['success'] == true) {
      final task = Task.fromJson(response['data'] as Map<String, dynamic>);
      _tasksByProject[projectId] = [...tasksFor(projectId), task];
      _bumpTaskCount(projectId, 1);
      notifyListeners();
      return null;
    }
    return response['error'].toString();
  }

  Future<String?> updateTask(
    Task task, {
    required String title,
    String? description,
    required TaskStatus status,
    TaskPriority? priority,
    required List<Subtask> subtasks,
  }) async {
    final response = await _api.put('/tasks/${task.id}', {
      'title': title,
      'description': description,
      'status': status.toJson,
      'priority': priority?.toJson,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    });
    if (response['success'] == true) {
      final updated = Task.fromJson(response['data'] as Map<String, dynamic>);
      _tasksByProject[task.projectId] = [
        for (final t in tasksFor(task.projectId)) if (t.id == task.id) updated else t
      ];
      notifyListeners();
      return null;
    }
    return response['error'].toString();
  }

  Future<String?> deleteTask(Task task) async {
    final response = await _api.delete('/tasks/${task.id}');
    if (response['success'] == true) {
      _tasksByProject[task.projectId] =
          tasksFor(task.projectId).where((t) => t.id != task.id).toList();
      _bumpTaskCount(task.projectId, -1);
      notifyListeners();
      return null;
    }
    return response['error'].toString();
  }

  void _bumpTaskCount(int projectId, int delta) {
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;
    final p = projects[index];
    final updated = Project(
      id: p.id,
      name: p.name,
      description: p.description,
      status: p.status,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      taskCount: p.taskCount + delta,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
    projects = [for (final proj in projects) if (proj.id == projectId) updated else proj];
  }
}
