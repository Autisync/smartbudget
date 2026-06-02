import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/components/forms/form_components.dart';

void main() {
  testWidgets('ModernInput renders label and accepts typing', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: ModernInput(
              controller: controller,
              label: 'Name',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Spotify');
    expect(controller.text, 'Spotify');
  });

  testWidgets('ModernSelect updates selection', (tester) async {
    String selected = 'Food';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                child: ModernSelect<String>(
                  value: selected,
                  label: 'Category',
                  items: const [
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selected = value);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bills').last);
    await tester.pumpAndSettle();

    expect(selected, 'Bills');
  });

  testWidgets('ModernSelect searchable mode picks option from sheet',
      (tester) async {
    String selected = 'Streaming';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                child: ModernSelect<String>(
                  value: selected,
                  label: 'Category',
                  searchable: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Streaming',
                      child: Text('Streaming'),
                    ),
                    DropdownMenuItem(
                      value: 'Productivity',
                      child: Text('Productivity'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selected = value);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Streaming'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Productivity').last);
    await tester.pumpAndSettle();

    expect(selected, 'Productivity');
  });
}
