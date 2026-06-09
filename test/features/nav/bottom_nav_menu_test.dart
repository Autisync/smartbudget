import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the + button opens the quick-add menu with the four targets',
      (tester) async {
    await _pumpShell(tester);

    // No add options visible until the + button is tapped.
    expect(find.text('Transaction'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Transaction'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Savings goal'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
  });

  testWidgets('tapping the scrim dismisses the quick-add menu', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Transaction'), findsOneWidget);

    // Tap near the top of the screen (the scrim area) to dismiss.
    await tester.tapAt(const Offset(20, 40));
    await tester.pumpAndSettle();
    expect(find.text('Transaction'), findsNothing);
  });
}
