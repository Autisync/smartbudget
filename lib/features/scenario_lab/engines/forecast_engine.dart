import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';

class ForecastEngine {
  const ForecastEngine();

  List<ScenarioTimelinePoint> buildTimeline({
    required double monthlyCashflow,
    required double monthlySavingsContribution,
    required EmergencyRunwayResult emergencyRunway,
    required double debtPressure,
    required double recurringBurden,
  }) {
    return const [1, 3, 6, 12].map((months) {
      return months;
    }).map((months) {
      return ScenarioTimelinePoint(
        months: months,
        projectedSurplusOrDeficit: monthlyCashflow * months,
        savingsGrowth: monthlySavingsContribution * months,
        emergencyRunwayDays: emergencyRunway.runwayDays,
        debtPressure: debtPressure,
        recurringBurden: recurringBurden,
      );
    }).toList(growable: false);
  }

  List<GoalForecastResult> buildGoalForecasts({
    required List<ScenarioGoal> goals,
    required double currentMonthlyContribution,
    required double simulatedMonthlyContribution,
    required DateTime now,
  }) {
    return goals.map((goal) {
      final currentMonths = _monthsToTarget(
        remainingAmount: goal.remainingAmount,
        monthlyContribution: currentMonthlyContribution,
      );
      final simulatedMonths = _monthsToTarget(
        remainingAmount: goal.remainingAmount,
        monthlyContribution: simulatedMonthlyContribution,
      );

      return GoalForecastResult(
        goalId: goal.id,
        goalTitle: goal.title,
        currentEstimatedCompletion:
            currentMonths == null ? null : _monthShift(now, currentMonths),
        simulatedEstimatedCompletion:
            simulatedMonths == null ? null : _monthShift(now, simulatedMonths),
        currentMonthsRemaining: currentMonths,
        simulatedMonthsRemaining: simulatedMonths,
        monthsSavedOrDelayed: _monthsDelta(currentMonths, simulatedMonths),
        requiredMonthlyContribution:
            goal.remainingAmount <= 0 ? 0 : goal.remainingAmount / 12,
      );
    }).toList(growable: false);
  }

  int? _monthsToTarget({
    required double remainingAmount,
    required double monthlyContribution,
  }) {
    if (remainingAmount <= 0) return 0;
    if (monthlyContribution <= 0) return null;
    return (remainingAmount / monthlyContribution).ceil();
  }

  DateTime _monthShift(DateTime start, int months) {
    return DateTime(start.year, start.month + months, start.day);
  }

  int _monthsDelta(int? current, int? simulated) {
    if (current == null && simulated == null) return 0;
    if (current == null && simulated != null) return -simulated;
    if (current != null && simulated == null) return current;
    return (current ?? 0) - (simulated ?? 0);
  }
}
