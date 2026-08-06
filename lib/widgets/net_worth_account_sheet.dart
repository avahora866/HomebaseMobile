import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/net_worth.dart';
import '../providers/net_worth_provider.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

/// Add / edit / delete for one net worth account. Pass [account] to edit an
/// existing row, omit it to create a new one.
///
/// Resolves to a message to show in a snackbar once the write has gone
/// through, or null if the sheet was dismissed without saving.
Future<String?> showNetWorthAccountSheet({
  required BuildContext context,
  required NetWorthProvider provider,
  NetWorthAccount? account,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _NetWorthAccountSheet(provider: provider, account: account),
  );
}

class _NetWorthAccountSheet extends StatefulWidget {
  final NetWorthProvider provider;
  final NetWorthAccount? account;

  const _NetWorthAccountSheet({required this.provider, this.account});

  @override
  State<_NetWorthAccountSheet> createState() => _NetWorthAccountSheetState();
}

class _NetWorthAccountSheetState extends State<_NetWorthAccountSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late NetWorthCategory _category;

  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameCtrl = TextEditingController(text: account?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: account == null ? '' : _trimTrailingZeros(account.balance),
    );
    _category = account?.category ?? NetWorthCategory.cash;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  static String _trimTrailingZeros(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the account a name.');
      return;
    }
    final balance = double.tryParse(_balanceCtrl.text.trim());
    if (balance == null) {
      setState(() => _error = 'Enter the balance as a number.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final account = widget.account;
    final failure = account == null
        ? await widget.provider.addAccount(name: name, category: _category, balance: balance)
        : await widget.provider
            .updateAccount(id: account.id, name: name, category: _category, balance: balance);

    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _busy = false;
        _error = failure;
      });
      return;
    }
    Navigator.of(context).pop(account == null ? 'Added $name' : 'Saved $name');
  }

  Future<void> _delete() async {
    final account = widget.account;
    if (account == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text('Delete ${account.name}?', style: AppTypography.heading(16)),
        content: Text(
          'It will be removed from your net worth. This cannot be undone.',
          style: AppTypography.body(13, color: AppColors.ink(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: AppTypography.body(13, color: AppColors.ink(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: AppTypography.body(13, weight: FontWeight.w700, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final failure = await widget.provider.deleteAccount(account.id);

    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _busy = false;
        _error = failure;
      });
      return;
    }
    Navigator.of(context).pop('Deleted ${account.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet clear of the keyboard while the fields are focused.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit account' : 'New account',
                      style: AppTypography.heading(17),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, size: 20, color: AppColors.ink(0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const SectionKicker('Name'),
              const SizedBox(height: 8),
              _Field(
                child: TextField(
                  controller: _nameCtrl,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.body(14, color: AppColors.text),
                  decoration: _inputDecoration('e.g. Cash ISA'),
                ),
              ),
              const SizedBox(height: 18),

              const SectionKicker('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in NetWorthCategory.values)
                    _CategoryChip(
                      label: category.label,
                      selected: _category == category,
                      onTap: _busy ? null : () => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              SectionKicker(_category.isLiability ? 'Amount owed' : 'Balance'),
              const SizedBox(height: 8),
              _Field(
                child: TextField(
                  controller: _balanceCtrl,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                  style: AppTypography.mono(14, color: AppColors.text),
                  decoration: _inputDecoration('0.00'),
                ),
              ),
              if (_category.isLiability) ...[
                const SizedBox(height: 8),
                Text(
                  'Entered as a positive figure — it comes off your net worth.',
                  style: AppTypography.body(12, color: AppColors.ink(0.55)),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: AppTypography.body(12.5, color: AppColors.neutral900),
                ),
              ],

              const SizedBox(height: 22),
              Row(
                children: [
                  if (_isEdit) ...[
                    Expanded(
                      child: _SheetButton(
                        label: 'Delete',
                        onTap: _busy ? null : _delete,
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _SheetButton(
                      label: _busy ? 'Saving…' : (_isEdit ? 'Save' : 'Add'),
                      onTap: _busy ? null : _save,
                      primary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      border: InputBorder.none,
      hintText: hint,
      hintStyle: AppTypography.body(14, color: AppColors.ink(0.4)),
    );
  }
}

class _Field extends StatelessWidget {
  final Widget child;
  const _Field({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _CategoryChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
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

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const _SheetButton({required this.label, required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: primary ? AppColors.accent : AppColors.divider),
          ),
          child: Text(
            label,
            style: AppTypography.heading(
              13,
              weight: FontWeight.w700,
              color: primary ? AppColors.bg : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
