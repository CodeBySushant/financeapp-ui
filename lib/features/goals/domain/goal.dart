import 'package:flutter/foundation.dart';

import '../../../core/models/json.dart';
import '../../../core/utils/money.dart';

@immutable
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.saved,
    required this.target,
    required this.fraction,
    required this.status,
    this.targetDate,
    this.requiredMonthly,
  });

  final String id;
  final String name;
  final Money saved;
  final Money target;
  final double fraction;
  final String status;
  final DateTime? targetDate;
  final Money? requiredMonthly;

  int get percent => (fraction * 100).round();
  bool get isComplete => status == 'COMPLETED' || fraction >= 1;

  Money get remaining {
    final left = target - saved;
    return left.isNegative ? left.zeroed() : left;
  }

  factory Goal.fromJson(Map<String, dynamic> j, String currency) => Goal(
        id: J.str(j['id']),
        name: J.str(j['name'], 'Goal'),
        saved: J.money(j['saved'], currency),
        target: J.money(j['target'], currency),
        fraction: (j['fraction'] as num?)?.toDouble() ?? 0,
        status: J.str(j['status'], 'ACTIVE'),
        targetDate: J.date(j['targetDate']),
        requiredMonthly: J.moneyOrNull(j['requiredMonthly'], currency),
      );
}
