import 'package:smartbudget/core/utils/money_utils.dart';

class FormValidation {
  const FormValidation._();

  static String? requiredText(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? positiveAmount(
      String? value, String emptyMessage, String invalidMessage) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }
    final parsed = parseDecimal(value);
    if (parsed == null || parsed <= 0 || !MoneyUtils.isWithinLimit(parsed)) {
      return invalidMessage;
    }
    return null;
  }

  static String? nonNegativeAmount(String? value, String invalidMessage) {
    final parsed = parseDecimal(value ?? '');
    if (parsed == null || parsed < 0 || !MoneyUtils.isWithinLimit(parsed)) {
      return invalidMessage;
    }
    return null;
  }

  /// Parses a monetary string. Locale-aware: tolerates both `1,234.56` and
  /// `1.234,56` conventions instead of blindly stripping commas, and accepts a
  /// leading minus for liability/credit balances.
  static double? parseDecimal(String raw) => MoneyUtils.parse(raw);

  static String? requiredDate(DateTime? value, String message) {
    if (value == null) return message;
    return null;
  }

  static String? percentage(String? value, String invalidMessage,
      {double min = 0, double max = 100}) {
    final parsed = parseDecimal(value ?? '');
    if (parsed == null || parsed < min || parsed > max) {
      return invalidMessage;
    }
    return null;
  }

  static bool isLogicalBudget(
      {required double limitAmount, required double thresholdPercent}) {
    return limitAmount > 0 && thresholdPercent >= 0 && thresholdPercent <= 100;
  }
}
