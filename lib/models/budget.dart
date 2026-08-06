/// Short weekday names indexed by `DateTime.weekday - 1` (Monday first),
/// shared by the transaction rows and the day-of-week filter chips.
const List<String> kWeekdayNames = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// Short month names indexed by `DateTime.month - 1`.
const List<String> kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class BudgetSummary {
  final String month;
  final double totalIncome;
  final double totalSpending;
  final double netFlow;

  BudgetSummary({
    required this.month,
    required this.totalIncome,
    required this.totalSpending,
    required this.netFlow,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      month: json['month'] as String,
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalSpending: (json['totalSpending'] as num).toDouble(),
      netFlow: (json['netFlow'] as num).toDouble(),
    );
  }
}

class BudgetTransaction {
  final int id;
  final DateTime date;
  final double amount;
  final String description;
  final String source;
  final String tags;
  final bool subscription;
  final String? note;

  BudgetTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.source,
    required this.tags,
    required this.subscription,
    this.note,
  });

  List<String> get tagList =>
      tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  /// 'Mon', 'Tue', … for the day this transaction landed on.
  String get weekdayLabel => kWeekdayNames[date.weekday - 1];

  factory BudgetTransaction.fromJson(Map<String, dynamic> json) {
    return BudgetTransaction(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      source: json['source'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      subscription: json['subscription'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
