import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_shell.dart';
import 'core/network/api_exception.dart';
import 'core/session/auth_controller.dart';
import 'features/activity/presentation/activity_screen.dart';
import 'features/accounts/application/accounts_provider.dart';
import 'features/budgets/application/budgets_provider.dart';
import 'features/goals/application/goals_provider.dart';
import 'features/goals/presentation/goals_screen.dart';
import 'features/home/application/dashboard_provider.dart';
import 'core/widgets/glass_route.dart';
import 'features/assistant/presentation/assistant_screen.dart';
import 'features/onboarding/presentation/budget_setup.dart';
import 'features/transactions/application/transactions_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/insights/presentation/insights_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/transactions/presentation/add_transaction_sheet.dart';

/// The signed-in app.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  void _go(int index) {
    // Guard against the screen count, not the destination count: Profile is a
    // screen without a bar slot, so those two numbers are deliberately
    // different. Using the wrong one is how the original RangeError happened.
    if (index < 0 || index >= kScreenCount) return;
    setState(() => _index = index);
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    await ref.read(dashboardProvider.future);
  }

  /// A new transaction moves a balance, a budget and possibly a category total,
  /// so every screen that reads those has to be told rather than left showing
  /// figures that are one entry out of date.
  void _invalidateAfterWrite() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(budgetsProvider);
    ref.invalidate(goalsProvider);
    ref.read(transactionsProvider.notifier).refresh();
  }

  Future<void> _add({String? categorySlug}) async {
    final saved = await showAddTransactionSheet(
      context,
      initialCategorySlug: categorySlug,
    );
    if (!saved || !mounted) return;
    _invalidateAfterWrite();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _soon(String what) => _toast('$what is not built yet.');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);

    final snapshot = async.valueOrNull;
    final summary = snapshot?.summary;

    final error = async.hasError
        ? (async.error is ApiException
            ? (async.error as ApiException).message
            : 'Could not load your dashboard.')
        : null;

    return AppShell(
      currentIndex: _index,
      onDestinationSelected: _go,
      onAdd: _add,
      child: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            userName: user?.firstName,
            summary: summary,
            errorMessage: error,
            staleSince: snapshot?.fromCache == true ? snapshot?.cachedAt : null,
            onRefresh: _refresh,
            onRetry: _refresh,
            onQuickAdd: (slug) => _add(categorySlug: slug),
            onOpenBudgets: () => _go(2),
            onOpenTransactions: () => _go(1),
            onOpenGoals: () => _go(3),
            onOpenProfile: () => _go(kProfileIndex),
            onOpenAssistant: () => Navigator.of(context).push(
              glassRoute(
                AssistantScreen(onBack: () => Navigator.of(context).pop()),
              ),
            ),
            onSetBudget: () => showBudgetSetup(context, ref),
          ),
          ActivityScreen(onAdd: _add),
          const InsightsScreen(),
          const GoalsScreen(),
          ProfileScreen(
            onNotImplemented: _soon,
            onBack: () => _go(0),
          ),
        ],
      ),
    );
  }
}
