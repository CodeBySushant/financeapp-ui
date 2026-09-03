import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../domain/home_summary.dart';

/// The dashboard.
///
/// Answers one question above the fold — am I on track this month — and treats
/// everything below it as supporting detail. Colour appears in exactly three
/// places: the accent on an action, green on money coming in, red when a budget
/// is blown. Everything else is neutral.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.summary,
    required this.onRefresh,
    required this.onOpenBudgets,
    required this.onOpenTransactions,
    required this.onOpenGoals,
    required this.onOpenProfile,
    required this.onQuickAdd,
  });

  /// First name of the signed-in person, or null before anyone has identified
  /// themselves. Comes from the session, not from the dashboard payload.
  final String? userName;

  final HomeSummary? summary;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenTransactions;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final s = summary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: context.glass.canvasBottom,
      color: context.glass.accent,
      edgeOffset: 100,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Greeting(name: userName, onOpenProfile: onOpenProfile),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              150,
            ),
            sliver: s == null
                ? const SliverToBoxAdapter(child: _LoadingBody())
                : SliverList.list(
                    children: [
                      _BalanceHero(summary: s),
                      const SizedBox(height: AppSpacing.md),
                      _BudgetCard(summary: s, onTap: onOpenBudgets),
                      const SizedBox(height: AppSpacing.huge),
                      _QuickAdd(onPick: onQuickAdd),
                      if (s.insight != null) ...[
                        const SizedBox(height: AppSpacing.huge),
                        _InsightCard(insight: s.insight!),
                      ],
                      const SizedBox(height: AppSpacing.huge),
                      SectionHeading(
                        title: 'Where it went',
                        actionLabel: 'All activity',
                        onAction: onOpenTransactions,
                      ),
                      if (s.topCategories.isEmpty)
                        const GlassEmpty(
                          icon: Icons.receipt_long_rounded,
                          title: 'Nothing logged yet',
                          body:
                              'Add your first expense and this fills in on its own.',
                        )
                      else
                        _CategoryList(categories: s.topCategories),
                      const SizedBox(height: AppSpacing.huge),
                      SectionHeading(
                        title: 'Goals',
                        actionLabel: s.goals.isEmpty ? null : 'See all',
                        onAction: onOpenGoals,
                      ),
                      if (s.goals.isEmpty)
                        GlassEmpty(
                          icon: Icons.flag_rounded,
                          title: 'No goal set',
                          body:
                              'Name something you are saving for and track it here.',
                          actionLabel: 'Create a goal',
                          onAction: onOpenGoals,
                        )
                      else
                        for (final g in s.goals)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _GoalCard(goal: g),
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.onOpenProfile});

  final String? name;
  final VoidCallback onOpenProfile;

  String get _partOfDay {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final top = MediaQuery.viewPaddingOf(context).top;
    final who = name?.trim();
    final known = who != null && who.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        top + AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  known ? _partOfDay : 'Welcome',
                  style: TextStyle(
                    fontSize: 13.5,
                    letterSpacing: -0.1,
                    color: g.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  known ? who : 'Set up your profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: g.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            label: 'Profile',
            child: GestureDetector(
              onTap: onOpenProfile,
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
                child: Center(
                  child: known
                      ? Text(
                          who.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: g.text,
                          ),
                        )
                      : Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: g.textSecondary,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one figure that matters, given the room to matter.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final text = context.text;

    return GlassPanel(
      blurred: true,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available balance',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: -0.1,
                    color: g.textMuted,
                  ),
                ),
              ),
              Text(
                summary.periodLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  color: g.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              summary.availableBalance.format(),
              style: text.moneyXl.copyWith(color: g.text),
              semanticsLabel: summary.availableBalance.semanticLabel(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Divider(height: 1, thickness: 1, color: g.strokeSoft),
          _Flow(
            label: 'Income',
            amount: summary.monthIncome,
            positive: true,
          ),
          Divider(height: 1, thickness: 1, color: g.strokeSoft),
          _Flow(
            label: 'Spent',
            amount: summary.monthExpenses,
            positive: false,
          ),
        ],
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({
    required this.label,
    required this.amount,
    required this.positive,
  });

  final String label;
  final Money amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            positive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 15,
            // Green earns its place: money arriving is the one genuinely good
            // event on this screen. Money leaving is normal, so it stays neutral
            // rather than being painted as an alarm.
            color: positive ? g.success : g.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                letterSpacing: -0.15,
                color: g.textSecondary,
              ),
            ),
          ),
          Text(
            amount.format(),
            style: context.text.moneyMd.copyWith(color: g.text),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.summary, required this.onTap});

  final HomeSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final budget = summary.monthlyBudget;

    if (budget == null) {
      return GlassPanel(
        blurred: true,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set a monthly budget',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: g.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'You get a daily safe-spend figure once you do.',
                    style: TextStyle(fontSize: 13, color: g.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: g.textMuted, size: 20),
          ],
        ),
      );
    }

    final fraction = summary.budgetFraction;
    final over = summary.isOverBudget;
    final daily = summary.safeDailySpend;
    // Neutral until it matters. An amber bar at 76% trains people to ignore it.
    final tone = over ? g.danger : g.textSecondary;

    return GlassPanel(
      blurred: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly budget',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: -0.1,
                    color: g.textMuted,
                  ),
                ),
              ),
              Text(
                '${(fraction * 100).round()}%',
                style: context.text.numMeta.copyWith(
                  color: over ? g.danger : g.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassBar(fraction: fraction, tone: tone, height: 5),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  over
                      ? 'Over by ${(summary.monthExpenses - budget).format()}'
                      : '${summary.budgetRemaining!.format()} left of ${budget.format()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: -0.1,
                    color: over ? g.danger : g.textSecondary,
                  ),
                ),
              ),
              if (daily != null)
                Text(
                  '${daily.format()} a day',
                  style: TextStyle(fontSize: 13, color: g.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.onPick});

  final ValueChanged<String> onPick;

  static const _picks = [
    ('food', 'Food'),
    ('transport', 'Transport'),
    ('groceries', 'Groceries'),
    ('coffee', 'Coffee'),
    ('shopping', 'Shopping'),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(title: 'Log a spend'),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            itemCount: _picks.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, i) {
              final (id, label) = _picks[i];
              return GestureDetector(
                onTap: () => onPick(id),
                child: SizedBox(
                  width: 62,
                  child: Column(
                    children: [
                      CategoryGlyph(categoryId: id, size: 50),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: -0.1,
                          color: g.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final SpendingInsight insight;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassPanel(
      blurred: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.body,
            style: context.text.voice.copyWith(color: g.text),
          ),
          if (insight.figures.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            // The figures the sentence was built from. An insight you cannot
            // audit is a claim, not an insight.
            for (final f in insight.figures)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        f.label,
                        style: TextStyle(fontSize: 13, color: g.textMuted),
                      ),
                    ),
                    Text(
                      f.value.format(),
                      style: context.text.numMeta.copyWith(
                        color: g.textSecondary,
                      ),
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

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 74, color: g.strokeSoft),
            _CategoryRow(item: categories[i]),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item});

  final CategoryTotal item;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final change = item.percentChange;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CategoryGlyph(categoryId: item.categoryId, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: g.text,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.total.format(),
                style: context.text.moneyMd.copyWith(color: g.text),
              ),
              if (change != null) ...[
                const SizedBox(height: 1),
                Text(
                  '${change > 0 ? '+' : ''}$change%',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: -0.1,
                    color: g.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                    color: g.text,
                  ),
                ),
              ),
              Text(
                '${goal.percent}%',
                style: context.text.numMeta.copyWith(color: g.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassBar(fraction: goal.fraction, tone: g.textSecondary, height: 5),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${goal.saved.format()} of ${goal.target.format()}',
            style: TextStyle(fontSize: 13, color: g.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        GlassSkeleton(height: 232),
        SizedBox(height: AppSpacing.md),
        GlassSkeleton(height: 116),
        SizedBox(height: AppSpacing.huge),
        GlassSkeleton(height: 140),
      ],
    );
  }
}
