import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/currency_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../budgets/application/budgets_provider.dart';
import '../../home/application/dashboard_provider.dart';

/// Asks for a monthly budget and creates it.
///
/// Deliberately a single field rather than a multi-step wizard: the only thing
/// standing between a new account and a useful dashboard is one number, and a
/// four-screen onboarding flow to collect it would be theatre.
Future<void> showBudgetSetup(BuildContext context, WidgetRef ref) async {
  final currency = ref.read(currencyProvider);
  final amount = await showDialog<Money>(
    context: context,
    builder: (_) => _BudgetDialog(currency: currency),
  );
  if (amount == null) return;

  try {
    await ref.read(budgetsRepositoryProvider).create(
          amountMinor: amount.minor,
        );
    ref.invalidate(budgetsProvider);
    ref.invalidate(dashboardProvider);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.currency});

  final String currency;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final money = Money.tryParse(_amount.text, widget.currency);
    if (money == null || money.minor <= 0) return;
    Navigator.of(context).pop(money);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How much do you want to spend in a month, across everything?',
            style: TextStyle(fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Amount',
              prefixText: Money.symbolOf(widget.currency),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        TextButton(onPressed: _submit, child: const Text('Set budget')),
      ],
    );
  }
}
