import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning.dart';
import '../providers/learning_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_dots.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/learning_sheets.dart';
import '../widgets/learning_widgets.dart';

/// One topic: its confidence (tap to rate on a leaf, read-only when derived
/// from subtopics), subtopics, and — where the field's capabilities allow —
/// prerequisites, logs and linked projects. Moving to a subtopic or to any
/// ancestor in the breadcrumb swaps the topic in place, like the web app's
/// drawer, so Back always returns to the tree.
class TopicDetailScreen extends StatefulWidget {
  final int specialisationId;
  final int topicId;
  const TopicDetailScreen({super.key, required this.specialisationId, required this.topicId});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late int _topicId = widget.topicId;
  final _logCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _logCtrl.dispose();
    super.dispose();
  }

  LearningProvider get _provider => context.read<LearningProvider>();

  void _goTo(int topicId) {
    _logCtrl.clear();
    setState(() => _topicId = topicId);
  }

  /// Runs a write with the screen marked busy, showing any error.
  Future<String?> _write(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return error;
    setState(() => _busy = false);
    showWriteError(context, error);
    return error;
  }

  Future<void> _delete(SpecialisationDetail detail, Topic topic) async {
    final n = detail.descendantCount(topic.id);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this topic?',
      message: '"${topic.name}"${n == 0 ? '' : ' and its $n ${n == 1 ? 'subtopic' : 'subtopics'}'} will be deleted, '
          'with their logs, prerequisite links and project links. Other topics and the linked projects themselves '
          "are kept. This can't be undone.",
    );
    if (!confirmed || !mounted) return;
    final navigator = Navigator.of(context);
    final error = await _write(() => _provider.deleteTopic(topic.id));
    if (error == null) navigator.pop();
  }

  void _addSubtopic(SpecialisationDetail detail, Topic topic) {
    showNameSheet(
      context,
      title: 'New Subtopic',
      hint: 'Subtopic name',
      notes: [
        'Under ${[...detail.ancestorsOf(topic).map((a) => a.name), topic.name].join(' › ')}.',
        "Placement is fixed at creation — topics can't be moved later.",
      ],
      warning: topic.confidenceRating == null
          ? null
          : '"${topic.name}" is rated ${topic.confidenceRating} by hand. Adding a subtopic discards that rating — '
              'from then on it’s derived from its subtopics.',
      onSave: (name) => _provider.createTopic(detail.id, name, parentTopicId: topic.id),
    );
  }

  Future<void> _addPrerequisite(SpecialisationDetail detail, Topic topic) async {
    final requiresId = await pickPrerequisite(context, detail, topic);
    if (requiresId == null || !mounted) return;
    await _write(() => _provider.addPrerequisite(topic.id, requiresId));
  }

  Future<void> _addLog(Topic topic) async {
    final note = _logCtrl.text.trim();
    if (note.isEmpty || _busy) return;
    final error = await _write(() => _provider.addLog(topic.id, note));
    if (error == null) _logCtrl.clear();
  }

  Future<void> _linkProject(Topic topic) async {
    final projectId = await pickProject(context, _provider, topic.projectLinks.map((l) => l.projectId));
    if (projectId == null || !mounted) return;
    await _write(() => _provider.linkProject(projectId, topicId: topic.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<LearningProvider>(
          builder: (context, provider, _) {
            final detail = provider.detail(widget.specialisationId);
            final topic = detail?.topic(_topicId);
            if (detail == null || topic == null) return const SizedBox.shrink();
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
                        child: Text(topic.name,
                            style: AppTypography.heading(17), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: () => showTopicEditSheet(
                          context,
                          provider: provider,
                          topic: topic,
                          allowsSuggestedOrder: detail.capabilities.allowsSuggestedOrder,
                        ),
                        child: const Icon(Icons.edit_outlined, size: 19, color: AppColors.text),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _delete(detail, topic),
                        child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.text),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _body(detail, topic)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(SpecialisationDetail detail, Topic topic) {
    final caps = detail.capabilities;
    final kids = detail.childrenOf(topic.id);
    final prerequisites = [for (final id in topic.prerequisiteIds) ?detail.topic(id)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
      children: [
        _Breadcrumb(detail: detail, topic: topic, onSelect: _goTo),
        const SizedBox(height: 14),
        _ConfidenceCard(
          topic: topic,
          subtopicCount: kids.length,
          onSet: topic.derived || _busy ? null : (rating) => _write(() => _provider.rateTopic(topic, rating)),
        ),
        if (caps.allowsSuggestedOrder) ...[
          const SizedBox(height: 10),
          Text(
            topic.suggestedOrder == null
                ? 'No suggested order — sorts by creation date.'
                : 'Suggested order ${topic.suggestedOrder}',
            style: AppTypography.body(12, color: AppColors.ink(0.55)),
          ),
        ],
        if (kids.isNotEmpty) ...[
          const SizedBox(height: 22),
          const LearningSectionHeader('Subtopics'),
          for (final kid in kids) _SubtopicRow(topic: kid, onTap: () => _goTo(kid.id)),
        ],
        if (caps.allowsPrerequisites) ...[
          const SizedBox(height: 22),
          LearningSectionHeader(
            'Prerequisites',
            actionLabel: detail.topics.length > 1 ? '+ Add' : null,
            onAction: () => _addPrerequisite(detail, topic),
          ),
          Text('Informational only — prerequisites never lock a topic.',
              style: AppTypography.body(11.5, color: AppColors.ink(0.5)).copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          if (prerequisites.isEmpty)
            Text('None set.', style: AppTypography.body(13, color: AppColors.ink(0.5)))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in prerequisites)
                  _PrerequisiteChip(
                    name: p.name,
                    onRemove: () => _write(() => _provider.removePrerequisite(topic.id, p.id)),
                  ),
              ],
            ),
        ],
        if (caps.allowsLogs) ...[
          const SizedBox(height: 22),
          const LearningSectionHeader('Logs'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _logCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addLog(topic),
                  style: AppTypography.body(13),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Add a log entry…',
                    hintStyle: AppTypography.body(13, color: AppColors.ink(0.5)),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _addLog(topic),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Text('Add', style: AppTypography.heading(12, weight: FontWeight.w700, color: AppColors.bg)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (topic.logs.isEmpty)
            Text('No entries yet.', style: AppTypography.body(13, color: AppColors.ink(0.5)))
          else
            for (final log in topic.logs)
              _LogEntry(log: log, onDelete: () => _write(() => _provider.deleteLog(topic.id, log.id))),
        ],
        if (caps.allowsProjectLinks) ...[
          const SizedBox(height: 22),
          LearningSectionHeader('Linked projects', actionLabel: '+ Link Project', onAction: () => _linkProject(topic)),
          if (topic.projectLinks.isEmpty)
            Text('No projects linked.', style: AppTypography.body(13, color: AppColors.ink(0.5)))
          else
            for (final link in topic.projectLinks)
              ProjectLinkRow(link: link, onUnlink: () => _write(() => _provider.unlinkProject(link.id))),
        ],
        const SizedBox(height: 26),
        _AddSubtopicButton(
          maxNestingDepth: caps.maxNestingDepth,
          enabled: detail.canNestUnder(topic),
          onTap: () => _addSubtopic(detail, topic),
        ),
      ],
    );
  }
}

/// Field › specialisation › ancestors — each ancestor jumps straight to that
/// topic.
class _Breadcrumb extends StatelessWidget {
  final SpecialisationDetail detail;
  final Topic topic;
  final ValueChanged<int> onSelect;
  const _Breadcrumb({required this.detail, required this.topic, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.heading(10.5, weight: FontWeight.w700, color: AppColors.ink(0.55))
        .copyWith(letterSpacing: 0.9);
    Widget sep() => Text('›', style: style);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(detail.fieldName.toUpperCase(), style: style),
        sep(),
        Text(detail.name.toUpperCase(), style: style),
        for (final ancestor in detail.ancestorsOf(topic)) ...[
          sep(),
          GestureDetector(
            onTap: () => onSelect(ancestor.id),
            child: Text(ancestor.name.toUpperCase(), style: style.copyWith(color: AppColors.accent)),
          ),
        ],
      ],
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  final Topic topic;
  final int subtopicCount;
  final ValueChanged<int>? onSet;
  const _ConfidenceCard({required this.topic, required this.subtopicCount, required this.onSet});

  String get _note {
    if (topic.derived) {
      return 'Averaged from $subtopicCount ${subtopicCount == 1 ? 'subtopic' : 'subtopics'}. '
          'Unrated subtopics are excluded.';
    }
    return topic.confidenceRating == null
        ? 'Unrated. Tap a dot to set 1–5.'
        : 'Set by hand — this is a leaf topic. Tap the same dot again to clear it.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONFIDENCE',
              style: AppTypography.heading(11, weight: FontWeight.w700, color: AppColors.ink(0.55))
                  .copyWith(letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConfidenceDots(value: topic.effectiveRating, size: 18, gap: 10, onSet: topic.derived ? null : onSet),
              Text(formatRating(topic.effectiveRating), style: AppTypography.heading(20)),
              if (topic.derived) const DerivedBadge(label: 'DERIVED · READ-ONLY'),
            ],
          ),
          const SizedBox(height: 4),
          Text(_note, style: AppTypography.body(12, color: AppColors.ink(0.6))),
        ],
      ),
    );
  }
}

class _SubtopicRow extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  const _SubtopicRow({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(topic.name,
                  style: AppTypography.body(13, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ConfidenceDots(value: topic.effectiveRating, size: 7),
            const SizedBox(width: 8),
            Text(formatRating(topic.effectiveRating), style: AppTypography.mono(11.5, color: AppColors.ink(0.7))),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.ink(0.4)),
          ],
        ),
      ),
    );
  }
}

class _PrerequisiteChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _PrerequisiteChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(color: AppColors.accent100, borderRadius: BorderRadius.circular(AppRadius.tag)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: AppTypography.body(12, weight: FontWeight.w600, color: AppColors.accent800)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.close_rounded, size: 14, color: AppColors.accent800),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final TopicLog log;
  final VoidCallback onDelete;
  const _LogEntry({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatLogDate(log.createdAt), style: AppTypography.body(10.5, color: AppColors.ink(0.5))),
                const SizedBox(height: 3),
                Text(log.note, style: AppTypography.body(13).copyWith(height: 1.45)),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: AppColors.ink(0.45)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSubtopicButton extends StatelessWidget {
  final int? maxNestingDepth;
  final bool enabled;
  final VoidCallback onTap;
  const _AddSubtopicButton({required this.maxNestingDepth, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = enabled
        ? '+ Add Subtopic'
        : (maxNestingDepth == 0 ? 'Subtopics not allowed (flat field)' : 'Max nesting depth reached');
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? AppColors.accent : AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Text(label,
              style: AppTypography.heading(13,
                  weight: FontWeight.w700, color: enabled ? AppColors.accent : AppColors.ink(0.6))),
        ),
      ),
    );
  }
}
