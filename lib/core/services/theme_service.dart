import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P3.7: theme mode isn't a secret — moved off Keychain-backed secure
/// storage onto SharedPreferences, same as the other non-sensitive UI
/// preference services (locale, currency, rollover policy, notification
/// preferences).
class ThemeService {
  final SharedPreferences _prefs;

  static const _keyThemeMode = 'theme_mode';

  const ThemeService(this._prefs);

  Future<ThemeMode> loadThemeMode() async {
    final raw = _prefs.getString(_keyThemeMode);
    return _fromString(raw);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, _toString(mode));
  }

  ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

class ThemeModeController extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeModeController(this._themeService) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    state = await _themeService.loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _themeService.saveThemeMode(mode);
  }
}




