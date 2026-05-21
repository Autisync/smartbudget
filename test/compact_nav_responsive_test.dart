import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class _ViewportScenario {
  const _ViewportScenario(this.name, this.size, this.textScale);

  final String name;
  final Size size;
  final double textScale;
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );

  await tester.pumpAndSettle();
  addTearDown(router.dispose);
}

List<Object> _drainExceptions(WidgetTester tester) {
  final exceptions = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    exceptions.add(error!);
  }
  return exceptions;
}

void main() {
  testWidgets(
    'Compact nav renders without overflow across viewports and text scales',
    (WidgetTester tester) async {
      const scenarios = <_ViewportScenario>[
        _ViewportScenario('small-phone-normal-text', Size(320, 568), 1.0),
        _ViewportScenario('small-phone-large-text', Size(320, 568), 1.4),
        _ViewportScenario('mid-phone-large-text', Size(360, 780), 1.6),
        _ViewportScenario('modern-phone-large-text', Size(393, 852), 1.5),
      ];

      for (final scenario in scenarios) {
        await _pumpShell(
          tester,
          size: scenario.size,
          textScale: scenario.textScale,
        );

        expect(
          find.byType(NavigationRail),
          findsNothing,
          reason: 'Expected compact nav for ${scenario.name}',
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final exceptions = _drainExceptions(tester);
        expect(
          exceptions,
          isEmpty,
          reason:
              'Unexpected exceptions for ${scenario.name} (${scenario.size}, textScale=${scenario.textScale}): $exceptions',
        );
      }
    },
  );
}
