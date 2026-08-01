// Feature-level cover for a re-audit finding: P3.2 routed most raw-exception
// display sites through AppErrorMapper, but a fresh sweep found 3 stray call
// sites outside its originally-scoped file list still interpolating
// err.toString() directly into user-facing l10n strings — security_screen.dart
// (x2) and financial_health_screen.dart (x1). Forces each provider into an
// error state and asserts only AppErrorMapper's safe message reaches the UI,
// never the raw exception text.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' show SecuritySetting;
import 'package:smartbudget/features/auth/presentation/providers/security_provider.dart';
import 'package:smartbudget/features/auth/presentation/screens/security_screen.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/screens/financial_health_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

Future<SharedPreferences> _freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Widget _app(Widget home, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  group('SecurityScreen', () {
    testWidgets(
        'shows a safe mapped message, never the raw exception, when auth logs fail to load',
        (tester) async {
      final prefs = await _freshPrefs();
      await tester.pumpWidget(_app(const SecurityScreen(), [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Settings must resolve to real data (not error/loading) to reach the
        // body where the auth-logs error branch actually renders.
        securitySettingProvider.overrideWith(
          (ref) async => SecuritySetting(
            id: 'default',
            sessionTimeout: 30,
            biometricEnabled: false,
            pinEnabled: false,
            maxFailedAttempts: 5,
            lockoutDuration: 15,
            lastSecurityUpdate: DateTime(2026, 1, 1),
          ),
        ),
        authLogsProvider.overrideWith(
          (ref) async => throw StateError(
            'db locked: /var/lib/smartspend/security.db is busy',
          ),
        ),
      ]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('db locked'), findsNothing);
      expect(find.textContaining('/var/lib/smartspend'), findsNothing);
      expect(
        find.textContaining(AppErrorMapper.defaultFallbackMessage),
        findsWidgets,
      );
    });

    testWidgets(
        'shows a safe mapped message, never the raw exception, when security settings fail to load',
        (tester) async {
      final prefs = await _freshPrefs();
      await tester.pumpWidget(_app(const SecurityScreen(), [
        sharedPreferencesProvider.overrideWithValue(prefs),
        securitySettingProvider.overrideWith(
          (ref) async => throw StateError(
            'keychain access denied: com.smaartspend.app entitlement missing',
          ),
        ),
      ]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('keychain access denied'), findsNothing);
      expect(find.textContaining('entitlement'), findsNothing);
      expect(
        find.textContaining(AppErrorMapper.defaultFallbackMessage),
        findsWidgets,
      );
    });
  });

  group('FinancialHealthScreen', () {
    testWidgets(
        'shows a safe mapped message, never the raw exception, when financial health fails to load',
        (tester) async {
      final prefs = await _freshPrefs();
      await tester.pumpWidget(_app(const FinancialHealthScreen(), [
        sharedPreferencesProvider.overrideWithValue(prefs),
        financialHealthProvider.overrideWith(
          (ref) async => throw StateError(
            'query failed: relation "budgets" does not exist at /data/user/0/db',
          ),
        ),
      ]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('relation "budgets"'), findsNothing);
      expect(find.textContaining('/data/user/0'), findsNothing);
      expect(
        find.textContaining(AppErrorMapper.defaultFallbackMessage),
        findsWidgets,
      );
    });
  });
}
