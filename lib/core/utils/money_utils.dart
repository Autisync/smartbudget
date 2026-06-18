/// Centralized money helpers that bring the client in line with standard
/// money-handling practice:
///
/// * **Minor units (ISO 4217):** the number of decimal places is currency
///   specific (JPY = 0, most = 2, a few Gulf currencies = 3) rather than a
///   hard-coded 2.
/// * **Quantization:** every amount is rounded to its currency's smallest unit
///   at each parse/persist boundary. The on-device store uses doubles, so
///   re-quantizing on the way in and out keeps floating-point drift from ever
///   accumulating into visible cent errors.
/// * **Locale-aware parsing:** user input like `1.234,56` (comma-decimal
///   locales) and `1,234.56` (point-decimal locales) both parse correctly,
///   instead of naively stripping all commas.
/// * **Bounds:** a single source of truth for the maximum representable amount,
///   matching the backend `Numeric(14, 2)` column envelope.
library;

class MoneyUtils {
  const MoneyUtils._();

  /// Largest amount the backend ledger can store (`Numeric(14, 2)` →
  /// 12 integer digits + 2 decimals). Used to validate input client-side so a
  /// value is never accepted locally only to be rejected on sync.
  static const double maxAmount = 999999999999.99;

  /// Currencies whose smallest unit is the whole unit (no decimals).
  static const Set<String> _zeroDecimalCurrencies = {
    'JPY', 'KRW', 'VND', 'CLP', 'ISK', 'XOF', 'XAF', 'XPF',
    'PYG', 'RWF', 'UGX', 'GNF', 'KMF', 'BIF', 'DJF', 'VUV',
  };

  /// Currencies that use three decimal places.
  static const Set<String> _threeDecimalCurrencies = {
    'BHD', 'KWD', 'OMR', 'TND', 'IQD', 'JOD', 'LYD',
  };

  /// Number of decimal places (minor units) for [currencyCode] per ISO 4217.
  static int decimalDigits(String currencyCode) {
    final code = currencyCode.toUpperCase().trim();
    if (_zeroDecimalCurrencies.contains(code)) return 0;
    if (_threeDecimalCurrencies.contains(code)) return 3;
    return 2;
  }

  /// 10^decimalDigits — the number of minor units in one major unit.
  static int minorUnitFactor(String currencyCode) {
    switch (decimalDigits(currencyCode)) {
      case 0:
        return 1;
      case 3:
        return 1000;
      default:
        return 100;
    }
  }

  /// Rounds [amount] to the smallest unit of [currencyCode] using
  /// round-half-away-from-zero (the convention users expect for currency).
  ///
  /// This is the single function every write/aggregation path should funnel
  /// through so stored doubles never carry sub-cent noise.
  static double quantize(double amount, String currencyCode) {
    if (amount.isNaN || amount.isInfinite) return 0;
    final factor = minorUnitFactor(currencyCode);
    final scaled = amount.abs() * factor;
    // Strip binary-representation noise before rounding so half-up behaves as
    // expected: 1.005 * 100 is stored as 100.4999997, which would otherwise
    // round DOWN to 100. Re-rounding the scaled value at a higher precision
    // first restores the true decimal (100.5) so it rounds up to 101.
    final denoised = double.parse(scaled.toStringAsFixed(6));
    final rounded = denoised.roundToDouble();
    final signed = amount.isNegative ? -rounded : rounded;
    return signed / factor;
  }

  /// True when [amount] is finite and within the storable envelope.
  static bool isWithinLimit(double amount) =>
      amount.isFinite && amount.abs() <= maxAmount;

  /// Converts a decimal [amount] into its integer minor-unit representation
  /// (e.g. 12.50 USD → 1250, 500 JPY → 500, 1.123 KWD → 1123).
  ///
  /// The value is quantized before conversion so floating-point noise never
  /// produces an off-by-one in the minor-unit integer.
  static int toMinorUnits(double amount, String currencyCode) {
    final q = quantize(amount, currencyCode);
    return (q * minorUnitFactor(currencyCode)).round();
  }

  /// Inverse of [toMinorUnits]: converts integer [minorUnits] back to the
  /// decimal double representation for the given currency.
  static double fromMinorUnits(int minorUnits, String currencyCode) {
    return minorUnits / minorUnitFactor(currencyCode);
  }

  /// Parses a user-entered amount string into a double, tolerant of both
  /// point-decimal (`1,234.56`) and comma-decimal (`1.234,56`) conventions as
  /// well as currency symbols and whitespace. Returns null if no number can be
  /// read.
  ///
  /// Disambiguation rules (applied in order):
  /// 1. **Both separators present** — whichever appears *last* is the decimal
  ///    separator (the standard heuristic for `1,234.56` vs `1.234,56`).
  /// 2. **Only one separator type, appearing more than once** — it's a
  ///    grouping separator (e.g. `1,000,000` or `1.000.000`).
  /// 3. **Exactly one separator followed by exactly three digits at end** —
  ///    treat as grouping separator (`2,000` → 2000, `2.000` → 2000). This
  ///    resolves the ambiguity between `2,000` (two thousand) and `2,00`
  ///    (two point zero zero in some locales).
  /// 4. **Otherwise** — treat the single separator as the decimal separator.
  static double? parse(String raw) {
    if (raw.trim().isEmpty) return null;
    var s = raw.replaceAll(RegExp(r'[^0-9.,-]'), '');
    if (s.isEmpty) return null;

    // Preserve only a single leading minus sign.
    final negative = s.startsWith('-');
    s = s.replaceAll('-', '');
    if (s.isEmpty) return null;

    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    final hasComma = lastComma != -1;
    final hasDot = lastDot != -1;

    if (!hasComma && !hasDot) {
      // Pure digits — fall through.
    } else if (hasComma && hasDot) {
      // Rule 1: both present — last one is the decimal separator.
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final groupSep = decimalSep == ',' ? '.' : ',';
      s = s.replaceAll(groupSep, '');
      if (decimalSep == ',') s = s.replaceAll(',', '.');
    } else {
      // Only one separator type present.
      final sep = hasComma ? ',' : '.';
      final sepCount = hasComma
          ? ','.allMatches(s).length
          : '.'.allMatches(s).length;
      final afterSep = s.substring(s.lastIndexOf(sep) + 1);

      final isGrouping = sepCount > 1 || afterSep.length == 3;
      if (isGrouping) {
        // Rule 2 or 3: strip the grouping separator; result is an integer.
        s = s.replaceAll(sep, '');
      } else {
        // Rule 4: treat as decimal separator.
        if (sep == ',') s = s.replaceAll(',', '.');
      }
    }

    final value = double.tryParse(s);
    if (value == null) return null;
    return negative ? -value : value;
  }
}
