import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/currency_provider.dart';
import '../data/budgets_repository.dart';
import '../domain/budget.dart';

final budgetsRepositoryProvider =
    Provider<BudgetsRepository>((ref) => BudgetsRepository());

final budgetsProvider = FutureProvider<BudgetBoard>((ref) async {
  final currency = ref.watch(currencyProvider);
  return ref.read(budgetsRepositoryProvider).board(currency);
});
