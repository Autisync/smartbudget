import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/features/scenario_lab/engines/behavioral_analysis_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/forecast_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/recommendation_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/risk_engine.dart';
import 'package:smartbudget/features/scenario_lab/engines/scenario_engine.dart';
import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';
import 'package:smartbudget/features/scenario_lab/presentation/providers/scenario_lab_controller.dart';

void main() {
  const scenarioEngine = ScenarioEngine();
  const forecastEngine = ForecastEngine();
  const riskEngine = RiskEngine();
  const recommendationEngine = RecommendationEngine();
  const behavioralEngine = BehavioralAnalysisEngine();

  ScenarioBaseData baseData() {
    return scenarioBaseDataForTesting(
      currencyCode: 'Kz',
      monthlyIncome: 3000,
      monthlyCategoryExpenses: {
        ScenarioCategory.housing: 900,
        ScenarioCategory.food: 450,
        ScenarioCategory.transport: 260,
        ScenarioCategory.subscriptions: 180,
        ScenarioCategory.entertainment: 200,
        ScenarioCategory.family: 220,
        ScenarioCategory.education: 150,
        ScenarioCategory.emergency: 120,
        ScenarioCategory.debt: 300,
        ScenarioCategory.savings: 280,
      },
      currentSavingsBalance: 2200,
      monthlyGoalContribution: 280,
      activeGoals: [
        ScenarioGoal(
          id: 'goal-1',
          title: 'Emergency Fund',
          targetAmount: 12000,
          savedAmount: 2200,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
  }

  test('scenario presets apply correct adjustments', () {
    final input = scenarioEngine.applyPreset(
      baseData: baseData(),
      currentInput: ScenarioInput.initial(),
      presetType: ScenarioPresetType.survivalMode,
    );

    expect(input.selectedPreset, ScenarioPresetType.survivalMode);
    expect(input.incomeMultiplier, lessThan(1));
    expect(
        input.categoryAdjustments[ScenarioCategory.entertainment]!
            .simulatedMonthlyAmount,
        lessThan(input.categoryAdjustments[ScenarioCategory.entertainment]!
            .currentMonthlyAmount));
  });

  test('category adjustments update monthly cashflow correctly', () {
    final input = ScenarioInput.initial().copyWith(
      categoryAdjustments: {
        ScenarioCategory.entertainment: const ScenarioCategoryAdjustment(
          category: ScenarioCategory.entertainment,
          currentMonthlyAmount: 200,
          simulatedMonthlyAmount: 100,
        ),
      },
    );

    final result = scenarioEngine.simulate(baseData: baseData(), input: input);

    expect(result.simulatedMonthlyCashflow,
        greaterThan(result.currentMonthlyCashflow));
  });

  test('timeline forecast calculates 1/3/6/12 months', () {
    final timeline = forecastEngine.buildTimeline(
      monthlyCashflow: 200,
      monthlySavingsContribution: 150,
      emergencyRunway: const EmergencyRunwayResult(
        runwayDays: 90,
        monthsCovered: 3,
        withIncomeLossDays: 50,
        withUnexpectedExpenseDays: 70,
      ),
      debtPressure: 0.3,
      recurringBurden: 0.5,
    );

    expect(timeline.map((point) => point.months), [1, 3, 6, 12]);
    expect(timeline.last.projectedSurplusOrDeficit, 2400);
  });

  test('emergency runway handles zero income safely', () {
    final events =
        riskEngine.buildRiskEvents({ScenarioRiskEventType.incomeDrop20});
    final runway = riskEngine.computeEmergencyRunway(
      liquidBuffer: 1000,
      monthlyObligations: 500,
      monthlyIncome: 0,
      events: events,
    );

    expect(runway.runwayDays, greaterThanOrEqualTo(0));
  });

  test('emergency runway handles zero expenses safely', () {
    final runway = riskEngine.computeEmergencyRunway(
      liquidBuffer: 1000,
      monthlyObligations: 0,
      monthlyIncome: 1000,
      events: const [],
    );

    expect(runway.runwayDays, greaterThan(3000));
  });

  test('financial stress score returns expected ranges', () {
    final lowStress = riskEngine.computeStressScore(
      monthlyIncome: 4000,
      monthlyExpenses: 1800,
      recurringObligations: 1000,
      runway: const EmergencyRunwayResult(
        runwayDays: 200,
        monthsCovered: 7,
        withIncomeLossDays: 140,
        withUnexpectedExpenseDays: 180,
      ),
    );

    final highStress = riskEngine.computeStressScore(
      monthlyIncome: 1800,
      monthlyExpenses: 2600,
      recurringObligations: 2000,
      runway: const EmergencyRunwayResult(
        runwayDays: 18,
        monthsCovered: 0.6,
        withIncomeLossDays: 9,
        withUnexpectedExpenseDays: 12,
      ),
    );

    expect(
      lowStress.status,
      anyOf(FinancialStressState.low, FinancialStressState.moderate),
    );
    expect(highStress.status,
        anyOf(FinancialStressState.high, FinancialStressState.critical));
  });

  test('risk events modify projections correctly', () {
    final events = riskEngine.buildRiskEvents({
      ScenarioRiskEventType.incomeDrop20,
      ScenarioRiskEventType.rentIncrease,
    });

    final adjusted = riskEngine.applyRiskEvents(
      monthlyIncome: 3000,
      monthlyExpenses: 2000,
      events: events,
    );

    expect(adjusted.income, lessThan(3000));
    expect(adjusted.expenses, greaterThan(2000));
  });

  test('goal forecast calculates completion dates correctly', () {
    final goals = forecastEngine.buildGoalForecasts(
      goals: [
        ScenarioGoal(
          id: '1',
          title: 'Laptop',
          targetAmount: 200000,
          savedAmount: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      currentMonthlyContribution: 2600,
      simulatedMonthlyContribution: 4200,
      now: DateTime(2026, 5, 1),
    );

    expect(goals.first.currentMonthsRemaining,
        greaterThan(goals.first.simulatedMonthsRemaining!));
    expect(goals.first.monthsSavedOrDelayed, greaterThan(0));
  });

  test('recommendation engine ranks highest-impact first', () {
    final computation = scenarioEngine.simulate(
      baseData: baseData(),
      input: ScenarioInput.initial(),
    );

    final recs = recommendationEngine.build(
      baseData: baseData(),
      computation: computation,
      stress: const FinancialStressScore(
        score: 70,
        status: FinancialStressState.high,
        financialPressure: 20,
        burnRateRisk: 25,
        obligationBurden: 15,
        cashflowResilience: 10,
      ),
      runway: const EmergencyRunwayResult(
        runwayDays: 20,
        monthsCovered: 0.7,
        withIncomeLossDays: 8,
        withUnexpectedExpenseDays: 12,
      ),
      probabilities: const ProbabilityForecast(
        nextMonthDeficitLikelihood: 0.7,
        goalReachLikelihood: 0.3,
        recurringShortfallRisk: 0.7,
      ),
    );

    expect(recs, isNotEmpty);
    for (var i = 1; i < recs.length; i++) {
      expect(
          recs[i - 1].impactValue, greaterThanOrEqualTo(recs[i].impactValue));
    }
  });

  test('probability forecast returns expected risk ranges', () {
    final probabilities = riskEngine.computeProbabilities(
      monthlyCashflow: -400,
      stress: const FinancialStressScore(
        score: 85,
        status: FinancialStressState.critical,
        financialPressure: 32,
        burnRateRisk: 30,
        obligationBurden: 15,
        cashflowResilience: 4,
      ),
      goals: const [],
      recurringBurden: 0.85,
    );

    expect(probabilities.nextMonthDeficitLikelihood, inInclusiveRange(0, 1));
    expect(probabilities.goalReachLikelihood, inInclusiveRange(0, 1));
    expect(probabilities.recurringShortfallRisk, inInclusiveRange(0, 1));
  });

  test('no division-by-zero and negative balances are handled', () {
    final computation = scenarioEngine.simulate(
      baseData: scenarioBaseDataForTesting(
        currencyCode: 'Kz',
        monthlyIncome: 0,
        monthlyCategoryExpenses: {
          for (final category in ScenarioCategory.values) category: 100,
        },
        currentSavingsBalance: 0,
        monthlyGoalContribution: 0,
      ),
      input: ScenarioInput.initial(),
    );

    final stress = riskEngine.computeStressScore(
      monthlyIncome: 0,
      monthlyExpenses: 1000,
      recurringObligations: 600,
      runway: const EmergencyRunwayResult(
        runwayDays: 0,
        monthsCovered: 0,
        withIncomeLossDays: 0,
        withUnexpectedExpenseDays: 0,
      ),
    );

    expect(computation.simulatedMonthlyCashflow, lessThan(0));
    expect(stress.score, inInclusiveRange(0, 100));
  });

  test('engines remain deterministic for repeated runs', () {
    final input = ScenarioInput.initial();
    final a = scenarioEngine.simulate(baseData: baseData(), input: input);
    final b = scenarioEngine.simulate(baseData: baseData(), input: input);
    expect(a.simulatedMonthlyCashflow, b.simulatedMonthlyCashflow);
    expect(a.simulatedSavingsRate, b.simulatedSavingsRate);
  });

  test('repeated slider-like updates do not trigger unstable calculations', () {
    var input = ScenarioInput.initial();
    final start = Stopwatch()..start();
    for (var i = 0; i < 200; i++) {
      final amount = 50 + (i % 120).toDouble();
      input = input.copyWith(
        categoryAdjustments: {
          ScenarioCategory.food: ScenarioCategoryAdjustment(
            category: ScenarioCategory.food,
            currentMonthlyAmount: 450,
            simulatedMonthlyAmount: amount,
          ),
        },
      );
      scenarioEngine.simulate(baseData: baseData(), input: input);
    }
    start.stop();

    expect(start.elapsedMilliseconds, lessThan(400));
  });

  test('large dataset simulation remains fast for 1k and 10k entries', () {
    ScenarioBaseData buildLargeData(int count) {
      final ledger = List<ScenarioLedgerEntry>.generate(
        count,
        (i) => ScenarioLedgerEntry(
          amount: (i % 300 + 1).toDouble(),
          isIncome: i % 5 == 0,
          isRecurring: i % 3 == 0,
          category: ScenarioCategory.values[i % ScenarioCategory.values.length],
          date: DateTime(2026, 1, (i % 28) + 1),
        ),
      );

      return scenarioBaseDataForTesting(
        currencyCode: 'Kz',
        monthlyIncome: 10000,
        monthlyCategoryExpenses: {
          for (final category in ScenarioCategory.values) category: 300,
        },
        currentSavingsBalance: 8000,
        monthlyGoalContribution: 800,
        ledgerEntries: ledger,
      );
    }

    final data1k = buildLargeData(1000);
    final data10k = buildLargeData(10000);
    final input = ScenarioInput.initial();

    final sw1k = Stopwatch()..start();
    final comp1k = scenarioEngine.simulate(baseData: data1k, input: input);
    final goals1k = forecastEngine.buildGoalForecasts(
      goals: data1k.activeGoals,
      currentMonthlyContribution: 300,
      simulatedMonthlyContribution: 500,
      now: DateTime(2026, 1, 1),
    );
    behavioralEngine.analyze(
        baseData: data1k, computation: comp1k, goalForecasts: goals1k);
    sw1k.stop();

    final sw10k = Stopwatch()..start();
    final comp10k = scenarioEngine.simulate(baseData: data10k, input: input);
    final goals10k = forecastEngine.buildGoalForecasts(
      goals: data10k.activeGoals,
      currentMonthlyContribution: 300,
      simulatedMonthlyContribution: 500,
      now: DateTime(2026, 1, 1),
    );
    behavioralEngine.analyze(
        baseData: data10k, computation: comp10k, goalForecasts: goals10k);
    sw10k.stop();

    expect(sw1k.elapsedMilliseconds, lessThan(300));
    expect(sw10k.elapsedMilliseconds, lessThan(1600));
  });

  test('behavioral analysis identifies weekend patterns', () {
    final ledger = [
      ScenarioLedgerEntry(
        amount: 100,
        isIncome: false,
        isRecurring: false,
        category: ScenarioCategory.entertainment,
        date: DateTime(2026, 5, 2),
      ),
      ScenarioLedgerEntry(
        amount: 140,
        isIncome: false,
        isRecurring: false,
        category: ScenarioCategory.food,
        date: DateTime(2026, 5, 3),
      ),
      ScenarioLedgerEntry(
        amount: 80,
        isIncome: false,
        isRecurring: false,
        category: ScenarioCategory.food,
        date: DateTime(2026, 5, 5),
      ),
    ];

    final base = scenarioBaseDataForTesting(
      currencyCode: 'Kz',
      monthlyIncome: 3000,
      monthlyCategoryExpenses: {
        for (final category in ScenarioCategory.values) category: 100,
      },
      currentSavingsBalance: 500,
      monthlyGoalContribution: 100,
      ledgerEntries: ledger,
    );

    final comp =
        scenarioEngine.simulate(baseData: base, input: ScenarioInput.initial());
    final behavior = behavioralEngine.analyze(
      baseData: base,
      computation: comp,
      goalForecasts: const [],
    );

    expect(behavior.weekendSpendingRatio, greaterThan(0.5));
  });

  test('risk event list includes enabled states', () {
    final events = riskEngine.buildRiskEvents({
      ScenarioRiskEventType.incomeDrop20,
      ScenarioRiskEventType.delayedSalary,
    });

    final enabledCount = events.where((e) => e.enabled).length;
    expect(enabledCount, 2);
    expect(events.length, ScenarioRiskEventType.values.length);
  });

  test('scenario simulation scales with very large numbers', () {
    final base = scenarioBaseDataForTesting(
      currencyCode: 'Kz',
      monthlyIncome: 1e12,
      monthlyCategoryExpenses: {
        for (final category in ScenarioCategory.values) category: 1e11,
      },
      currentSavingsBalance: 1e12,
      monthlyGoalContribution: 1e10,
    );

    final sim =
        scenarioEngine.simulate(baseData: base, input: ScenarioInput.initial());
    expect(sim.simulatedMonthlyIncome.isFinite, true);
    expect(sim.simulatedMonthlyCashflow.isFinite, true);
    expect(sim.simulatedMonthlyCashflow, lessThan(base.monthlyIncome));
  });

  test('stability check across randomized category adjustments', () {
    final rand = math.Random(42);
    var input = ScenarioInput.initial();

    for (var i = 0; i < 200; i++) {
      final category =
          ScenarioCategory.values[rand.nextInt(ScenarioCategory.values.length)];
      final current = 100 + rand.nextInt(900).toDouble();
      final simulated = rand.nextDouble() * 1500;
      input = input.copyWith(
        categoryAdjustments: {
          category: ScenarioCategoryAdjustment(
            category: category,
            currentMonthlyAmount: current,
            simulatedMonthlyAmount: simulated,
          ),
        },
      );
      final result =
          scenarioEngine.simulate(baseData: baseData(), input: input);
      expect(result.simulatedMonthlyCashflow.isFinite, true);
    }
  });
}
