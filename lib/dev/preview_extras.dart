import '../core/utils/money.dart';

/// **Development only.** Fixtures for the screens that do not yet have a
/// repository behind them. Delete alongside `preview_data.dart` once
/// `GET /api/transactions` and `GET /api/budgets` are wired up.

enum TxKind { income, expense }

class PreviewTx {
  const PreviewTx({
    required this.id,
    required this.merchant,
    required this.categoryId,
    required this.categoryLabel,
    required this.amount,
    required this.kind,
    required this.at,
    this.note,
  });

  final String id;
  final String merchant;
  final String categoryId;
  final String categoryLabel;
  final Money amount;
  final TxKind kind;
  final DateTime at;
  final String? note;

  bool get isIncome => kind == TxKind.income;
}

class PreviewBudget {
  const PreviewBudget({
    required this.categoryId,
    required this.label,
    required this.spent,
    required this.limit,
  });

  final String categoryId;
  final String label;
  final Money spent;
  final Money limit;

  double get fraction => spent.ratioOf(limit);
  Money get remaining {
    final left = limit - spent;
    return left.isNegative ? left.zeroed() : left;
  }
}

abstract final class PreviewExtras {
  static Money _inr(int rupees, [int paise = 0]) =>
      Money.fromMinor(rupees * 100 + paise, 'INR');

  static DateTime _daysAgo(int d, int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - d, hour, minute);
  }

  static List<PreviewTx> transactions() => [
        PreviewTx(
          id: 't1',
          merchant: 'Swiggy',
          categoryId: 'food',
          categoryLabel: 'Food',
          amount: _inr(428),
          kind: TxKind.expense,
          at: _daysAgo(0, 20, 40),
          note: 'Dinner',
        ),
        PreviewTx(
          id: 't2',
          merchant: 'Blue Tokai',
          categoryId: 'coffee',
          categoryLabel: 'Coffee',
          amount: _inr(320),
          kind: TxKind.expense,
          at: _daysAgo(0, 9, 15),
        ),
        PreviewTx(
          id: 't3',
          merchant: 'Uber',
          categoryId: 'transport',
          categoryLabel: 'Transport',
          amount: _inr(186),
          kind: TxKind.expense,
          at: _daysAgo(1, 18, 5),
          note: 'Airport drop',
        ),
        PreviewTx(
          id: 't4',
          merchant: 'BigBasket',
          categoryId: 'groceries',
          categoryLabel: 'Groceries',
          amount: _inr(1240),
          kind: TxKind.expense,
          at: _daysAgo(1, 11, 30),
        ),
        PreviewTx(
          id: 't5',
          merchant: 'Client retainer',
          categoryId: 'freelance',
          categoryLabel: 'Freelance',
          amount: _inr(25000),
          kind: TxKind.income,
          at: _daysAgo(2, 10, 0),
        ),
        PreviewTx(
          id: 't6',
          merchant: 'Airtel',
          categoryId: 'bills',
          categoryLabel: 'Bills',
          amount: _inr(699),
          kind: TxKind.expense,
          at: _daysAgo(3, 8, 20),
          note: 'Broadband',
        ),
        PreviewTx(
          id: 't7',
          merchant: 'Myntra',
          categoryId: 'shopping',
          categoryLabel: 'Shopping',
          amount: _inr(2199),
          kind: TxKind.expense,
          at: _daysAgo(4, 16, 45),
        ),
        PreviewTx(
          id: 't8',
          merchant: 'Netflix',
          categoryId: 'subscriptions',
          categoryLabel: 'Subscriptions',
          amount: _inr(649),
          kind: TxKind.expense,
          at: _daysAgo(5, 7, 0),
        ),
        PreviewTx(
          id: 't9',
          merchant: 'Apollo Pharmacy',
          categoryId: 'health',
          categoryLabel: 'Health',
          amount: _inr(540),
          kind: TxKind.expense,
          at: _daysAgo(6, 19, 10),
        ),
      ];

  static List<PreviewBudget> budgets() => [
        PreviewBudget(
          categoryId: 'food',
          label: 'Food',
          spent: _inr(1820),
          limit: _inr(2500),
        ),
        PreviewBudget(
          categoryId: 'transport',
          label: 'Transport',
          spent: _inr(960),
          limit: _inr(1500),
        ),
        PreviewBudget(
          categoryId: 'shopping',
          label: 'Shopping',
          spent: _inr(2199),
          limit: _inr(2000),
        ),
        PreviewBudget(
          categoryId: 'groceries',
          label: 'Groceries',
          spent: _inr(1240),
          limit: _inr(3000),
        ),
        PreviewBudget(
          categoryId: 'subscriptions',
          label: 'Subscriptions',
          spent: _inr(649),
          limit: _inr(800),
        ),
      ];
}
