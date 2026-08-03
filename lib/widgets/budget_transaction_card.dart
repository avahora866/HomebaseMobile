import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A single read-only transaction row: date, description, source, any
/// tags, and the amount — green for income, ink for spending.
class BudgetTransactionCard extends StatelessWidget {
  final BudgetTransaction transaction;
  const BudgetTransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final date = transaction.date;
    final dateLabel = '${_monthNames[date.month - 1]} ${date.day}';

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(dateLabel, style: AppTypography.body(11.5, color: AppColors.ink(0.55))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTypography.body(13.5, weight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.tagList.isNotEmpty || transaction.subscription) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (transaction.subscription) const OutlineTag('Subscription'),
                      for (final tag in transaction.tagList) OutlineTag(tag),
                    ],
                  ),
                ],
                if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    transaction.note!,
                    style: AppTypography.body(12, color: AppColors.ink(0.6)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
            style: AppTypography.mono(
              13.5,
              weight: FontWeight.w600,
              color: isIncome ? AppColors.accent : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
