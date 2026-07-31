import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P3.7: the selected currency isn't a secret — moved off Keychain-backed
/// secure storage onto SharedPreferences.
class CurrencyService {
  const CurrencyService(this._prefs);

  static const String defaultCurrency = 'USD';
  static const List<String> supportedCurrencyCodes = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CHF',
    'CAD',
    'AUD',
    'BRL',
    'CNY',
    'INR',
    'MXN',
    'NZD',
    'SGD',
    'HKD',
    'ZAR',
    'SEK',
    'NOK',
    'DKK',
    'AED',
    'SAR',
    'KES',
    'NGN',
    'NAD',
    'AOA',
  ];
  static const _keyCurrencyCode = 'app_currency_code';
  static const _keySavingsCurrencyCode = 'savings_currency_code';

  final SharedPreferences _prefs;

  Future<String> loadCurrencyCode() async {
    final raw = _prefs.getString(_keyCurrencyCode);
    if (raw == null || raw.trim().isEmpty) return defaultCurrency;
    final normalized = raw.toUpperCase();
    if (!supportedCurrencyCodes.contains(normalized)) return defaultCurrency;
    return normalized;
  }

  Future<void> saveCurrencyCode(String code) async {
    await _prefs.setString(_keyCurrencyCode, code.toUpperCase());
  }

  Future<String> loadSavingsCurrencyCode({
    String fallback = defaultCurrency,
  }) async {
    final raw = _prefs.getString(_keySavingsCurrencyCode);
    if (raw == null || raw.trim().isEmpty) return fallback.toUpperCase();
    final normalized = raw.toUpperCase();
    if (!supportedCurrencyCodes.contains(normalized)) {
      return fallback.toUpperCase();
    }
    return normalized;
  }

  Future<void> saveSavingsCurrencyCode(String code) async {
    await _prefs.setString(_keySavingsCurrencyCode, code.toUpperCase());
  }
}

class AppCurrencyController extends StateNotifier<String> {
  AppCurrencyController(this._service)
      : super(CurrencyService.defaultCurrency) {
    _load();
  }

  final CurrencyService _service;

  Future<void> _load() async {
    state = await _service.loadCurrencyCode();
  }

  Future<void> setCurrencyCode(String code) async {
    final normalized = code.toUpperCase();
    if (state == normalized) return;
    state = normalized;
    await _service.saveCurrencyCode(normalized);
  }
}




