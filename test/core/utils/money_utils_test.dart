import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/utils/money_utils.dart';

void main() {
  // ---------------------------------------------------------------------------
  // MoneyUtils.parse — locale-agnostic amount parser
  // ---------------------------------------------------------------------------
  group('MoneyUtils.parse', () {
    // --- Null / empty / non-numeric ----------------------------------------
    test('returns null for empty string', () {
      expect(MoneyUtils.parse(''), isNull);
      expect(MoneyUtils.parse('   '), isNull);
    });

    test('returns null for non-numeric input', () {
      expect(MoneyUtils.parse('abc'), isNull);
      expect(MoneyUtils.parse('N/A'), isNull);
    });

    // --- Pure integers -------------------------------------------------------
    test('parses plain integers', () {
      expect(MoneyUtils.parse('0'), 0.0);
      expect(MoneyUtils.parse('100'), 100.0);
      expect(MoneyUtils.parse('2000'), 2000.0);
    });

    // --- en_US comma-thousands / dot-decimal ---------------------------------
    test('parses en_US thousands comma as grouping separator', () {
      expect(MoneyUtils.parse('2,000'), 2000.0);
      expect(MoneyUtils.parse('10,000'), 10000.0);
      expect(MoneyUtils.parse('1,000,000'), 1000000.0);
    });

    test('parses en_US decimal dot', () {
      expect(MoneyUtils.parse('2.50'), 2.5);
      expect(MoneyUtils.parse('100.00'), 100.0);
      expect(MoneyUtils.parse('999.99'), 999.99);
    });

    test('parses en_US both separators correctly', () {
      expect(MoneyUtils.parse('1,234.56'), 1234.56);
      expect(MoneyUtils.parse('1,000,000.99'), 1000000.99);
    });

    // --- European dot-thousands / comma-decimal ------------------------------
    test('parses EU thousands dot as grouping separator', () {
      expect(MoneyUtils.parse('2.000'), 2000.0);
      expect(MoneyUtils.parse('10.000'), 10000.0);
      expect(MoneyUtils.parse('1.000.000'), 1000000.0);
    });

    test('parses EU decimal comma', () {
      expect(MoneyUtils.parse('2,50'), 2.5);
      expect(MoneyUtils.parse('100,00'), 100.0);
      expect(MoneyUtils.parse('999,99'), 999.99);
    });

    test('parses EU both separators correctly', () {
      expect(MoneyUtils.parse('1.234,56'), 1234.56);
      expect(MoneyUtils.parse('1.000.000,99'), 1000000.99);
    });

    // --- Short decimal fractions (1–2 digits after separator) ----------------
    test('treats single digit after comma as decimal', () {
      expect(MoneyUtils.parse('1,5'), 1.5);
      expect(MoneyUtils.parse('12,5'), 12.5);
    });

    test('treats two digits after comma as decimal', () {
      expect(MoneyUtils.parse('1,50'), 1.5);
      expect(MoneyUtils.parse('12,99'), 12.99);
    });

    // --- Currency symbol / prefix --------------------------------------------
    test('strips currency symbols before parsing', () {
      expect(MoneyUtils.parse(r'$ 2,499.90'), 2499.9);
      expect(MoneyUtils.parse('Kz 12,300.00'), 12300.0);
      expect(MoneyUtils.parse('€ 1.234,56'), 1234.56);
    });

    // --- Negative values -----------------------------------------------------
    test('parses negative en_US amounts', () {
      expect(MoneyUtils.parse('-1,500.75'), -1500.75);
      expect(MoneyUtils.parse('-2,000'), -2000.0);
    });

    test('parses negative EU amounts', () {
      expect(MoneyUtils.parse('-1.500,75'), -1500.75);
    });

    // --- Zero ----------------------------------------------------------------
    test('parses zero representations', () {
      expect(MoneyUtils.parse('0'), 0.0);
      expect(MoneyUtils.parse('0.00'), 0.0);
      expect(MoneyUtils.parse('0,00'), 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // MoneyUtils.quantize
  // ---------------------------------------------------------------------------
  group('MoneyUtils.quantize', () {
    test('rounds to 2 decimal places for standard currencies', () {
      expect(MoneyUtils.quantize(1.005, 'USD'), 1.01);
      expect(MoneyUtils.quantize(1.004, 'USD'), 1.0);
      expect(MoneyUtils.quantize(99.999, 'EUR'), 100.0);
    });

    test('rounds to 0 decimal places for zero-decimal currencies', () {
      expect(MoneyUtils.quantize(1500.7, 'JPY'), 1501.0);
      expect(MoneyUtils.quantize(200.4, 'KRW'), 200.0);
    });

    test('rounds to 3 decimal places for three-decimal currencies', () {
      expect(MoneyUtils.quantize(1.0005, 'KWD'), 1.001);
      expect(MoneyUtils.quantize(1.0004, 'BHD'), 1.0);
    });

    test('handles NaN and Infinity as zero', () {
      expect(MoneyUtils.quantize(double.nan, 'USD'), 0.0);
      expect(MoneyUtils.quantize(double.infinity, 'USD'), 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // MoneyUtils.toMinorUnits / fromMinorUnits
  // ---------------------------------------------------------------------------
  group('MoneyUtils minor units', () {
    test('USD: 12.50 → 1250 and back', () {
      expect(MoneyUtils.toMinorUnits(12.50, 'USD'), 1250);
      expect(MoneyUtils.fromMinorUnits(1250, 'USD'), 12.50);
    });

    test('JPY: 500 → 500 (no decimals)', () {
      expect(MoneyUtils.toMinorUnits(500, 'JPY'), 500);
      expect(MoneyUtils.fromMinorUnits(500, 'JPY'), 500.0);
    });

    test('KWD: 1.123 → 1123 (3 decimals)', () {
      expect(MoneyUtils.toMinorUnits(1.123, 'KWD'), 1123);
      expect(MoneyUtils.fromMinorUnits(1123, 'KWD'), 1.123);
    });
  });

  // ---------------------------------------------------------------------------
  // MoneyUtils.decimalDigits
  // ---------------------------------------------------------------------------
  group('MoneyUtils.decimalDigits', () {
    test('returns 0 for zero-decimal currencies', () {
      for (final c in ['JPY', 'KRW', 'VND', 'CLP']) {
        expect(MoneyUtils.decimalDigits(c), 0, reason: c);
      }
    });

    test('returns 3 for three-decimal currencies', () {
      for (final c in ['KWD', 'BHD', 'OMR']) {
        expect(MoneyUtils.decimalDigits(c), 3, reason: c);
      }
    });

    test('returns 2 for all other currencies', () {
      for (final c in ['USD', 'EUR', 'GBP', 'AUD', 'ZAR', 'NAD']) {
        expect(MoneyUtils.decimalDigits(c), 2, reason: c);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // MoneyUtils.isWithinLimit
  // ---------------------------------------------------------------------------
  group('MoneyUtils.isWithinLimit', () {
    test('accepts amounts within the backend envelope', () {
      expect(MoneyUtils.isWithinLimit(0), isTrue);
      expect(MoneyUtils.isWithinLimit(999999999999.99), isTrue);
      expect(MoneyUtils.isWithinLimit(-999999999999.99), isTrue);
    });

    test('rejects amounts beyond the backend envelope', () {
      expect(MoneyUtils.isWithinLimit(1000000000000), isFalse);
      expect(MoneyUtils.isWithinLimit(-1000000000000), isFalse);
      expect(MoneyUtils.isWithinLimit(double.infinity), isFalse);
      expect(MoneyUtils.isWithinLimit(double.nan), isFalse);
    });
  });
}
