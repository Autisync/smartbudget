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
            title: 'Subscription burden is high',
            reason:
                'Subscriptions consume ${(subsShare * 100).toStringAsFixed(0)}% of recurring obligations.',
            suggestedAction: 'Cancel or pause low-priority subscriptions.',
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
          title: 'Optimize food spending',
          reason:
              'Reducing food spend by 15% can recover ${recoverable.toStringAsFixed(0)} per month.',
          suggestedAction: 'Set a food budget cap and track weekly variance.',
          impactValue: recoverable,
          actionType: ScenarioActionType.openBudgetAdjustment,
        ),
      );
    }

    if (computation.simulatedMonthlyCashflow < 0) {
      final breakEvenGap = computation.simulatedMonthlyCashflow.abs();
      recommendations.add(
        ScenarioRecommendation(
          title: 'Break-even income gap detected',
          reason:
              'Increase recurring income by ${breakEvenGap.toStringAsFixed(0)} to avoid monthly deficit.',
          suggestedAction:
              'Create a recurring income goal or reduce variable spending.',
          impactValue: breakEvenGap,
          actionType: ScenarioActionType.openRecurringBalanceSheet,
        ),
      );
    }

    if (runway.runwayDays < 30) {
      recommendations.add(
        ScenarioRecommendation(
          title: 'Emergency runway is low',
          reason: 'Current emergency runway is below 30 days.',
          suggestedAction:
              'Increase emergency allocation and reduce optional spend.',
          impactValue: (30 - runway.runwayDays).toDouble(),
          actionType: ScenarioActionType.createSavingsRule,
        ),
      );
    }

    if (debtCost > 0) {
      final debtRelief = math.min(debtCost * 0.1, 500).toDouble();
      recommendations.add(
        ScenarioRecommendation(
          title: 'Debt repayment acceleration available',
          reason:
              'Debt obligations are taking a significant share of cashflow.',
          suggestedAction:
              'Route ${debtRelief.toStringAsFixed(0)} extra monthly to debt repayment.',
          impactValue: debtRelief,
          actionType: ScenarioActionType.openBudgetAdjustment,
        ),
      );
    }

    if (probabilities.nextMonthDeficitLikelihood >= 0.6) {
      recommendations.add(
        ScenarioRecommendation(
          title: 'High next-month deficit probability',
          reason:
              'Deficit likelihood is ${(probabilities.nextMonthDeficitLikelihood * 100).toStringAsFixed(0)}%.',
          suggestedAction:
              'Review transactions by category and apply targeted reductions.',
          impactValue: probabilities.nextMonthDeficitLikelihood * 100,
          actionType: ScenarioActionType.openTransactionsByCategory,
        ),
      );
    }

    recommendations.sort((a, b) => b.impactValue.compareTo(a.impactValue));
    return recommendations;
  }
}
