// Regression + feature cover for P4.4: fixed-width financial displays (the
// dashboard's hero balance number in particular) weren't protected against
// extreme OS accessibility text-scale settings, risking a clipped/illegible
// balance at TextScaler.linear(2.0)+ despite the existing ellipsis
// fallback. main.dart's MaterialApp.router now wraps every screen in this
// exact widget via its `builder:`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/widgets/text_scale_clamp.dart';

void main() {
  testWidgets('an extreme OS text scale (2.0x) is clamped down to the configured maximum',
      (tester) async {
    late double observedScale;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          builder: (context, child) => TextScaleClamp(child: child!),
          home: Builder(
            builder: (context) {
              observedScale = MediaQuery.textScalerOf(context).scale(1.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(observedScale, 1.6);
  });

  testWidgets('a normal OS text scale (1.0x) passes through unclamped',
      (tester) async {
    late double observedScale;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
        child: MaterialApp(
          builder: (context, child) => TextScaleClamp(child: child!),
          home: Builder(
            builder: (context) {
              observedScale = MediaQuery.textScalerOf(context).scale(1.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(observedScale, 1.0);
  });

  testWidgets('a very small OS text scale (0.5x) is clamped up to the configured minimum',
      (tester) async {
    late double observedScale;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
        child: MaterialApp(
          builder: (context, child) => TextScaleClamp(child: child!),
          home: Builder(
            builder: (context) {
              observedScale = MediaQuery.textScalerOf(context).scale(1.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(observedScale, 0.85);
  });

  testWidgets(
    'the hero balance style (fontSize 42, single line, ellipsis) does not overflow '
    'under an extreme OS text scale once clamped',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
            size: Size(390, 844), // a typical phone width
          ),
          child: MaterialApp(
            builder: (context, child) => TextScaleClamp(child: child!),
            home: const Scaffold(
              body: SizedBox(
                width: 342, // hero card width minus its padding
                child: Text(
                  r'$1,234,567.89',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(r'$1,234,567.89'), findsOneWidget);
    },
  );
}
