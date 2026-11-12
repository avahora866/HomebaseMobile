import 'package:flutter/material.dart';
import '../models/learning.dart';
import '../providers/learning_provider.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';
import 'confirm_dialog.dart';

/// New/edit field: name, the four capability switches and subtopic nesting.
/// Editing also offers Delete, behind a confirmation.
Future<void> showFieldFormSheet(BuildContext context, {required LearningProvider provider, LearningField? field}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _FieldFormSheet(provider: provider, field: field),
  );
}

/// A one-field sheet for naming things — new specialisation, renaming one,
/// new topic or subtopic. [onSave] returns null on success or a message to
/// show; [notes] render as muted lines under the field and [warning] as an
/// emphasised one. With [onDelete] a Delete button sits beside Save, asking
/// [deleteConfirmTitle] / [deleteConfirmMessage] first.
Future<void> showNameSheet(
  BuildContext context, {
  required String title,
  required String hint,
  String initialValue = '',
  List<String> notes = const [],
  String? warning,
  required Future<String?> Function(String name) onSave,
  Future<String?> Function()? onDelete,
  String deleteConfirmTitle = 'Delete this?',
  String deleteConfirmMessage = "This can't be undone.",
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _NameSheet(
      title: title,
      hint: hint,
      initialValue: initialValue,
      notes: notes,
      warning: warning,
      onSave: onSave,
      onDelete: onDelete,
      deleteConfirmTitle: deleteConfirmTitle,
      deleteConfirmMessage: deleteConfirmMessage,
    ),
  );
}

/// Rename a topic and, where the field uses it, change its suggested order.
Future<void> showTopicEditSheet(
  BuildContext context, {
  required LearningProvider provider,
  required Topic topic,
  required bool allowsSuggestedOrder,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _TopicEditSheet(provider: provider, topic: topic, allowsSuggestedOrder: allowsSuggestedOrder),
  );
}

// ── Field ─────────────────────────────────────────────────────────────

enum _Nesting { unlimited, flat, limited }

class _FieldFormSheet extends StatefulWidget {
  final LearningProvider provider;
  final LearningField? field;
  const _FieldFormSheet({required this.provider, this.field});

  @override
  State<_FieldFormSheet> createState() => _FieldFormSheetState();
}

class _FieldFormSheetState extends State<_FieldFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _depthCtrl;
  late bool _prerequisites;
  late bool _suggestedOrder;
  late bool _logs;
  late bool _projectLinks;
  late _Nesting _nesting;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.field != null;

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    final caps = f?.capabilities;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    // A new field starts with everything allowed — easier to narrow than to discover.
    _prerequisites = caps?.allowsPrerequisites ?? true;
    _suggestedOrder = caps?.allowsSuggestedOrder ?? true;
    _logs = caps?.allowsLogs ?? true;
    _projectLinks = caps?.allowsProjectLinks ?? true;
    final depth = caps?.maxNestingDepth;
    _nesting = depth == null ? _Nesting.unlimited : (depth == 0 ? _Nesting.flat : _Nesting.limited);
    _depthCtrl = TextEditingController(text: depth != null && depth > 0 ? '$depth' : '1');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _depthCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    int? depth;
    if (_nesting == _Nesting.flat) depth = 0;
    if (_nesting == _Nesting.limited) {
      depth = int.tryParse(_depthCtrl.text.trim());
      if (depth == null || depth < 1) {
        setState(() => _error = 'Nesting levels must be a whole number, 1 or more');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final caps = FieldCapabilities(
      allowsPrerequisites: _prerequisites,
      allowsSuggestedOrder: _suggestedOrder,
      allowsLogs: _logs,
      allowsProjectLinks: _projectLinks,
      maxNestingDepth: depth,
    );
    final result = _isEdit
        ? await widget.provider.updateField(widget.field!.id, name, caps)
        : await widget.provider.createField(name, caps);
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = result;
      });
    }
  }

  Future<void> _delete() async {
    final field = widget.field!;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this field?',
      message: '"${field.name}", all of its specialisations (Basic included) and every topic beneath them '
          "will be deleted. Linked projects are kept — only the links go. This can't be undone.",
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    final result = await widget.provider.deleteField(field.id);
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: _isEdit ? 'Edit Field' : 'New Field',
      children: [
        const _FieldLabel('Name'),
        _TextInput(controller: _nameCtrl, hint: 'e.g. Cooking'),
        const SizedBox(height: 14),
        const _FieldLabel('Capabilities'),
        _CapabilityToggle(
          label: 'Prerequisites',
          hint: 'Topics can note what they build on — never locks anything.',
          value: _prerequisites,
          onChanged: (v) => setState(() => _prerequisites = v),
        ),
        _CapabilityToggle(
          label: 'Suggested order',
          hint: 'Order sibling topics by a sort key instead of creation date.',
          value: _suggestedOrder,
          onChanged: (v) => setState(() => _suggestedOrder = v),
        ),
        _CapabilityToggle(
          label: 'Logs',
          hint: 'Timestamped notes on any topic.',
          value: _logs,
          onChanged: (v) => setState(() => _logs = v),
        ),
        _CapabilityToggle(
          label: 'Project links',
          hint: 'Link project-tracker projects to topics or specialisations.',
          value: _projectLinks,
          onChanged: (v) => setState(() => _projectLinks = v),
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Subtopic nesting'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            SelectPill(
              label: 'Unlimited',
              selected: _nesting == _Nesting.unlimited,
              onTap: () => setState(() => _nesting = _Nesting.unlimited),
            ),
            SelectPill(
              label: 'Flat',
              selected: _nesting == _Nesting.flat,
              onTap: () => setState(() => _nesting = _Nesting.flat),
            ),
            SelectPill(
              label: 'Limited',
              selected: _nesting == _Nesting.limited,
              onTap: () => setState(() => _nesting = _Nesting.limited),
            ),
          ],
        ),
        if (_nesting == _Nesting.limited) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 64,
                child: _TextInput(controller: _depthCtrl, hint: '1', keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('levels below a top-level topic',
                    style: AppTypography.body(12, color: AppColors.ink(0.6))),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _Note(_isEdit
            ? "A capability that existing data relies on can't be switched off — you'll be told what's in the way."
            : 'A Basic specialisation is created with the field.'),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 20),
        _SheetActions(
          saving: _saving,
          onSave: _save,
          onDelete: _isEdit ? _delete : null,
          deleteLabel: 'Delete field',
        ),
      ],
    );
  }
}

class _CapabilityToggle extends StatelessWidget {
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CapabilityToggle({required this.label, required this.hint, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: value ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: value ? AppColors.accent : AppColors.divider),
              ),
              child: value ? const Icon(Icons.check_rounded, size: 13, color: AppColors.bg) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.heading(13, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(hint, style: AppTypography.body(11.5, color: AppColors.ink(0.55))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Name ──────────────────────────────────────────────────────────────

class _NameSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String initialValue;
  final List<String> notes;
  final String? warning;
  final Future<String?> Function(String name) onSave;
  final Future<String?> Function()? onDelete;
  final String deleteConfirmTitle;
  final String deleteConfirmMessage;

  const _NameSheet({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.notes,
    required this.warning,
    required this.onSave,
    required this.onDelete,
    required this.deleteConfirmTitle,
    required this.deleteConfirmMessage,
  });

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initialValue);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = result;
      });
    }
  }

  void _save() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    _run(() => widget.onSave(name));
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: widget.deleteConfirmTitle,
      message: widget.deleteConfirmMessage,
    );
    if (confirmed && mounted) _run(widget.onDelete!);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.title,
      children: [
        const _FieldLabel('Name'),
        _TextInput(controller: _ctrl, hint: widget.hint, autofocus: true, onSubmitted: (_) => _save()),
        for (final note in widget.notes) ...[const SizedBox(height: 10), _Note(note)],
        if (widget.warning != null) ...[
          const SizedBox(height: 10),
          Text(widget.warning!, style: AppTypography.body(12, weight: FontWeight.w600, color: AppColors.accent800)),
        ],
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 20),
        _SheetActions(
          saving: _saving,
          onSave: _save,
          onDelete: widget.onDelete == null ? null : _delete,
        ),
      ],
    );
  }
}

// ── Topic ─────────────────────────────────────────────────────────────

class _TopicEditSheet extends StatefulWidget {
  final LearningProvider provider;
  final Topic topic;
  final bool allowsSuggestedOrder;
  const _TopicEditSheet({required this.provider, required this.topic, required this.allowsSuggestedOrder});

  @override
  State<_TopicEditSheet> createState() => _TopicEditSheetState();
}

class _TopicEditSheetState extends State<_TopicEditSheet> {
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.topic.name);
  late final TextEditingController _orderCtrl =
      TextEditingController(text: widget.topic.suggestedOrder?.toString() ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final rawOrder = _orderCtrl.text.trim();
    final order = rawOrder.isEmpty ? null : int.tryParse(rawOrder);
    if (widget.allowsSuggestedOrder && rawOrder.isNotEmpty && order == null) {
      setState(() => _error = 'Suggested order must be a whole number');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = widget.allowsSuggestedOrder
        ? await widget.provider.updateTopic(widget.topic, name: name, suggestedOrder: order, clearOrder: order == null)
        : await widget.provider.updateTopic(widget.topic, name: name);
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Edit Topic',
      children: [
        const _FieldLabel('Name'),
        _TextInput(controller: _nameCtrl, hint: 'Topic name'),
        if (widget.allowsSuggestedOrder) ...[
          const SizedBox(height: 14),
          const _FieldLabel('Suggested order'),
          SizedBox(
            width: 96,
            child: _TextInput(controller: _orderCtrl, hint: '—', keyboardType: TextInputType.number),
          ),
          const SizedBox(height: 8),
          const _Note('Sort key among siblings — gaps are fine (10, 20, 30…). Blank sorts by creation date.'),
        ],
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 20),
        _SheetActions(saving: _saving, onSave: _save),
      ],
    );
  }
}

// ── Shared pieces (styled like the project tracker's sheets) ──────────

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SheetFrame({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          border: const Border(top: BorderSide(color: AppColors.divider, width: 2)),
        ),
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 36, height: 3, color: AppColors.divider)),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.heading(17)),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final String deleteLabel;
  const _SheetActions({required this.saving, required this.onSave, this.onDelete, this.deleteLabel = 'Delete'});

  @override
  Widget build(BuildContext context) {
    final save = GestureDetector(
      onTap: saving ? null : onSave,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.field)),
        child: saving
            ? const SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
            : Text('Save', style: AppTypography.heading(14, weight: FontWeight.w700, color: AppColors.bg)),
      ),
    );
    if (onDelete == null) return save;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: saving ? null : onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Text(deleteLabel, style: AppTypography.heading(14, weight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: save),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: AppTypography.body(11, color: AppColors.ink(0.6))),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.body(12, color: AppColors.ink(0.55)).copyWith(fontStyle: FontStyle.italic));
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(text, style: AppTypography.body(12.5, color: AppColors.neutral900)),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  const _TextInput({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: AppTypography.body(13, color: AppColors.text),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppTypography.body(13, color: AppColors.ink(0.5)),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
