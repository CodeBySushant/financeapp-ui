import 'package:flutter_test/flutter_test.dart';
import 'package:fintrak/core/utils/money.dart';

void main() {
  group('parsing', () {
    test('reads plain and grouped input', () {
      expect(Money.parse('249.50', 'INR').minor, 24950);
      expect(Money.parse('1,240', 'INR').minor, 124000);
      expect(Money.parse('\u20B9 80', 'INR').minor, 8000);
    });

    test('rejects more precision than the currency allows', () {
      expect(Money.tryParse('10.999', 'INR'), isNull);
    });

    test('honours zero-decimal currencies', () {
      expect(Money.parse('500', 'JPY').minor, 500);
    });

    test('rejects junk rather than defaulting to zero', () {
      expect(Money.tryParse('', 'INR'), isNull);
      expect(Money.tryParse('abc', 'INR'), isNull);
    });
  });

  group('arithmetic', () {
    test('the classic float trap stays exact', () {
      final a = Money.parse('0.10', 'USD');
      final b = Money.parse('0.20', 'USD');
      expect((a + b), Money.parse('0.30', 'USD'));
    });

    test('refuses to mix currencies', () {
      expect(
        () => const Money.fromMinor(100, 'INR') + Money.fromMinor(100, 'USD'),
        throwsArgumentError,
      );
    });

    test('summing an empty list yields a typed zero', () {
      expect(<Money>[].total('INR'), const Money.fromMinor(0, 'INR'));
    });
  });

  group('allocate', () {
    test('parts always sum back to the original', () {
      for (final total in [100, 1000, 54501, 999999, 7]) {
        for (final parts in [3, 7, 28, 30, 31]) {
          final split = Money.fromMinor(total, 'INR').allocate(parts);
          expect(
            split.total('INR').minor,
            total,
            reason: 'splitting $total into $parts lost or created value',
          );
          expect(split, hasLength(parts));
        }
      }
    });

    test('distributes the remainder to the earliest parts', () {
      final split = const Money.fromMinor(100, 'INR').allocate(3);
      expect(split.map((m) => m.minor).toList(), [34, 33, 33]);
    });

    test('handles negative balances without losing a unit', () {
      final split = const Money.fromMinor(-100, 'INR').allocate(3);
      expect(split.total('INR').minor, -100);
    });
  });

  group('ratioOf', () {
    test('is zero rather than NaN when the denominator is zero', () {
      expect(
        const Money.fromMinor(500, 'INR').ratioOf(Money.fromMinor(0, 'INR')),
        0,
      );
    });

    test('clamps once spending passes the budget', () {
      expect(
        const Money.fromMinor(1500, 'INR').ratioOf(Money.fromMinor(1000, 'INR')),
        1.0,
      );
    });
  });

  group('formatting', () {
    test('groups by lakh for INR', () {
      expect(
        const Money.fromMinor(48292050, 'INR').format(),
        contains('4,82,920'),
      );
    });

    test('drops empty decimals but keeps real ones', () {
      expect(const Money.fromMinor(1845000, 'INR').format(), '\u20B918,450');
      expect(const Money.fromMinor(1845050, 'INR').format(), '\u20B918,450.50');
    });

    test('uses a true minus sign, not a hyphen', () {
      expect(const Money.fromMinor(-25000, 'INR').format(), startsWith('\u2212'));
    });
  });
}
