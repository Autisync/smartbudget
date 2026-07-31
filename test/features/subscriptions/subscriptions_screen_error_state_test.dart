// Feature-level cover for P3.2: subscriptions_screen.dart's error state
// used to interpolate the raw exception (`error.toString()`) straight into
// the user-facing message. Forces the subscription list into an error state
// and asserts the rendered text is AppErrorMapper's safe, mapped message —
// never the raw exception text.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class _FakeCurrencyService extends CurrencyService {
  _FakeCurrencyService(super.prefs);

  @override
  Future<String> loadCurrencyCode() async => 'USD';

  @override
  Future<void> saveCurrencyCode(String code) async {}
}

class _ThrowingSubscriptionList extends SubscriptionList {
  @override
  Future<List<Subscription>> build() async {
    throw StateError(
      'connection refused to db.internal.example:5432 while loading subscriptions',
    );
  }
}

void main() {
  testWidgets(
    'shows a safe mapped message, never the raw exception, when subscriptions fail to load',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currencyServiceProvider.overrideWith((_) => _FakeCurrencyService(prefs)),
            subscriptionListProvider.overrideWith(_ThrowingSubscriptionList.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SubscriptionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('connection refused'), findsNothing);
      expect(find.textContaining('db.internal.example'), findsNothing);
      expect(
        find.text('Error loading subscription: ${AppErrorMapper.defaultFallbackMessage}'),
        findsOneWidget,
      );
    },
  );
}
