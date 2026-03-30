import 'package:intl/intl.dart';

class CurrencyUtils {
  static const Map<String, String> _symbols = {
    'USD': r'$',
    'EUR': 'EUR ',
    'GBP': 'GBP ',
    'JPY': 'JPY ',
    'CHF': 'CHF ',
    'CAD': 'CAD ',
    'AUD': 'AUD ',
    'BRL': 'R\$',
    'CNY': 'CNY ',
    'INR': 'INR ',
    'NAD': 'N\$',
    'AOA': 'Kz ',
  };

  static NumberFormat getFormat(String currencyCode) {
    final code = currencyCode.toUpperCase();
    try {
      return NumberFormat.simpleCurrency(name: code);
    } catch (_) {
      return NumberFormat.currency(symbol: _symbols[code] ?? '$code ');
    }
  }

  static NumberFormat getCompactFormat(String currencyCode) {
    final code = currencyCode.toUpperCase();
    try {
      return NumberFormat.compactCurrency(name: code);
    } catch (_) {
      return NumberFormat.compactCurrency(symbol: _symbols[code] ?? '$code ');
    }
  }

  static String formatAmount(double amount, String currencyCode) {
    return getFormat(currencyCode).format(amount);
  }

  static String symbol(String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (_symbols.containsKey(code)) {
      return _symbols[code]!;
    }
    try {
      return getFormat(code).currencySymbol;
    } catch (_) {
      return code;
    }
  }
}
