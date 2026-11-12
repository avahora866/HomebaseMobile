import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning.dart';
import '../providers/learning_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/atoms.dart';
import '../widgets/confidence_dots.dart';
import '../widgets/learning_sheets.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/result_states.dart';
import '../widgets/slide_route.dart';
import 'topic_detail_screen.dart';

/// One specialisation: its rollup, the expandable topic tree, and projects
/// linked to the specialisation as a whole.
class SpecialisationScreen extends StatefulWidget {
  final int specialisationId;
  const SpecialisationScreen({super.key, required this.specialisationId});

  @override
  State<SpecialisationScreen> createState() => _SpecialisationScreenState();
}

class _SpecialisationScreenState extends State<SpecialisationScreen> {
  /// Topics whose subtopics are showing — the tree starts collapsed.
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LearningProvider>().loadSpecialisation(widget.specialisationId);
    });
  }

  void _openTopic(Topic topic) {
    Navigator.of(context).push(slideRoute(
      TopicDetailScreen(specialisationId: widget.specialisationId, topicId: topic.id),
    ));
  }

  void _newTopic(SpecialisationDetail detail) {
    final provider = context.read<LearningProvider>();
    showNameSheet(
      context,
      title: 'New Topic',
      hint: 'Topic name',
      notes: ['Top level of ${detail.name}.', "Placement is fixed at creation — topics can't be moved later."],
      onSave: (name) => provider.createTopic(detail.id, name),
    );
  }

  Future<void> _edit(SpecialisationDetail detail) async {
    final provider = context.read<LearningProvider>();
    final count = detail.topics.length;
    var deleted = false;
    await showNameSheet(
      context,
      title: 'Edit Specialisation',
      hint: 'Specialisation name',
      initialValue: detail.name,
      onSave: (name) => provider.renameSpecialisation(detail.id, name),
      onDelete: () async {
        final error = await provider.deleteSpecialisation(detail.id);
        deleted = error == null;
        return error;
      },
      deleteConfirmTitle: 'Delete this specialisation?',
      deleteConfirmMessage:
          '"${detail.name}"${count == 0 ? '' : ' and all $count of its ${count == 1 ? 'topic' : 'topics'}'} '
          'will be deleted, with their logs, prerequisites and project links. Linked projects are kept. '
          "This can't be undone.",
    );
    if (deleted && mounted) Navigator.of(context).pop();
  }

  Future<void> _linkProject(SpecialisationDetail detail) async {
    final provider = context.read<LearningProvider>();
    final projectId = await pickProject(context, provider, detail.projectLinks.map((l) => l.projectId));
    if (projectId == null || !mounted) return;
    final error = await provider.linkProject(projectId, specialisationId: detail.id);
    if (mounted) showWriteError(context, error);
  }

  Future<void> _unlinkProject(LearningProvider provider, ProjectLink link) async {
    final error = await provider.unlinkProject(link.id);
    if (mounted) showWriteError(context, error);
  }

  /// Depth-first rows for the expanded part of the tree.
  List<Topic> _visibleTopics(SpecialisationDetail detail) {
    final out = <Topic>[];
    void walk(int? parentId) {
      for (final t in detail.childrenOf(parentId)) {
        out.add(t);
        if (_expanded.contains(t.id)) walk(t.id);
      }
    }

    walk(null);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<LearningProvider>(
          builder: (context, provider, _) {
            final detail = provider.detail(widget.specialisationId);
            final error = provider.detailError(widget.specialisationId);
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
                        child: Text(detail?.name ?? '',
                            style: AppTypography.heading(17), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      // Basic is only ever renamed or deleted along with its field.
                      if (detail != null && !detail.basic)
                        GestureDetector(
                          onTap: () => _edit(detail),
                          child: const Icon(Icons.edit_outlined, size: 19, color: AppColors.text),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: detail == null
                      ? (error != null
                          ? ListView(padding: const EdgeInsets.all(18), children: [ErrorResultCard(message: error)])
                          : const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                            ))
                      : RefreshIndicator(
                          color: AppColors.accent,
                          onRefresh: () => provider.loadSpecialisation(widget.specialisationId),
                          child: _body(detail, provider),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(SpecialisationDetail detail, LearningProvider provider) {
    final rows = _visibleTopics(detail);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        SectionKicker('Learning Path — ${detail.fieldName}'),
        const SizedBox(height: 10),
        Row(
          children: [
            ConfidenceDots(value: detail.rollupRating, size: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rollupLabel(detail.rollupRating, detail.ratedLeafCount, detail.leafCount, empty: 'No topics yet'),
                style: AppTypography.body(12.5, color: AppColors.ink(0.65)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const ThickDivider(),
        const SizedBox(height: 16),
        LearningSectionHeader('Topics', actionLabel: '+ Add Topic', onAction: () => _newTopic(detail)),
        if (rows.isEmpty) ...[
          const SizedBox(height: 12),
          Text('No topics in this specialisation yet.', style: AppTypography.body(13, color: AppColors.ink(0.6))),
          const SizedBox(height: 4),
          Text("Topics can't be moved later — placement is fixed at creation.",
              style: AppTypography.body(12, color: AppColors.ink(0.5)).copyWith(fontStyle: FontStyle.italic)),
        ] else
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: Column(
              children: [
                for (final topic in rows)
                  _TopicRow(
                    topic: topic,
                    hasChildren: detail.childrenOf(topic.id).isNotEmpty,
                    expanded: _expanded.contains(topic.id),
                    onToggle: () => setState(() {
                      if (!_expanded.remove(topic.id)) _expanded.add(topic.id);
                    }),
                    onTap: () => _openTopic(topic),
                  ),
              ],
            ),
          ),
        if (detail.capabilities.allowsProjectLinks) ...[
          const SizedBox(height: 24),
          LearningSectionHeader('Linked projects',
              actionLabel: '+ Link Project', onAction: () => _linkProject(detail)),
          if (detail.projectLinks.isEmpty)
            Text('No projects linked to the specialisation itself.',
                style: AppTypography.body(13, color: AppColors.ink(0.5)))
          else
            for (final link in detail.projectLinks)
              ProjectLinkRow(
                link: link,
                onUnlink: () => _unlinkProject(provider, link),
              ),
        ],
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  final Topic topic;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TopicRow({
    required this.topic,
    required this.hasChildren,
    required this.expanded,
    required this.onToggle,
    required this.onTap,
  });

  String get _meta => [
        if (topic.prerequisiteIds.isNotEmpty) '${topic.prerequisiteIds.length} prereq',
        if (topic.logs.isNotEmpty) '${topic.logs.length} ${topic.logs.length == 1 ? 'log' : 'logs'}',
        if (topic.projectLinks.isNotEmpty)
          '${topic.projectLinks.length} ${topic.projectLinks.length == 1 ? 'project' : 'projects'}',
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(topic.depth * 16.0, 10, 0, 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 1))),
        child: Row(
          children: [
            if (hasChildren)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(
                    expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                    key: Key('topic-caret-${topic.id}'),
                    size: 20,
                    color: AppColors.ink(0.55),
                  ),
                ),
              )
            else
              SizedBox(
                width: 26,
                child: Center(child: StatusDot(color: AppColors.ink(0.3), size: 4)),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(topic.name,
                            style: AppTypography.body(13.5, weight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (hasChildren && topic.effectiveRating != null) ...[
                        const SizedBox(width: 6),
                        const DerivedBadge(),
                      ],
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(meta, style: AppTypography.body(10.5, color: AppColors.ink(0.5))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConfidenceDots(value: topic.effectiveRating, size: 7),
            SizedBox(
              width: 30,
              child: Text(formatRating(topic.effectiveRating),
                  textAlign: TextAlign.right, style: AppTypography.mono(11.5, color: AppColors.ink(0.7))),
            ),
          ],
        ),
      ),
    );
  }
}
