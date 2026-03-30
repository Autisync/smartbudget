import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CurrencyService {
  const CurrencyService(this._secureStorage);

  static const String defaultCurrency = 'USD';
  static const _keyCurrencyCode = 'app_currency_code';

  final FlutterSecureStorage _secureStorage;

  Future<String> loadCurrencyCode() async {
    final raw = await _secureStorage.read(key: _keyCurrencyCode);
    if (raw == null || raw.trim().isEmpty) return defaultCurrency;
    return raw.toUpperCase();
  }

  Future<void> saveCurrencyCode(String code) async {
    await _secureStorage.write(
        key: _keyCurrencyCode, value: code.toUpperCase());
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
