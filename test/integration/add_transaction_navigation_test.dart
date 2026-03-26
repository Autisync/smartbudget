import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';

void main() {
  testWidgets('AddTransactionScreen renders correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddTransactionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the screen renders basic elements
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
