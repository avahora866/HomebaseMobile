import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/api_service.dart';

enum BudgetStatus { idle, loading, success, error }

enum BudgetSortField { date, amount }

/// Read-only view onto `finance/budget` — fetches the monthly summary and
/// transaction list for [selectedMonth] together, defaulting to the
/// current month. There is no write path here (no note/tag editing);
/// that stays a desktop/API-only capability for now.
class BudgetProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  BudgetStatus status = BudgetStatus.idle;
  BudgetSummary? summary;
  List<BudgetTransaction> transactions = [];
  String? errorMessage;

  // ── Client-side filters over the fetched transactions ─────────────
  String searchQuery = '';
  bool subscriptionOnly = false;
  Set<String> selectedTags = {};

  /// Days of the week to keep, as `DateTime.monday`…`DateTime.sunday`.
  /// Empty means "every day".
  Set<int> selectedWeekdays = {};

  /// A single calendar day to narrow to, or null for the whole month.
  DateTime? selectedDate;

  // ── Sort — defaults to date, oldest first ───────────────────────
  BudgetSortField sortField = BudgetSortField.date;
  bool sortAscending = true;

  bool get canGoToNextMonth {
    final now = DateTime.now();
    return selectedMonth.year != now.year || selectedMonth.month != now.month;
  }

  /// Every distinct tag seen across this month's transactions, sorted —
  /// the set of chips offered for tag filtering.
  List<String> get availableTags {
    final tags = <String>{};
    for (final t in transactions) {
      tags.addAll(t.tagList);
    }
    return tags.toList()..sort();
  }

  List<BudgetTransaction> get filteredTransactions {
    final query = searchQuery.trim().toLowerCase();
    final filtered = transactions.where((t) {
      if (subscriptionOnly && !t.subscription) return false;
      if (selectedTags.isNotEmpty && !t.tagList.any(selectedTags.contains)) return false;
      if (selectedWeekdays.isNotEmpty && !selectedWeekdays.contains(t.date.weekday)) return false;
      if (selectedDate != null && !_isSameDay(t.date, selectedDate!)) return false;
      if (query.isEmpty) return true;
      final note = t.note?.toLowerCase() ?? '';
      return t.description.toLowerCase().contains(query) || note.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final cmp = sortField == BudgetSortField.date
          ? a.date.compareTo(b.date)
          : a.amount.compareTo(b.amount);
      return sortAscending ? cmp : -cmp;
    });
    return filtered;
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void toggleSubscriptionOnly() {
    subscriptionOnly = !subscriptionOnly;
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    notifyListeners();
  }

  void toggleWeekday(int weekday) {
    if (selectedWeekdays.contains(weekday)) {
      selectedWeekdays.remove(weekday);
    } else {
      selectedWeekdays.add(weekday);
    }
    notifyListeners();
  }

  void clearWeekdays() {
    if (selectedWeekdays.isEmpty) return;
    selectedWeekdays = {};
    notifyListeners();
  }

  /// Narrows to a single day. Picking a date outside [selectedMonth] moves
  /// the month with it and refetches, so the date filter doubles as a
  /// jump-to-date.
  void setSelectedDate(DateTime? date) {
    if (date == null) {
      selectedDate = null;
      notifyListeners();
      return;
    }

    selectedDate = DateTime(date.year, date.month, date.day);
    if (date.year != selectedMonth.year || date.month != selectedMonth.month) {
      selectedMonth = DateTime(date.year, date.month);
      load();
      return;
    }
    notifyListeners();
  }

  void setSortField(BudgetSortField field) {
    sortField = field;
    notifyListeners();
  }

  void toggleSortDirection() {
    sortAscending = !sortAscending;
    notifyListeners();
  }

  Future<void> load() async {
    status = BudgetStatus.loading;
    errorMessage = null;
    notifyListeners();

    final monthParam =
        '${selectedMonth.year.toString().padLeft(4, '0')}-${selectedMonth.month.toString().padLeft(2, '0')}';
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    try {
      final results = await Future.wait([
        _api.get('/finance/budget/summary?month=$monthParam'),
        _api.get(
            '/finance/budget/transactions?from=${_isoDate(firstDay)}&to=${_isoDate(lastDay)}'),
      ]);

      final summaryResponse = results[0];
      final transactionsResponse = results[1];

      if (summaryResponse['success'] == true && transactionsResponse['success'] == true) {
        summary = BudgetSummary.fromJson(summaryResponse['data'] as Map<String, dynamic>);
        transactions = (transactionsResponse['data'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(BudgetTransaction.fromJson)
            .toList();
        status = BudgetStatus.success;
      } else {
        status = BudgetStatus.error;
        errorMessage =
            (summaryResponse['error'] ?? transactionsResponse['error'] ?? 'Unknown error')
                .toString();
      }
    } catch (e) {
      status = BudgetStatus.error;
      errorMessage = e.toString();
    }

    notifyListeners();
  }

  void goToPreviousMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    selectedDate = null;
    load();
  }

  void goToNextMonth() {
    if (!canGoToNextMonth) return;
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    selectedDate = null;
    load();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
