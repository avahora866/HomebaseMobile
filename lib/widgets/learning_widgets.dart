import 'package:flutter/material.dart';
import '../models/learning.dart';
import '../providers/learning_provider.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';
import 'searchable_picker_sheet.dart';

/// A section kicker with an optional accent action on the right — the same
/// pattern as the project detail screen's "TASKS … + Add Task".
class LearningSectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  const LearningSectionHeader(this.label, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SectionKicker(label),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: AppTypography.heading(12, weight: FontWeight.w700, color: AppColors.accent)),
            ),
        ],
      ),
    );
  }
}

/// A linked project: name, its live project-tracker status, and an unlink
/// button. Unlinking never touches the project itself.
class ProjectLinkRow extends StatelessWidget {
  final ProjectLink link;
  final VoidCallback onUnlink;
  const ProjectLinkRow({super.key, required this.link, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(link.projectName,
                style: AppTypography.body(13, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          OutlineTag(link.projectStatus.label),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onUnlink,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.ink(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the user pick one of [ids] from the shared searchable picker, which
/// keys options by display string — so labels are made unique (an id is
/// appended only when two would otherwise collide) and mapped back.
Future<int?> _pickById(
  BuildContext context, {
  required String title,
  required List<int> ids,
  required String Function(int id) label,
}) async {
  final counts = <String, int>{};
  for (final id in ids) {
    counts.update(label(id), (n) => n + 1, ifAbsent: () => 1);
  }
  final byLabel = <String, int>{
    for (final id in ids) (counts[label(id)]! > 1 ? '${label(id)} (#$id)' : label(id)): id,
  };
  int? picked;
  await showSearchablePickerSheet(
    context: context,
    title: title,
    options: byLabel.keys.toList(),
    selectedValues: const [],
    multiSelect: false,
    onToggle: (value) => picked = byLabel[value],
  );
  return picked;
}

/// A topic of [detail] for [topic] to build on — every other topic not
/// already one of its prerequisites, labelled with its path.
Future<int?> pickPrerequisite(BuildContext context, SpecialisationDetail detail, Topic topic) {
  final candidates = detail.topics
      .where((t) => t.id != topic.id && !topic.prerequisiteIds.contains(t.id))
      .map((t) => t.id)
      .toList();
  return _pickById(
    context,
    title: 'Builds on…',
    ids: candidates,
    label: (id) {
      final t = detail.topic(id)!;
      return [...detail.ancestorsOf(t).map((a) => a.name), t.name].join(' › ');
    },
  );
}

/// A project-tracker project not in [alreadyLinked]. Shows a snackbar and
/// resolves null if the projects can't be loaded.
Future<int?> pickProject(BuildContext context, LearningProvider provider, Iterable<int> alreadyLinked) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final projects = await provider.loadProjects();
    if (!context.mounted) return null;
    final names = {for (final p in projects) p.id: p.name};
    final ids = projects.map((p) => p.id).where((id) => !alreadyLinked.contains(id)).toList();
    if (ids.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No other projects to link')));
      return null;
    }
    return await _pickById(context, title: 'Link a project', ids: ids, label: (id) => names[id]!);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    return null;
  }
}

/// Shows [error] in a snackbar when a write failed; does nothing on success.
void showWriteError(BuildContext context, String? error) {
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

/// Marks a rating as calculated from subtopics rather than set by hand.
class DerivedBadge extends StatelessWidget {
  final String label;
  const DerivedBadge({super.key, this.label = 'DERIVED'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: AppTypography.heading(8.5, weight: FontWeight.w700, color: AppColors.ink(0.55))
              .copyWith(letterSpacing: 0.6)),
    );
  }
}
