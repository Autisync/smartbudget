// Feature-level cover for P3.2: edit_subscription_screen.dart's error state
// used to interpolate the raw exception straight into the user-facing
// message via l10n's {error} placeholder. Forces the subscription-by-id
// lookup into an error state and asserts only AppErrorMapper's safe message
// reaches the screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/edit_subscription_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'shows a safe mapped message, never the raw exception, when the subscription lookup fails',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionProvider('sub-1').overrideWith(
              (ref) async => throw StateError(
                "SELECT * FROM subscriptions WHERE id = 'sub-1' failed: relation missing",
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EditSubscriptionScreen(subscriptionId: 'sub-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('relation missing'), findsNothing);
      expect(find.textContaining('SELECT'), findsNothing);
      expect(
        find.text('Error loading subscription: ${AppErrorMapper.defaultFallbackMessage}'),
        findsOneWidget,
      );
    },
  );
}
