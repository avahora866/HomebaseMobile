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
                        const SizedBox(height: 20),
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
        const SizedBox(height: 10),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
