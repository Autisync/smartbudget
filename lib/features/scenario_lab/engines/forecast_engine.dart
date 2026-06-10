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
        requiredMonthlyContribution: _requiredMonthlyContribution(goal, now),
      );
    }).toList(growable: false);
  }

  /// Monthly amount needed to reach the goal. Paced to the goal's deadline when
  /// one is set (never dividing by a non-positive horizon), otherwise spread
  /// over a default 12-month planning window.
  double _requiredMonthlyContribution(ScenarioGoal goal, DateTime now) {
    final remaining = goal.remainingAmount;
    if (remaining <= 0) return 0;

    final deadline = goal.targetDate;
    if (deadline == null) return remaining / 12;

    // Whole months until the deadline, with at least one month so an imminent
    // or overdue goal asks for the full remaining amount rather than dividing
    // by zero (which would yield Infinity).
    final days = deadline.difference(now).inDays;
    final months = (days / 30).ceil();
    final horizon = months < 1 ? 1 : months;
    return remaining / horizon;
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
