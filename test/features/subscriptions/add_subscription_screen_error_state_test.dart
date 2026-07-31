// Feature-level cover for P3.2: add_subscription_screen.dart's save-failure
// toast used to interpolate the raw exception straight into the user-facing
// message via l10n's {error} placeholder. Forces the save operation to throw
// and asserts only AppErrorMapper's safe message reaches the toast.
//
// SubscriptionList.addSubscription/updateSubscription normally swallow
// repository failures into AsyncValue state (via AsyncValue.guard) rather
// than rethrowing to the caller, so _save()'s catch block is a defensive
// path for the unusual case where the notifier call itself throws. This
// test overrides the notifier method to throw directly to exercise that
// exact catch block/message-mapping logic.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class _ThrowingOnSaveSubscriptionList extends SubscriptionList {
  @override
  Future<List<Subscription>> build() async => const [];

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    throw StateError('Postgres write failed: connection reset by peer');
  }
}

void main() {
  testWidgets(
    'shows a safe mapped message, never the raw exception, when saving fails',
    (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime(2026, 1, 1);
      final existing = Subscription(
        id: 'sub-1',
        name: 'Existing Sub',
        amount: 9.99,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        startDate: now,
        nextBillingDate: now.add(const Duration(days: 30)),
        category: 'Streaming',
        importance: SubscriptionImportance.medium,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionListProvider.overrideWith(_ThrowingOnSaveSubscriptionList.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SubscriptionFormSheet(
                mode: SubscriptionFormMode.update,
                initialData: existing,
                asModal: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'), warnIfMissed: false);
      await tester.pump();

      expect(find.textContaining('Postgres'), findsNothing);
      expect(find.textContaining('connection reset'), findsNothing);
      expect(
        find.textContaining(
          'Error saving subscription: ${AppErrorMapper.defaultFallbackMessage}',
        ),
        findsOneWidget,
      );

      // Flush the toast's own auto-dismiss timer so none is left pending
      // when the widget tree is torn down at the end of the test.
      await tester.pump(const Duration(seconds: 8));
    },
  );
}
