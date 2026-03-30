import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/notification_service.dart';
import 'package:smartbudget/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets('notifications appear in inbox list', (tester) async {
    final now = DateTime(2026, 3, 29, 9, 30);
    final items = <AppNotificationEntry>[
      AppNotificationEntry(
        id: 1,
        title: 'Budget Alert',
        body: 'Food spending reached 90%.',
        payload: 'budget_food',
        category: AppNotificationCategory.budget,
        createdAt: now,
      ),
      AppNotificationEntry(
        id: 2,
        title: 'Savings Nudge',
        body: 'You can save an extra 50 this week.',
        payload: 'goal_trip',
        category: AppNotificationCategory.savings,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxProvider.overrideWith(
            (ref) => Stream<List<AppNotificationEntry>>.value(items),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: NotificationsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Budget Alert'), findsOneWidget);
    expect(find.text('Savings Nudge'), findsOneWidget);
    expect(find.text('Food spending reached 90%.'), findsOneWidget);
  });

  testWidgets('bell shows number of notifications', (tester) async {
    final now = DateTime(2026, 3, 29, 11, 0);
    final items = List<AppNotificationEntry>.generate(
      3,
      (index) => AppNotificationEntry(
        id: index + 1,
        title: 'Notification $index',
        body: 'Body $index',
        payload: 'payload_$index',
        category: AppNotificationCategory.health,
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxProvider.overrideWith(
            (ref) => Stream<List<AppNotificationEntry>>.value(items),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            appBar: AppBar(
              actions: [
                NotificationBellButton(onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notification-badge')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
