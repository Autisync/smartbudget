import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smartbudget/components/shared/slidable_edge_clip.dart';

void main() {
  test('SwipeableCard uses a square left edge for start panes', () {
    final borderRadius = SwipeableCard.borderRadiusForPaneType(
      ActionPaneType.start,
      24,
    );

    expect(
      borderRadius,
      const BorderRadius.horizontal(
        left: Radius.zero,
        right: Radius.circular(24),
      ),
    );
  });

  test('SwipeableCard uses a square right edge for end panes', () {
    final borderRadius = SwipeableCard.borderRadiusForPaneType(
      ActionPaneType.end,
      24,
    );

    expect(
      borderRadius,
      const BorderRadius.horizontal(
        left: Radius.circular(24),
        right: Radius.zero,
      ),
    );
  });

  testWidgets('SwipeableCard clips Dismissible startToEnd swipe correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwipeableCard(
            radius: 24,
            swipeDirection: DismissDirection.startToEnd,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    );

    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));

    expect(
      clip.borderRadius,
      const BorderRadius.horizontal(
        left: Radius.zero,
        right: Radius.circular(24),
      ),
    );
  });

  testWidgets('SwipeableCard clips Dismissible endToStart swipe correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SwipeableCard(
            radius: 24,
            swipeDirection: DismissDirection.endToStart,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    );

    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));

    expect(
      clip.borderRadius,
      const BorderRadius.horizontal(
        left: Radius.circular(24),
        right: Radius.zero,
      ),
    );
  });
}
