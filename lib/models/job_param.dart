enum ParamInputType { dropdown, multiSelectDropdown, text }

class JobParam {
  final String key;
  final String label;
  final ParamInputType inputType;
  final bool required;

  /// For dropdown / multiSelectDropdown: the list of selectable options.
  List<String> options;

  /// Optional per-option counts (e.g. how many unread items exist for a
  /// fandom), keyed by the option value. Empty when not applicable.
  Map<String, int> optionCounts;

  /// True while [optionCounts] entries are still being fetched in the
  /// background (e.g. one request per option, resolving independently).
  /// Unlike [isLoadingOptions], the field stays interactive while this is
  /// true — options are already known, only their counts are pending.
  bool isLoadingOptionCounts;

  /// True while options are being fetched from an API.
  bool isLoadingOptions;

  /// If set, this param is only shown when [dependsOnKey] == [dependsOnValue].
  final String? dependsOnKey;
  final String? dependsOnValue;

  /// Single-select / text value.
  String? currentValue;

  /// Multi-select selected values.
  List<String> selectedValues;

  JobParam({
    required this.key,
    required this.label,
    required this.inputType,
    this.required = false,
    this.options = const [],
    this.optionCounts = const {},
    this.isLoadingOptionCounts = false,
    this.isLoadingOptions = false,
    this.dependsOnKey,
    this.dependsOnValue,
    this.currentValue,
    this.selectedValues = const [],
  });

  bool isVisible(Map<String, String?> currentValues) {
    if (dependsOnKey == null) return true;
    return currentValues[dependsOnKey] == dependsOnValue;
  }

  /// For multi-select: comma-separated string of selected values,
  /// used when building the query string / body.
  String get commaSeparatedValues => selectedValues.join(',');

  bool get hasValue {
    if (inputType == ParamInputType.multiSelectDropdown) {
      return selectedValues.isNotEmpty;
    }
    return currentValue != null && currentValue!.isNotEmpty;
  }
}
