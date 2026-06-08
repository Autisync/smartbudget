import 'dart:math';

import 'package:smartbudget/data/models/tables.dart'
    show TransactionRecurrence, TransactionType;
import 'package:smartbudget/domain/entities/transaction.dart';

enum BurnRateStatus {
  healthy,
  watch,
  high,
  critical,
}

class BurnRateInsight {
  const BurnRateInsight({
    required this.monthlySpend,
    required this.averageDailySpend,
    required this.projectedMonthEndSpend,
    required this.daysRemaining,
    required this.safeDailySpend,
    required this.status,
    required this.hasData,
  });

  final double monthlySpend;
  final double averageDailySpend;
  final double projectedMonthEndSpend;
  final int daysRemaining;
  final double safeDailySpend;
  final BurnRateStatus status;
  final bool hasData;
}

class TransactionDecisionSnapshotData {
  const TransactionDecisionSnapshotData({
    required this.monthIncome,
    required this.monthExpense,
    required this.netFlow,
    required this.recurringCount,
    required this.topCategory,
    required this.message,
    required this.hasTransactions,
  });

  final double monthIncome;
  final double monthExpense;
  final double netFlow;
  final int recurringCount;
  final String? topCategory;
  final String message;
  final bool hasTransactions;
}

class BurnRateEngine {
  const BurnRateEngine();

  BurnRateInsight calculate({
    required List<Transaction> transactions,
    DateTime? now,
    double? monthlyBudgetLimit,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final monthStart = DateTime(effectiveNow.year, effectiveNow.month, 1);
    final monthEnd = DateTime(effectiveNow.year, effectiveNow.month + 1, 0);
    final daysInMonth = monthEnd.day;
    final elapsedDays = min(max(effectiveNow.day, 1), daysInMonth);
    final daysRemaining = max(daysInMonth - elapsedDays, 0);

    final monthExpenses = transactions
        .where((tx) =>
            tx.type == TransactionType.expense &&
            !tx.date.isBefore(monthStart) &&
            tx.date.year == effectiveNow.year &&
            tx.date.month == effectiveNow.month)
        .toList();

    if (monthExpenses.isEmpty) {
      return const BurnRateInsight(
        monthlySpend: 0,
        averageDailySpend: 0,
        projectedMonthEndSpend: 0,
        daysRemaining: 0,
        safeDailySpend: 0,
        status: BurnRateStatus.healthy,
        hasData: false,
      );
    }

    final monthlySpend =
        monthExpenses.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final averageDailySpend = monthlySpend / max(elapsedDays, 1);
    final projectedMonthEndSpend = averageDailySpend * daysInMonth;

    final budgetLimit = (monthlyBudgetLimit != null && monthlyBudgetLimit > 0)
        ? monthlyBudgetLimit
        : null;
    final safeDailySpend = budgetLimit == null || daysRemaining == 0
        ? 0.0
        : max<double>((budgetLimit - monthlySpend) / daysRemaining, 0);

    final status = _status(
      monthlySpend: monthlySpend,
      projectedMonthEndSpend: projectedMonthEndSpend,
      budgetLimit: budgetLimit,
      elapsedDays: elapsedDays,
    );

    return BurnRateInsight(
      monthlySpend: monthlySpend,
      averageDailySpend: averageDailySpend,
      projectedMonthEndSpend: projectedMonthEndSpend,
      daysRemaining: daysRemaining,
      safeDailySpend: safeDailySpend,
      status: status,
      hasData: true,
    );
  }

  BurnRateStatus _status({
    required double monthlySpend,
    required double projectedMonthEndSpend,
    required double? budgetLimit,
    required int elapsedDays,
  }) {
    if (budgetLimit != null && budgetLimit > 0) {
      final projectedRatio = projectedMonthEndSpend / budgetLimit;
      if (projectedRatio >= 1.2) return BurnRateStatus.critical;
      if (projectedRatio >= 1.0) return BurnRateStatus.high;
      if (projectedRatio >= 0.85) return BurnRateStatus.watch;
      return BurnRateStatus.healthy;
    }

    if (elapsedDays <= 3 && monthlySpend > 0) return BurnRateStatus.watch;
    if (projectedMonthEndSpend >= 3000) return BurnRateStatus.critical;
    if (projectedMonthEndSpend >= 2000) return BurnRateStatus.high;
    if (projectedMonthEndSpend >= 1000) return BurnRateStatus.watch;
    return BurnRateStatus.healthy;
  }
}

class TransactionInsightEngine {
  const TransactionInsightEngine();

  TransactionDecisionSnapshotData build({
    required List<Transaction> transactions,
    DateTime? now,
  }) {
    if (transactions.isEmpty) {
      return const TransactionDecisionSnapshotData(
        monthIncome: 0,
        monthExpense: 0,
        netFlow: 0,
        recurringCount: 0,
        topCategory: null,
        message: 'No transactions yet. Add one to unlock insights.',
        hasTransactions: false,
      );
    }

    final effectiveNow = now ?? DateTime.now();
    final monthStart = DateTime(effectiveNow.year, effectiveNow.month, 1);
    final monthTransactions = transactions
        .where((tx) =>
            !tx.date.isBefore(monthStart) &&
            tx.date.year == effectiveNow.year &&
            tx.date.month == effectiveNow.month)
        .toList();

    final monthIncome = monthTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final monthExpense = monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final netFlow = monthIncome - monthExpense;
    final recurringCount = transactions
        .where((tx) => tx.recurrence != TransactionRecurrence.none)
        .length;

    final categoryTotals = <String, double>{};
    for (final tx in monthTransactions.where((tx) => tx.isExpense)) {
      categoryTotals.update(
        tx.category,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }
    final topCategoryEntry = categoryTotals.entries.isEmpty
        ? null
        : (categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first;

    final message = _message(
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      recurringCount: recurringCount,
      topCategory: topCategoryEntry?.key,
      hasCurrentMonthData: monthTransactions.isNotEmpty,
    );

    return TransactionDecisionSnapshotData(
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      netFlow: netFlow,
      recurringCount: recurringCount,
      topCategory: topCategoryEntry?.key,
      message: message,
      hasTransactions: true,
    );
  }

  String _message({
    required double monthIncome,
    required double monthExpense,
    required int recurringCount,
    required String? topCategory,
    required bool hasCurrentMonthData,
  }) {
    if (!hasCurrentMonthData) {
      return 'No activity this month yet. Keep tracking daily spending.';
    }
    if (monthExpense > monthIncome && monthIncome > 0) {
      return 'Spending is outpacing income this month. Consider tightening variable categories.';
    }
    if (recurringCount >= 5) {
      return 'Recurring payments are a big part of your outflow. Review subscriptions and autopays.';
    }
    if (topCategory != null) {
      return 'Your highest spending category this month is $topCategory.';
    }
    return 'Your cash flow is balanced this month. Keep the momentum.';
  }
}

class FinancialInsightEngine {
  const FinancialInsightEngine();

  double savingsRatio({required double income, required double expense}) {
    if (income <= 0) return 0;
    return ((income - expense) / income).clamp(-1.0, 1.0);
  }
}

class BudgetInsightEngine {
  const BudgetInsightEngine();

  double utilizationRatio({required double spent, required double limit}) {
    if (limit <= 0) return 0;
    return (spent / limit).clamp(0, 10);
  }
}

class SubscriptionInsightEngine {
  const SubscriptionInsightEngine();

  double monthlyLoad({required double recurringTotal, required double income}) {
    if (income <= 0) return recurringTotal > 0 ? 1 : 0;
    return (recurringTotal / income).clamp(0, 10);
  }
}

class SavingsInsightEngine {
  const SavingsInsightEngine();

  double monthlyProgress({
    required double savedThisMonth,
    required double targetThisMonth,
  }) {
    if (targetThisMonth <= 0) return 0;
    return (savedThisMonth / targetThisMonth).clamp(0, 2);
  }
}
