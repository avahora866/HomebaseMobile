import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

/// A single task row inside the project detail screen's status tabs. The
/// leading dot marks status — hollow (To Do), accent-ringed (In Progress),
/// filled accent with a check (Done) — instead of a checkbox; tapping the
/// row opens the edit sheet where status actually changes.
class TaskRow extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const TaskRow({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.done;
    return Opacity(
      opacity: done ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: _StatusDot(status: task.status),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.body(13, weight: FontWeight.w600).copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description!,
                        style: AppTypography.body(11, color: AppColors.ink(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (task.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: task.subtasksDone / task.subtasks.length,
                                backgroundColor: AppColors.ink(0.15),
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${task.subtasksDone}/${task.subtasks.length} subtasks',
                            style: AppTypography.body(9.5, color: AppColors.ink(0.55)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (task.priority != null) ...[
                const SizedBox(width: 8),
                _PriorityTag(priority: task.priority!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final TaskStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TaskStatus.todo:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink(0.4), width: 1.5),
          ),
        );
      case TaskStatus.inProgress:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
        );
      case TaskStatus.done:
        return Container(
          width: 12,
          height: 12,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
          child: const Icon(Icons.check_rounded, size: 9, color: AppColors.bg),
        );
    }
  }
}

class _PriorityTag extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityTag({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.shortLabel,
        style: AppTypography.heading(9, weight: FontWeight.w700, color: AppColors.accent),
      ),
    );
  }
}
