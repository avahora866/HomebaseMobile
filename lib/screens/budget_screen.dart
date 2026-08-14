import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/atoms.dart';
import '../widgets/budget_transaction_card.dart';
import '../widgets/result_states.dart';

const List<String> _fullMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Read-only view of the budget: this month's income/spending/net summary
/// plus the transactions behind it. There is no create/edit/upload flow
/// here — that's a desktop/API-only capability for now.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BudgetProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Budget', style: AppTypography.heading(17))),
                ],
              ),
            ),
            Expanded(
              child: Consumer<BudgetProvider>(
                builder: (context, budget, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                    children: [
                      _MonthSelector(budget: budget),
                      const SizedBox(height: 16),
                      if (budget.status == BudgetStatus.loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                        )
                      else if (budget.status == BudgetStatus.error)
                        ErrorResultCard(message: budget.errorMessage ?? 'Unknown error')
                      else if (budget.status == BudgetStatus.success) ...[
                        if (budget.summary != null) _SummaryCard(summary: budget.summary!),
                        const SizedBox(height: 24),
                        _FilterBar(budget: budget),
                        const SizedBox(height: 16),
                        _SortBar(budget: budget),
                        const SizedBox(height: 14),
                        SectionKicker('Transactions', margin: const EdgeInsets.only(bottom: 10)),
                        if (budget.filteredTransactions.isEmpty)
                          const EmptyResultCard()
                        else
                          for (final transaction in budget.filteredTransactions)
                            BudgetTransactionCard(transaction: transaction),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final BudgetProvider budget;
  const _MonthSelector({required this.budget});

  @override
  Widget build(BuildContext context) {
    final month = budget.selectedMonth;
    final label = '${_fullMonthNames[month.month - 1]} ${month.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: budget.goToPreviousMonth,
          child: const Icon(Icons.chevron_left_rounded, size: 26, color: AppColors.text),
        ),
        Text(label, style: AppTypography.heading(15)),
        GestureDetector(
          onTap: budget.canGoToNextMonth ? budget.goToNextMonth : null,
          child: Icon(
            Icons.chevron_right_rounded,
            size: 26,
            color: budget.canGoToNextMonth ? AppColors.text : AppColors.ink(0.25),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final BudgetProvider budget;
  const _FilterBar({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: AppColors.ink(0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: budget.setSearchQuery,
                  style: AppTypography.body(13, color: AppColors.text),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Search description or note…',
                    hintStyle: AppTypography.body(13, color: AppColors.ink(0.6)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DayFilterRow(budget: budget),
        const SizedBox(height: 10),
        _DateFilterRow(budget: budget),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Subscriptions',
              selected: budget.subscriptionOnly,
              onTap: budget.toggleSubscriptionOnly,
            ),
            for (final tag in budget.availableTags)
              _FilterChip(
                label: tag,
                selected: budget.selectedTags.contains(tag),
                onTap: () => budget.toggleTag(tag),
              ),
          ],
        ),
      ],
    );
  }
}

/// Mon–Sun chips: a day-of-week filter over the month's transactions.
/// Selecting none means every day, matching how the tag chips behave.
class _DayFilterRow extends StatelessWidget {
  final BudgetProvider budget;
  const _DayFilterRow({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Day', style: AppTypography.body(12, color: AppColors.ink(0.55))),
            const Spacer(),
            if (budget.selectedWeekdays.isNotEmpty)
              GestureDetector(
                onTap: budget.clearWeekdays,
                child: Text(
                  'Clear',
                  style: AppTypography.body(12, weight: FontWeight.w600, color: AppColors.accent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
              _FilterChip(
                label: kWeekdayNames[weekday - 1],
                selected: budget.selectedWeekdays.contains(weekday),
                onTap: () => budget.toggleWeekday(weekday),
                compact: true,
              ),
          ],
        ),
      ],
    );
  }
}

/// A single-date filter. Tapping opens the calendar; picking a date in
/// another month moves the whole screen to that month.
class _DateFilterRow extends StatelessWidget {
  final BudgetProvider budget;
  const _DateFilterRow({required this.budget});

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final month = budget.selectedMonth;

    // The month selector never goes past the current month, so neither does
    // the calendar. It opens on the selected date, else on the last day of
    // the month being viewed (today, when that month is this one).
    final lastDate = DateTime(now.year, now.month + 1, 0);
    final decadeAgo = DateTime(now.year - 10);
    final firstDate = month.isBefore(decadeAgo) ? month : decadeAgo;

    var initial = budget.selectedDate ??
        (month.year == now.year && month.month == now.month
            ? now
            : DateTime(month.year, month.month + 1, 0));
    if (initial.isAfter(lastDate)) initial = lastDate;
    if (initial.isBefore(firstDate)) initial = firstDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) budget.setSelectedDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final date = budget.selectedDate;
    final selected = date != null;
    final label = date == null
        ? 'Pick a date'
        : '${kWeekdayNames[date.weekday - 1]} ${date.day} ${kMonthAbbr[date.month - 1]}';

    return Row(
      children: [
        Text('Date', style: AppTypography.body(12, color: AppColors.ink(0.55))),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: selected ? AppColors.accent : AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: selected ? AppColors.bg : AppColors.ink(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.heading(
                    11,
                    weight: FontWeight.w600,
                    color: selected ? AppColors.bg : AppColors.text,
                  ).copyWith(letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
        if (selected) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => budget.setSelectedDate(null),
            child: Icon(Icons.close_rounded, size: 16, color: AppColors.ink(0.6)),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.accent : AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTypography.heading(
            11,
            weight: FontWeight.w600,
            color: selected ? AppColors.bg : AppColors.text,
          ).copyWith(letterSpacing: 0.3),
        ),
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  final BudgetProvider budget;
  const _SortBar({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Sort', style: AppTypography.body(12, color: AppColors.ink(0.55))),
        const SizedBox(width: 10),
        _FilterChip(
          label: 'Date',
          selected: budget.sortField == BudgetSortField.date,
          onTap: () => budget.setSortField(BudgetSortField.date),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Amount',
          selected: budget.sortField == BudgetSortField.amount,
          onTap: () => budget.setSortField(BudgetSortField.amount),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: budget.toggleSortDirection,
          child: Icon(
            budget.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 18,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BudgetSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: 'Income', amount: summary.totalIncome, accent: true),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Spending', amount: summary.totalSpending),
          const SizedBox(height: 10),
          const ThickDivider(),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Net',
            amount: summary.netFlow,
            accent: summary.netFlow >= 0,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool accent;
  final bool bold;
  const _SummaryRow({required this.label, required this.amount, this.accent = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(13, color: AppColors.ink(0.65))),
        Text(
          '£${amount.toStringAsFixed(2)}',
          style: AppTypography.mono(
            14,
            weight: bold ? FontWeight.w700 : FontWeight.w600,
            color: accent ? AppColors.accent : AppColors.text,
          ),
        ),
      ],
    );
  }
}
