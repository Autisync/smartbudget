// Feature-level cover for P4.1: notifications_screen.dart previously
// rendered the raw exception interpolated into 'Error loading
// notifications: {error}' — no retry, no visual consistency, and a
// raw-exception leak closed here as a side effect of moving to
// AppErrorState. Forces notificationInboxProvider into an error state and
// asserts the shared AppErrorState widget renders with a working Retry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'shows AppErrorState (not the raw exception) when notifications fail to load, and Retry re-triggers the provider',
    (tester) async {
      var buildCount = 0;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationInboxProvider.overrideWith((ref) {
              buildCount++;
              return Stream.error(StateError('AMQP channel closed unexpectedly'));
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(buildCount, 1);
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Unable to load notifications'), findsOneWidget);
      expect(find.textContaining('AMQP'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(seconds: 1));

      expect(buildCount, 2);
    },
  );
}
