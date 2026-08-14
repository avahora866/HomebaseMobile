import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

/// New/edit project bottom sheet. Category has no separate management
/// screen — new ones are created inline, right where they're used, via the
/// dashed "+ Add" chip.
Future<void> showProjectFormSheet(BuildContext context, {Project? project}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _ProjectFormSheet(project: project),
  );
}

class _ProjectFormSheet extends StatefulWidget {
  final Project? project;
  const _ProjectFormSheet({this.project});

  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  int? _categoryId;
  late ProjectStatus _status;
  bool _addingCategory = false;
  final _newCategoryCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.project != null;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _categoryId = p?.categoryId;
    _status = p?.status ?? ProjectStatus.idea;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _newCategoryCtrl.text.trim();
    if (name.isEmpty) return;
    final result = await context.read<ProjectProvider>().createCategory(name);
    if (!mounted) return;
    if (result is ProjectCategory) {
      setState(() {
        _categoryId = result.id;
        _addingCategory = false;
        _newCategoryCtrl.clear();
      });
    } else {
      setState(() => _error = result.toString());
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Pick a category');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final provider = context.read<ProjectProvider>();
    final description = _descCtrl.text.trim();
    final result = _isEdit
        ? await provider.updateProject(
            widget.project!.id,
            name: name,
            description: description.isEmpty ? null : description,
            status: _status,
            categoryId: _categoryId!,
          )
        : await provider.createProject(
            name: name,
            description: description.isEmpty ? null : description,
            status: _status,
            categoryId: _categoryId!,
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = context.watch<ProjectProvider>().categories;

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
              Text(_isEdit ? 'Edit Project' : 'New Project', style: AppTypography.heading(17)),
              const SizedBox(height: 16),

              _FieldLabel('Name'),
              _TextInput(controller: _nameCtrl, hint: 'Project name'),
              const SizedBox(height: 14),

              _FieldLabel('Description'),
              _TextInput(controller: _descCtrl, hint: 'Optional notes…', minLines: 2, maxLines: 4),
              const SizedBox(height: 14),

              _FieldLabel('Category'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final c in categories)
                    _CategoryChip(
                      label: c.name,
                      selected: _categoryId == c.id,
                      onTap: () => setState(() => _categoryId = c.id),
                    ),
                  if (!_addingCategory)
                    _CategoryChip(
                      label: '+ Add',
                      selected: false,
                      dashed: true,
                      onTap: () => setState(() => _addingCategory = true),
                    ),
                ],
              ),
              if (_addingCategory) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TextInput(
                        controller: _newCategoryCtrl,
                        hint: 'Category name',
                        autofocus: true,
                        onSubmitted: (_) => _addCategory(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _addCategory,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              ],
              const SizedBox(height: 14),

              _FieldLabel('Status'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in ProjectStatus.values)
                    SelectPill(
                      label: s.label,
                      selected: _status == s,
                      onTap: () => setState(() => _status = s),
                    ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTypography.body(12.5, color: AppColors.neutral900)),
              ],

              const SizedBox(height: 20),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  width: double.infinity,
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = (selected || dashed) ? AppColors.accent : AppColors.text;
    final borderColor = (selected || dashed) ? AppColors.accent : AppColors.divider;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: dashed
              ? null
              : Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.tag),
        ),
        foregroundDecoration: dashed
            ? _DashedBorder(color: AppColors.accent, radius: AppRadius.tag)
            : null,
        child: Text(label, style: AppTypography.heading(10.5, weight: FontWeight.w600, color: color)),
      ),
    );
  }
}

/// A dashed-border decoration for the "+ Add category" chip — no Flutter
/// built-in for dashed borders, so this paints one directly.
class _DashedBorder extends Decoration {
  final Color color;
  final double radius;
  const _DashedBorder({required this.color, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DashedBorderPainter(color, radius);
}

class _DashedBorderPainter extends BoxPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dashWidth = 3.0;
      const dashGap = 2.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }
}
