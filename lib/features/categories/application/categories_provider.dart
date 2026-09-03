import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/categories_repository.dart';
import '../domain/category.dart';

final categoriesRepositoryProvider =
    Provider<CategoriesRepository>((ref) => CategoriesRepository());

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.read(categoriesRepositoryProvider).list(),
);

/// Categories filtered to one side of the ledger. Offering "Salary" while
/// logging a coffee is the kind of thing that makes an app feel unfinished.
final categoriesOfKindProvider =
    Provider.family<List<Category>, CategoryKind>((ref, kind) {
  final all = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
  return all.where((c) => c.kind == kind).toList(growable: false);
});
