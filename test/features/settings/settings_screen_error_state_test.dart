// Feature-level cover for P3.2: settings_screen.dart's currency-change
// failure toast used to interpolate the raw exception straight into the
// user-facing message. Forces the currency migration to throw and asserts
// only AppErrorMapper's safe message reaches the toast.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_migration_service.dart';
import 'package:smartbudget/features/settings/presentation/screens/settings_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class _ThrowingCurrencyMigrationService extends CurrencyMigrationService {
  _ThrowingCurrencyMigrationService(super.db, super.exchangeRateService, super.currencyService);

  @override
  Future<void> migrateAllData({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    throw StateError('migration failed: disk write error at /var/lib/postgres/data/base');
  }
}

void main() {
  testWidgets(
    'shows a safe mapped message, never the raw exception, when currency migration fails',
    (tester) async {
      tester.view.physicalSize = const Size(400, 3400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currencyMigrationServiceProvider.overrideWith(
              (ref) => _ThrowingCurrencyMigrationService(
                ref.watch(databaseProvider),
                ref.watch(exchangeRateServiceProvider),
                ref.watch(currencyServiceProvider),
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Currency'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('EUR'), warnIfMissed: false);
      await tester.pump();

      expect(find.textContaining('disk write error'), findsNothing);
      expect(find.textContaining('/var/lib/postgres'), findsNothing);
      expect(
        find.textContaining(
          'Unable to convert currency: ${AppErrorMapper.defaultFallbackMessage}',
        ),
        findsOneWidget,
      );

      // Flush the toast's own auto-dismiss timer before teardown.
      await tester.pump(const Duration(seconds: 8));
    },
  );
}
