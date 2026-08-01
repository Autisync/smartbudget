// Feature-level cover for a re-audit finding: dashboard_screen.dart's
// financial-health card used its own bespoke _ErrorCard (a plain
// errorContainer box with no Retry) instead of the shared AppErrorState
// widget used by every other error state in this same screen (burn rate,
// recent transactions) — the exact inconsistency the P4.1 fix was supposed
// to eliminate, just missed on this one card. Forces financialHealthProvider
// into an error state and asserts AppErrorState renders with a working
// Retry that re-invalidates the provider.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

Future<SharedPreferences> _freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets(
      'the financial-health card shows AppErrorState (not the old bespoke card) and Retry re-invalidates the provider',
      (tester) async {
    // A wider-than-phone viewport: at typical phone widths the pre-existing
    // "Recent Transactions"/"See All" header row overflows regardless of
    // this fix (unrelated to the health card under test here), so this test
    // sidesteps that rather than asserting on it.
    tester.view.physicalSize = const Size(600, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await _freshPrefs();
    var callCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          financialHealthProvider.overrideWith((ref) {
            callCount++;
            throw StateError('financial health computation failed');
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AppErrorState), findsWidgets);
    expect(find.text('Unable to load financial health'), findsOneWidget);
    final callsBeforeRetry = callCount;

    await tester.tap(find.text('Retry').first, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));

    expect(callCount, greaterThan(callsBeforeRetry));
  });
}
