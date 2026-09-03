import 'package:flutter/material.dart';

import '../../../core/models/json.dart';
import '../../../core/utils/money.dart';

enum AccountType {
  cash, bank, upi, creditCard, savings, wallet, other;

  String get wire => switch (this) {
        AccountType.cash => 'CASH',
        AccountType.bank => 'BANK',
        AccountType.upi => 'UPI',
        AccountType.creditCard => 'CREDIT_CARD',
        AccountType.savings => 'SAVINGS',
        AccountType.wallet => 'WALLET',
        AccountType.other => 'OTHER',
      };

  String get label => switch (this) {
        AccountType.cash => 'Cash',
        AccountType.bank => 'Bank',
        AccountType.upi => 'UPI',
        AccountType.creditCard => 'Credit card',
        AccountType.savings => 'Savings',
        AccountType.wallet => 'Wallet',
        AccountType.other => 'Other',
      };

  IconData get icon => switch (this) {
        AccountType.cash => Icons.payments_outlined,
        AccountType.bank => Icons.account_balance_outlined,
        AccountType.upi => Icons.qr_code_rounded,
        AccountType.creditCard => Icons.credit_card_rounded,
        AccountType.savings => Icons.savings_outlined,
        AccountType.wallet => Icons.account_balance_wallet_outlined,
        AccountType.other => Icons.circle_outlined,
      };

  static AccountType parse(String? raw) => switch (raw) {
        'CASH' => AccountType.cash,
        'BANK' => AccountType.bank,
        'UPI' => AccountType.upi,
        'CREDIT_CARD' => AccountType.creditCard,
        'SAVINGS' => AccountType.savings,
        'WALLET' => AccountType.wallet,
        _ => AccountType.other,
      };
}

@immutable
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.isDefault,
    required this.balance,
  });

  final String id;
  final String name;
  final AccountType type;
  final bool isDefault;
  final Money balance;

  factory Account.fromJson(Map<String, dynamic> j, String fallbackCurrency) =>
      Account(
        id: J.str(j['id']),
        name: J.str(j['name'], 'Account'),
        type: AccountType.parse(j['type'] as String?),
        isDefault: j['isDefault'] as bool? ?? false,
        balance: J.money(j['balance'], fallbackCurrency),
      );
}
