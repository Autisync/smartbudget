// Feature-level cover for P4.1: accounts_screen.dart previously rendered a
// bare Center(Text(...)) on load failure — no retry, no visual consistency
// with the rest of the app's error states. Forces the accounts stream into
// an error and asserts the shared AppErrorState widget renders (Lottie +
// title + message + working Retry), matching dashboard_screen.dart's
// pattern.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'shows AppErrorState (not raw text) when accounts fail to load, and Retry re-triggers the provider',
    (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) {
              buildCount++;
              return Stream.error(StateError('accounts db unreachable'));
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AccountsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(buildCount, 1);
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Unable to load accounts'), findsOneWidget);
      expect(find.text("Couldn't load accounts."), findsOneWidget);
      expect(find.textContaining('accounts db unreachable'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(seconds: 1));

      expect(buildCount, 2);
    },
  );
}
