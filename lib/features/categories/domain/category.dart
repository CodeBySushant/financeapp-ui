import 'package:flutter/foundation.dart';

import '../../../core/models/json.dart';

enum CategoryKind {
  income,
  expense;

  String get wire => this == CategoryKind.income ? 'INCOME' : 'EXPENSE';

  static CategoryKind parse(String? raw) =>
      raw == 'INCOME' ? CategoryKind.income : CategoryKind.expense;
}

@immutable
class Category {
  const Category({
    required this.id,
    required this.slug,
    required this.name,
    required this.kind,
    this.isSystem = false,
  });

  final String id;

  /// The stable key the icon and colour lookups use. `id` is a UUID and differs
  /// per account, so it cannot drive presentation.
  final String slug;

  final String name;
  final CategoryKind kind;
  final bool isSystem;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: J.str(j['id']),
        slug: J.str(j['slug'], 'other'),
        name: J.str(j['name'], 'Uncategorised'),
        kind: CategoryKind.parse(j['kind'] as String?),
        isSystem: j['isSystem'] as bool? ?? false,
      );
}
