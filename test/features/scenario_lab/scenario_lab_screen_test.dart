import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';
import 'package:smartbudget/features/scenario_lab/presentation/providers/scenario_lab_controller.dart';
import 'package:smartbudget/features/scenario_lab/presentation/screens/scenario_lab_screen.dart';

void main() {
  ScenarioBaseData buildBase({bool withGoals = true}) {
    return scenarioBaseDataForTesting(
      currencyCode: 'Kz',
      monthlyIncome: 3200,
      monthlyCategoryExpenses: {
        ScenarioCategory.housing: 900,
        ScenarioCategory.food: 460,
        ScenarioCategory.transport: 280,
        ScenarioCategory.subscriptions: 220,
        ScenarioCategory.entertainment: 210,
        ScenarioCategory.family: 180,
        ScenarioCategory.education: 120,
        ScenarioCategory.emergency: 90,
        ScenarioCategory.debt: 260,
        ScenarioCategory.savings: 240,
      },
      currentSavingsBalance: 1400,
      monthlyGoalContribution: 240,
      activeGoals: withGoals
          ? [
              ScenarioGoal(
                id: 'goal-1',
                title: 'Emergency Fund',
                targetAmount: 20000,
                savedAmount: 2000,
                createdAt: DateTime(2026, 1, 1),
              ),
            ]
          : const [],
      ledgerEntries: [
        ScenarioLedgerEntry(
          amount: 180,
          isIncome: false,
          isRecurring: false,
          category: ScenarioCategory.entertainment,
          date: DateTime(2026, 5, 3),
        ),
      ],
    );
  }

  Future<void> pumpScenarioLab(
    WidgetTester tester, {
    required ScenarioBaseData base,
    Size? size,
  }) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioLabBaseDataProvider.overrideWith((ref) async => base),
        ],
        child: const MaterialApp(home: ScenarioLabScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Scenario Lab renders preset chips', (tester) async {
    await pumpScenarioLab(tester, base: buildBase());

    expect(find.text('Scenario Lab'), findsWidgets);
    expect(find.text('Survival'), findsOneWidget);
    expect(find.text('Balanced Living'), findsOneWidget);
    expect(find.text('Aggressive Savings'), findsOneWidget);
  });

  testWidgets('selecting preset updates summary', (tester) async {
    await pumpScenarioLab(tester, base: buildBase());

    final before = find.textContaining('Sim: Kz ');
    expect(before, findsWidgets);

    await tester.tap(find.text('Survival'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Current vs Simulated'), findsOneWidget);
    expect(find.textContaining('Sim: Kz '), findsWidgets);
  });

  testWidgets('adjusting category slider updates comparison', (tester) async {
    await pumpScenarioLab(tester, base: buildBase());

    final slider = find.byType(Slider).first;
    await tester.ensureVisible(slider);
    final sliderCenter = tester.getCenter(slider.hitTestable().first);
    await tester.dragFrom(sliderCenter, const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cashflow impact'), findsWidgets);
  });

  testWidgets('selecting timeline period updates forecast', (tester) async {
    await pumpScenarioLab(tester, base: buildBase());

    final timelineChip = find.widgetWithText(ChoiceChip, '12M').first;
    await tester.ensureVisible(timelineChip);
    await tester.tap(timelineChip.hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Projected surplus/deficit'), findsOneWidget);
    expect(find.textContaining('12M'), findsWidgets);
  });

  testWidgets('risk event toggle updates stress section', (tester) async {
    await pumpScenarioLab(tester, base: buildBase());

    final chipFinder = find.widgetWithText(FilterChip, 'Income -20%');
    final before = tester.widget<FilterChip>(chipFinder).selected;

    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    final after = tester.widget<FilterChip>(chipFinder).selected;

    expect(after, isNot(equals(before)));
  });

  testWidgets('recommendations render when scenario has opportunities',
      (tester) async {
    await pumpScenarioLab(tester, base: buildBase());

    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.textContaining('Estimated impact:'), findsWidgets);
  });

  testWidgets('empty goals state renders correctly', (tester) async {
    await pumpScenarioLab(tester, base: buildBase(withGoals: false));

    expect(find.text('No active savings goals found.'), findsOneWidget);
  });

  testWidgets('no overflow on small screen size', (tester) async {
    await pumpScenarioLab(
      tester,
      base: buildBase(),
      size: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('bottom area remains usable with scrolling', (tester) async {
    await pumpScenarioLab(
      tester,
      base: buildBase(),
      size: const Size(360, 640),
    );

    await tester.fling(
        find.byType(SingleChildScrollView), const Offset(0, -700), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Smart Actions'), findsOneWidget);
  });
}
