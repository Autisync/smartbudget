import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P3.7: the selected language isn't a secret — moved off Keychain-backed
/// secure storage onto SharedPreferences.
class LocaleService {
  const LocaleService(this._prefs);

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

  final SharedPreferences _prefs;

  Future<String> loadLanguageCode() async {
    final raw = _prefs.getString(_keyLanguageCode);
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
    await _prefs.setString(_keyLanguageCode, normalized);
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




