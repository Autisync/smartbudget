import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleService {
  const LocaleService(this._secureStorage);

  static const String defaultLanguageCode = 'en';
  // Must stay in sync with the generated AppLocalizations.supportedLocales and
  // the language picker in settings. German and French ship complete ARB
  // translations, so they are exposed for selection here.
  static const List<String> supportedLanguageCodes = [
    'en',
    'pt',
    'es',
    'de',
    'fr',
  ];
  static const _keyLanguageCode = 'app_language_code';

  final FlutterSecureStorage _secureStorage;

  Future<String> loadLanguageCode() async {
    final raw = await _secureStorage.read(key: _keyLanguageCode);
    if (raw == null || raw.trim().isEmpty) {
      return defaultLanguageCode;
    }

    final normalized = raw.toLowerCase();
    if (!supportedLanguageCodes.contains(normalized)) {
      return defaultLanguageCode;
    }
    return normalized;
  }

  Future<void> saveLanguageCode(String code) async {
    final normalized = code.toLowerCase();
    await _secureStorage.write(key: _keyLanguageCode, value: normalized);
  }
}

class AppLocaleController extends StateNotifier<Locale> {
  AppLocaleController(this._service)
      : super(const Locale(LocaleService.defaultLanguageCode)) {
    _load();
  }

  final LocaleService _service;

  Future<void> _load() async {
    state = Locale(await _service.loadLanguageCode());
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = code.toLowerCase();
    if (state.languageCode == normalized) return;
    state = Locale(normalized);
    await _service.saveLanguageCode(normalized);
  }
}




