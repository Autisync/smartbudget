import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smartbudget/domain/entities/transaction.dart';

part 'cashflow_predictor.freezed.dart';

@freezed
class CashflowPrediction with _$CashflowPrediction {
  const factory CashflowPrediction({
    required double projectedMonthlySpend,
    required double projectedEndBalance,
    required double confidenceInterval,
    required RiskLevel riskLevel,
    required String recommendation,
    required DateTime predictionDate,
  }) = _CashflowPrediction;
}

enum RiskLevel { low, medium, high, critical }

class CashflowPredictor {
  CashflowPrediction predict(
    List<Transaction> history,
    DateTime targetMonth,
    double currentBalance,
  ) {
    final now = DateTime.now();
    final daysRemaining =
        DateTime(targetMonth.year, targetMonth.month + 1, 0).day - now.day;

    // Calculate daily spend rate from current month
    final currentMonthTxs = history
        .where(
          (t) =>
              t.date.month == targetMonth.month &&
              t.date.year == targetMonth.year &&
              t.isExpense,
        )
        .toList();

    final currentSpend = currentMonthTxs.fold(0.0, (sum, t) => sum + t.amount);
    final dailyRate = now.day > 0 ? currentSpend / now.day : 0;

    // Simple linear projection
    final projectedSpend = currentSpend + (dailyRate * daysRemaining);

    // Calculate confidence based on historical variance
    final confidence = _calculateConfidence(history, targetMonth);

    // Assess risk
    final avgIncome = _calculateAverageIncome(history);
    final riskLevel = _assessRisk(projectedSpend, avgIncome, currentBalance);

    return CashflowPrediction(
      projectedMonthlySpend: projectedSpend,
      projectedEndBalance: currentBalance - (projectedSpend - currentSpend),
      confidenceInterval: confidence,
      riskLevel: riskLevel,
      recommendation: _generateRecommendation(
        riskLevel,
        projectedSpend,
        avgIncome,
      ),
      predictionDate: now,
    );
  }

  double _calculateConfidence(List<Transaction> history, DateTime month) {
    // Simplified confidence calculation
    final monthlyTotals = <int, double>{};

    for (var i = 0; i < 3; i++) {
      final m = DateTime(month.year, month.month - i);
      final spend = history
          .where(
            (t) =>
                t.date.month == m.month && t.date.year == m.year && t.isExpense,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
      monthlyTotals[i] = spend;
    }

    if (monthlyTotals.length < 2) return 0.5;

    final values = monthlyTotals.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final cv = mean > 0 ? (variance / mean).abs() : 1.0;

    // Higher variance = lower confidence
    return (1.0 - cv).clamp(0.1, 0.9);
  }

  double _calculateAverageIncome(List<Transaction> history) {
    final incomeByMonth = <String, double>{};

    for (final tx in history.where((t) => t.isIncome)) {
      final key = '${tx.date.year}-${tx.date.month}';
      incomeByMonth[key] = (incomeByMonth[key] ?? 0) + tx.amount;
    }

    if (incomeByMonth.isEmpty) return 0;
    return incomeByMonth.values.reduce((a, b) => a + b) / incomeByMonth.length;
  }

  RiskLevel _assessRisk(
    double projectedSpend,
    double avgIncome,
    double currentBalance,
  ) {
    if (avgIncome == 0) return RiskLevel.medium;

    final spendRatio = projectedSpend / avgIncome;
    if (spendRatio > 1.0 || currentBalance < 0) return RiskLevel.critical;
    if (spendRatio > 0.9) return RiskLevel.high;
    if (spendRatio > 0.75) return RiskLevel.medium;
    return RiskLevel.low;
  }

  String _generateRecommendation(
    RiskLevel risk,
    double projectedSpend,
    double income,
  ) {
    switch (risk) {
      case RiskLevel.critical:
        return 'Critical: Reduce spending by ${((projectedSpend - income) / projectedSpend * 100).toStringAsFixed(0)}% to avoid debt';
      case RiskLevel.high:
        return 'Warning: You\'re on track to spend ${(projectedSpend / income * 100).toStringAsFixed(0)}% of income';
      case RiskLevel.medium:
        return 'Caution: Consider reducing discretionary spending';
      case RiskLevel.low:
        return 'Great! You\'re within healthy spending limits';
    }
  }
}




