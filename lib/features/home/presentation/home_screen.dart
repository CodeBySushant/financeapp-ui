import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/money.dart';
import '../domain/home_summary.dart';

/// The dashboard. Answers one question above the fold: am I on track this
/// month? Everything below it is supporting detail.
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
    final g = context.glass;
    final s = summary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: const Color(0xFF141B2E),
      color: g.accentAlt,
      edgeOffset: 90,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Greeting(name: userName, onOpenProfile: onOpenProfile),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              140,
            ),
            sliver: s == null
                ? const SliverToBoxAdapter(child: _LoadingBody())
                : SliverList.list(
                    children: [
                      _BalanceHero(summary: s),
                      const SizedBox(height: AppSpacing.lg),
                      _BudgetCard(summary: s, onTap: onOpenBudgets),
                      const SizedBox(height: AppSpacing.xxl),
                      _QuickAdd(onPick: onQuickAdd),
                      const SizedBox(height: AppSpacing.xxl),
                      if (s.insight != null) ...[
                        _InsightCard(insight: s.insight!),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
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
                        _CategoryList(
                          categories: s.topCategories,
                          total: s.monthExpenses,
                        ),
                      const SizedBox(height: AppSpacing.xxl),
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
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
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
        AppSpacing.lg,
        top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
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
                    fontSize: 13,
                    color: g.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Until someone signs in there is no name to show, so the
                  // greeting says something true instead of inventing one.
                  known ? who : 'Set up your profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: g.text,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onOpenProfile,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: known
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [g.accent, g.accentAlt],
                      )
                    : null,
                color: known ? null : g.strokeSoft,
                border: Border.all(color: g.stroke),
              ),
              child: Center(
                child: known
                    ? Text(
                        who.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
        ],
      ),
    );
  }
}

/// The one genuinely blurred, genuinely bold surface in the app.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final text = context.text;
    final radius = BorderRadius.circular(28);

    // Dark carries a saturated violet wash; light keeps the panel near-white
    // with only a hint of it, so the hero stays airy against the pale sky
    // instead of stamping a heavy block onto it.
    final hero = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: g.isDark
                  ? [
                      g.accent.withValues(alpha: 0.30),
                      g.accentAlt.withValues(alpha: 0.12),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.92),
                      g.accent.withValues(alpha: 0.10),
                    ],
            ),
            border: Border.all(color: g.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Available balance',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: g.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  GlassChip(label: summary.periodLabel, tone: g.accentAlt),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  summary.availableBalance.format(),
                  style: text.moneyXl.copyWith(
                    color: g.text,
                    fontSize: 42,
                    height: 1.05,
                  ),
                  semanticsLabel:
                      summary.availableBalance.semanticLabel(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _Flow(
                      icon: Icons.south_west_rounded,
                      label: 'In',
                      amount: summary.monthIncome,
                      tone: g.success,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: g.isDark ? g.stroke : g.strokeSoft,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                  ),
                  Expanded(
                    child: _Flow(
                      icon: Icons.north_east_rounded,
                      label: 'Out',
                      amount: summary.monthExpenses,
                      tone: g.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (g.isDark) return hero;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: g.shadow, blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: hero,
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Money amount;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: tone.withValues(alpha: 0.18),
          ),
          child: Icon(icon, size: 15, color: tone),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: g.textMuted),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount.format(compact: true),
                  style: context.text.moneySm.copyWith(
                    color: g.text,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.pie_chart_outline_rounded,
                color: g.accentAlt, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set a monthly budget',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: g.text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'You get a daily safe-spend figure once you do.',
                    style: TextStyle(fontSize: 12.5, color: g.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: g.textMuted),
          ],
        ),
      );
    }

    final fraction = summary.budgetFraction;
    final tone = g.budgetTone(fraction);
    final daily = summary.safeDailySpend;

    return GlassPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Monthly budget',
                style: TextStyle(fontSize: 13, color: g.textSecondary),
              ),
              const Spacer(),
              Text(
                '${(fraction * 100).round()}% used',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tone,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassBar(fraction: fraction, tone: tone),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.isOverBudget
                      ? 'Over by ${(summary.monthExpenses - budget).format()}'
                      : '${summary.budgetRemaining!.format()} left of ${budget.format()}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: g.textMuted,
                  ),
                ),
              ),
              if (daily != null)
                Text(
                  '${daily.format()}/day',
                  style: context.text.numMeta.copyWith(
                    color: g.textSecondary,
                    fontSize: 12.5,
                  ),
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
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            itemCount: _picks.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final (id, label) = _picks[i];
              return GestureDetector(
                onTap: () => onPick(id),
                child: SizedBox(
                  width: 66,
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
                          color: g.textSecondary,
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
      tint: g.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: g.text),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Pattern spotted',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: g.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            insight.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: g.text,
            ),
          ),
          if (insight.figures.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            // The figures the sentence was built from. An insight you cannot
            // audit is a claim, not an insight.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final f in insight.figures)
                  GlassChip(label: '${f.label} ${f.value.format()}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories, required this.total});

  final List<CategoryTotal> categories;
  final Money total;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: AppSpacing.xxl + AppSpacing.xxxl,
                color: g.strokeSoft,
              ),
            _CategoryRow(item: categories[i], total: total),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, required this.total});

  final CategoryTotal item;
  final Money total;

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final change = item.percentChange;
    final share = total.isZero ? 0.0 : item.total.ratioOf(total);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CategoryGlyph(categoryId: item.categoryId),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: g.text,
                  ),
                ),
                const SizedBox(height: 5),
                GlassBar(
                  fraction: share,
                  tone: g.categoryColor(item.categoryId),
                  height: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.total.format(),
                style: context.text.moneySm.copyWith(
                  color: g.text,
                  fontSize: 14,
                ),
              ),
              if (change != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${change > 0 ? '+' : ''}$change%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: change > 0 ? g.danger : g.success,
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
      child: Row(
        children: [
          GlassRing(
            fraction: goal.fraction,
            tone: g.success,
            child: Text(
              '${goal.percent}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: g.text,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: g.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${goal.saved.format(compact: true)} of ${goal.target.format(compact: true)}',
                  style: context.text.numMeta.copyWith(
                    fontSize: 12.5,
                    color: g.textMuted,
                  ),
                ),
              ],
            ),
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
        GlassSkeleton(height: 196),
        SizedBox(height: AppSpacing.lg),
        GlassSkeleton(height: 108),
        SizedBox(height: AppSpacing.lg),
        GlassSkeleton(height: 140),
      ],
    );
  }
}
