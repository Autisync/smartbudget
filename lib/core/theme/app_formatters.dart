import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static NumberFormat currency({
    required String currencyCode,
    String? symbol,
    int decimalDigits = 2,
  }) {
    return NumberFormat.currency(
      name: currencyCode,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
  }

  static DateFormat shortDate([String pattern = 'MMM d']) {
    return DateFormat(pattern);
  }

  static DateFormat longDate([String pattern = 'MMM d, yyyy']) {
    return DateFormat(pattern);
  }

  static String compactNumber(num value) {
    return NumberFormat.compact().format(value);
  }
}
