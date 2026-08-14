import 'package:flutter_test/flutter_test.dart';

import 'package:homebase_mobile/models/budget.dart';
import 'package:homebase_mobile/providers/budget_provider.dart';

BudgetTransaction _tx(int id, DateTime date, {String tags = ''}) => BudgetTransaction(
      id: id,
      date: date,
      amount: -10,
      description: 'Transaction $id',
      source: 'test',
      tags: tags,
      subscription: false,
    );

void main() {
  // January 2026: the 5th and 12th are Mondays, the 6th a Tuesday, the 9th a
  // Friday. Every date used here sits inside `selectedMonth`, so nothing in
  // these tests triggers a fetch.
  final mon5 = DateTime(2026, 1, 5);
  final tue6 = DateTime(2026, 1, 6);
  final fri9 = DateTime(2026, 1, 9);
  final mon12 = DateTime(2026, 1, 12);

  late BudgetProvider budget;

  setUp(() {
    budget = BudgetProvider()
      ..selectedMonth = DateTime(2026, 1)
      ..transactions = [_tx(1, mon5), _tx(2, tue6), _tx(3, fri9), _tx(4, mon12)];
  });

  test('no day or date filter keeps every transaction', () {
    expect(budget.filteredTransactions.length, 4);
  });

  test('weekday filter keeps only that day of the week', () {
    budget.toggleWeekday(DateTime.monday);

    expect(budget.filteredTransactions.map((t) => t.id), [1, 4]);
  });

  test('weekday filters are additive and clear back to everything', () {
    budget.toggleWeekday(DateTime.monday);
    budget.toggleWeekday(DateTime.friday);
    expect(budget.filteredTransactions.map((t) => t.id), [1, 3, 4]);

    budget.toggleWeekday(DateTime.monday);
    expect(budget.filteredTransactions.map((t) => t.id), [3]);

    budget.clearWeekdays();
    expect(budget.filteredTransactions.length, 4);
  });

  test('date filter narrows to a single day and clears back', () {
    budget.setSelectedDate(tue6);
    expect(budget.filteredTransactions.map((t) => t.id), [2]);

    budget.setSelectedDate(null);
    expect(budget.filteredTransactions.length, 4);
  });

  test('date filter ignores the time of day on a transaction', () {
    budget.transactions = [_tx(5, DateTime(2026, 1, 6, 21, 30))];
    budget.setSelectedDate(DateTime(2026, 1, 6));

    expect(budget.filteredTransactions.map((t) => t.id), [5]);
  });

  test('day and date filters compose with the existing tag filter', () {
    budget.transactions = [
      _tx(1, mon5, tags: 'food'),
      _tx(2, mon12, tags: 'food'),
      _tx(3, mon12, tags: 'travel'),
    ];
    budget.toggleWeekday(DateTime.monday);
    budget.toggleTag('food');
    budget.setSelectedDate(mon12);

    expect(budget.filteredTransactions.map((t) => t.id), [2]);
  });

  test('a date with no transactions filters everything out', () {
    budget.setSelectedDate(DateTime(2026, 1, 7));

    expect(budget.filteredTransactions, isEmpty);
  });

  test('weekdayLabel names the day the transaction landed on', () {
    expect(_tx(1, mon5).weekdayLabel, 'Mon');
    expect(_tx(2, tue6).weekdayLabel, 'Tue');
    expect(_tx(3, fri9).weekdayLabel, 'Fri');
  });
}
