import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

/// New/edit task bottom sheet — title, description, an inline subtask
/// checklist, status, priority (including a "None" option for a null
/// priority), and Save/Delete.
Future<void> showTaskFormSheet(BuildContext context, {required int projectId, Task? task}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _TaskFormSheet(projectId: projectId, task: task),
  );
}

class _TaskFormSheet extends StatefulWidget {
  final int projectId;
  final Task? task;
  const _TaskFormSheet({required this.projectId, this.task});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _newSubtaskCtrl = TextEditingController();
  late List<Subtask> _subtasks;
  late TaskStatus _status;
  TaskPriority? _priority;
  bool _addingSubtask = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _subtasks = List.of(t?.subtasks ?? const []);
    _status = t?.status ?? TaskStatus.todo;
    _priority = t?.priority;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _newSubtaskCtrl.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final title = _newSubtaskCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks = [..._subtasks, Subtask(title: title, done: false)];
      _newSubtaskCtrl.clear();
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final provider = context.read<ProjectProvider>();
    final description = _descCtrl.text.trim();
    final result = _isEdit
        ? await provider.updateTask(
            widget.task!,
            title: title,
            description: description.isEmpty ? null : description,
            status: _status,
            priority: _priority,
            subtasks: _subtasks,
          )
        : await provider.createTask(
            widget.projectId,
            title: title,
            description: description.isEmpty ? null : description,
            status: _status,
            priority: _priority,
            subtasks: _subtasks,
          );

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
    setState(() => _saving = true);
    final result = await context.read<ProjectProvider>().deleteTask(widget.task!);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
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
              Text(_isEdit ? 'Edit Task' : 'New Task', style: AppTypography.heading(17)),
              const SizedBox(height: 16),

              _FieldLabel('Title'),
              _TextInput(controller: _titleCtrl, hint: 'Task title'),
              const SizedBox(height: 14),

              _FieldLabel('Description'),
              _TextInput(controller: _descCtrl, hint: 'Optional notes…', minLines: 2, maxLines: 4),
              const SizedBox(height: 14),

              _FieldLabel('Subtasks'),
              const SizedBox(height: 4),
              for (int i = 0; i < _subtasks.length; i++) _SubtaskRow(
                subtask: _subtasks[i],
                onToggle: () => setState(() {
                  _subtasks = [
                    for (int j = 0; j < _subtasks.length; j++)
                      j == i ? _subtasks[j].copyWith(done: !_subtasks[j].done) : _subtasks[j],
                  ];
                }),
                onRemove: () => setState(() {
                  _subtasks = [for (int j = 0; j < _subtasks.length; j++) if (j != i) _subtasks[j]];
                }),
              ),
              if (_addingSubtask)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TextInput(
                          controller: _newSubtaskCtrl,
                          hint: 'Subtask title',
                          autofocus: true,
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _addSubtask,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppRadius.field),
                          ),
                          child: Text('Add',
                              style: AppTypography.heading(12, weight: FontWeight.w700, color: AppColors.bg)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _addingSubtask = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text('+ Add subtask',
                        style: AppTypography.heading(11.5, weight: FontWeight.w600, color: AppColors.accent)),
                  ),
                ),
              const SizedBox(height: 10),

              _FieldLabel('Status'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in TaskStatus.values)
                    SelectPill(label: s.label, selected: _status == s, onTap: () => setState(() => _status = s)),
                ],
              ),
              const SizedBox(height: 14),

              _FieldLabel('Priority'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in TaskPriority.values)
                    SelectPill(label: p.label, selected: _priority == p, onTap: () => setState(() => _priority = p)),
                  SelectPill(label: 'None', selected: _priority == null, onTap: () => setState(() => _priority = null)),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTypography.body(12.5, color: AppColors.neutral900)),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _saving ? null : _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.field),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg),
                              )
                            : Text('Save',
                                style: AppTypography.heading(14, weight: FontWeight.w700, color: AppColors.bg)),
                      ),
                    ),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saving ? null : _delete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(AppRadius.field),
                        ),
                        child: Text('Delete', style: AppTypography.heading(13, weight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  const _TextInput({
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
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

class _SubtaskRow extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  const _SubtaskRow({required this.subtask, required this.onToggle, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: subtask.done ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: subtask.done ? AppColors.accent : AppColors.divider, width: 1.5),
              ),
              child: subtask.done ? const Icon(Icons.check_rounded, size: 9, color: AppColors.bg) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              style: AppTypography.body(
                11.5,
                color: subtask.done ? AppColors.ink(0.55) : AppColors.text,
              ).copyWith(decoration: subtask.done ? TextDecoration.lineThrough : null),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: AppColors.ink(0.4)),
          ),
        ],
      ),
    );
  }
}
