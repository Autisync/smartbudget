import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

// Pump one frame + a full animation cycle.
// pumpAndSettle cannot be used: BackdropFilter inside _FrostedSurface keeps
// requesting frames indefinitely in the test environment.
const _animDuration = Duration(milliseconds: 300);
Future<void> _pumpAnim(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_animDuration);
}

Future<void> _pumpShell(WidgetTester tester) async {
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
}
