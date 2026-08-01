// Feature-level cover for a re-audit finding: onboarding_screen.dart's Skip
// button hardcoded 'Skip' one line away from the already-localized
// l10n.onboardingGetStarted/onboardingContinue buttons on the same screen —
// notable since this is the very first screen a new user sees. The
// l10n.onboardingSkip key already existed (and already had a real German
// translation) but was never wired up to the _TopBar widget that renders it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets('the Skip button renders in German with no missing-key exceptions',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Überspringen'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}
