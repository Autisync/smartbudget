// Feature-level cover for P4.5: several icon-only buttons across the app
// (password visibility toggles, delete/clear/close actions, notification
// bulk actions, report export) had no tooltip/Semantics label, so screen
// readers announced them as unlabeled buttons. Fixed by adding `tooltip:`
// (backed by AppLocalizations, with 7 new a11y* keys added for the actions
// that had no existing reusable string) to every identified bare IconButton.
//
// find.byTooltip proves the label actually reaches the accessibility tree —
// IconButton's `tooltip:` wraps the icon in a Tooltip, which exposes the
// message via a Semantics `tooltip` field (read aloud by screen readers for
// an otherwise-unlabeled icon button) — rather than just checking the
// widget's `tooltip` property is non-null.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/core/services/notification_service.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/data/models/tables.dart' show BudgetPeriod;
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/features/auth/presentation/screens/login_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/signup_screen.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/budgets/presentation/screens/budget_screen.dart';
import 'package:smartbudget/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/features/reports/presentation/screens/reports_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class _FakeCurrencyService extends CurrencyService {
  _FakeCurrencyService(super.prefs);

  @override
  Future<String> loadCurrencyCode() async => 'USD';

  @override
  Future<void> saveCurrencyCode(String code) async {}
}

// A single INACTIVE budget: reaches the dormant-budget-card section
// (activeBudgets empty, inactiveBudgets non-empty) without the "no budgets
// at all" early-return, and without needing budgetSpendingProvider/
// transactionListProvider data for an active item — same fixture as
// budget_screen_status_color_test.dart.
class _SingleInactiveBudgetList extends BudgetList {
  @override
  Future<List<Budget>> build() async => [
        Budget(
          id: 'b-1',
          category: 'Food',
          limitAmount: 500,
          currency: 'USD',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 3, 1),
          isActive: false,
        ),
      ];
}

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
  group('auth screens: password visibility toggles', () {
    testWidgets('SignupScreen exposes show/hide password tooltips',
        (tester) async {
      await tester.pumpWidget(_app(const SignupScreen(), []));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      // Both fields start obscured -> both show "Show password".
      expect(find.byTooltip('Show password'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();

      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('LoginScreen exposes the show/hide password tooltip',
        (tester) async {
      await tester.pumpWidget(_app(const LoginScreen(), []));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Show password'), findsOneWidget);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets(
        'ResetPasswordScreen exposes show/hide password tooltips for both fields',
        (tester) async {
      await tester.pumpWidget(_app(
        const ResetPasswordScreen(token: 'a-token'),
        [],
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Show password'), findsNWidgets(2));
    });
  });

  group('page_header actions', () {
    testWidgets('settings and notifications actions expose tooltips',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(
                actions: buildPageHeaderActions(
                  context: context,
                  isScrolled: false,
                  useProviderNotificationBell: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);
    });
  });

  group('notification bell button', () {
    testWidgets('exposes a Notifications tooltip', (tester) async {
      await tester.pumpWidget(_app(
        Scaffold(
          appBar: AppBar(
            actions: [NotificationBellButton(onPressed: () {})],
          ),
        ),
        [
          notificationInboxProvider
              .overrideWith((ref) => Stream.value(<AppNotificationEntry>[])),
        ],
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Notifications'), findsOneWidget);
    });
  });

  group('NotificationsScreen bulk actions', () {
    testWidgets('mark-all-read and clear-inbox actions expose tooltips',
        (tester) async {
      final prefs = await _freshPrefs();
      await tester.pumpWidget(_app(const NotificationsScreen(), [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationInboxProvider
            .overrideWith((ref) => Stream.value(<AppNotificationEntry>[])),
      ]));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Mark all as read'), findsOneWidget);
      expect(find.byTooltip('Clear all notifications'), findsOneWidget);
    });
  });

  group('ReportsScreen export action', () {
    testWidgets('export action exposes a tooltip', (tester) async {
      await tester.pumpWidget(_app(const ReportsScreen(), []));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Export report'), findsOneWidget);
    });
  });

  group('BudgetScreen dormant card delete action', () {
    testWidgets('delete action on a dormant budget exposes a tooltip',
        (tester) async {
      // Tall viewport: the dormant-card section sits below the (empty, with
      // this fixture) active-budgets section inside a CustomScrollView, so
      // the default test viewport doesn't build it (SliverList
      // virtualization).
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await _freshPrefs();
      await tester.pumpWidget(_app(const BudgetScreen(), [
        sharedPreferencesProvider.overrideWithValue(prefs),
        budgetListProvider.overrideWith(_SingleInactiveBudgetList.new),
        budgetAlertsProvider.overrideWith((ref) async => []),
      ]));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Delete'), findsOneWidget);
    });
  });

  group('AddTransactionScreen close action', () {
    testWidgets('close action exposes a tooltip', (tester) async {
      final prefs = await _freshPrefs();
      await tester.pumpWidget(_app(const AddTransactionScreen(), [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Close'), findsOneWidget);
    });
  });

  group('AddSubscriptionScreen close action', () {
    testWidgets('close action exposes a tooltip', (tester) async {
      final prefs = await _freshPrefs();
      await tester.pumpWidget(_app(const AddSubscriptionScreen(), [
        sharedPreferencesProvider
            .overrideWithValue(prefs),
        currencyServiceProvider.overrideWith((_) => _FakeCurrencyService(prefs)),
      ]));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Close'), findsOneWidget);
    });
  });
}
