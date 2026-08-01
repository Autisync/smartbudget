// Feature-level cover for a re-audit finding: _FinancialStressMeter
// (scenario_lab_screen.dart) used raw Colors.green/orange/deepOrange/red for
// its stress-level meter instead of the documented AppColors.statusFor money-
// color system used everywhere else (established in P4.2). Asserts the
// rendered LinearProgressIndicator's color is one of statusFor's outputs for
// the current brightness, in both light and dark ThemeData — never a raw
// Material color.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';
import 'package:smartbudget/features/scenario_lab/presentation/providers/scenario_lab_controller.dart';
import 'package:smartbudget/features/scenario_lab/presentation/screens/scenario_lab_screen.dart';

ScenarioBaseData _buildBase() {
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
    activeGoals: const [],
    ledgerEntries: const [],
  );
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'the stress meter renders with an AppColors.statusFor color, never a raw Material color, in ${brightness.name} mode',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              scenarioLabBaseDataProvider.overrideWith((ref) async => _buildBase()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const ScenarioLabScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator).first,
        );
        final validColors = AppStatus.values
            .map((s) => AppColors.statusFor(brightness, s))
            .toSet();

        expect(tester.takeException(), isNull);
        expect(
          validColors.contains(indicator.color),
          isTrue,
          reason: 'expected ${indicator.color} to be one of the statusFor '
              'palette $validColors, not a raw Material color',
        );
        expect(indicator.color, isNot(equals(Colors.green)));
        expect(indicator.color, isNot(equals(Colors.orange)));
        expect(indicator.color, isNot(equals(Colors.deepOrange)));
        expect(indicator.color, isNot(equals(Colors.red)));
      },
    );
  }
}
