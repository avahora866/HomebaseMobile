import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/api_service.dart';

enum BudgetStatus { idle, loading, success, error }

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

  bool get canGoToNextMonth {
    final now = DateTime.now();
    return selectedMonth.year != now.year || selectedMonth.month != now.month;
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
    load();
  }

  void goToNextMonth() {
    if (!canGoToNextMonth) return;
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    load();
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
