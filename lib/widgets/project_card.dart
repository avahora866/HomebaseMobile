import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

/// The tracker-home project row: status dot, name, "category · N tasks"
/// subtitle, trailing chevron. Paused projects dim slightly; completed and
/// archived ones dim further, matching how far out of active rotation they
/// are.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  const ProjectCard({super.key, required this.project, required this.onTap});

  Color get _dotColor {
    switch (project.status) {
      case ProjectStatus.inProgress:
      case ProjectStatus.paused:
        return AppColors.accent;
      case ProjectStatus.idea:
      case ProjectStatus.completed:
      case ProjectStatus.archived:
        return AppColors.divider;
    }
  }

  double get _opacity {
    switch (project.status) {
      case ProjectStatus.paused:
        return 0.85;
      case ProjectStatus.completed:
        return 0.55;
      case ProjectStatus.archived:
        return 0.45;
      case ProjectStatus.idea:
      case ProjectStatus.inProgress:
        return 1.0;
    }
  }

  String get _subtitle {
    final taskLabel = project.taskCount == 0
        ? 'no tasks'
        : project.taskCount == 1
            ? '1 task'
            : '${project.taskCount} tasks';
    return '${project.categoryName} · $taskLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              StatusDot(color: _dotColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: AppTypography.heading(13, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(_subtitle, style: AppTypography.body(10.5, color: AppColors.ink(0.6))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
