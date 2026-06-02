import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';

class BehavioralAnalysisEngine {
  const BehavioralAnalysisEngine();

  BehavioralAnalysisResult analyze({
    required ScenarioBaseData baseData,
    required ScenarioComputation computation,
    required List<GoalForecastResult> goalForecasts,
  }) {
    final overspendingCategories = <ScenarioCategory>[];

    for (final adjustment in computation.categoryAdjustments) {
      if (adjustment.currentMonthlyAmount <= 0) continue;
      if (adjustment.percentageChange >= 12) {
        overspendingCategories.add(adjustment.category);
      }
    }

    final expenseEntries =
        baseData.ledgerEntries.where((entry) => !entry.isIncome).toList();
    final weekendEntries = expenseEntries
        .where((entry) =>
            entry.date.weekday == DateTime.saturday ||
            entry.date.weekday == DateTime.sunday)
        .toList();

    final totalExpense =
        expenseEntries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final weekendExpense =
        weekendEntries.fold<double>(0, (sum, entry) => sum + entry.amount);

    final weekendSpendingRatio = totalExpense <= 0
        ? 0.0
        : (weekendExpense / totalExpense).clamp(0, 1).toDouble();

    final recurringGrowthWarning = computation.simulatedRecurringObligations >
        computation.simulatedMonthlyIncome * 0.7;

    final goalBehindWarning = goalForecasts.any((forecast) {
      final currentMonths = forecast.currentMonthsRemaining;
      final simulatedMonths = forecast.simulatedMonthsRemaining;
      if (currentMonths == null || simulatedMonths == null) {
        return false;
      }
      return simulatedMonths > currentMonths;
    });

    final nudges = <String>[];

    if (overspendingCategories.isNotEmpty) {
      nudges.add(
        'Overspending risk in ${overspendingCategories.first.label}. Consider reducing by 10-15%.',
      );
    }
    if (weekendSpendingRatio >= 0.35) {
      nudges.add(
        'Weekend spending is ${((weekendSpendingRatio) * 100).toStringAsFixed(0)}% of total expenses.',
      );
    }
    if (recurringGrowthWarning) {
      nudges.add('Recurring expenses are growing faster than monthly income.');
    }
    if (goalBehindWarning) {
      nudges
          .add('Your active savings goals may be delayed under this scenario.');
    }

    final inactiveSubscriptionSignals = baseData
                .monthlyCategoryExpenses[ScenarioCategory.subscriptions] ==
            0
        ? 0
        : (baseData.monthlyCategoryExpenses[ScenarioCategory.subscriptions]! /
                100)
            .floor();

    return BehavioralAnalysisResult(
      overspendingCategories: overspendingCategories,
      inactiveSubscriptionSignals: inactiveSubscriptionSignals,
      weekendSpendingRatio: weekendSpendingRatio,
      recurringGrowthWarning: recurringGrowthWarning,
      goalBehindWarning: goalBehindWarning,
      nudges: nudges,
    );
  }
}
