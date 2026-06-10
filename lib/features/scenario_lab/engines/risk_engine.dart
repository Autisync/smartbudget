import 'dart:math' as math;

import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';

class RiskEngine {
  const RiskEngine();

  List<ScenarioRiskEvent> buildRiskEvents(Set<ScenarioRiskEventType> enabled) {
    return ScenarioRiskEventType.values.map((type) {
      final isEnabled = enabled.contains(type);
      switch (type) {
        case ScenarioRiskEventType.incomeDrop20:
          return ScenarioRiskEvent(
            type: type,
            enabled: isEnabled,
            impactIncomeDelta: isEnabled ? -0.20 : 0,
            impactExpenseDelta: 0,
          );
        case ScenarioRiskEventType.rentIncrease:
          return ScenarioRiskEvent(
            type: type,
            enabled: isEnabled,
            impactIncomeDelta: 0,
            impactExpenseDelta: isEnabled ? 0.08 : 0,
          );
        case ScenarioRiskEventType.transportIncrease:
          return ScenarioRiskEvent(
            type: type,
            enabled: isEnabled,
            impactIncomeDelta: 0,
            impactExpenseDelta: isEnabled ? 0.05 : 0,
          );
        case ScenarioRiskEventType.emergencyCost:
          return ScenarioRiskEvent(
            type: type,
            enabled: isEnabled,
            impactIncomeDelta: 0,
            impactExpenseDelta: 0,
            oneTimeExpense: isEnabled ? 600 : 0,
          );
        case ScenarioRiskEventType.delayedSalary:
          return ScenarioRiskEvent(
            type: type,
            enabled: isEnabled,
            impactIncomeDelta: isEnabled ? -0.10 : 0,
            impactExpenseDelta: 0,
          );
        case ScenarioRiskEventType.subscriptionIncrease:
          return ScenarioRiskEvent(
            type: type,
            enabled: isEnabled,
            impactIncomeDelta: 0,
            impactExpenseDelta: isEnabled ? 0.03 : 0,
          );
      }
    }).toList(growable: false);
  }

  ({double income, double expenses}) applyRiskEvents({
    required double monthlyIncome,
    required double monthlyExpenses,
    required List<ScenarioRiskEvent> events,
  }) {
    var income = monthlyIncome;
    var expenses = monthlyExpenses;
    for (final event in events.where((event) => event.enabled)) {
      income += income * event.impactIncomeDelta;
      expenses += expenses * event.impactExpenseDelta;
      expenses += event.oneTimeExpense / 12;
    }
    return (income: income.clamp(0, double.infinity), expenses: expenses);
  }

  EmergencyRunwayResult computeEmergencyRunway({
    required double liquidBuffer,
    required double monthlyObligations,
    required double monthlyIncome,
    required List<ScenarioRiskEvent> events,
  }) {
    if (monthlyObligations <= 0) {
      return const EmergencyRunwayResult(
        runwayDays: 3650,
        monthsCovered: 120,
        withIncomeLossDays: 3650,
        withUnexpectedExpenseDays: 3650,
      );
    }

    final perDayBurn = monthlyObligations / 30;
    final runwayDays = (liquidBuffer / perDayBurn).floor().clamp(0, 3650);
    final monthsCovered = liquidBuffer / monthlyObligations;

    final incomeLossEnabled = events.any((event) =>
        event.type == ScenarioRiskEventType.incomeDrop20 && event.enabled);
    final emergencyCostEnabled = events.any((event) =>
        event.type == ScenarioRiskEventType.emergencyCost && event.enabled);

    final lostIncomeEffect = incomeLossEnabled ? monthlyIncome * 0.2 : 0;
    final lostIncomeBurn =
        math.max(monthlyObligations + lostIncomeEffect, 1) / 30;
    // Model an unexpected expense relative to the user's own cost of living so
    // the shock is currency-agnostic and realistic across income levels: a
    // severe event is roughly one month of obligations, a baseline event half
    // a month.
    final emergencyExpense =
        monthlyObligations * (emergencyCostEnabled ? 1.0 : 0.5);
    final emergencyBuffer = math.max(0.0, liquidBuffer - emergencyExpense);

    final withIncomeLossDays =
        (liquidBuffer / lostIncomeBurn).floor().clamp(0, 3650);
    final withUnexpectedExpenseDays =
        (emergencyBuffer / perDayBurn).floor().clamp(0, 3650);

    return EmergencyRunwayResult(
      runwayDays: runwayDays,
      monthsCovered: monthsCovered,
      withIncomeLossDays: withIncomeLossDays,
      withUnexpectedExpenseDays: withUnexpectedExpenseDays,
    );
  }

  FinancialStressScore computeStressScore({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double recurringObligations,
    required EmergencyRunwayResult runway,
  }) {
    final incomeBase = math.max(monthlyIncome, 1);
    final pressureRatio = monthlyExpenses / incomeBase;
    final net = monthlyIncome - monthlyExpenses;

    final financialPressure = (pressureRatio * 40).clamp(0, 40).toDouble();
    final burnRateRisk = net >= 0
        ? ((1 - (net / incomeBase).clamp(0, 1)) * 30).toDouble()
        : (30 + ((-net / incomeBase) * 40)).clamp(30, 40).toDouble();
    final obligationBurden =
        ((recurringObligations / math.max(monthlyExpenses, 1)) * 20)
            .clamp(0, 20)
            .toDouble();
    final resilienceScore = runway.runwayDays >= 180
        ? 0.0
        : ((180 - runway.runwayDays) / 180 * 20).clamp(0, 20).toDouble();

    final score =
        (financialPressure + burnRateRisk + obligationBurden + resilienceScore)
            .round()
            .clamp(0, 100)
            .toInt();

    final status = score <= 30
        ? FinancialStressState.low
        : score <= 55
            ? FinancialStressState.moderate
            : score <= 75
                ? FinancialStressState.high
                : FinancialStressState.critical;

    return FinancialStressScore(
      score: score,
      status: status,
      financialPressure: financialPressure,
      burnRateRisk: burnRateRisk,
      obligationBurden: obligationBurden,
      cashflowResilience: 20 - resilienceScore,
    );
  }

  ProbabilityForecast computeProbabilities({
    required double monthlyCashflow,
    required FinancialStressScore stress,
    required List<GoalForecastResult> goals,
    required double recurringBurden,
  }) {
    final deficitLikelihood = monthlyCashflow >= 0
        ? (stress.score / 200).clamp(0, 0.6).toDouble()
        : (0.45 + ((-monthlyCashflow) / (monthlyCashflow.abs() + 1) * 0.5))
            .clamp(0.45, 0.98)
            .toDouble();

    final averageGoalMonths = goals.isEmpty
        ? 12.0
        : goals
                .map((goal) => (goal.simulatedMonthsRemaining ?? 48).toDouble())
                .reduce((a, b) => a + b) /
            goals.length;

    final goalReachLikelihood =
        ((1 - (averageGoalMonths / 120)).clamp(0, 1) * (1 - deficitLikelihood))
            .toDouble();

    final recurringShortfallRisk =
        (recurringBurden * 0.7 + (stress.score / 100) * 0.3)
            .clamp(0, 1)
            .toDouble();

    return ProbabilityForecast(
      nextMonthDeficitLikelihood: deficitLikelihood,
      goalReachLikelihood: goalReachLikelihood,
      recurringShortfallRisk: recurringShortfallRisk,
    );
  }
}
