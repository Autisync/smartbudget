import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeService {
  final FlutterSecureStorage _secureStorage;

  static const _keyThemeMode = 'theme_mode';

  const ThemeService(this._secureStorage);

  Future<ThemeMode> loadThemeMode() async {
    final raw = await _secureStorage.read(key: _keyThemeMode);
    return _fromString(raw);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _secureStorage.write(key: _keyThemeMode, value: _toString(mode));
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
