import 'dart:math';

import '../utils/money.dart';

/// Shared JSON helpers.
///
/// Every endpoint sends money as `{ amountMinor, currency }` and dates as ISO
/// strings, so those two conversions live here rather than being re-typed in
/// every mapper.
abstract final class J {
  static Money money(Object? raw, String fallbackCurrency) {
    if (raw is Map) {
      return Money.fromMinor(
        (raw['amountMinor'] as num?)?.toInt() ?? 0,
        raw['currency'] as String? ?? fallbackCurrency,
      );
    }
    return Money.fromMinor(0, fallbackCurrency);
  }

  static Money? moneyOrNull(Object? raw, String fallbackCurrency) =>
      raw is Map ? money(raw, fallbackCurrency) : null;

  static DateTime? date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

  static String str(Object? raw, [String fallback = '']) =>
      raw is String ? raw : fallback;

  static List<Map<String, dynamic>> items(Object? raw) {
    if (raw is Map && raw['items'] is List) {
      return (raw['items'] as List)
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false);
    }
    return const [];
  }

  /// A v4 UUID, used as `clientRef` so a retried create returns the original
  /// transaction instead of writing a second one. The API validates the format,
  /// so this has to be a real v4 rather than any random string.
  static String uuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hex(int start, int end) =>
        b.sublist(start, end).map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
