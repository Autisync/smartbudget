import 'package:flutter/foundation.dart';

enum ScenarioPresetType {
  survivalMode,
  balancedLiving,
  aggressiveSavings,
  familyPlanning,
  debtRecovery,
  growthMode,
}

enum ScenarioCategory {
  housing,
  food,
  transport,
  subscriptions,
  entertainment,
  family,
  education,
  emergency,
  debt,
  savings,
}

enum FinancialStressState { low, moderate, high, critical }

enum ScenarioRiskEventType {
  incomeDrop20,
  rentIncrease,
  transportIncrease,
  emergencyCost,
  delayedSalary,
  subscriptionIncrease,
}

enum ScenarioActionType {
  openBudgetAdjustment,
  createSavingsRule,
  reviewSubscriptions,
  openRecurringBalanceSheet,
  openTransactionsByCategory,
  openSavingsGoal,
}

extension ScenarioPresetTypeX on ScenarioPresetType {
  String get label {
    switch (this) {
      case ScenarioPresetType.survivalMode:
        return 'Survival Mode';
      case ScenarioPresetType.balancedLiving:
        return 'Balanced Living';
      case ScenarioPresetType.aggressiveSavings:
        return 'Aggressive Savings';
      case ScenarioPresetType.familyPlanning:
        return 'Family Planning';
      case ScenarioPresetType.debtRecovery:
        return 'Debt Recovery';
      case ScenarioPresetType.growthMode:
        return 'Growth Mode';
    }
  }
}

extension ScenarioCategoryX on ScenarioCategory {
  String get label {
    switch (this) {
      case ScenarioCategory.housing:
        return 'Housing';
      case ScenarioCategory.food:
        return 'Food';
      case ScenarioCategory.transport:
        return 'Transport';
      case ScenarioCategory.subscriptions:
        return 'Subscriptions';
      case ScenarioCategory.entertainment:
        return 'Entertainment';
      case ScenarioCategory.family:
        return 'Family';
      case ScenarioCategory.education:
        return 'Education';
      case ScenarioCategory.emergency:
        return 'Emergency';
      case ScenarioCategory.debt:
        return 'Debt';
      case ScenarioCategory.savings:
        return 'Savings';
    }
  }
}

extension ScenarioRiskEventTypeX on ScenarioRiskEventType {
  String get label {
    switch (this) {
      case ScenarioRiskEventType.incomeDrop20:
        return 'Income -20%';
      case ScenarioRiskEventType.rentIncrease:
        return 'Rent increase';
      case ScenarioRiskEventType.transportIncrease:
        return 'Transport increase';
      case ScenarioRiskEventType.emergencyCost:
        return 'Medical/emergency cost';
      case ScenarioRiskEventType.delayedSalary:
        return 'Delayed salary';
      case ScenarioRiskEventType.subscriptionIncrease:
        return 'Subscription increase';
    }
  }
}

@immutable
class ScenarioPreset {
  const ScenarioPreset({
    required this.type,
    required this.name,
    required this.incomeMultiplier,
    required this.recurringExpenseMultiplier,
    required this.optionalSpendingMultiplier,
    required this.savingsRateDelta,
    required this.riskTolerance,
    required this.goalContributionMultiplier,
    required this.categoryMultipliers,
  });

  final ScenarioPresetType type;
  final String name;
  final double incomeMultiplier;
  final double recurringExpenseMultiplier;
  final double optionalSpendingMultiplier;
  final double savingsRateDelta;
  final double riskTolerance;
  final double goalContributionMultiplier;
  final Map<ScenarioCategory, double> categoryMultipliers;
}

@immutable
class ScenarioCategoryAdjustment {
  const ScenarioCategoryAdjustment({
    required this.category,
    required this.currentMonthlyAmount,
    required this.simulatedMonthlyAmount,
  });

  final ScenarioCategory category;
  final double currentMonthlyAmount;
  final double simulatedMonthlyAmount;

  double get impactOnCashflow => currentMonthlyAmount - simulatedMonthlyAmount;

  double get percentageChange {
    if (currentMonthlyAmount == 0) {
      if (simulatedMonthlyAmount == 0) return 0;
      return 100;
    }
    return ((simulatedMonthlyAmount - currentMonthlyAmount) /
            currentMonthlyAmount) *
        100;
  }

  ScenarioCategoryAdjustment copyWith({
    ScenarioCategory? category,
    double? currentMonthlyAmount,
    double? simulatedMonthlyAmount,
  }) {
    return ScenarioCategoryAdjustment(
      category: category ?? this.category,
      currentMonthlyAmount: currentMonthlyAmount ?? this.currentMonthlyAmount,
      simulatedMonthlyAmount:
          simulatedMonthlyAmount ?? this.simulatedMonthlyAmount,
    );
  }
}

@immutable
class ScenarioRiskEvent {
  const ScenarioRiskEvent({
    required this.type,
    required this.enabled,
    required this.impactIncomeDelta,
    required this.impactExpenseDelta,
    this.oneTimeExpense = 0,
  });

  final ScenarioRiskEventType type;
  final bool enabled;
  final double impactIncomeDelta;
  final double impactExpenseDelta;
  final double oneTimeExpense;
}

@immutable
class ScenarioGoal {
  const ScenarioGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.createdAt,
    this.targetDate,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime createdAt;

  /// Optional deadline. When set, the required monthly contribution is paced to
  /// meet the target by this date instead of an arbitrary fixed horizon.
  final DateTime? targetDate;

  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0, double.infinity).toDouble();
}

@immutable
class ScenarioLedgerEntry {
  const ScenarioLedgerEntry({
    required this.amount,
    required this.isIncome,
    required this.isRecurring,
    required this.category,
    required this.date,
  });

  final double amount;
  final bool isIncome;
  final bool isRecurring;
  final ScenarioCategory category;
  final DateTime date;
}

@immutable
class ScenarioBaseData {
  const ScenarioBaseData({
    required this.currencyCode,
    required this.monthlyIncome,
    required this.monthlyRecurringExpenses,
    required this.monthlyCategoryExpenses,
    required this.currentSavingsBalance,
    required this.optionalMonthlySpending,
    required this.monthlyGoalContribution,
    required this.activeGoals,
    required this.ledgerEntries,
  });

  final String currencyCode;
  final double monthlyIncome;
  final double monthlyRecurringExpenses;
  final Map<ScenarioCategory, double> monthlyCategoryExpenses;
  final double currentSavingsBalance;
  final double optionalMonthlySpending;
  final double monthlyGoalContribution;
  final List<ScenarioGoal> activeGoals;
  final List<ScenarioLedgerEntry> ledgerEntries;

  double get currentTotalExpenses {
    return monthlyCategoryExpenses.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
  }

  double get currentCashflow => monthlyIncome - currentTotalExpenses;
}

@immutable
class ScenarioInput {
  const ScenarioInput({
    this.selectedPreset,
    required this.incomeMultiplier,
    required this.recurringExpenseMultiplier,
    required this.optionalSpendingMultiplier,
    required this.savingsRateDelta,
    required this.riskTolerance,
    required this.goalContributionMultiplier,
    required this.categoryAdjustments,
    required this.enabledRiskEvents,
    required this.timelineMonths,
  });

  final ScenarioPresetType? selectedPreset;
  final double incomeMultiplier;
  final double recurringExpenseMultiplier;
  final double optionalSpendingMultiplier;
  final double savingsRateDelta;
  final double riskTolerance;
  final double goalContributionMultiplier;
  final Map<ScenarioCategory, ScenarioCategoryAdjustment> categoryAdjustments;
  final Set<ScenarioRiskEventType> enabledRiskEvents;
  final int timelineMonths;

  factory ScenarioInput.initial() {
    return const ScenarioInput(
      selectedPreset: null,
      incomeMultiplier: 1,
      recurringExpenseMultiplier: 1,
      optionalSpendingMultiplier: 1,
      savingsRateDelta: 0,
      riskTolerance: 0.5,
      goalContributionMultiplier: 1,
      categoryAdjustments: <ScenarioCategory, ScenarioCategoryAdjustment>{},
      enabledRiskEvents: <ScenarioRiskEventType>{},
      timelineMonths: 3,
    );
  }

  ScenarioInput copyWith({
    ScenarioPresetType? selectedPreset,
    bool clearPreset = false,
    double? incomeMultiplier,
    double? recurringExpenseMultiplier,
    double? optionalSpendingMultiplier,
    double? savingsRateDelta,
    double? riskTolerance,
    double? goalContributionMultiplier,
    Map<ScenarioCategory, ScenarioCategoryAdjustment>? categoryAdjustments,
    Set<ScenarioRiskEventType>? enabledRiskEvents,
    int? timelineMonths,
  }) {
    return ScenarioInput(
      selectedPreset:
          clearPreset ? null : (selectedPreset ?? this.selectedPreset),
      incomeMultiplier: incomeMultiplier ?? this.incomeMultiplier,
      recurringExpenseMultiplier:
          recurringExpenseMultiplier ?? this.recurringExpenseMultiplier,
      optionalSpendingMultiplier:
          optionalSpendingMultiplier ?? this.optionalSpendingMultiplier,
      savingsRateDelta: savingsRateDelta ?? this.savingsRateDelta,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      goalContributionMultiplier:
          goalContributionMultiplier ?? this.goalContributionMultiplier,
      categoryAdjustments: categoryAdjustments ?? this.categoryAdjustments,
      enabledRiskEvents: enabledRiskEvents ?? this.enabledRiskEvents,
      timelineMonths: timelineMonths ?? this.timelineMonths,
    );
  }
}

@immutable
class ScenarioTimelinePoint {
  const ScenarioTimelinePoint({
    required this.months,
    required this.projectedSurplusOrDeficit,
    required this.savingsGrowth,
    required this.emergencyRunwayDays,
    required this.debtPressure,
    required this.recurringBurden,
  });

  final int months;
  final double projectedSurplusOrDeficit;
  final double savingsGrowth;
  final int emergencyRunwayDays;
  final double debtPressure;
  final double recurringBurden;
}

@immutable
class ScenarioComparison {
  const ScenarioComparison({
    required this.currentMonthlyCashflow,
    required this.simulatedMonthlyCashflow,
    required this.currentSavingsRate,
    required this.simulatedSavingsRate,
    required this.currentSubscriptionBurden,
    required this.simulatedSubscriptionBurden,
    required this.currentRecurringObligations,
    required this.simulatedRecurringObligations,
    required this.currentEmergencyRunwayDays,
    required this.simulatedEmergencyRunwayDays,
    required this.currentHealthScore,
    required this.simulatedHealthScore,
  });

  final double currentMonthlyCashflow;
  final double simulatedMonthlyCashflow;
  final double currentSavingsRate;
  final double simulatedSavingsRate;
  final double currentSubscriptionBurden;
  final double simulatedSubscriptionBurden;
  final double currentRecurringObligations;
  final double simulatedRecurringObligations;
  final int currentEmergencyRunwayDays;
  final int simulatedEmergencyRunwayDays;
  final int currentHealthScore;
  final int simulatedHealthScore;
}

@immutable
class FinancialStressScore {
  const FinancialStressScore({
    required this.score,
    required this.status,
    required this.financialPressure,
    required this.burnRateRisk,
    required this.obligationBurden,
    required this.cashflowResilience,
  });

  final int score;
  final FinancialStressState status;
  final double financialPressure;
  final double burnRateRisk;
  final double obligationBurden;
  final double cashflowResilience;
}

@immutable
class EmergencyRunwayResult {
  const EmergencyRunwayResult({
    required this.runwayDays,
    required this.monthsCovered,
    required this.withIncomeLossDays,
    required this.withUnexpectedExpenseDays,
  });

  final int runwayDays;
  final double monthsCovered;
  final int withIncomeLossDays;
  final int withUnexpectedExpenseDays;
}

@immutable
class ScenarioRecommendation {
  const ScenarioRecommendation({
    required this.title,
    required this.reason,
    required this.suggestedAction,
    required this.impactValue,
    required this.actionType,
  });

  final String title;
  final String reason;
  final String suggestedAction;
  final double impactValue;
  final ScenarioActionType actionType;
}

@immutable
class GoalForecastResult {
  const GoalForecastResult({
    required this.goalId,
    required this.goalTitle,
    required this.currentEstimatedCompletion,
    required this.simulatedEstimatedCompletion,
    required this.currentMonthsRemaining,
    required this.simulatedMonthsRemaining,
    required this.monthsSavedOrDelayed,
    required this.requiredMonthlyContribution,
  });

  final String goalId;
  final String goalTitle;
  final DateTime? currentEstimatedCompletion;
  final DateTime? simulatedEstimatedCompletion;
  final int? currentMonthsRemaining;
  final int? simulatedMonthsRemaining;
  final int monthsSavedOrDelayed;
  final double requiredMonthlyContribution;
}

@immutable
class ProbabilityForecast {
  const ProbabilityForecast({
    required this.nextMonthDeficitLikelihood,
    required this.goalReachLikelihood,
    required this.recurringShortfallRisk,
  });

  final double nextMonthDeficitLikelihood;
  final double goalReachLikelihood;
  final double recurringShortfallRisk;
}

@immutable
class BehavioralAnalysisResult {
  const BehavioralAnalysisResult({
    required this.overspendingCategories,
    required this.inactiveSubscriptionSignals,
    required this.weekendSpendingRatio,
    required this.recurringGrowthWarning,
    required this.goalBehindWarning,
    required this.nudges,
  });

  final List<ScenarioCategory> overspendingCategories;
  final int inactiveSubscriptionSignals;
  final double weekendSpendingRatio;
  final bool recurringGrowthWarning;
  final bool goalBehindWarning;
  final List<String> nudges;
}

@immutable
class ScenarioResult {
  const ScenarioResult({
    required this.currencyCode,
    required this.categoryAdjustments,
    required this.timeline,
    required this.comparison,
    required this.stressScore,
    required this.emergencyRunway,
    required this.recommendations,
    required this.riskEvents,
    required this.goalForecasts,
    required this.probabilities,
    required this.behavioralAnalysis,
  });

  final String currencyCode;
  final List<ScenarioCategoryAdjustment> categoryAdjustments;
  final List<ScenarioTimelinePoint> timeline;
  final ScenarioComparison comparison;
  final FinancialStressScore stressScore;
  final EmergencyRunwayResult emergencyRunway;
  final List<ScenarioRecommendation> recommendations;
  final List<ScenarioRiskEvent> riskEvents;
  final List<GoalForecastResult> goalForecasts;
  final ProbabilityForecast probabilities;
  final BehavioralAnalysisResult behavioralAnalysis;
}

@immutable
class ScenarioComputation {
  const ScenarioComputation({
    required this.simulatedMonthlyIncome,
    required this.simulatedCategoryExpenses,
    required this.simulatedMonthlySavingsContribution,
    required this.categoryAdjustments,
    required this.simulatedMonthlyCashflow,
    required this.currentMonthlyCashflow,
    required this.simulatedRecurringObligations,
    required this.currentRecurringObligations,
    required this.simulatedSubscriptionBurden,
    required this.currentSubscriptionBurden,
    required this.simulatedSavingsRate,
    required this.currentSavingsRate,
  });

  final double simulatedMonthlyIncome;
  final Map<ScenarioCategory, double> simulatedCategoryExpenses;
  final double simulatedMonthlySavingsContribution;
  final List<ScenarioCategoryAdjustment> categoryAdjustments;
  final double simulatedMonthlyCashflow;
  final double currentMonthlyCashflow;
  final double simulatedRecurringObligations;
  final double currentRecurringObligations;
  final double simulatedSubscriptionBurden;
  final double currentSubscriptionBurden;
  final double simulatedSavingsRate;
  final double currentSavingsRate;
}

Map<ScenarioCategory, double> defaultScenarioCategories() {
  return {
    for (final category in ScenarioCategory.values) category: 0,
  };
}

ScenarioCategory mapCategoryName(String input) {
  final normalized = input.trim().toLowerCase();
  if (normalized.contains('rent') || normalized.contains('housing')) {
    return ScenarioCategory.housing;
  }
  if (normalized.contains('food') ||
      normalized.contains('grocery') ||
      normalized.contains('meal')) {
    return ScenarioCategory.food;
  }
  if (normalized.contains('transport') ||
      normalized.contains('fuel') ||
      normalized.contains('taxi') ||
      normalized.contains('uber')) {
    return ScenarioCategory.transport;
  }
  if (normalized.contains('subscription') || normalized.contains('stream')) {
    return ScenarioCategory.subscriptions;
  }
  if (normalized.contains('movie') ||
      normalized.contains('entertainment') ||
      normalized.contains('fun')) {
    return ScenarioCategory.entertainment;
  }
  if (normalized.contains('family') || normalized.contains('child')) {
    return ScenarioCategory.family;
  }
  if (normalized.contains('school') || normalized.contains('education')) {
    return ScenarioCategory.education;
  }
  if (normalized.contains('emergency') || normalized.contains('medical')) {
    return ScenarioCategory.emergency;
  }
  if (normalized.contains('debt') ||
      normalized.contains('loan') ||
      normalized.contains('credit')) {
    return ScenarioCategory.debt;
  }
  if (normalized.contains('saving')) {
    return ScenarioCategory.savings;
  }
  return ScenarioCategory.entertainment;
}
