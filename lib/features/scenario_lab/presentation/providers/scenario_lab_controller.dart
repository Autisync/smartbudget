import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/models/tables.dart'
    show BillingCycle, TransactionRecurrence, TransactionType;
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/features/scenario_lab/engines/behavioral_analysis_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/forecast_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/recommendation_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/risk_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/scenario_engine.dart';
import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';

final scenarioLabBaseDataProvider =
    FutureProvider<ScenarioBaseData>((ref) async {
  final appCurrency = ref.watch(appCurrencyControllerProvider);
  final transactions = await ref.watch(transactionListProvider().future);
  final subscriptions = await ref.watch(subscriptionListProvider.future);
  final goals = await ref.watch(savingsGoalListProvider.future);

  final now = DateTime.now();
  final last90Days = now.subtract(const Duration(days: 90));
  final last365Days = now.subtract(const Duration(days: 365));

  final tx90 = transactions.where((tx) => tx.date.isAfter(last90Days)).toList();
  final tx365 =
      transactions.where((tx) => tx.date.isAfter(last365Days)).toList();

  final incomeMonthly = _monthlyIncome(tx90);
  final categoryMonthly = _monthlyCategoryExpenses(tx90, subscriptions);
  final recurringExpenses = _monthlyRecurringExpenses(tx90, subscriptions);

  final optional = (categoryMonthly[ScenarioCategory.entertainment] ?? 0) +
      (categoryMonthly[ScenarioCategory.subscriptions] ?? 0) * 0.4;

  final savingsContribution = math.max(
    categoryMonthly[ScenarioCategory.savings] ?? 0,
    math.max(
            0,
            incomeMonthly -
                categoryMonthly.values.fold<double>(0, (s, v) => s + v)) *
        0.2,
  );

  final goalModels = goals
      .map(
        (goal) => ScenarioGoal(
          id: goal.id,
          title: goal.title,
          targetAmount: goal.targetAmount,
          savedAmount: goal.savedAmount,
          createdAt: goal.createdAt ?? now,
        ),
      )
      .toList(growable: false);

  final ledgerEntries = tx365
      .where((tx) => tx.type != TransactionType.transfer)
      .map(
        (tx) => ScenarioLedgerEntry(
          amount: tx.amount,
          isIncome: tx.isIncome,
          isRecurring: tx.isRecurring,
          category: mapCategoryName(tx.category),
          date: tx.date,
        ),
      )
      .toList(growable: false);

  final savingsBalance =
      goalModels.fold<double>(0, (sum, g) => sum + g.savedAmount);

  return ScenarioBaseData(
    currencyCode: appCurrency,
    monthlyIncome: incomeMonthly,
    monthlyRecurringExpenses: recurringExpenses,
    monthlyCategoryExpenses: categoryMonthly,
    currentSavingsBalance: savingsBalance,
    optionalMonthlySpending: optional,
    monthlyGoalContribution: savingsContribution,
    activeGoals: goalModels,
    ledgerEntries: ledgerEntries,
  );
});

class ScenarioLabController extends Notifier<ScenarioInput> {
  @override
  ScenarioInput build() => ScenarioInput.initial();

  void applyPreset(ScenarioBaseData baseData, ScenarioPresetType presetType) {
    const engine = ScenarioEngine();
    state = engine.applyPreset(
      baseData: baseData,
      currentInput: state,
      presetType: presetType,
    );
  }

  void setTimelineMonths(int months) {
    state = state.copyWith(timelineMonths: months);
  }

  void setCategoryAmount(
    ScenarioCategory category,
    double currentMonthlyAmount,
    double simulatedMonthlyAmount,
  ) {
    final nextAdjustments =
        Map<ScenarioCategory, ScenarioCategoryAdjustment>.from(
      state.categoryAdjustments,
    );
    nextAdjustments[category] = ScenarioCategoryAdjustment(
      category: category,
      currentMonthlyAmount: currentMonthlyAmount,
      simulatedMonthlyAmount: simulatedMonthlyAmount,
    );
    state = state.copyWith(
      categoryAdjustments: nextAdjustments,
      clearPreset: true,
    );
  }

  void toggleRiskEvent(ScenarioRiskEventType type) {
    final next = Set<ScenarioRiskEventType>.from(state.enabledRiskEvents);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    state = state.copyWith(enabledRiskEvents: next);
  }

  void resetToCurrent(ScenarioBaseData baseData) {
    final seeded = <ScenarioCategory, ScenarioCategoryAdjustment>{};
    for (final category in ScenarioCategory.values) {
      final amount = baseData.monthlyCategoryExpenses[category] ?? 0;
      seeded[category] = ScenarioCategoryAdjustment(
        category: category,
        currentMonthlyAmount: amount,
        simulatedMonthlyAmount: amount,
      );
    }
    state = ScenarioInput.initial().copyWith(categoryAdjustments: seeded);
  }
}

final scenarioLabControllerProvider =
    NotifierProvider<ScenarioLabController, ScenarioInput>(
  ScenarioLabController.new,
);

final scenarioLabResultProvider = Provider<AsyncValue<ScenarioResult>>((ref) {
  final baseAsync = ref.watch(scenarioLabBaseDataProvider);
  final input = ref.watch(scenarioLabControllerProvider);

  return baseAsync.whenData((baseData) {
    const scenarioEngine = ScenarioEngine();
    const forecastEngine = ForecastEngine();
    const recommendationEngine = RecommendationEngine();
    const riskEngine = RiskEngine();
    const behavioralEngine = BehavioralAnalysisEngine();

    final computation = scenarioEngine.simulate(
      baseData: baseData,
      input: input,
    );

    final riskEvents = riskEngine.buildRiskEvents(input.enabledRiskEvents);
    final riskAdjusted = riskEngine.applyRiskEvents(
      monthlyIncome: computation.simulatedMonthlyIncome,
      monthlyExpenses: computation.simulatedCategoryExpenses.values
          .fold<double>(0, (sum, amount) => sum + amount),
      events: riskEvents,
    );

    final runway = riskEngine.computeEmergencyRunway(
      liquidBuffer: baseData.currentSavingsBalance,
      monthlyObligations: computation.simulatedRecurringObligations,
      monthlyIncome: riskAdjusted.income,
      events: riskEvents,
    );

    final stress = riskEngine.computeStressScore(
      monthlyIncome: riskAdjusted.income,
      monthlyExpenses: riskAdjusted.expenses,
      recurringObligations: computation.simulatedRecurringObligations,
      runway: runway,
    );

    final goalForecasts = forecastEngine.buildGoalForecasts(
      goals: baseData.activeGoals,
      currentMonthlyContribution: baseData.monthlyGoalContribution,
      simulatedMonthlyContribution:
          computation.simulatedMonthlySavingsContribution,
      now: DateTime.now(),
    );

    final recurringBurden = riskAdjusted.income <= 0
        ? 1.0
        : (computation.simulatedRecurringObligations / riskAdjusted.income)
            .clamp(0, 2)
            .toDouble();

    final probabilities = riskEngine.computeProbabilities(
      monthlyCashflow: riskAdjusted.income - riskAdjusted.expenses,
      stress: stress,
      goals: goalForecasts,
      recurringBurden: recurringBurden,
    );

    final timeline = forecastEngine.buildTimeline(
      monthlyCashflow: riskAdjusted.income - riskAdjusted.expenses,
      monthlySavingsContribution:
          computation.simulatedMonthlySavingsContribution,
      emergencyRunway: runway,
      debtPressure: baseData.monthlyIncome <= 0
          ? 1.0
          : ((computation.simulatedCategoryExpenses[ScenarioCategory.debt] ??
                      0) /
                  baseData.monthlyIncome)
              .clamp(0, 2)
              .toDouble(),
      recurringBurden: recurringBurden,
    );

    final behavioral = behavioralEngine.analyze(
      baseData: baseData,
      computation: computation,
      goalForecasts: goalForecasts,
    );

    final recommendations = recommendationEngine.build(
      baseData: baseData,
      computation: computation,
      stress: stress,
      runway: runway,
      probabilities: probabilities,
    );

    final currentRunway = riskEngine.computeEmergencyRunway(
      liquidBuffer: baseData.currentSavingsBalance,
      monthlyObligations: computation.currentRecurringObligations,
      monthlyIncome: baseData.monthlyIncome,
      events: const <ScenarioRiskEvent>[],
    );

    final currentStress = riskEngine.computeStressScore(
      monthlyIncome: baseData.monthlyIncome,
      monthlyExpenses: baseData.monthlyCategoryExpenses.values
          .fold<double>(0, (sum, value) => sum + value),
      recurringObligations: computation.currentRecurringObligations,
      runway: currentRunway,
    );

    final comparison = ScenarioComparison(
      currentMonthlyCashflow: computation.currentMonthlyCashflow,
      simulatedMonthlyCashflow: riskAdjusted.income - riskAdjusted.expenses,
      currentSavingsRate: computation.currentSavingsRate,
      simulatedSavingsRate: computation.simulatedSavingsRate,
      currentSubscriptionBurden: computation.currentSubscriptionBurden,
      simulatedSubscriptionBurden: computation.simulatedSubscriptionBurden,
      currentRecurringObligations: computation.currentRecurringObligations,
      simulatedRecurringObligations: computation.simulatedRecurringObligations,
      currentEmergencyRunwayDays: currentRunway.runwayDays,
      simulatedEmergencyRunwayDays: runway.runwayDays,
      currentHealthScore: 100 - currentStress.score,
      simulatedHealthScore: 100 - stress.score,
    );

    return ScenarioResult(
      currencyCode: baseData.currencyCode,
      categoryAdjustments: computation.categoryAdjustments,
      timeline: timeline,
      comparison: comparison,
      stressScore: stress,
      emergencyRunway: runway,
      recommendations: recommendations,
      riskEvents: riskEvents,
      goalForecasts: goalForecasts,
      probabilities: probabilities,
      behavioralAnalysis: behavioral,
    );
  });
});

double _monthlyIncome(List<Transaction> transactions) {
  final income = transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold<double>(0, (sum, tx) => sum + tx.amount);
  return (income / 3).clamp(0, double.infinity).toDouble();
}

Map<ScenarioCategory, double> _monthlyCategoryExpenses(
  List<Transaction> transactions,
  List<Subscription> subscriptions,
) {
  final map = defaultScenarioCategories();

  for (final tx in transactions) {
    if (tx.type != TransactionType.expense) continue;
    final category = mapCategoryName(tx.category);
    map[category] = (map[category] ?? 0) + tx.amount / 3;
  }

  final activeSubscriptions = subscriptions.where((sub) => sub.isActive);
  for (final sub in activeSubscriptions) {
    map[ScenarioCategory.subscriptions] =
        (map[ScenarioCategory.subscriptions] ?? 0) + sub.monthlyCost;
  }

  return map;
}

double _monthlyRecurringExpenses(
  List<Transaction> transactions,
  List<Subscription> subscriptions,
) {
  final recurringTx =
      transactions.where((tx) => tx.isRecurring && tx.isExpense);
  final txRecurringTotal = recurringTx.fold<double>(0, (sum, tx) {
    return sum + _monthlyAmountForRecurrence(tx.amount, tx.recurrence);
  });
  final subTotal = subscriptions
      .where((sub) => sub.isActive)
      .fold<double>(0, (sum, sub) => sum + sub.monthlyCost);
  return txRecurringTotal + subTotal;
}

double _monthlyAmountForRecurrence(
    double amount, TransactionRecurrence recurrence) {
  switch (recurrence) {
    case TransactionRecurrence.daily:
      return amount * 30.4;
    case TransactionRecurrence.weekly:
      return amount * 4.33;
    case TransactionRecurrence.monthly:
      return amount;
    case TransactionRecurrence.yearly:
      return amount / 12;
    case TransactionRecurrence.none:
      return 0;
  }
}

double monthlyAmountForBillingCycle(double amount, BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return amount * 4.33;
    case BillingCycle.monthly:
      return amount;
    case BillingCycle.quarterly:
      return amount / 3;
    case BillingCycle.yearly:
      return amount / 12;
  }
}

ScenarioBaseData scenarioBaseDataForTesting({
  required String currencyCode,
  required double monthlyIncome,
  required Map<ScenarioCategory, double> monthlyCategoryExpenses,
  required double currentSavingsBalance,
  required double monthlyGoalContribution,
  List<ScenarioGoal> activeGoals = const [],
  List<ScenarioLedgerEntry> ledgerEntries = const [],
}) {
  return ScenarioBaseData(
    currencyCode: currencyCode,
    monthlyIncome: monthlyIncome,
    monthlyRecurringExpenses: monthlyCategoryExpenses.entries
        .where((entry) =>
            entry.key == ScenarioCategory.housing ||
            entry.key == ScenarioCategory.transport ||
            entry.key == ScenarioCategory.subscriptions ||
            entry.key == ScenarioCategory.debt ||
            entry.key == ScenarioCategory.emergency)
        .fold<double>(0, (sum, entry) => sum + entry.value),
    monthlyCategoryExpenses: monthlyCategoryExpenses,
    currentSavingsBalance: currentSavingsBalance,
    optionalMonthlySpending:
        (monthlyCategoryExpenses[ScenarioCategory.entertainment] ?? 0) +
            (monthlyCategoryExpenses[ScenarioCategory.subscriptions] ?? 0) *
                0.4,
    monthlyGoalContribution: monthlyGoalContribution,
    activeGoals: activeGoals,
    ledgerEntries: ledgerEntries,
  );
}
