import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/ft_atoms.dart';
import '../../../core/widgets/ft_states.dart';
import '../domain/home_summary.dart';
import 'widgets/home_cards.dart';

/// Quick-add categories. Icons live here rather than in the model so the
/// backend never has to ship a Material codepoint.
const _quickAdd = <({String id, String label, IconData icon})>[
  (id: 'food', label: 'Food', icon: Icons.restaurant_rounded),
  (id: 'transport', label: 'Transport', icon: Icons.directions_car_rounded),
  (id: 'coffee', label: 'Coffee', icon: Icons.local_cafe_rounded),
  (id: 'shopping', label: 'Shopping', icon: Icons.shopping_bag_rounded),
];

const _categoryIcons = <String, IconData>{
  'food': Icons.restaurant_rounded,
  'transport': Icons.directions_car_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'groceries': Icons.local_grocery_store_rounded,
  'bills': Icons.receipt_long_rounded,
  'entertainment': Icons.movie_rounded,
  'education': Icons.school_rounded,
  'health': Icons.favorite_rounded,
  'travel': Icons.flight_rounded,
  'rent': Icons.home_rounded,
  'housing': Icons.home_rounded,
  'subscriptions': Icons.autorenew_rounded,
  'coffee': Icons.local_cafe_rounded,
  'other': Icons.more_horiz_rounded,
};

/// The dashboard.
///
/// Answers one question above the fold — *how am I doing this month?* — and
/// puts the fastest path to logging an expense directly beneath it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.summary,
    required this.onRefresh,
    this.isLoading = false,
    this.aiUnavailable = false,
    this.onQuickAdd,
    this.onOpenBudgets,
    this.onOpenTransactions,
    this.onOpenGoals,
    this.onAskMyMoney,
  });

  /// Null while the first load is in flight.
  final HomeSummary? summary;
  final Future<void> Function() onRefresh;
  final bool isLoading;
  final bool aiUnavailable;

  final ValueChanged<String>? onQuickAdd;
  final VoidCallback? onOpenBudgets;
  final VoidCallback? onOpenTransactions;
  final VoidCallback? onOpenGoals;
  final VoidCallback? onAskMyMoney;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hidden = false;

  void _noop() {}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.gutter(width);
    final summary = widget.summary;

    return PrivacyScope(
      hidden: _hidden,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            edgeOffset: 8,
            color: context.colors.ink,
            backgroundColor: context.colors.surfaceRaised,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.lg,
                    gutter,
                    // Clear the bottom bar and the floating action button.
                    AppSpacing.huge + AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: ContentBounds(
                      child: summary == null
                          ? const _HomeSkeleton()
                          : _HomeContent(
                              summary: summary,
                              hidden: _hidden,
                              aiUnavailable: widget.aiUnavailable,
                              onTogglePrivacy: () =>
                                  setState(() => _hidden = !_hidden),
                              onQuickAdd: widget.onQuickAdd ?? (_) {},
                              onOpenBudgets: widget.onOpenBudgets ?? _noop,
                              onOpenTransactions:
                                  widget.onOpenTransactions ?? _noop,
                              onOpenGoals: widget.onOpenGoals ?? _noop,
                              onAskMyMoney: widget.onAskMyMoney ?? _noop,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.summary,
    required this.hidden,
    required this.aiUnavailable,
    required this.onTogglePrivacy,
    required this.onQuickAdd,
    required this.onOpenBudgets,
    required this.onOpenTransactions,
    required this.onOpenGoals,
    required this.onAskMyMoney,
  });

  final HomeSummary summary;
  final bool hidden;
  final bool aiUnavailable;
  final VoidCallback onTogglePrivacy;
  final ValueChanged<String> onQuickAdd;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenTransactions;
  final VoidCallback onOpenGoals;
  final VoidCallback onAskMyMoney;

  @override
  Widget build(BuildContext context) {
    // Balance and quick-add stay full width at every size — they are the
    // primary answer and the primary action. Everything below reflows into
    // columns once there is room for two readable measures side by side.
    final cards = <Widget>[
      BudgetCard(
        summary: summary,
        onSetBudget: onOpenBudgets,
        onOpenBudgets: onOpenBudgets,
      ),
      TopCategoriesCard(
        summary: summary,
        categoryIcons: _categoryIcons,
        onViewAll: onOpenTransactions,
      ),
      InsightCard(
        insight: summary.insight,
        unavailable: aiUnavailable,
        onAsk: onAskMyMoney,
      ),
      GoalsCard(
        goals: summary.goals,
        onViewAll: onOpenGoals,
        onCreateGoal: onOpenGoals,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BalanceHeader(
          summary: summary,
          hidden: hidden,
          onTogglePrivacy: onTogglePrivacy,
        ),
        const SizedBox(height: AppSpacing.xxl),
        QuickAddRow(
          categories: _quickAdd,
          onQuickAdd: onQuickAdd,
          onMore: onOpenTransactions,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AdaptiveColumns(children: cards),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FtSkeleton(width: 120, height: 13),
        SizedBox(height: AppSpacing.sm),
        FtSkeleton(width: 160, height: 24),
        SizedBox(height: AppSpacing.xxl),
        FtSkeleton(width: 110, height: 11),
        SizedBox(height: AppSpacing.sm),
        FtSkeleton(width: 210, height: 34),
        SizedBox(height: AppSpacing.xxl),
        FtCardSkeleton(lines: 3),
        SizedBox(height: AppSpacing.lg),
        FtCardSkeleton(lines: 2),
      ],
    );
  }
}
