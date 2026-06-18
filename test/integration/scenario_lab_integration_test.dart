import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';
import 'package:smartbudget/features/scenario_lab/presentation/providers/scenario_lab_controller.dart';
import 'package:smartbudget/features/scenario_lab/presentation/screens/scenario_lab_screen.dart';

void main() {
  testWidgets(
    'open Scenario Lab, apply Survival, adjust subscriptions, enable income loss, verify forecast and smart action nav',
    (tester) async {
      final base = scenarioBaseDataForTesting(
        currencyCode: 'Kz',
        monthlyIncome: 2800,
        monthlyCategoryExpenses: {
          ScenarioCategory.housing: 900,
          ScenarioCategory.food: 430,
          ScenarioCategory.transport: 250,
          ScenarioCategory.subscriptions: 240,
          ScenarioCategory.entertainment: 210,
          ScenarioCategory.family: 150,
          ScenarioCategory.education: 100,
          ScenarioCategory.emergency: 80,
          ScenarioCategory.debt: 350,
          ScenarioCategory.savings: 140,
        },
        currentSavingsBalance: 900,
        monthlyGoalContribution: 140,
        activeGoals: [
          ScenarioGoal(
            id: 'goal',
            title: 'Family Buffer',
            targetAmount: 10000,
            savedAmount: 1000,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/scenario-lab',
        routes: [
          GoRoute(
            path: '/scenario-lab',
            builder: (context, state) => const ScenarioLabScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Subscriptions Page'))),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Budgets Page'))),
          ),
          GoRoute(
            path: '/balance-sheet',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Balance Sheet Page'))),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Transactions Page'))),
          ),
          GoRoute(
            path: '/savings',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Savings Page'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scenarioLabBaseDataProvider.overrideWith((ref) async => base),
          ],
          child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scenario Lab'), findsWidgets);

      await tester.tap(find.text('Survival'));
      await tester.pumpAndSettle();

      final subRow = find.text('Subscriptions').first;
      await tester.ensureVisible(subRow);
      await tester.pumpAndSettle();

      final slider = find.byType(Slider).at(3);
      await tester.drag(slider, const Offset(-80, 0));
      await tester.pumpAndSettle();

      final incomeRiskChip = find.widgetWithText(FilterChip, 'Income -20%');
      await tester.ensureVisible(incomeRiskChip);
      await tester.tap(incomeRiskChip.hitTestable().first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Projected surplus/deficit'), findsOneWidget);
      expect(find.text('Recommendations'), findsOneWidget);

      await tester.fling(
          find.byType(SingleChildScrollView), const Offset(0, -1000), 1200);
      await tester.pumpAndSettle();
      final reviewSubsButton =
          find.widgetWithText(OutlinedButton, 'Review Subs');
      await tester.ensureVisible(reviewSubsButton);
      await tester.tap(reviewSubsButton);
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions Page'), findsOneWidget);
    },
  );
}
