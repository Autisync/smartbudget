import 'dart:math' as math;

import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';

class ScenarioEngine {
  const ScenarioEngine();

  static const List<ScenarioPreset> presets = [
    ScenarioPreset(
      type: ScenarioPresetType.survivalMode,
      name: 'Survival Mode',
      incomeMultiplier: 0.95,
      recurringExpenseMultiplier: 0.88,
      optionalSpendingMultiplier: 0.65,
      savingsRateDelta: -0.05,
      riskTolerance: 0.2,
      goalContributionMultiplier: 0.7,
      categoryMultipliers: {
        ScenarioCategory.housing: 1,
        ScenarioCategory.food: 0.9,
        ScenarioCategory.transport: 0.85,
        ScenarioCategory.subscriptions: 0.55,
        ScenarioCategory.entertainment: 0.4,
        ScenarioCategory.family: 0.9,
        ScenarioCategory.education: 0.9,
        ScenarioCategory.emergency: 1.2,
        ScenarioCategory.debt: 1.1,
        ScenarioCategory.savings: 0.7,
      },
    ),
    ScenarioPreset(
      type: ScenarioPresetType.balancedLiving,
      name: 'Balanced Living',
      incomeMultiplier: 1,
      recurringExpenseMultiplier: 0.97,
      optionalSpendingMultiplier: 0.9,
      savingsRateDelta: 0.03,
      riskTolerance: 0.5,
      goalContributionMultiplier: 1.1,
      categoryMultipliers: {
        ScenarioCategory.housing: 1,
        ScenarioCategory.food: 0.95,
        ScenarioCategory.transport: 0.95,
        ScenarioCategory.subscriptions: 0.9,
        ScenarioCategory.entertainment: 0.85,
        ScenarioCategory.family: 1,
        ScenarioCategory.education: 1,
        ScenarioCategory.emergency: 1.1,
        ScenarioCategory.debt: 1,
        ScenarioCategory.savings: 1.1,
      },
    ),
    ScenarioPreset(
      type: ScenarioPresetType.aggressiveSavings,
      name: 'Aggressive Savings',
      incomeMultiplier: 1.02,
      recurringExpenseMultiplier: 0.88,
      optionalSpendingMultiplier: 0.7,
      savingsRateDelta: 0.12,
      riskTolerance: 0.35,
      goalContributionMultiplier: 1.45,
      categoryMultipliers: {
        ScenarioCategory.housing: 0.95,
        ScenarioCategory.food: 0.85,
        ScenarioCategory.transport: 0.82,
        ScenarioCategory.subscriptions: 0.6,
        ScenarioCategory.entertainment: 0.55,
        ScenarioCategory.family: 0.9,
        ScenarioCategory.education: 1,
        ScenarioCategory.emergency: 1.15,
        ScenarioCategory.debt: 1,
        ScenarioCategory.savings: 1.5,
      },
    ),
    ScenarioPreset(
      type: ScenarioPresetType.familyPlanning,
      name: 'Family Planning',
      incomeMultiplier: 1,
      recurringExpenseMultiplier: 1.08,
      optionalSpendingMultiplier: 0.8,
      savingsRateDelta: 0,
      riskTolerance: 0.45,
      goalContributionMultiplier: 0.95,
      categoryMultipliers: {
        ScenarioCategory.housing: 1.05,
        ScenarioCategory.food: 1.15,
        ScenarioCategory.transport: 1.05,
        ScenarioCategory.subscriptions: 0.9,
        ScenarioCategory.entertainment: 0.8,
        ScenarioCategory.family: 1.35,
        ScenarioCategory.education: 1.25,
        ScenarioCategory.emergency: 1.2,
        ScenarioCategory.debt: 1,
        ScenarioCategory.savings: 0.95,
      },
    ),
    ScenarioPreset(
      type: ScenarioPresetType.debtRecovery,
      name: 'Debt Recovery',
      incomeMultiplier: 1.03,
      recurringExpenseMultiplier: 0.92,
      optionalSpendingMultiplier: 0.72,
      savingsRateDelta: -0.02,
      riskTolerance: 0.25,
      goalContributionMultiplier: 0.85,
      categoryMultipliers: {
        ScenarioCategory.housing: 0.97,
        ScenarioCategory.food: 0.88,
        ScenarioCategory.transport: 0.9,
        ScenarioCategory.subscriptions: 0.65,
        ScenarioCategory.entertainment: 0.5,
        ScenarioCategory.family: 0.95,
        ScenarioCategory.education: 0.95,
        ScenarioCategory.emergency: 1.05,
        ScenarioCategory.debt: 1.35,
        ScenarioCategory.savings: 0.8,
      },
    ),
    ScenarioPreset(
      type: ScenarioPresetType.growthMode,
      name: 'Growth Mode',
      incomeMultiplier: 1.12,
      recurringExpenseMultiplier: 1.04,
      optionalSpendingMultiplier: 1,
      savingsRateDelta: 0.08,
      riskTolerance: 0.7,
      goalContributionMultiplier: 1.25,
      categoryMultipliers: {
        ScenarioCategory.housing: 1.02,
        ScenarioCategory.food: 1,
        ScenarioCategory.transport: 1.05,
        ScenarioCategory.subscriptions: 1,
        ScenarioCategory.entertainment: 0.95,
        ScenarioCategory.family: 1.05,
        ScenarioCategory.education: 1.2,
        ScenarioCategory.emergency: 1.1,
        ScenarioCategory.debt: 1.05,
        ScenarioCategory.savings: 1.3,
      },
    ),
  ];

  ScenarioPreset? findPreset(ScenarioPresetType? type) {
    if (type == null) return null;
    for (final preset in presets) {
      if (preset.type == type) return preset;
    }
    return null;
  }

  ScenarioInput applyPreset({
    required ScenarioBaseData baseData,
    required ScenarioInput currentInput,
    required ScenarioPresetType presetType,
  }) {
    final preset = findPreset(presetType);
    if (preset == null) return currentInput;

    final adjustments = <ScenarioCategory, ScenarioCategoryAdjustment>{};
    for (final category in ScenarioCategory.values) {
      final current = baseData.monthlyCategoryExpenses[category] ?? 0;
      final factor = preset.categoryMultipliers[category] ?? 1;
      adjustments[category] = ScenarioCategoryAdjustment(
        category: category,
        currentMonthlyAmount: current,
        simulatedMonthlyAmount: (current * factor).clamp(0, double.infinity),
      );
    }

    return currentInput.copyWith(
      selectedPreset: preset.type,
      incomeMultiplier: preset.incomeMultiplier,
      recurringExpenseMultiplier: preset.recurringExpenseMultiplier,
      optionalSpendingMultiplier: preset.optionalSpendingMultiplier,
      savingsRateDelta: preset.savingsRateDelta,
      riskTolerance: preset.riskTolerance,
      goalContributionMultiplier: preset.goalContributionMultiplier,
      categoryAdjustments: adjustments,
    );
  }

  ScenarioComputation simulate({
    required ScenarioBaseData baseData,
    required ScenarioInput input,
  }) {
    final categoryExpenses = <ScenarioCategory, double>{
      ...defaultScenarioCategories(),
      ...baseData.monthlyCategoryExpenses,
    };

    final simulatedCategoryExpenses = <ScenarioCategory, double>{};
    final categoryAdjustments = <ScenarioCategoryAdjustment>[];

    for (final category in ScenarioCategory.values) {
      final currentAmount = categoryExpenses[category] ?? 0;
      final adjustment = input.categoryAdjustments[category];
      final adjustedAmount =
          adjustment?.simulatedMonthlyAmount ?? currentAmount;
      final boundedAmount = adjustedAmount.clamp(0, double.infinity).toDouble();
      simulatedCategoryExpenses[category] = boundedAmount;
      categoryAdjustments.add(
        ScenarioCategoryAdjustment(
          category: category,
          currentMonthlyAmount: currentAmount,
          simulatedMonthlyAmount: boundedAmount,
        ),
      );
    }

    final simulatedMonthlyIncome =
        (baseData.monthlyIncome * input.incomeMultiplier)
            .clamp(0, double.infinity)
            .toDouble();

    final recurringCategories = {
      ScenarioCategory.housing,
      ScenarioCategory.transport,
      ScenarioCategory.subscriptions,
      ScenarioCategory.debt,
      ScenarioCategory.emergency,
    };

    final currentRecurringObligations = recurringCategories.fold<double>(
      0,
      (sum, category) => sum + (categoryExpenses[category] ?? 0),
    );

    final simulatedRecurringObligations = recurringCategories.fold<double>(
      0,
      (sum, category) => sum + (simulatedCategoryExpenses[category] ?? 0),
    );

    final optionalCategories = {
      ScenarioCategory.entertainment,
      ScenarioCategory.subscriptions,
      ScenarioCategory.food,
    };

    final optionalCurrent = optionalCategories.fold<double>(
      0,
      (sum, category) => sum + (simulatedCategoryExpenses[category] ?? 0),
    );

    final optionalTarget = optionalCurrent * input.optionalSpendingMultiplier;
    if (optionalCurrent > 0) {
      final ratio = optionalTarget / optionalCurrent;
      for (final category in optionalCategories) {
        simulatedCategoryExpenses[category] =
            ((simulatedCategoryExpenses[category] ?? 0) * ratio)
                .clamp(0, double.infinity)
                .toDouble();
      }
    }

    final totalCurrentExpense =
        categoryExpenses.values.fold<double>(0, (sum, value) => sum + value);
    final totalSimulatedExpense = simulatedCategoryExpenses.values
        .fold<double>(0, (sum, value) => sum + value);

    final currentMonthlyCashflow = baseData.monthlyIncome - totalCurrentExpense;
    final simulatedMonthlyCashflow =
        simulatedMonthlyIncome - totalSimulatedExpense;

    final baselineSavings = baseData.monthlyGoalContribution;
    final scenarioSavings =
        ((simulatedCategoryExpenses[ScenarioCategory.savings] ??
                    baselineSavings) *
                input.goalContributionMultiplier)
            .clamp(0, double.infinity)
            .toDouble();

    final adjustedScenarioSavings = (scenarioSavings +
            math.max(0, simulatedMonthlyIncome * input.savingsRateDelta))
        .clamp(0, double.infinity)
        .toDouble();

    final currentSavingsRate = baseData.monthlyIncome <= 0
        ? 0.0
        : (baselineSavings / baseData.monthlyIncome).clamp(0, 1).toDouble();
    final simulatedSavingsRate = simulatedMonthlyIncome <= 0
        ? 0.0
        : (adjustedScenarioSavings / simulatedMonthlyIncome)
            .clamp(0, 1)
            .toDouble();

    final currentSubscriptionBurden = baseData.monthlyIncome <= 0
        ? 0.0
        : ((categoryExpenses[ScenarioCategory.subscriptions] ?? 0) /
                baseData.monthlyIncome)
            .clamp(0, 1.5)
            .toDouble();

    final simulatedSubscriptionBurden = simulatedMonthlyIncome <= 0
        ? 0.0
        : ((simulatedCategoryExpenses[ScenarioCategory.subscriptions] ?? 0) /
                simulatedMonthlyIncome)
            .clamp(0, 1.5)
            .toDouble();

    return ScenarioComputation(
      simulatedMonthlyIncome: simulatedMonthlyIncome,
      simulatedCategoryExpenses: simulatedCategoryExpenses,
      simulatedMonthlySavingsContribution: adjustedScenarioSavings,
      categoryAdjustments: categoryAdjustments,
      simulatedMonthlyCashflow: simulatedMonthlyCashflow,
      currentMonthlyCashflow: currentMonthlyCashflow,
      simulatedRecurringObligations: simulatedRecurringObligations,
      currentRecurringObligations: currentRecurringObligations,
      simulatedSubscriptionBurden: simulatedSubscriptionBurden,
      currentSubscriptionBurden: currentSubscriptionBurden,
      simulatedSavingsRate: simulatedSavingsRate,
      currentSavingsRate: currentSavingsRate,
    );
  }
}
