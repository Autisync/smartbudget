import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';

part 'financial_health_provider.g.dart';

class FinancialHealthSnapshot {
  const FinancialHealthSnapshot({
    required this.totalScore,
    required this.budgetDisciplineScore,
    required this.savingsMomentumScore,
    required this.budgetUtilizationScore,
    required this.recommendations,
    required this.activeBudgets,
    required this.activeGoals,
  });

  final double totalScore;
  final double budgetDisciplineScore;
  final double savingsMomentumScore;
  final double budgetUtilizationScore;
  final List<String> recommendations;
  final int activeBudgets;
  final int activeGoals;
}

class FinancialHealthTrendPoint {
  const FinancialHealthTrendPoint({
    required this.weekStart,
    required this.score,
    required this.deltaFromPrevious,
    required this.note,
  });

  final DateTime weekStart;
  final double score;
  final double deltaFromPrevious;
  final String note;
}

class FinancialHealthTrendSnapshot {
  const FinancialHealthTrendSnapshot({
    required this.points,
    required this.biggestGain,
    required this.biggestDrop,
    required this.overallDelta,
  });

  final List<FinancialHealthTrendPoint> points;
  final FinancialHealthTrendPoint? biggestGain;
  final FinancialHealthTrendPoint? biggestDrop;
  final double overallDelta;
}

@riverpod
Future<FinancialHealthSnapshot> financialHealth(FinancialHealthRef ref) async {
  final budgets = await ref.watch(budgetListProvider.future);
  final goals = await ref.watch(savingsGoalListProvider.future);
  final alerts = await ref.watch(budgetAlertsProvider.future);

  final budgetDisciplineScore = _computeBudgetDisciplineScore(alerts);
  final savingsMomentumScore = _computeSavingsMomentumScore(goals);
  final budgetUtilizationScore =
      await _computeBudgetUtilizationScore(ref, budgets);

  final totalScore = ((budgetDisciplineScore * 0.5) +
          (savingsMomentumScore * 0.35) +
          (budgetUtilizationScore * 0.15))
      .clamp(0, 100)
      .toDouble();

  final recommendations = <String>[];

  if (alerts.any((a) => a.overLimit)) {
    recommendations.add(
        'Reduce discretionary spending in categories that already exceeded budget.');
  }
  if (alerts.where((a) => a.nearLimit && !a.overLimit).isNotEmpty) {
    recommendations.add('Rebalance near-limit budgets before the period ends.');
  }

  final behindGoals = _countBehindGoals(goals);
  if (behindGoals > 0) {
    recommendations.add(
        'Increase monthly contributions for $behindGoals goal(s) behind schedule.');
  }

  if (goals.where((g) => g.autoAllocate).isEmpty && goals.isNotEmpty) {
    recommendations.add(
        'Enable auto-allocation for at least one savings goal to improve consistency.');
  }

  if (recommendations.isEmpty) {
    recommendations
        .add('Keep your current pace and review your health score weekly.');
  }

  return FinancialHealthSnapshot(
    totalScore: totalScore,
    budgetDisciplineScore: budgetDisciplineScore,
    savingsMomentumScore: savingsMomentumScore,
    budgetUtilizationScore: budgetUtilizationScore,
    recommendations: recommendations,
    activeBudgets: budgets.length,
    activeGoals: goals.length,
  );
}

@riverpod
Future<FinancialHealthTrendSnapshot> financialHealthHistory(
  FinancialHealthHistoryRef ref, {
  int weeks = 8,
}) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final goals = await ref.watch(savingsGoalListProvider.future);
  final alerts = await ref.watch(budgetAlertsProvider.future);
  final transactions = await repo.getTransactions();

  final now = DateTime.now();
  final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
  final points = <FinancialHealthTrendPoint>[];

  double previousScore = 0;

  for (var i = weeks - 1; i >= 0; i--) {
    final weekStart = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    ).subtract(Duration(days: i * 7));
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23));

    final weeklyTx = transactions
        .where(
            (tx) => !tx.date.isBefore(weekStart) && !tx.date.isAfter(weekEnd))
        .toList();

    final weeklyIncome = weeklyTx
        .where((tx) => tx.isIncome)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final weeklyExpense = weeklyTx
        .where((tx) => tx.isExpense)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final cashflowRatio = weeklyIncome <= 0
        ? 0.5
        : ((weeklyIncome - weeklyExpense) / weeklyIncome).clamp(-1.0, 1.0);

    final budgetPressure = alerts.isEmpty
        ? 0.0
        : alerts.map((a) => a.progress).fold<double>(0.0, (sum, p) => sum + p) /
            alerts.length;

    final savingsProgress = goals.isEmpty
        ? 0.55
        : goals
                .map((g) => g.targetAmount > 0
                    ? (g.savedAmount / g.targetAmount).clamp(0.0, 1.0)
                    : 0.0)
                .fold<double>(0.0, (sum, p) => sum + p) /
            goals.length;

    final score = ((cashflowRatio * 45) +
            50 +
            (savingsProgress * 25) -
            (budgetPressure * 20))
        .clamp(0, 100)
        .toDouble();

    final delta = points.isEmpty ? 0.0 : score - previousScore;
    previousScore = score;

    points.add(
      FinancialHealthTrendPoint(
        weekStart: weekStart,
        score: score,
        deltaFromPrevious: delta,
        note: _weeklyNote(
          income: weeklyIncome,
          expense: weeklyExpense,
          delta: delta,
        ),
      ),
    );
  }

  FinancialHealthTrendPoint? biggestGain;
  FinancialHealthTrendPoint? biggestDrop;
  for (final point in points.skip(1)) {
    if (biggestGain == null ||
        point.deltaFromPrevious > biggestGain.deltaFromPrevious) {
      biggestGain = point;
    }
    if (biggestDrop == null ||
        point.deltaFromPrevious < biggestDrop.deltaFromPrevious) {
      biggestDrop = point;
    }
  }

  final overallDelta =
      points.length < 2 ? 0.0 : points.last.score - points.first.score;

  return FinancialHealthTrendSnapshot(
    points: points,
    biggestGain: biggestGain,
    biggestDrop: biggestDrop,
    overallDelta: overallDelta,
  );
}

String _weeklyNote({
  required double income,
  required double expense,
  required double delta,
}) {
  if (income <= 0 && expense > 0) {
    return 'No income recorded this week; spending pressure increased.';
  }
  if (delta >= 4) {
    return 'Health improved with stronger weekly cashflow balance.';
  }
  if (delta <= -4) {
    return 'Health dropped this week due to higher spending pressure.';
  }
  return 'Stable week with limited change in financial behavior.';
}

double _computeBudgetDisciplineScore(List<dynamic> alerts) {
  if (alerts.isEmpty) return 100;

  final overLimitCount = alerts.where((a) => a.overLimit == true).length;
  final nearLimitCount =
      alerts.where((a) => a.nearLimit == true && a.overLimit != true).length;
  final penalty = (overLimitCount * 22) + (nearLimitCount * 10);
  return (100 - penalty).clamp(0, 100).toDouble();
}

double _computeSavingsMomentumScore(List<SavingsGoal> goals) {
  if (goals.isEmpty) return 55;

  final averageProgress = goals
          .map((g) => g.targetAmount > 0
              ? (g.savedAmount / g.targetAmount).clamp(0.0, 1.0)
              : 0.0)
          .fold<double>(0.0, (sum, value) => sum + value) /
      goals.length;

  final behindCount = _countBehindGoals(goals);
  final behindPenalty = (behindCount * 8).clamp(0, 30);

  return ((averageProgress * 100) - behindPenalty).clamp(0, 100).toDouble();
}

int _countBehindGoals(List<SavingsGoal> goals) {
  final now = DateTime.now();
  var count = 0;

  for (final goal in goals) {
    if (goal.deadline == null) continue;

    final createdAt = goal.createdAt ?? now;
    final totalDays = goal.deadline!.difference(createdAt).inDays;
    final elapsedDays = now.difference(createdAt).inDays;

    if (totalDays <= 0) continue;

    final expectedProgress = (elapsedDays / totalDays).clamp(0.0, 1.0);
    final actualProgress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    if (actualProgress + 0.05 < expectedProgress) {
      count++;
    }
  }

  return count;
}

Future<double> _computeBudgetUtilizationScore(
  FinancialHealthRef ref,
  List<Budget> budgets,
) async {
  if (budgets.isEmpty) return 70;

  var total = 0.0;
  var count = 0;

  for (final budget in budgets) {
    final spent = await ref.watch(budgetSpendingProvider(
      category: budget.category,
      start: budget.startDate,
      end: budget.endDate ?? DateTime.now(),
    ).future);

    final ratio = budget.limitAmount > 0 ? spent / budget.limitAmount : 0.0;

    if (ratio <= 0.7) {
      total += 100;
    } else if (ratio <= 0.9) {
      total += 78;
    } else if (ratio <= 1.0) {
      total += 58;
    } else {
      total += 25;
    }
    count++;
  }

  return count == 0 ? 70 : (total / count).clamp(0, 100).toDouble();
}
