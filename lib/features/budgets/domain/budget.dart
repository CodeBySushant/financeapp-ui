import 'package:flutter/foundation.dart';

import '../../../core/models/json.dart';
import '../../../core/utils/money.dart';

@immutable
class BudgetLine {
  const BudgetLine({
    required this.id,
    required this.label,
    required this.categorySlug,
    required this.limit,
    required this.used,
    required this.remaining,
    required this.percentUsed,
    required this.isExceeded,
    this.recommendedDaily,
  });

  final String id;
  final String label;
  final String categorySlug;
  final Money limit;
  final Money used;
  final Money remaining;
  final int percentUsed;
  final bool isExceeded;
  final Money? recommendedDaily;

  double get fraction => (percentUsed / 100).clamp(0.0, 1.0);

  factory BudgetLine.fromJson(Map<String, dynamic> j, String currency) {
    final category = j['category'];
    // A null category means the overall monthly budget rather than a
    // per-category one — the server keys the whole-month budget that way.
    final isOverall = category is! Map;
    return BudgetLine(
      id: J.str(j['id']),
      label: isOverall ? 'Everything' : J.str(category['name'], 'Category'),
      categorySlug: isOverall ? 'other' : J.str(category['slug'], 'other'),
      limit: J.money(j['limit'], currency),
      used: J.money(j['used'], currency),
      remaining: J.money(j['remaining'], currency),
      percentUsed: (j['percentUsed'] as num?)?.round() ?? 0,
      isExceeded: j['isExceeded'] as bool? ?? false,
      recommendedDaily: J.moneyOrNull(j['recommendedDaily'], currency),
    );
  }
}

@immutable
class BudgetBoard {
  const BudgetBoard({
    required this.period,
    required this.daysRemaining,
    required this.items,
  });

  final String period;
  final int daysRemaining;
  final List<BudgetLine> items;

  factory BudgetBoard.fromJson(Map<String, dynamic> j, String currency) =>
      BudgetBoard(
        period: J.str(j['period']),
        daysRemaining: (j['daysRemaining'] as num?)?.toInt() ?? 0,
        items: J
            .items(j)
            .map((i) => BudgetLine.fromJson(i, currency))
            .toList(growable: false),
      );
}
