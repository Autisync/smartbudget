import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/features/auth/presentation/screens/signup_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets('signup empty submit shows inline validation and stays on screen',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SignupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Sign Up'), findsOneWidget);
    expect(
      find.text('Complete the required fields and accept the legal terms.'),
      findsOneWidget,
    );
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });
}
