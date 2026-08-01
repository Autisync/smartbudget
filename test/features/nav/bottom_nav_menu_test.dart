import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/core/theme/app_icons.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

// Pump one frame + a full animation cycle.
// pumpAndSettle cannot be used: BackdropFilter inside _FrostedSurface keeps
// requesting frames indefinitely in the test environment.
const _animDuration = Duration(milliseconds: 300);
Future<void> _pumpAnim(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_animDuration);
}

Future<void> _pumpShell(WidgetTester tester, {Locale? locale}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox.expand(
              child: ColoredBox(color: Colors.white),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await _pumpAnim(tester);
}

// Find the detached "+" action button by its icon.
Finder get _addButton => find.byIcon(Icons.add_rounded, skipOffstage: false);

// Find the "More" tab by its icon.
Finder get _moreButton => find.byIcon(AppIcons.moreGrid, skipOffstage: false);

void main() {
  testWidgets('the + button opens the quick-add menu with the four targets',
      (tester) async {
    await _pumpShell(tester);

    // No add options visible until the + button is tapped.
    expect(find.text('Transaction', skipOffstage: false), findsNothing);

    await tester.tap(_addButton.first, warnIfMissed: false);
    await _pumpAnim(tester);

    expect(find.text('Transaction', skipOffstage: false), findsOneWidget);
    expect(find.text('Subscription', skipOffstage: false), findsOneWidget);
    // "Savings goal" was shortened to "Savings"
    expect(find.text('Savings', skipOffstage: false), findsOneWidget);
    expect(find.text('Budget', skipOffstage: false), findsOneWidget);
  });

  testWidgets('tapping the scrim dismisses the quick-add menu', (tester) async {
    await _pumpShell(tester);

    // Open the panel.
    await tester.tap(_addButton.first, warnIfMissed: false);
    await _pumpAnim(tester);
    expect(find.text('Transaction', skipOffstage: false), findsOneWidget);

    // Tap near the top of the screen (inside the scrim, outside the panel).
    await tester.tapAt(const Offset(20, 40));
    // Pump past both the AnimatedSwitcher exit animation (240 ms) and the
    // AnimatedOpacity scrim fade (240 ms) — 500 ms is a safe margin.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // After the exit animation the NavActionPanel is fully removed from the tree.
    expect(find.text('Transaction'), findsNothing);
  });

  testWidgets('the More panel lists every secondary destination', (tester) async {
    await _pumpShell(tester);

    await tester.tap(_moreButton.first, warnIfMissed: false);
    await _pumpAnim(tester);

    // Previously hardcoded English literals — now routed through
    // AppLocalizations, but the default locale's rendered text is unchanged.
    expect(find.text('Accounts', skipOffstage: false), findsOneWidget);
    expect(find.text('Balance Sheet', skipOffstage: false), findsOneWidget);
    expect(find.text('Reports', skipOffstage: false), findsOneWidget);
    expect(find.text('Exchange Rates', skipOffstage: false), findsOneWidget);
    expect(find.text('AI Insights', skipOffstage: false), findsOneWidget);
    expect(find.text('Scenario Lab', skipOffstage: false), findsOneWidget);
    expect(find.text('Dark mode', skipOffstage: false), findsOneWidget);
    expect(find.text('Help', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'quick-add and More panels render in German with no missing-key exceptions',
      (tester) async {
    await _pumpShell(tester, locale: const Locale('de'));

    await tester.tap(_addButton.first, warnIfMissed: false);
    await _pumpAnim(tester);
    expect(tester.takeException(), isNull);
    // Quick-add labels reuse existing, already-translated keys (navSavings).
    expect(find.text('Sparen', skipOffstage: false), findsOneWidget);

    // Dismiss via the scrim (the action button now shows a close icon while
    // the panel is open, so it can't be re-found via _addButton).
    await tester.tapAt(const Offset(20, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(_moreButton.first, warnIfMissed: false);
    await _pumpAnim(tester);
    expect(tester.takeException(), isNull);
    // Settings has a real German translation — anchors that the More panel's
    // localization is genuinely active, not just present and inert.
    expect(find.text('Einstellungen', skipOffstage: false), findsOneWidget);
  });
}
