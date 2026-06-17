import 'dart:math' as math;

import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';

class RecommendationEngine {
  const RecommendationEngine();

  List<ScenarioRecommendation> build({
    required ScenarioBaseData baseData,
    required ScenarioComputation computation,
    required FinancialStressScore stress,
    required EmergencyRunwayResult runway,
    required ProbabilityForecast probabilities,
  }) {
    final recommendations = <ScenarioRecommendation>[];

    final subscriptionCost =
        computation.simulatedCategoryExpenses[ScenarioCategory.subscriptions] ??
            0;
    final foodCost =
        computation.simulatedCategoryExpenses[ScenarioCategory.food] ?? 0;
    final debtCost =
        computation.simulatedCategoryExpenses[ScenarioCategory.debt] ?? 0;

    if (subscriptionCost > 0) {
      final subsShare = computation.simulatedRecurringObligations <= 0
          ? 0
          : subscriptionCost / computation.simulatedRecurringObligations;
      if (subsShare >= 0.25) {
        recommendations.add(
          ScenarioRecommendation(
            code: ScenarioRecommendationCode.subscriptionBurden,
            reasonParam: (subsShare * 100).toStringAsFixed(0),
            impactValue: subscriptionCost * 0.2,
            actionType: ScenarioActionType.reviewSubscriptions,
          ),
        );
      }
    }

    if (foodCost > 0) {
      final recoverable = foodCost * 0.15;
      recommendations.add(
        ScenarioRecommendation(
          code: ScenarioRecommendationCode.optimizeFood,
          reasonParam: recoverable.toStringAsFixed(0),
          impactValue: recoverable,
          actionType: ScenarioActionType.openBudgetAdjustment,
        ),
      );
    }

    if (computation.simulatedMonthlyCashflow < 0) {
      final breakEvenGap = computation.simulatedMonthlyCashflow.abs();
      recommendations.add(
        ScenarioRecommendation(
          code: ScenarioRecommendationCode.breakEvenGap,
          reasonParam: breakEvenGap.toStringAsFixed(0),
          impactValue: breakEvenGap,
          actionType: ScenarioActionType.openRecurringBalanceSheet,
        ),
      );
    }

    if (runway.runwayDays < 30) {
      recommendations.add(
        ScenarioRecommendation(
          code: ScenarioRecommendationCode.emergencyRunway,
          impactValue: (30 - runway.runwayDays).toDouble(),
          actionType: ScenarioActionType.createSavingsRule,
        ),
      );
    }

    if (debtCost > 0) {
      final debtRelief = math.min(debtCost * 0.1, 500).toDouble();
      recommendations.add(
        ScenarioRecommendation(
          code: ScenarioRecommendationCode.debtAcceleration,
          actionParam: debtRelief.toStringAsFixed(0),
          impactValue: debtRelief,
          actionType: ScenarioActionType.openBudgetAdjustment,
        ),
      );
    }

    if (probabilities.nextMonthDeficitLikelihood >= 0.6) {
      recommendations.add(
        ScenarioRecommendation(
          code: ScenarioRecommendationCode.deficitProbability,
          reasonParam:
              (probabilities.nextMonthDeficitLikelihood * 100).toStringAsFixed(0),
          impactValue: probabilities.nextMonthDeficitLikelihood * 100,
          actionType: ScenarioActionType.openTransactionsByCategory,
        ),
      );
    }

    recommendations.sort((a, b) => b.impactValue.compareTo(a.impactValue));
    return recommendations;
  }
}
