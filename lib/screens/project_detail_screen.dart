import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/atoms.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/project_form_sheet.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_row.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  TaskStatus _tab = TaskStatus.todo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectProvider>().loadTasks(widget.projectId);
    });
  }

  Future<void> _delete(Project project) async {
    if (project.taskCount > 0) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Delete this project?',
        message: '"${project.name}" has ${project.taskCount} '
            '${project.taskCount == 1 ? 'task' : 'tasks'}. Deleting it will also delete all its tasks. '
            "This can't be undone.",
      );
      if (!confirmed) return;
    }
    if (!mounted) return;
    final error = await context.read<ProjectProvider>().deleteProject(project.id, confirm: true);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<ProjectProvider>(
          builder: (context, provider, _) {
            Project? found;
            for (final p in provider.projects) {
              if (p.id == widget.projectId) {
                found = p;
                break;
              }
            }
            if (found == null) {
              return const SizedBox.shrink();
            }
            final project = found;
            final tasks = provider.tasksFor(widget.projectId);
            final loading = provider.tasksLoading(widget.projectId);

            final byStatus = <TaskStatus, List<Task>>{
              for (final s in TaskStatus.values) s: tasks.where((t) => t.status == s).toList(),
            };
            final visibleTasks = byStatus[_tab] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(project.name,
                            style: AppTypography.heading(17), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: () => showProjectFormSheet(context, project: project),
                        child: const Icon(Icons.edit_outlined, size: 19, color: AppColors.text),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _delete(project),
                        child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.text),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                    children: [
                      Row(
                        children: [
                          _StatusPill(status: project.status),
                          const SizedBox(width: 8),
                          OutlineTag(project.categoryName),
                        ],
                      ),
                      if (project.description != null && project.description!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(project.description!,
                            style: AppTypography.body(12.5, color: AppColors.ink(0.7)).copyWith(height: 1.5)),
                      ],
                      const SizedBox(height: 16),
                      const ThickDivider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SectionKicker('Tasks'),
                          if (project.status == ProjectStatus.development)
                            GestureDetector(
                              onTap: () => showTaskFormSheet(context, projectId: project.id),
                              child: Text('+ Add Task',
                                  style: AppTypography.heading(12, weight: FontWeight.w700, color: AppColors.accent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TaskTabs(
                        selected: _tab,
                        counts: {for (final s in TaskStatus.values) s: byStatus[s]?.length ?? 0},
                        onSelect: (s) => setState(() => _tab = s),
                      ),
                      const SizedBox(height: 4),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                        )
                      else if (visibleTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text('No tasks here.', style: AppTypography.body(13, color: AppColors.ink(0.5))),
                        )
                      else
                        for (final task in visibleTasks)
                          TaskRow(
                            task: task,
                            onTap: () => showTaskFormSheet(context, projectId: project.id, task: task),
                          ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProjectStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(status.label,
          style: AppTypography.heading(10, weight: FontWeight.w600, color: AppColors.bg)),
    );
  }
}

class _TaskTabs extends StatelessWidget {
  final TaskStatus selected;
  final Map<TaskStatus, int> counts;
  final ValueChanged<TaskStatus> onSelect;
  const _TaskTabs({required this.selected, required this.counts, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          for (final s in TaskStatus.values) _TaskTab(status: s, count: counts[s] ?? 0, selected: s == selected, onTap: () => onSelect(s)),
        ],
      ),
    );
  }
}

class _TaskTab extends StatelessWidget {
  final TaskStatus status;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _TaskTab({required this.status, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.accent : Colors.transparent, width: 2)),
        ),
        child: Text(
          '${status.label} · $count',
          style: AppTypography.heading(11,
              weight: FontWeight.w700, color: selected ? AppColors.accent : AppColors.ink(0.55)),
        ),
      ),
    );
  }
}
