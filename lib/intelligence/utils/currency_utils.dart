import 'package:intl/intl.dart';

class CurrencyUtils {
  static const Map<String, String> _symbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CHF': 'CHF ',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'BRL': 'R\$',
    'CNY': 'CNY ',
    'INR': 'INR ',
    'NAD': 'N\$',
    'AOA': 'Kz ',
    'MXN': 'MX\$',
    'NZD': 'NZ\$',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'ZAR': 'R ',
    'SEK': 'SEK ',
    'NOK': 'NOK ',
    'DKK': 'DKK ',
    'AED': 'AED ',
    'SAR': 'SAR ',
    'KES': 'KSh ',
    'NGN': '₦',
  };

  static NumberFormat getFormat(String currencyCode) {
    final code = currencyCode.toUpperCase();
    final mappedSymbol = _symbols[code];
    if (mappedSymbol != null) {
      return NumberFormat.currency(name: code, symbol: mappedSymbol);
    }
    try {
      return NumberFormat.simpleCurrency(name: code);
    } catch (_) {
      return NumberFormat.currency(name: code, symbol: '$code ');
    }
  }

  static NumberFormat getCompactFormat(String currencyCode) {
    final code = currencyCode.toUpperCase();
    final mappedSymbol = _symbols[code];
    if (mappedSymbol != null) {
      return NumberFormat.compactCurrency(name: code, symbol: mappedSymbol);
    }
    try {
      return NumberFormat.compactCurrency(name: code);
    } catch (_) {
      return NumberFormat.compactCurrency(name: code, symbol: '$code ');
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
