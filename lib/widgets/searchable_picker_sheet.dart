import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A modal bottom sheet with a search field and a scrollable list.
/// Works for both single-select and multi-select use cases.
///
/// For single-select: pass [selectedValues] = [] and handle [onToggle] to
/// pop after selecting.
/// For multi-select: pass the current [selectedValues]; user closes manually.
Future<void> showSearchablePickerSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required List<String> selectedValues,
  required void Function(String value) onToggle,
  bool multiSelect = true,
  // Optional per-option display label override (e.g. to append a count),
  // used only for rendering — search and selection still key off [options].
  String Function(String value)? labelBuilder,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _SearchablePickerSheet(
      title: title,
      options: options,
      selectedValues: selectedValues,
      onToggle: onToggle,
      multiSelect: multiSelect,
      labelBuilder: labelBuilder,
    ),
  );
}

class _SearchablePickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedValues;
  final void Function(String) onToggle;
  final bool multiSelect;
  final String Function(String value)? labelBuilder;

  const _SearchablePickerSheet({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    required this.multiSelect,
    this.labelBuilder,
  });

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = [];
  late List<String> _selectedValues; // local mirror — updates immediately on tap

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.options);
    _selectedValues = List.from(widget.selectedValues);
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.options.where((o) => o.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      // Push the sheet up as the keyboard slides in
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
        ),
        constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle + header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(width: 36, height: 3, color: AppColors.divider),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.title,
                            style: AppTypography.heading(16, weight: FontWeight.w600)),
                      ),
                      if (widget.multiSelect && _selectedValues.isNotEmpty)
                        Text(
                          '${_selectedValues.length} selected',
                          style: AppTypography.body(13, color: AppColors.accent),
                        ),
                      if (!widget.multiSelect)
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('Done',
                              style: AppTypography.heading(13,
                                  weight: FontWeight.w600, color: AppColors.accent)),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Search field ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: AppTypography.body(14),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: AppTypography.body(14, color: AppColors.ink(0.5)),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.ink(0.5)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _filtered = List.from(widget.options));
                          },
                          child: Icon(Icons.close_rounded, size: 16, color: AppColors.ink(0.5)),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 2, color: AppColors.divider),

            // ── Results list ─────────────────────────────────────────
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No matches', style: AppTypography.body(14, color: AppColors.ink(0.5))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final opt = _filtered[i];
                        final selected = _selectedValues.contains(opt);
                        return _OptionTile(
                          label: widget.labelBuilder?.call(opt) ?? opt,
                          selected: selected,
                          multiSelect: widget.multiSelect,
                          onTap: () {
                            widget.onToggle(opt);
                            if (!widget.multiSelect) {
                              Navigator.pop(context);
                            } else {
                              setState(() {
                                if (_selectedValues.contains(opt)) {
                                  _selectedValues.remove(opt);
                                } else {
                                  _selectedValues.add(opt);
                                }
                              });
                            }
                          },
                        );
                      },
                    ),
            ),

            if (bottomInset == 0) SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.body(14,
                      weight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.text : AppColors.ink(0.75))),
            ),
            if (multiSelect)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.accent : AppColors.divider),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 13, color: AppColors.bg)
                    : null,
              )
            else if (selected)
              const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
