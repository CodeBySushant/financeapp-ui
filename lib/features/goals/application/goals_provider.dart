import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/currency_provider.dart';
import '../data/goals_repository.dart';
import '../domain/goal.dart';

final goalsRepositoryProvider =
    Provider<GoalsRepository>((ref) => GoalsRepository());

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final currency = ref.watch(currencyProvider);
  return ref.read(goalsRepositoryProvider).list(currency);
});
