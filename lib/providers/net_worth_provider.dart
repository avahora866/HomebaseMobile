import 'package:flutter/material.dart';
import '../models/net_worth.dart';
import '../services/api_service.dart';

enum NetWorthStatus { idle, loading, success, error }

/// Read/write view onto `finance/networth` — unlike the budget, the net worth
/// accounts are fully editable from the phone (add, edit, delete), since
/// they're hand-maintained figures rather than imported data.
class NetWorthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  static const String _accountsPath = '/finance/networth/accounts';

  NetWorthStatus status = NetWorthStatus.idle;
  NetWorthSummary? summary;
  String? errorMessage;

  /// Set while a create/update/delete is in flight, so the form can disable
  /// its buttons; separate from [status] so the list doesn't flash a spinner.
  bool saving = false;

  List<NetWorthAccount> get accounts => summary?.accounts ?? const [];

  /// The accounts grouped under their category, in the category order the
  /// server returns totals in.
  List<MapEntry<NetWorthCategoryTotal, List<NetWorthAccount>>> get grouped {
    final categories = summary?.categories ?? const <NetWorthCategoryTotal>[];
    return categories
        .map((c) => MapEntry(
              c,
              accounts.where((a) => a.category == c.category).toList(),
            ))
        .toList();
  }

  Future<void> load() async {
    status = NetWorthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/finance/networth/summary');
      if (response['success'] == true) {
        summary = NetWorthSummary.fromJson(response['data'] as Map<String, dynamic>);
        status = NetWorthStatus.success;
      } else {
        status = NetWorthStatus.error;
        errorMessage = (response['error'] ?? 'Unknown error').toString();
      }
    } catch (e) {
      status = NetWorthStatus.error;
      errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Returns null on success, or a message to show on the form when the write
  /// failed. The list is reloaded on success so the totals stay in step.
  Future<String?> addAccount({
    required String name,
    required NetWorthCategory category,
    required double balance,
  }) {
    return _write(() => _api.post(
          _accountsPath,
          NetWorthAccount.toRequestJson(name: name, category: category, balance: balance),
        ));
  }

  Future<String?> updateAccount({
    required int id,
    required String name,
    required NetWorthCategory category,
    required double balance,
  }) {
    return _write(() => _api.put(
          '$_accountsPath/$id',
          NetWorthAccount.toRequestJson(name: name, category: category, balance: balance),
        ));
  }

  Future<String?> deleteAccount(int id) {
    return _write(() => _api.delete('$_accountsPath/$id'));
  }

  Future<String?> _write(Future<Map<String, dynamic>> Function() request) async {
    saving = true;
    notifyListeners();

    String? failure;
    try {
      final response = await request();
      if (response['success'] != true) {
        failure = (response['error'] ?? 'Unknown error').toString();
      }
    } catch (e) {
      failure = e.toString();
    } finally {
      saving = false;
      notifyListeners();
    }

    if (failure == null) {
      await load();
    }
    return failure;
  }
}
