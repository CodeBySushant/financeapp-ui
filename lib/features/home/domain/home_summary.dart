import 'package:flutter/foundation.dart';

import '../../../core/utils/money.dart';

/// Everything the dashboard renders, already computed.
///
/// The UI does no financial arithmetic beyond reading these fields. Totals are
/// aggregated in SQL and returned by `GET /api/analytics/dashboard`; the two
/// derived figures below ([safeDailySpend], [budgetFraction]) are recomputed
/// client-side only so the dashboard stays correct while offline, using the
/// same integer-minor-unit rules as the server.
@immutable
class HomeSummary {
  const HomeSummary({
    required this.displayName,
    required this.availableBalance,
    required this.monthIncome,
    required this.monthExpenses,
    required this.monthlyBudget,
    required this.periodLabel,
    required this.daysRemaining,
    required this.topCategories,
    required this.insight,
    required this.goals,
  });

  final String displayName;
  final Money availableBalance;
  final Money monthIncome;
  final Money monthExpenses;

  /// Null when the user has not set a budget — the card becomes a prompt
  /// rather than showing a zero.
  final Money? monthlyBudget;

  /// e.g. "August" — formatted server-side in the user's timezone, because a
  /// device clock in another zone must not shift which month they are seeing.
  final String periodLabel;

  /// Days left in the budget period, inclusive of today.
  final int daysRemaining;

  final List<CategoryTotal> topCategories;

  /// Null when AI is unavailable or the user is on the free tier. Everything
  /// else on this screen keeps working.
  final SpendingInsight? insight;

  final List<GoalProgress> goals;

  Money? get budgetRemaining {
    final budget = monthlyBudget;
    if (budget == null) return null;
    final left = budget - monthExpenses;
    return left.isNegative ? left.zeroed() : left;
  }

  bool get isOverBudget {
    final budget = monthlyBudget;
    return budget != null && monthExpenses > budget;
  }

  double get budgetFraction {
    final budget = monthlyBudget;
    if (budget == null) return 0;
    return monthExpenses.ratioOf(budget);
  }

  /// What the user can spend per day and still land on budget.
  ///
  /// Uses [Money.allocate] so the daily figures sum exactly back to the
  /// remaining budget — no cent is created or lost by division.
  Money? get safeDailySpend {
    final left = budgetRemaining;
    if (left == null || daysRemaining <= 0) return null;
    return left.allocate(daysRemaining).first;
  }

  bool get hasActivity => !monthIncome.isZero || !monthExpenses.isZero;
}

@immutable
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.label,
    required this.total,
    this.previousTotal,
  });

  final String categoryId;
  final String label;
  final Money total;
  final Money? previousTotal;

  /// Percentage change against the previous period, or null when there is no
  /// comparable history. Never fabricated to fill the slot.
  int? get percentChange {
    final prev = previousTotal;
    if (prev == null || prev.minor == 0) return null;
    return (((total.minor - prev.minor) / prev.minor) * 100).round();
  }
}

@immutable
class SpendingInsight {
  const SpendingInsight({required this.body, this.figures = const []});

  /// One sentence, generated from verified figures.
  final String body;

  /// The exact values the sentence was built from, so the UI can show its
  /// working. An insight the user cannot audit is a claim, not an insight.
  final List<InsightFigure> figures;
}

@immutable
class InsightFigure {
  const InsightFigure({required this.label, required this.value});
  final String label;
  final Money value;
}

@immutable
class GoalProgress {
  const GoalProgress({
    required this.id,
    required this.name,
    required this.saved,
    required this.target,
    this.targetDate,
  });

  final String id;
  final String name;
  final Money saved;
  final Money target;
  final DateTime? targetDate;

  double get fraction => saved.ratioOf(target);
  int get percent => (fraction * 100).round();
}
