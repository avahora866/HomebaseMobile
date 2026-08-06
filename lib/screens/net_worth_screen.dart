import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/net_worth.dart';
import '../providers/net_worth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/atoms.dart';
import '../utils/formatting.dart';
import '../widgets/net_worth_account_sheet.dart';
import '../widgets/result_states.dart';

/// The net worth tracker: every hand-maintained balance, grouped by category,
/// with add / edit / delete. The figures live in the server's
/// `net_worth_accounts` table, so the phone and HomebaseWeb see the same rows.
class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NetWorthProvider>().load();
    });
  }

  Future<void> _openSheet({NetWorthAccount? account}) async {
    final provider = context.read<NetWorthProvider>();
    final saved = await showNetWorthAccountSheet(
      context: context,
      account: account,
      provider: provider,
    );
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
        child: const Icon(Icons.add_rounded),
      ),
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
                  Expanded(child: Text('Net Worth', style: AppTypography.heading(17))),
                ],
              ),
            ),
            Expanded(
              child: Consumer<NetWorthProvider>(
                builder: (context, netWorth, _) {
                  if (netWorth.status == NetWorthStatus.loading ||
                      netWorth.status == NetWorthStatus.idle) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                  }
                  if (netWorth.status == NetWorthStatus.error) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                      children: [ErrorResultCard(message: netWorth.errorMessage ?? 'Unknown error')],
                    );
                  }

                  final summary = netWorth.summary;
                  if (summary == null) return const SizedBox.shrink();

                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: netWorth.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
                      children: [
                        _SummaryCard(summary: summary),
                        const SizedBox(height: 24),
                        if (summary.accounts.isEmpty)
                          const _NoAccountsCard()
                        else
                          for (final group in netWorth.grouped) ...[
                            _CategoryHeader(total: group.key),
                            const SizedBox(height: 10),
                            for (final account in group.value)
                              _AccountCard(
                                account: account,
                                onTap: () => _openSheet(account: account),
                              ),
                            const SizedBox(height: 14),
                          ],
                      ],
                    ),
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

class _SummaryCard extends StatelessWidget {
  final NetWorthSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NET WORTH',
            style: AppTypography.heading(11, weight: FontWeight.w700, color: AppColors.ink(0.55))
                .copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(summary.netWorth),
            style: AppTypography.heading(
              30,
              color: summary.netWorth < 0 ? AppColors.neutral900 : AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          const ThickDivider(),
          const SizedBox(height: 12),
          _Row(label: 'Assets', amount: summary.totalAssets, accent: true),
          const SizedBox(height: 10),
          _Row(label: 'Liabilities', amount: summary.totalLiabilities),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double amount;
  final bool accent;
  const _Row({required this.label, required this.amount, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(13, color: AppColors.ink(0.65))),
        Text(
          formatMoney(amount),
          style: AppTypography.mono(
            14,
            weight: FontWeight.w600,
            color: accent ? AppColors.accent : AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final NetWorthCategoryTotal total;
  const _CategoryHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SectionKicker(total.label),
        Text(
          '${total.category.isLiability ? '−' : ''}${formatMoney(total.total)}',
          style: AppTypography.mono(12, color: AppColors.ink(0.6)),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final NetWorthAccount account;
  final VoidCallback onTap;
  const _AccountCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTypography.heading(14, weight: FontWeight.w600)),
                    if (account.updatedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Updated ${_formatDate(account.updatedAt!)}',
                        style: AppTypography.body(11.5, color: AppColors.ink(0.5)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${account.category.isLiability ? '−' : ''}${formatMoney(account.balance)}',
                style: AppTypography.mono(
                  14,
                  weight: FontWeight.w600,
                  color: account.signedBalance < 0 ? AppColors.neutral900 : AppColors.text,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAccountsCard extends StatelessWidget {
  const _NoAccountsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 30, color: AppColors.ink(0.4)),
          const SizedBox(height: 12),
          Text('No accounts yet', style: AppTypography.heading(15, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first balance.',
            style: AppTypography.body(13, color: AppColors.ink(0.55)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
