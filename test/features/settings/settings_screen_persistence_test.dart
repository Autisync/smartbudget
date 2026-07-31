// Feature-level cover for P3.7: theme, locale, currency, and notification
// preferences moved from Keychain-backed secure storage to SharedPreferences.
// Drives the real settings UI to change each one, then simulates an app
// restart — a brand new ProviderContainer wired to the SAME underlying
// SharedPreferences instance, exactly like main.dart's _boot() building a
// fresh container against whatever SharedPreferences.getInstance() returns
// on the next cold start — and confirms every change survived.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_migration_service.dart';
import 'package:smartbudget/core/services/notification_preferences_service.dart';
import 'package:smartbudget/features/settings/presentation/screens/settings_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

// _handleCurrencyChange runs a real data migration before persisting the new
// currency code, which needs a live exchange-rate fetch — unavailable and
// out of scope in a widget test. No-op it so the currency change (the thing
// this test actually verifies) can complete.
class _NoopCurrencyMigrationService implements CurrencyMigrationService {
  @override
  Future<void> migrateAllData({
    required String fromCurrency,
    required String toCurrency,
  }) async {}
}

void main() {
  testWidgets(
    'theme/locale/currency/notification changes survive a simulated app restart',
    (tester) async {
      tester.view.physicalSize = const Size(400, 3400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currencyMigrationServiceProvider
                .overrideWithValue(_NoopCurrencyMigrationService()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Theme: Appearance -> Dark.
      await tester.tap(find.text('Appearance'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Language: Language -> Deutsch.
      await tester.tap(find.text('Language'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutsch'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Currency: Currency -> EUR. _handleCurrencyChange shows loading/success
      // toasts with their own auto-dismiss timers — pump a fixed duration
      // instead of pumpAndSettle, same as settings_screen_error_state_test.dart.
      await tester.tap(find.text('Currency'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('EUR'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      // Notifications master toggle starts enabled by default, so tapping it
      // takes the disable path (no OS permission prompts involved).
      await tester.tap(find.text('Notifications'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      // "Restart": a brand new container over the same underlying storage.
      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);

      expect(
        await restarted.read(themeServiceProvider).loadThemeMode(),
        ThemeMode.dark,
      );
      expect(
        await restarted.read(localeServiceProvider).loadLanguageCode(),
        'de',
      );
      expect(
        await restarted.read(currencyServiceProvider).loadCurrencyCode(),
        'EUR',
      );
      final notificationPrefs =
          await restarted.read(notificationPreferencesServiceProvider).loadPreferences();
      expect(notificationPrefs.enabled, isFalse);

      // Flush the toast auto-dismiss timers so none is left pending at teardown.
      await tester.pump(const Duration(seconds: 8));
    },
  );

  testWidgets(
    'a normal repeat launch (no restart) keeps reading the same persisted values',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(themeServiceProvider).saveThemeMode(ThemeMode.dark);
      await container.read(currencyServiceProvider).saveCurrencyCode('GBP');
      await container.read(notificationPreferencesServiceProvider).savePreferences(
            NotificationPreferences.defaults.copyWith(enabled: false),
          );

      expect(
        await container.read(themeServiceProvider).loadThemeMode(),
        ThemeMode.dark,
      );
      expect(
        await container.read(currencyServiceProvider).loadCurrencyCode(),
        'GBP',
      );
      expect(
        (await container.read(notificationPreferencesServiceProvider).loadPreferences())
            .enabled,
        isFalse,
      );
    },
  );
}
