import 'package:flutter/foundation.dart';

import '../../../core/models/json.dart';
import '../../../core/utils/money.dart';

enum TxType {
  income,
  expense,
  transfer;

  String get wire => switch (this) {
        TxType.income => 'INCOME',
        TxType.expense => 'EXPENSE',
        TxType.transfer => 'TRANSFER',
      };

  String get label => switch (this) {
        TxType.income => 'Income',
        TxType.expense => 'Spending',
        TxType.transfer => 'Transfer',
      };

  static TxType parse(String? raw) => switch (raw) {
        'INCOME' => TxType.income,
        'TRANSFER' => TxType.transfer,
        _ => TxType.expense,
      };
}

@immutable
class TxAccountRef {
  const TxAccountRef({required this.id, required this.name});

  final String id;
  final String name;

  static TxAccountRef? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return TxAccountRef(
      id: J.str(raw['id']),
      name: J.str(raw['name'], 'Account'),
    );
  }
}

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.merchant,
    this.note,
    this.categorySlug,
    this.categoryName,
    this.categoryId,
    this.account,
    this.toAccount,
  });

  final String id;
  final TxType type;
  final Money amount;
  final DateTime transactionDate;
  final String? merchant;
  final String? note;
  final String? categorySlug;
  final String? categoryName;
  final String? categoryId;
  final TxAccountRef? account;
  final TxAccountRef? toAccount;

  bool get isIncome => type == TxType.income;
  bool get isTransfer => type == TxType.transfer;

  /// What the row shows as its heading. Merchant when there is one, otherwise
  /// the category, otherwise the account — never an empty line.
  String get title {
    final m = merchant?.trim();
    if (m != null && m.isNotEmpty) return m;
    if (isTransfer) return 'Transfer to ${toAccount?.name ?? 'account'}';
    final c = categoryName?.trim();
    if (c != null && c.isNotEmpty) return c;
    return account?.name ?? 'Transaction';
  }

  String get subtitle {
    final parts = <String>[];
    if (!isTransfer && (categoryName?.isNotEmpty ?? false)) {
      parts.add(categoryName!);
    }
    if (account != null) parts.add(account!.name);
    final n = note?.trim();
    if (n != null && n.isNotEmpty) parts.add(n);
    return parts.join(' · ');
  }

  factory Transaction.fromJson(Map<String, dynamic> j, String fallbackCurrency) {
    final category = j['category'];
    return Transaction(
      id: J.str(j['id']),
      type: TxType.parse(j['type'] as String?),
      amount: J.money(j['amount'], fallbackCurrency),
      transactionDate: J.date(j['transactionDate']) ?? DateTime.now(),
      merchant: j['merchant'] as String?,
      note: j['note'] as String?,
      categoryId: category is Map ? category['id'] as String? : null,
      categorySlug: category is Map ? category['slug'] as String? : null,
      categoryName: category is Map ? category['name'] as String? : null,
      account: TxAccountRef.fromJson(j['account']),
      toAccount: TxAccountRef.fromJson(j['toAccount']),
    );
  }
}

/// One page of results plus the cursor for the next.
@immutable
class TransactionPage {
  const TransactionPage({required this.items, required this.nextCursor});

  final List<Transaction> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
