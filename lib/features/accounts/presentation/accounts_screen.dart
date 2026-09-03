import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/currency_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/screen_header.dart';
import '../application/accounts_provider.dart';
import '../domain/account.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final currency = ref.read(currencyProvider);
    final result = await showDialog<_NewAccount>(
      context: context,
      builder: (_) => _NewAccountDialog(currency: currency),
    );
    if (result == null) return;

    try {
      await ref.read(accountsRepositoryProvider).create(
            name: result.name,
            type: result.type,
            openingBalanceMinor: result.openingMinor,
          );
      ref.invalidate(accountsProvider);
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref, Account a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Close ${a.name}?'),
        content: const Text(
          'The account is archived, not deleted — its transactions stay in your '
          'history. The balance must be zero first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Close account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(accountsRepositoryProvider).close(a.id);
      ref.invalidate(accountsProvider);
    } on ApiException catch (e) {
      // The server refuses while a balance remains and says so clearly, so its
      // message is shown rather than a generic one.
      if (context.mounted) _toast(context, e.message);
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = context.glass;
    final async = ref.watch(accountsProvider);
    final accounts = async.valueOrNull ?? const <Account>[];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: 'Accounts',
            subtitle: async.isLoading
                ? 'Loading…'
                : '${accounts.length} open',
            onBack: () => Navigator.of(context).pop(),
            trailing: Semantics(
              button: true,
              label: 'New account',
              child: GestureDetector(
                onTap: () => _create(context, ref),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: g.isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.78),
                    border: Border.all(color: g.stroke, width: 0.8),
                  ),
                  child: Icon(Icons.add_rounded, size: 20, color: g.text),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.huge,
          ),
          sliver: SliverToBoxAdapter(
            child: async.isLoading
                ? const GlassSkeleton(height: 180)
                : accounts.isEmpty
                    ? GlassEmpty(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No accounts',
                        body:
                            'Add the places your money actually sits — cash, bank, UPI, a card.',
                        actionLabel: 'Add an account',
                        onAction: () => _create(context, ref),
                      )
                    : GlassPanel(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < accounts.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  indent: 68,
                                  color: g.strokeSoft,
                                ),
                              _AccountRow(
                                account: accounts[i],
                                onClose: () =>
                                    _close(context, ref, accounts[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.onClose});

  final Account account;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: g.isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.70),
              border: Border.all(color: g.stroke, width: 0.8),
            ),
            child: Icon(account.type.icon, size: 18, color: g.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          color: g.text,
                        ),
                      ),
                    ),
                    if (account.isDefault) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Default',
                        style: TextStyle(fontSize: 11, color: g.textMuted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  account.type.label,
                  style: TextStyle(fontSize: 12.5, color: g.textMuted),
                ),
              ],
            ),
          ),
          Text(
            account.balance.format(),
            style: context.text.moneyMd.copyWith(color: g.text),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.more_horiz_rounded, size: 20, color: g.textMuted),
            tooltip: 'Close account',
          ),
        ],
      ),
    );
  }
}

class _NewAccount {
  const _NewAccount(this.name, this.type, this.openingMinor);
  final String name;
  final AccountType type;
  final int openingMinor;
}

class _NewAccountDialog extends StatefulWidget {
  const _NewAccountDialog({required this.currency});

  final String currency;

  @override
  State<_NewAccountDialog> createState() => _NewAccountDialogState();
}

class _NewAccountDialogState extends State<_NewAccountDialog> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  AccountType _type = AccountType.bank;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final opening = Money.tryParse(_opening.text, widget.currency);
    Navigator.of(context).pop(
      _NewAccount(_name.text.trim(), _type, opening?.minor ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Name, e.g. HDFC'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _opening,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Opening balance',
                prefixText: Money.symbolOf(widget.currency),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in AccountType.values)
                  GlassChip(
                    label: t.label,
                    icon: t.icon,
                    selected: t == _type,
                    tone: context.glass.accent,
                    onTap: () => setState(() => _type = t),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
