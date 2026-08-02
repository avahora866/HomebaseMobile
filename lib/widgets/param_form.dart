import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';
import 'searchable_picker_sheet.dart';

class ParamForm extends StatelessWidget {
  final String jobId;
  const ParamForm({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        final job = provider.jobs.firstWhere((j) => j.id == jobId);
        final visible = job.visibleParams;
        if (visible.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionKicker('Parameters'),
            const SizedBox(height: 14),
            ...visible.map((param) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildField(context, provider, job, param),
                )),
          ],
        );
      },
    );
  }

  Widget _buildField(
      BuildContext context, JobProvider provider, Job job, JobParam param) {
    switch (param.inputType) {
      case ParamInputType.dropdown:
        return _SearchableDropdownField(
          param: param,
          onChanged: (val) => provider.setParamValue(job.id, param.key, val),
        );
      case ParamInputType.multiSelectDropdown:
        return _MultiSelectField(
          param: param,
          onToggle: (val) => provider.toggleMultiSelectValue(job.id, param.key, val),
        );
      case ParamInputType.text:
        return _TextInputField(
          param: param,
          onChanged: (val) => provider.setParamValue(job.id, param.key, val),
        );
    }
  }
}

// ── Searchable single dropdown ─────────────────────────────────────────

class _SearchableDropdownField extends StatelessWidget {
  final JobParam param;
  final ValueChanged<String?> onChanged;
  const _SearchableDropdownField({required this.param, required this.onChanged});

  /// Display label for an option — title-cased (with known acronym/compound
  /// overrides) for the media type dropdown, left as-is aside from any count
  /// suffix for everything else.
  String _displayLabel(String opt) {
    if (param.key != 'media') return _countLabelBuilder(param)?.call(opt) ?? opt;
    final base = _mediaTypeLabelOverrides[opt] ?? _titleCase(opt);
    final count = param.optionCounts[opt];
    if (count != null) return '$base ($count)';
    return param.isLoadingOptionCounts ? '$base (…)' : base;
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = param.options.contains(param.currentValue);

    return _FieldWrapper(
      label: param.label,
      isRequired: param.required,
      child: param.isLoadingOptions
          ? const _LoadingField()
          : GestureDetector(
              onTap: param.options.isEmpty
                  ? null
                  : () => showSearchablePickerSheet(
                        context: context,
                        title: param.label,
                        options: param.options,
                        selectedValues: hasSelection ? [param.currentValue!] : [],
                        multiSelect: false,
                        onToggle: (val) => onChanged(val),
                        labelBuilder: _displayLabel,
                      ),
              child: _PickerTrigger(
                placeholder: param.options.isEmpty ? 'No options available' : 'Select ${param.label}',
                displayValue: hasSelection ? _displayLabel(param.currentValue!) : null,
                enabled: param.options.isNotEmpty,
                loading: param.isLoadingOptionCounts,
              ),
            ),
    );
  }
}

/// Media type values that read as one run-together word (no camelCase
/// boundary for [_titleCase] to split on) and need an explicit two-word
/// display label.
const _mediaTypeLabelOverrides = {
  'tvshow': 'TV Show',
  'webnovel': 'Web Novel',
};

/// Splits a camelCase or lowercase option value into title-cased words,
/// e.g. 'animatedMovie' -> 'Animated Movie', 'novel' -> 'Novel'.
String _titleCase(String value) {
  final spaced = value.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (m) => ' ');
  return spaced
      .split(RegExp(r'[\s_-]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Builds a per-option display label showing its count once known, an
/// ellipsis while it's still being fetched, or the plain option name when
/// counts aren't in play for this param at all.
String Function(String value)? _countLabelBuilder(JobParam param) {
  if (param.optionCounts.isEmpty && !param.isLoadingOptionCounts) return null;
  return (opt) {
    final count = param.optionCounts[opt];
    if (count != null) return '$opt ($count)';
    return param.isLoadingOptionCounts ? '$opt (…)' : opt;
  };
}

// ── Multi-select field ────────────────────────────────────────────────

class _MultiSelectField extends StatelessWidget {
  final JobParam param;
  final ValueChanged<String> onToggle;
  const _MultiSelectField({required this.param, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      label: param.label,
      isRequired: param.required,
      child: param.isLoadingOptions
          ? const _LoadingField()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: param.options.isEmpty
                      ? null
                      : () => showSearchablePickerSheet(
                            context: context,
                            title: param.label,
                            options: param.options,
                            selectedValues: List.from(param.selectedValues),
                            multiSelect: true,
                            onToggle: onToggle,
                            labelBuilder: _countLabelBuilder(param),
                          ),
                  child: _PickerTrigger(
                    placeholder:
                        param.options.isEmpty ? 'No options available' : 'Select ${param.label}',
                    displayValue:
                        param.selectedValues.isEmpty ? null : '${param.selectedValues.length} selected',
                    enabled: param.options.isNotEmpty,
                    showCount: param.selectedValues.isNotEmpty,
                  ),
                ),
                if (param.selectedValues.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: param.selectedValues.map((val) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent100,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(val,
                                style: AppTypography.body(12,
                                    weight: FontWeight.w600, color: AppColors.accent800)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => onToggle(val),
                              child: const Icon(Icons.close_rounded, size: 13, color: AppColors.accent800),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Picker trigger button ─────────────────────────────────────────────

class _PickerTrigger extends StatelessWidget {
  final String placeholder;
  final String? displayValue;
  final bool enabled;
  final bool showCount;
  final bool loading;

  const _PickerTrigger({
    required this.placeholder,
    required this.displayValue,
    required this.enabled,
    this.showCount = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: enabled ? AppColors.divider : AppColors.divider.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayValue ?? placeholder,
              style: AppTypography.body(
                14,
                color: displayValue != null ? AppColors.text : AppColors.ink(0.45),
                weight: showCount ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (loading) ...[
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: enabled ? AppColors.ink(0.7) : AppColors.ink(0.4)),
        ],
      ),
    );
  }
}

// ── Loading placeholder ───────────────────────────────────────────────

class _LoadingField extends StatelessWidget {
  const _LoadingField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 12),
          Text('Loading options…', style: AppTypography.body(14, color: AppColors.ink(0.5))),
        ],
      ),
    );
  }
}

// ── Text input ────────────────────────────────────────────────────────

class _TextInputField extends StatelessWidget {
  final JobParam param;
  final ValueChanged<String?> onChanged;
  const _TextInputField({required this.param, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      label: param.label,
      isRequired: param.required,
      child: TextFormField(
        initialValue: param.currentValue,
        style: AppTypography.body(14),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          hintText: param.label,
          hintStyle: AppTypography.body(14, color: AppColors.ink(0.45)),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field), borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field), borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────

class _FieldWrapper extends StatelessWidget {
  final String label;
  final bool isRequired;
  final Widget child;
  const _FieldWrapper({required this.label, required this.isRequired, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.body(13, weight: FontWeight.w600)),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('*', style: AppTypography.body(13, color: AppColors.accent)),
              ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}
