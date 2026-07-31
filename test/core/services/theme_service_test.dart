// Regression cover for P3.7: theme mode isn't a secret and previously lived
// in Keychain-backed secure storage — moved to SharedPreferences.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/services/theme_service.dart';

void main() {
  Future<ThemeService> freshService() async {
    SharedPreferences.setMockInitialValues({});
    return ThemeService(await SharedPreferences.getInstance());
  }

  test('defaults to system theme when nothing is stored', () async {
    final service = await freshService();
    expect(await service.loadThemeMode(), ThemeMode.system);
  });

  test('round-trips each theme mode through SharedPreferences', () async {
    final service = await freshService();
    for (final mode in ThemeMode.values) {
      await service.saveThemeMode(mode);
      expect(await service.loadThemeMode(), mode);
    }
  });
}
