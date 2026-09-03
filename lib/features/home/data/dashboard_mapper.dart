import '../../../core/utils/money.dart';
import '../domain/home_summary.dart';

/// Maps `GET /api/analytics/dashboard` onto [HomeSummary].
///
/// Field names here are taken from `analytics.service.ts` -> `dashboard()`.
/// Money always arrives as `{ amountMinor, currency }`; nothing is parsed from
/// a formatted string, so no rounding happens on this side.
abstract final class DashboardMapper {
  static HomeSummary fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as String? ?? 'INR';

    return HomeSummary(
      displayName: json['displayName'] as String? ?? '',
      availableBalance: _money(json['availableBalance'], currency),
      monthIncome: _money(json['monthIncome'], currency),
      monthExpenses: _money(json['monthExpenses'], currency),
      monthlyBudget: _moneyOrNull(json['monthlyBudget'], currency),
      periodLabel: json['periodLabel'] as String? ?? '',
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      topCategories: _categories(json['topCategories'], currency),
      insight: _insight(json['insight'], currency),
      goals: _goals(json['goals'], currency),
    );
  }

  static Money _money(Object? raw, String fallbackCurrency) {
    if (raw is Map) {
      final minor = (raw['amountMinor'] as num?)?.toInt() ?? 0;
      return Money.fromMinor(
        minor,
        raw['currency'] as String? ?? fallbackCurrency,
      );
    }
    return Money.fromMinor(0, fallbackCurrency);
  }

  static Money? _moneyOrNull(Object? raw, String fallbackCurrency) =>
      raw is Map ? _money(raw, fallbackCurrency) : null;

  static List<CategoryTotal> _categories(Object? raw, String currency) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((c) {
      // `categoryId` is null for uncategorised rows, but `slug` is always
      // present and is what the icon and colour lookups key on.
      final slug = c['slug'] as String? ?? 'other';
      return CategoryTotal(
        categoryId: slug,
        label: c['name'] as String? ?? 'Uncategorised',
        total: _money(c['total'], currency),
        previousTotal: _moneyOrNull(c['previousTotal'], currency),
      );
    }).toList(growable: false);
  }

  static SpendingInsight? _insight(Object? raw, String currency) {
    if (raw is! Map) return null;
    final body = raw['body'] as String?;
    if (body == null || body.isEmpty) return null;

    final figures = <InsightFigure>[];
    final rawFigures = raw['figures'];
    if (rawFigures is List) {
      for (final f in rawFigures.whereType<Map>()) {
        final label = f['label'] as String?;
        if (label == null) continue;
        figures.add(
          InsightFigure(label: label, value: _money(f['value'], currency)),
        );
      }
    }
    return SpendingInsight(body: body, figures: figures);
  }

  static List<GoalProgress> _goals(Object? raw, String currency) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((gJson) {
      final targetDate = gJson['targetDate'] as String?;
      return GoalProgress(
        id: gJson['id'] as String? ?? '',
        name: gJson['name'] as String? ?? 'Goal',
        saved: _money(gJson['saved'], currency),
        target: _money(gJson['target'], currency),
        targetDate: targetDate == null ? null : DateTime.tryParse(targetDate),
      );
    }).toList(growable: false);
  }
}
