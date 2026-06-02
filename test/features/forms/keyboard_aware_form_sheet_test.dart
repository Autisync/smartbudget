import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/components/sheets/keyboard_aware_form_sheet.dart';

Widget _buildHarness({
  required Widget child,
  required MediaQueryData mediaQuery,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: mediaQuery,
      child: Scaffold(body: child),
    ),
  );
}

Widget _buildSheetUnderTest() {
  return const KeyboardAwareFormSheet(
    maxHeightFactor: 0.9,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 12),
        TextField(key: Key('nameField')),
        SizedBox(height: 140),
        TextField(key: Key('amountField')),
        SizedBox(height: 120),
        TextField(key: Key('notesField')),
      ],
    ),
    actions: FilledButton(
      onPressed: null,
      child: Text('Submit'),
    ),
  );
}

void main() {
  group('KeyboardAwareFormSheet', () {
    testWidgets('keeps focused field visible when keyboard is open',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mediaQuery = const MediaQueryData(
        size: Size(390, 844),
        viewInsets: EdgeInsets.only(bottom: 320),
      );

      await tester.pumpWidget(
        _buildHarness(
          mediaQuery: mediaQuery,
          child: _buildSheetUnderTest(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('amountField')));
      await tester.pumpAndSettle();

      final focusedRect = tester.getRect(find.byKey(const Key('amountField')));
      const keyboardTop = 844.0 - 320.0;

      expect(focusedRect.bottom <= keyboardTop, isTrue);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('tapping outside input hides keyboard focus', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mediaQuery = const MediaQueryData(
        size: Size(390, 844),
        viewInsets: EdgeInsets.only(bottom: 280),
      );

      await tester.pumpWidget(
        _buildHarness(
          mediaQuery: mediaQuery,
          child: _buildSheetUnderTest(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('amountField')));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, isNotNull);

      await tester.tapAt(const Offset(16, 16));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isFalse);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders action inline under last form field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mediaQuery = const MediaQueryData(
        size: Size(390, 844),
        viewInsets: EdgeInsets.only(bottom: 240),
      );

      await tester.pumpWidget(
        _buildHarness(
          mediaQuery: mediaQuery,
          child: _buildSheetUnderTest(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notesField')));
      await tester.pumpAndSettle();

      final notesRect = tester.getRect(find.byKey(const Key('notesField')));
      final submitRect =
          tester.getRect(find.widgetWithText(FilledButton, 'Submit'));

      expect(submitRect.top > notesRect.bottom, isTrue);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
