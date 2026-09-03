import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/currency_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/screen_header.dart';
import '../application/goals_provider.dart';
import '../domain/goal.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final currency = ref.read(currencyProvider);
    final result = await showDialog<_NewGoal>(
      context: context,
      builder: (_) => _NewGoalDialog(currency: currency),
    );
    if (result == null) return;

    try {
      await ref.read(goalsRepositoryProvider).create(
            name: result.name,
            targetAmountMinor: result.targetMinor,
          );
      ref.invalidate(goalsProvider);
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _contribute(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final currency = ref.read(currencyProvider);
    final amount = await showDialog<Money>(
      context: context,
      builder: (_) => _ContributeDialog(goal: goal, currency: currency),
    );
    if (amount == null) return;

    try {
      await ref
          .read(goalsRepositoryProvider)
          .contribute(goal.id, amount.minor);
      ref.invalidate(goalsProvider);
      if (context.mounted) {
        _toast(context, 'Added ${amount.format()} to ${goal.name}');
      }
    } on ApiException catch (e) {
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
    final async = ref.watch(goalsProvider);
    final goals = async.valueOrNull ?? const <Goal>[];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(goalsProvider),
      backgroundColor: g.canvasBottom,
      color: g.accent,
      edgeOffset: 100,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: 'Goals',
              subtitle: async.isLoading
                  ? 'Loading…'
                  : goals.isEmpty
                      ? 'Nothing tracked yet'
                      : '${goals.where((x) => !x.isComplete).length} in progress',
              trailing: Semantics(
                button: true,
                label: 'New goal',
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
              150,
            ),
            sliver: SliverToBoxAdapter(
              child: switch (async) {
                AsyncValue(hasError: true, :final error) => GlassEmpty(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load your goals',
                    body: error is ApiException
                        ? error.message
                        : 'Something went wrong.',
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(goalsProvider),
                  ),
                AsyncValue(isLoading: true) => const Column(
                    children: [
                      GlassSkeleton(height: 132),
                      SizedBox(height: AppSpacing.lg),
                      GlassSkeleton(height: 132),
                    ],
                  ),
                _ => goals.isEmpty
                    ? GlassEmpty(
                        icon: Icons.flag_rounded,
                        title: 'No goal set',
                        body:
                            'A goal turns saving from a vague intention into a number you can watch move.',
                        actionLabel: 'Create a goal',
                        onAction: () => _create(context, ref),
                      )
                    : Column(
                        children: [
                          for (final goal in goals)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.lg),
                              child: _GoalTile(
                                goal: goal,
                                onContribute: () =>
                                    _contribute(context, ref, goal),
                              ),
                            ),
                        ],
                      ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.onContribute});

  final Goal goal;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassPanel(
      onTap: onContribute,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: g.text,
                  ),
                ),
              ),
              Text(
                goal.isComplete ? 'Reached' : '${goal.percent}%',
                style: context.text.numMeta.copyWith(
                  color: goal.isComplete ? g.success : g.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassBar(
            fraction: goal.fraction,
            tone: goal.isComplete ? g.success : g.textSecondary,
            height: 5,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${goal.saved.format()} of ${goal.target.format()}',
                  style: TextStyle(fontSize: 13, color: g.textMuted),
                ),
              ),
              if (!goal.isComplete)
                Text(
                  '${goal.remaining.format()} to go',
                  style: TextStyle(fontSize: 13, color: g.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewGoal {
  const _NewGoal(this.name, this.targetMinor);
  final String name;
  final int targetMinor;
}

class _NewGoalDialog extends StatefulWidget {
  const _NewGoalDialog({required this.currency});

  final String currency;

  @override
  State<_NewGoalDialog> createState() => _NewGoalDialogState();
}

class _NewGoalDialogState extends State<_NewGoalDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final target = Money.tryParse(_amount.text, widget.currency);
    if (_name.text.trim().isEmpty || target == null || target.minor <= 0) return;
    Navigator.of(context).pop(_NewGoal(_name.text.trim(), target.minor));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What are you saving for?'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Target amount',
              prefixText: Money.symbolOf(widget.currency),
            ),
          ),
        ],
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

class _ContributeDialog extends StatefulWidget {
  const _ContributeDialog({required this.goal, required this.currency});

  final Goal goal;
  final String currency;

  @override
  State<_ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<_ContributeDialog> {
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
      title: Text('Add to ${widget.goal.name}'),
      content: TextField(
        controller: _amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: 'Amount',
          prefixText: Money.symbolOf(widget.currency),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
