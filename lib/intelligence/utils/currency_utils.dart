import 'package:intl/intl.dart';

class CurrencyUtils {
  static NumberFormat getFormat(String currencyCode) {
    try {
      return NumberFormat.simpleCurrency(name: currencyCode);
    } catch (_) {
      return NumberFormat.currency(symbol: '$currencyCode ');
    }
  }

  static String formatAmount(double amount, String currencyCode) {
    return getFormat(currencyCode).format(amount);
  }

  static String symbol(String currencyCode) {
    try {
      return getFormat(currencyCode).currencySymbol;
    } catch (_) {
      return currencyCode;
    }
  }
}
