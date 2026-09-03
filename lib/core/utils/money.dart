import 'package:intl/intl.dart';

/// A monetary amount held as an **integer number of minor units** (paise,
/// cents, pence) alongside its currency code.
///
/// Floating point never touches an amount. `0.1 + 0.2 != 0.3` is a rounding bug
/// in a demo and a reconciliation failure in a finance app, so `double` is not
/// used for storage, arithmetic, or transport. On the wire, amounts are integers
/// and a currency code; on the server they map to `Decimal(18, 2)`.
///
/// ```dart
/// final coffee = Money.fromMinor(18000, 'INR'); // Rs 180.00
/// final lunch  = Money.parse('249.50', 'INR');
/// (coffee + lunch).format();                    // Rs 429.50
/// ```
class Money implements Comparable<Money> {
  const Money._(this.minor, this.currency);

  /// Construct from minor units — the only representation that round-trips.
  const Money.fromMinor(this.minor, this.currency);

  final int minor;
  final String currency;

  /// Minor units per major unit, per ISO 4217. Most currencies are 2; a few
  /// (JPY, KRW) have none, and misplacing that is a factor-of-100 error.
  static const Map<String, int> _exponent = {
    'INR': 2, 'NPR': 2, 'USD': 2, 'EUR': 2, 'GBP': 2, 'AUD': 2,
    'CAD': 2, 'SGD': 2, 'AED': 2, 'JPY': 0, 'KRW': 0,
  };

  static const Map<String, String> _symbol = {
    'INR': '\u20B9', 'NPR': '\u0930\u0942', 'USD': '\$', 'EUR': '\u20AC',
    'GBP': '\u00A3', 'AUD': 'A\$', 'CAD': 'C\$', 'SGD': 'S\$',
    'AED': 'AED ', 'JPY': '\u00A5', 'KRW': '\u20A9',
  };

  /// Grouping differs by market and is not cosmetic: Indian and Nepali readers
  /// expect 4,82,920 (lakh grouping), not 482,920.
  static const Map<String, String> _locale = {
    'INR': 'en_IN', 'NPR': 'en_IN', 'USD': 'en_US', 'EUR': 'de_DE',
    'GBP': 'en_GB', 'AUD': 'en_AU', 'CAD': 'en_CA', 'SGD': 'en_SG',
    'AED': 'en_AE', 'JPY': 'ja_JP', 'KRW': 'ko_KR',
  };

  static int exponentOf(String currency) => _exponent[currency.toUpperCase()] ?? 2;

  static String symbolOf(String currency) =>
      _symbol[currency.toUpperCase()] ?? '${currency.toUpperCase()} ';

  int get _exp => exponentOf(currency);

  /// Parse user input ("1,240.50", "₹250", "  80 ") without ever going through
  /// a `double`. Digits after the currency's exponent are rejected rather than
  /// silently rounded, so the UI can tell the user what it did not accept.
  static Money? tryParse(String input, String currency) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;

    final negative = cleaned.startsWith('-');
    final body = negative ? cleaned.substring(1) : cleaned;
    final parts = body.split('.');
    if (parts.length > 2) return null;

    final exp = exponentOf(currency);
    final whole = parts[0].isEmpty ? '0' : parts[0];
    var frac = parts.length == 2 ? parts[1] : '';
    if (frac.length > exp) return null;
    frac = frac.padRight(exp, '0');

    final digits = int.tryParse('$whole$frac');
    if (digits == null) return null;
    return Money.fromMinor(negative ? -digits : digits, currency.toUpperCase());
  }

  /// Throwing variant, for trusted input such as server responses.
  static Money parse(String input, String currency) {
    final v = tryParse(input, currency);
    if (v == null) {
      throw FormatException('Not a valid amount for $currency', input);
    }
    return v;
  }

  /// Decode `{"amountMinor": 18000, "currency": "INR"}`.
  factory Money.fromJson(Map<String, dynamic> json) => Money.fromMinor(
        (json['amountMinor'] as num).toInt(),
        json['currency'] as String,
      );

  Map<String, dynamic> toJson() => {
        'amountMinor': minor,
        'currency': currency,
      };

  Money zeroed() => Money.fromMinor(0, currency);
  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  Money get abs => Money.fromMinor(minor.abs(), currency);

  void _assertSame(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Cannot combine $currency with ${other.currency}. Convert first — '
        'mixing currencies silently is how totals go wrong.',
      );
    }
  }

  Money operator +(Money other) {
    _assertSame(other);
    return Money.fromMinor(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _assertSame(other);
    return Money.fromMinor(minor - other.minor, currency);
  }

  Money operator -() => Money.fromMinor(-minor, currency);

  /// Scale by a ratio, rounding half-away-from-zero at the minor unit.
  Money scaled(num factor) =>
      Money.fromMinor((minor * factor).round(), currency);

  /// Split evenly, distributing the remainder one minor unit at a time so the
  /// parts always sum back to the original. Used for shared expenses and for
  /// "safe daily spend" over the remaining days of a month.
  List<Money> allocate(int parts) {
    if (parts <= 0) throw ArgumentError('parts must be positive');
    final base = minor ~/ parts;
    var remainder = minor.remainder(parts).abs();
    final step = minor.isNegative ? -1 : 1;
    return List.generate(parts, (i) {
      var value = base;
      if (remainder > 0) {
        value += step;
        remainder--;
      }
      return Money.fromMinor(value, currency);
    });
  }

  /// [minor] as a ratio of [total], clamped to 0..1. Returns 0 when [total] is
  /// zero so progress bars never produce NaN.
  double ratioOf(Money total) {
    _assertSame(total);
    if (total.minor == 0) return 0;
    return (minor / total.minor).clamp(0.0, 1.0);
  }

  /// Only for handing a value to a chart library, which needs doubles. Never
  /// feed the result back into money arithmetic.
  double toChartValue() => minor / _pow10(_exp);

  static int _pow10(int e) {
    var v = 1;
    for (var i = 0; i < e; i++) {
      v *= 10;
    }
    return v;
  }

  /// Render for display.
  ///
  /// [showSign] prefixes an explicit `+` on positives, for income rows.
  /// [trimZeroDecimals] drops `.00` — a dashboard reads better as Rs 18,450
  /// than Rs 18,450.00, while an edit field wants the full precision.
  /// [compact] gives Rs 4.8L / $1.2M for tight chart labels.
  String format({
    bool showSign = false,
    bool trimZeroDecimals = true,
    bool compact = false,
    bool withSymbol = true,
  }) {
    final locale = _locale[currency] ?? 'en_US';
    final symbol = withSymbol ? symbolOf(currency) : '';
    final value = minor.abs() / _pow10(_exp);

    final String body;
    if (compact) {
      body = NumberFormat.compactCurrency(
        locale: locale,
        symbol: symbol,
        decimalDigits: 1,
      ).format(value);
    } else {
      final decimals =
          trimZeroDecimals && minor.abs() % _pow10(_exp) == 0 ? 0 : _exp;
      body = NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: decimals,
      ).format(value);
    }

    if (minor < 0) return '\u2212$body'; // U+2212, aligns with digit width
    if (showSign && minor > 0) return '+$body';
    return body;
  }

  /// Screen-reader text. "Minus 250 rupees" beats "−₹250" read as "250".
  String semanticLabel() {
    final sign = minor < 0 ? 'minus ' : '';
    final value = minor.abs() / _pow10(_exp);
    return '$sign${NumberFormat.decimalPattern(_locale[currency] ?? 'en_US').format(value)} '
        '${_spokenName[currency.toUpperCase()] ?? currency}';
  }

  static const Map<String, String> _spokenName = {
    'INR': 'rupees', 'NPR': 'Nepali rupees', 'USD': 'dollars',
    'EUR': 'euros', 'GBP': 'pounds', 'JPY': 'yen',
  };

  @override
  int compareTo(Money other) {
    _assertSame(other);
    return minor.compareTo(other.minor);
  }

  bool operator >(Money other) => compareTo(other) > 0;
  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >=(Money other) => compareTo(other) >= 0;
  bool operator <=(Money other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => 'Money($minor $currency)';
}

extension MoneyIterableX on Iterable<Money> {
  /// Sum, returning a zero of [currency] for an empty list so callers never
  /// have to null-check a total.
  Money total(String currency) => fold(
        Money.fromMinor(0, currency),
        (sum, m) => sum + m,
      );
}
