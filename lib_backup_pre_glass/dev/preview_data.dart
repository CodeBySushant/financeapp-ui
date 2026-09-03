import '../core/utils/money.dart';
import '../features/home/domain/home_summary.dart';

/// **Development only.** Never import this from production code paths.
///
/// It exists so the dashboard can be looked at, screenshotted and widget-tested
/// before `GET /api/analytics/dashboard` is live. Every figure below is invented
/// for layout purposes; nothing in `lib/features` may read from here.
///
/// Delete this file once the repository layer lands.
abstract final class PreviewData {
  static Money _inr(int rupees, [int paise = 0]) =>
      Money.fromMinor(rupees * 100 + paise, 'INR');

  static HomeSummary dashboard() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    return HomeSummary(
      displayName: 'Sheetal',
      availableBalance: _inr(18450),
      monthIncome: _inr(25000),
      monthExpenses: _inr(6550),
      monthlyBudget: _inr(12000),
      periodLabel: _monthName(now.month),
      daysRemaining: lastDay - now.day + 1,
      topCategories: [
        CategoryTotal(
          categoryId: 'food',
          label: 'Food',
          total: _inr(1820),
          previousTotal: _inr(1420),
        ),
        CategoryTotal(
          categoryId: 'transport',
          label: 'Transport',
          total: _inr(960),
          previousTotal: _inr(1600),
        ),
        CategoryTotal(
          categoryId: 'shopping',
          label: 'Shopping',
          total: _inr(740),
        ),
      ],
      insight: SpendingInsight(
        body: 'Food is up 28% on last month, almost all of it delivery.',
        figures: [
          InsightFigure(label: 'This month', value: _inr(1820)),
          InsightFigure(label: 'Last month', value: _inr(1420)),
        ],
      ),
      goals: [
        GoalProgress(
          id: 'laptop',
          name: 'New laptop',
          saved: _inr(24000),
          target: _inr(80000),
          targetDate: DateTime(2027, 6, 1),
        ),
      ],
    );
  }

  /// A brand-new account: no budget, no history, no goals. Worth running as
  /// often as the populated state — empty screens are where most apps look
  /// unfinished.
  static HomeSummary emptyAccount() {
    final now = DateTime.now();
    return HomeSummary(
      displayName: 'Sheetal',
      availableBalance: const Money.fromMinor(0, 'INR'),
      monthIncome: const Money.fromMinor(0, 'INR'),
      monthExpenses: const Money.fromMinor(0, 'INR'),
      monthlyBudget: null,
      periodLabel: _monthName(now.month),
      daysRemaining: DateTime(now.year, now.month + 1, 0).day - now.day + 1,
      topCategories: const [],
      insight: null,
      goals: const [],
    );
  }

  static String _monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][month - 1];
}
