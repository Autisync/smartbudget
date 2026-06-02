import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets('AddTransactionScreen renders correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: AddTransactionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the screen renders basic elements
    expect(find.text('Add Transaction'), findsWidgets);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.byType(FilledButton), findsWidgets);
  });
}
