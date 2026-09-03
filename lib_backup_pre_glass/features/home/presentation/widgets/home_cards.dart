import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/ft_atoms.dart';
import '../../../../core/widgets/ft_card.dart';
import '../../../../core/widgets/ft_states.dart';
import '../../domain/home_summary.dart';

/// Greeting, balance, and the in/out pair. The one place on the dashboard that
/// uses the largest type, because it answers the only question the user opened
/// the app to ask.
class BalanceHeader extends StatelessWidget {
  const BalanceHeader({
    super.key,
    required this.summary,
    required this.hidden,
    required this.onTogglePrivacy,
  });

  final HomeSummary summary;
  final bool hidden;
  final VoidCallback onTogglePrivacy;

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting(DateTime.now())},',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(summary.displayName, style: t.displayMd),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onTogglePrivacy();
              },
              icon: Icon(hidden ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              color: c.muted,
              tooltip: hidden ? 'Show amounts' : 'Hide amounts',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.inner,
                  side: BorderSide(color: c.line),
                ),
                minimumSize: const Size(46, 46),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const FtKicker('Available balance'),
        const SizedBox(height: AppSpacing.xs),
        FtMoneyText(
          summary.availableBalance,
          style: t.moneyXl,
          animate: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FtPill(
              label: hidden
                  ? '\u2022\u2022\u2022\u2022 in'
                  : '${summary.monthIncome.format(showSign: true)} in',
              tone: c.success,
              icon: Icons.arrow_downward_rounded,
            ),
            FtPill(
              label: hidden
                  ? '\u2022\u2022\u2022\u2022 out'
                  : '\u2212${summary.monthExpenses.format()} out',
              neutral: true,
              icon: Icons.arrow_upward_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

/// Budget progress plus the safe daily figure. Reads as one sentence of state,
/// not a wall of statistics.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.summary,
    required this.onSetBudget,
    required this.onOpenBudgets,
  });

  final HomeSummary summary;
  final VoidCallback onSetBudget;
  final VoidCallback onOpenBudgets;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final budget = summary.monthlyBudget;

    if (budget == null) {
      return FtEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        headline: 'Set a monthly budget',
        body: 'Give this month a ceiling and the app will track how much you '
            'can safely spend each day.',
        actionLabel: 'Set budget',
        onAction: onSetBudget,
        compactPadding: true,
      );
    }

    final fraction = summary.budgetFraction;
    final tone = c.budgetTone(fraction);
    final remaining = summary.budgetRemaining!;
    final daily = summary.safeDailySpend;

    return FtCard(
      onTap: onOpenBudgets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${summary.periodLabel} budget',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (!PrivacyScope.of(context))
                Text(
                  '${summary.monthExpenses.format()} / ${budget.format()}',
                  style: t.numMeta,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FtProgressBar(
            fraction: fraction,
            tone: tone,
            semanticLabel: '${summary.periodLabel} budget used',
          ),
          const SizedBox(height: AppSpacing.md),
          // Stacks instead of clipping once the user scales text up.
          Flex(
            direction: context.isLargeText ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Figure(
                value: remaining,
                label: summary.isOverBudget ? 'over budget' : 'left',
                tone: summary.isOverBudget ? c.danger : null,
              ),
              if (context.isLargeText)
                const SizedBox(height: AppSpacing.sm)
              else
                const Spacer(),
              if (daily != null)
                _Figure(
                  value: daily,
                  label: 'per day, safely',
                  alignEnd: !context.isLargeText,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    required this.label,
    this.tone,
    this.alignEnd = false,
  });

  final Money value;
  final String label;
  final Color? tone;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        FtMoneyText(value, style: context.text.moneySm, color: tone),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// One-tap category entry. The fastest path to a logged expense: tap a chip,
/// type an amount, done.
class QuickAddRow extends StatelessWidget {
  const QuickAddRow({
    super.key,
    required this.categories,
    required this.onQuickAdd,
    required this.onMore,
  });

  final List<({String id, String label, IconData icon})> categories;
  final ValueChanged<String> onQuickAdd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FtKicker('Quick add'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final cat in categories)
              ActionChip(
                avatar: Icon(
                  cat.icon,
                  size: 16,
                  color: AppColors.forCategory(cat.id),
                ),
                label: Text(cat.label),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onQuickAdd(cat.id);
                },
              ),
            ActionChip(
              avatar: Icon(Icons.add_rounded, size: 16, color: c.ink),
              label: const Text('More'),
              onPressed: onMore,
              side: BorderSide(color: c.ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Where the month's money actually went.
class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({
    super.key,
    required this.summary,
    required this.categoryIcons,
    required this.onViewAll,
  });

  final HomeSummary summary;
  final Map<String, IconData> categoryIcons;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (summary.topCategories.isEmpty) {
      return const FtEmptyState(
        icon: Icons.receipt_long_outlined,
        headline: 'No spending yet this month',
        body: 'Add an expense and this is where your categories will show up.',
        compactPadding: true,
      );
    }

    final c = context.colors;
    final t = context.text;
    final largest = summary.topCategories.first.total;

    return FtCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FtSectionHeader(
            title: 'This month',
            actionLabel: 'All',
            onAction: onViewAll,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < summary.topCategories.length; i++) ...[
            if (i > 0) const FtRowDivider(indent: 50),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  FtIconTile(
                    icon: categoryIcons[summary.topCategories[i].categoryId] ??
                        Icons.circle_outlined,
                    tone: AppColors.forCategory(
                        summary.topCategories[i].categoryId),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.topCategories[i].label,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Share-of-spend bar, scaled to the largest category
                        // so relative weight is readable at a glance.
                        FtProgressBar(
                          fraction: summary.topCategories[i]
                              .total
                              .ratioOf(largest),
                          tone: AppColors.forCategory(
                                  summary.topCategories[i].categoryId)
                              .withValues(alpha: 0.55),
                          height: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FtMoneyText(
                        summary.topCategories[i].total,
                        style: t.moneyMd,
                      ),
                      if (summary.topCategories[i].percentChange
                          case final change?)
                        Text(
                          change >= 0 ? '+$change%' : '$change%',
                          style: t.numMeta.copyWith(
                            fontSize: 11,
                            color: change > 0 ? c.muted : c.success,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The AI remark, in the serif voice — and the figures it was built from.
///
/// Showing the source numbers is a product decision, not decoration: the user
/// can check the sentence against their own data, and the assistant has nowhere
/// to hide an invented figure.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    required this.onAsk,
    this.unavailable = false,
  });

  final SpendingInsight? insight;
  final VoidCallback onAsk;

  /// AI is down or not enabled. Everything else on the dashboard still works,
  /// so this states the fact plainly instead of showing an error.
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    if (unavailable || insight == null) {
      return FtCard(
        tinted: true,
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: c.muted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Insights are unavailable right now. Your balances, budgets '
                'and goals are unaffected.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final data = insight!;

    return FtCard(
      tinted: true,
      onTap: onAsk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 13, color: c.muted),
              const SizedBox(width: AppSpacing.xs + 2),
              const FtKicker('Insight'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(data.body, style: t.voice),
          if (data.figures.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FtInnerCard(
              child: Column(
                children: [
                  for (var i = 0; i < data.figures.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.figures[i].label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        FtMoneyText(
                          data.figures[i].value,
                          style: t.moneySm,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Ask my money',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: c.accent),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.arrow_forward_rounded, size: 15, color: c.accent),
            ],
          ),
        ],
      ),
    );
  }
}

/// Savings goals, condensed.
class GoalsCard extends StatelessWidget {
  const GoalsCard({
    super.key,
    required this.goals,
    required this.onViewAll,
    required this.onCreateGoal,
  });

  final List<GoalProgress> goals;
  final VoidCallback onViewAll;
  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return FtEmptyState(
        icon: Icons.flag_outlined,
        headline: 'Give your money a purpose',
        body: 'Name something you are saving towards and track it here.',
        actionLabel: 'Create goal',
        onAction: onCreateGoal,
        compactPadding: true,
      );
    }

    final c = context.colors;
    final t = context.text;

    return FtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FtSectionHeader(
            title: 'Goals',
            actionLabel: 'View all',
            onAction: onViewAll,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < goals.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goals[i].name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${goals[i].percent}%', style: t.numMeta),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FtProgressBar(
                  fraction: goals[i].fraction,
                  tone: c.success,
                  semanticLabel: '${goals[i].name} progress',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!PrivacyScope.of(context))
                  Text(
                    '${goals[i].saved.format()} of ${goals[i].target.format()}',
                    style: t.numMeta,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
