import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/currency_provider.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';

final accountsRepositoryProvider =
    Provider<AccountsRepository>((ref) => AccountsRepository());

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final currency = ref.watch(currencyProvider);
  return ref.read(accountsRepositoryProvider).list(currency);
});

/// Where a new transaction lands unless the person picks otherwise. Every
/// account is created with a default, so this is only null before the first
/// load finishes.
final defaultAccountProvider = Provider<Account?>((ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull;
  if (accounts == null || accounts.isEmpty) return null;
  for (final a in accounts) {
    if (a.isDefault) return a;
  }
  return accounts.first;
});
