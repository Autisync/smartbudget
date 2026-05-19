import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smartbudget/domain/entities/transaction.dart';

part 'spending_analyzer.freezed.dart';

@freezed
class SpendingProfile with _$SpendingProfile {
  const factory SpendingProfile({
    required double monthlyBurnRate,
    required double averageDailySpend,
    required Map<String, double> categoryDistribution,
    required List<SpendingAnomaly> anomalies,
    required TrendDirection trend,
    required double topCategoryPercentage,
  }) = _SpendingProfile;
}

@freezed
class SpendingAnomaly with _$SpendingAnomaly {
  const factory SpendingAnomaly({
    required Transaction transaction,
    required AnomalySeverity severity,
    required String reason,
    required double deviationPercentage,
  }) = _SpendingAnomaly;
}

enum TrendDirection { increasing, decreasing, stable }

enum AnomalySeverity { low, medium, high, critical }

class SpendingAnalyzer {
  SpendingProfile analyze(List<Transaction> transactions, DateTime month) {
    final monthlyTxs = transactions
        .where(
          (t) =>
              t.date.month == month.month &&
              t.date.year == month.year &&
              t.isExpense,
        )
        .toList();

    if (monthlyTxs.isEmpty) {
      return const SpendingProfile(
        monthlyBurnRate: 0,
        averageDailySpend: 0,
        categoryDistribution: {},
        anomalies: [],
        trend: TrendDirection.stable,
        topCategoryPercentage: 0,
      );
    }

    final burnRate = monthlyTxs.fold(0.0, (sum, t) => sum + t.amount);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final avgDaily = burnRate / daysInMonth;

    final distribution = _calculateCategoryDistribution(monthlyTxs);
    final anomalies = _detectAnomalies(monthlyTxs);
    final trend = _calculateTrend(transactions, month);

    final topCategory = distribution.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final topPercentage = (topCategory.value / burnRate) * 100;

    return SpendingProfile(
      monthlyBurnRate: burnRate,
      averageDailySpend: avgDaily,
      categoryDistribution: distribution,
      anomalies: anomalies,
      trend: trend,
      topCategoryPercentage: topPercentage,
    );
  }

  Map<String, double> _calculateCategoryDistribution(List<Transaction> txs) {
    final map = <String, double>{};
    final total = txs.fold(0.0, (sum, t) => sum + t.amount);

    for (var tx in txs) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }

    // Convert to percentages
    return map.map(
      (key, value) => MapEntry(key, total > 0 ? (value / total) * 100 : 0),
    );
  }

  List<SpendingAnomaly> _detectAnomalies(List<Transaction> txs) {
    final anomalies = <SpendingAnomaly>[];
    final categoryHistory = <String, List<double>>{};

    // Build historical data (simplified - would use 3-month history in production)
    for (final tx in txs) {
      categoryHistory.putIfAbsent(tx.category, () => []).add(tx.amount);
    }

    categoryHistory.forEach((category, amounts) {
      if (amounts.length < 2) return;

      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance =
          amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) /
              amounts.length;
      final sd = sqrt(variance);

      if (sd == 0) return;

      for (final tx in txs.where((t) => t.category == category)) {
        final zScore = (tx.amount - mean) / sd;

        if (zScore > 2.5) {
          anomalies.add(
            SpendingAnomaly(
              transaction: tx,
              severity:
                  zScore > 3.5 ? AnomalySeverity.high : AnomalySeverity.medium,
              reason:
                  'Spending ${zScore.toStringAsFixed(1)}x above your $category average',
              deviationPercentage: ((tx.amount - mean) / mean) * 100,
            ),
          );
        }
      }
    });

    return anomalies
      ..sort((a, b) => b.deviationPercentage.compareTo(a.deviationPercentage));
  }

  TrendDirection _calculateTrend(
    List<Transaction> allTransactions,
    DateTime currentMonth,
  ) {
    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1);

    final currentSpend = allTransactions
        .where(
          (t) =>
              t.date.month == currentMonth.month &&
              t.date.year == currentMonth.year &&
              t.isExpense,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final prevSpend = allTransactions
        .where(
          (t) =>
              t.date.month == prevMonth.month &&
              t.date.year == prevMonth.year &&
              t.isExpense,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    if (prevSpend == 0) return TrendDirection.stable;

    final change = ((currentSpend - prevSpend) / prevSpend) * 100;
    if (change > 10) return TrendDirection.increasing;
    if (change < -10) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }
}




