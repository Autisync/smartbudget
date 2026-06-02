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
    if (parsed == null || parsed <= 0) {
      return invalidMessage;
    }
    return null;
  }

  static String? nonNegativeAmount(String? value, String invalidMessage) {
    final parsed = parseDecimal(value ?? '');
    if (parsed == null || parsed < 0) {
      return invalidMessage;
    }
    return null;
  }

  static double? parseDecimal(String raw) {
    final normalized =
        raw.replaceAll(RegExp(r'[^0-9,.-]'), '').replaceAll(',', '');
    return double.tryParse(normalized);
  }

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
