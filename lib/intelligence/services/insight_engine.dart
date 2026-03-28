import 'package:smartbudget/data/datasources/local/app_database.dart'
    show SecuritySetting;
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/intelligence/models/forecast_data_point.dart';
import 'package:smartbudget/intelligence/models/insight.dart';
import 'package:smartbudget/intelligence/models/insight_results.dart';
import 'package:smartbudget/intelligence/models/money.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

class InsightEngine {
  const InsightEngine();

  InsightResults buildResults({
    required SpendingProfile profile,
    required CashflowPrediction forecast,
    required List<Transaction> history,
    required List<Subscription> subscriptions,
    SecuritySetting? securitySetting,
  }) {
    final currency = _detectCurrency(history);
    final insights = <Insight>[..._buildAnomalyInsights(profile, currency)];

    insights.add(_buildForecastInsight(profile, forecast, currency));
    insights.add(_buildTrendInsight(profile, forecast, currency));
    insights.addAll(_buildSubscriptionInsights(subscriptions, currency));

    if (securitySetting != null) {
      insights.add(_buildSecurityInsight(securitySetting, currency));
    }

    if (insights.isEmpty) {
      insights.add(_buildHealthyInsight(currency));
    }

    final forecastSeries = _buildForecastSeries(history, forecast, currency);

    return InsightResults(
      currency: currency,
      insights: insights,
      forecastSeries: forecastSeries,
      spendingProfile: profile,
      forecast: forecast,
      subscriptions: subscriptions,
      securitySetting: securitySetting,
    );
  }

  String _detectCurrency(List<Transaction> history) {
    if (history.isEmpty) return 'USD';

    final counts = <String, int>{};
    for (final tx in history) {
      counts[tx.currency] = (counts[tx.currency] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<Insight> _buildAnomalyInsights(
    SpendingProfile profile,
    String currency,
  ) {
    if (profile.anomalies.isEmpty) {
      return const [];
    }

    final topAnomaly = profile.anomalies.first;
    final threshold = profile.anomalies
            .any((anomaly) => anomaly.severity == AnomalySeverity.high)
        ? InsightSeverity.high
        : InsightSeverity.medium;

    return [
      Insight(
        id: 'anomaly-main',
        title: 'Unusual spending detected',
        explanation:
            '${topAnomaly.reason} in ${topAnomaly.transaction.category}.',
        impact:
            'This pattern is likely increasing your monthly expense by ${topAnomaly.deviationPercentage.toStringAsFixed(0)}%.',
        action:
            'Review the transaction and reduce similar spending in ${topAnomaly.transaction.category}.',
        confidence: 0.88,
        severity: threshold,
        type: InsightType.anomaly,
      ),
    ];
  }

  Insight _buildForecastInsight(
    SpendingProfile profile,
    CashflowPrediction forecast,
    String currency,
  ) {
    final riskLevel = forecast.riskLevel;
    final isCritical = riskLevel == RiskLevel.critical;
    final isHigh = riskLevel == RiskLevel.high || isCritical;
    final projected = _formatMoney(forecast.projectedMonthlySpend, currency);
    final balance = _formatMoney(forecast.projectedEndBalance, currency);

    final explanation = isCritical
        ? 'Projected spend is $projected, putting your cashflow at risk with an estimated balance of $balance.'
        : isHigh
            ? 'Your forecast shows elevated spending relative to income.'
            : 'Your current forecast is within a healthy range.';

    final impact = isCritical
        ? 'If this continues, your account balance may fall below zero.'
        : isHigh
            ? 'You may have less buffer for unexpected expenses.'
            : 'You should stay on track for the rest of the month.';

    final action = isCritical
        ? 'Trim discretionary spending and review upcoming bills.'
        : isHigh
            ? 'Consider limiting non-essential purchases this week.'
            : 'Keep monitoring your spending and stay within budget.';

    return Insight(
      id: 'forecast-main',
      title: 'Cashflow forecast',
      explanation: explanation,
      impact: impact,
      action: action,
      confidence: forecast.confidenceInterval,
      severity: isCritical
          ? InsightSeverity.high
          : isHigh
              ? InsightSeverity.medium
              : InsightSeverity.low,
      type: InsightType.forecast,
    );
  }

  Insight _buildTrendInsight(
    SpendingProfile profile,
    CashflowPrediction forecast,
    String currency,
  ) {
    switch (profile.trend) {
      case TrendDirection.increasing:
        return const Insight(
          id: 'trend-increasing',
          title: 'Spending trend is climbing',
          explanation:
              'Your expenses are higher this month compared to last month.',
          impact:
              'At this pace, you may end the month with less financial flexibility.',
          action:
              'Set a weekly cap for variable spending categories like dining or travel.',
          confidence: 0.72,
          severity: InsightSeverity.medium,
          type: InsightType.recommendation,
        );
      case TrendDirection.decreasing:
        return const Insight(
          id: 'trend-decreasing',
          title: 'Spending trend is improving',
          explanation: 'Your expenses have decreased compared to last month.',
          impact: 'This gives you more room to build savings or pay down debt.',
          action: 'Keep the momentum and maintain the current pace.',
          confidence: 0.78,
          severity: InsightSeverity.low,
          type: InsightType.recommendation,
        );
      case TrendDirection.stable:
        return const Insight(
          id: 'trend-stable',
          title: 'Spending is stable',
          explanation: 'Your spending is consistent with recent behavior.',
          impact: 'This makes it easier to plan the rest of the month.',
          action: 'Review your budget and keep unnecessary expenses in check.',
          confidence: 0.7,
          severity: InsightSeverity.low,
          type: InsightType.recommendation,
        );
    }
  }

  Insight _buildHealthyInsight(String currency) {
    return const Insight(
      id: 'healthy-baseline',
      title: 'Financial health check',
      explanation: 'No critical anomalies or forecast risks were detected.',
      impact: 'Your current pattern is manageable for this month.',
      action: 'Continue tracking spending and review alerts regularly.',
      confidence: 0.85,
      severity: InsightSeverity.low,
      type: InsightType.recommendation,
    );
  }

  List<Insight> _buildSubscriptionInsights(
    List<Subscription> subscriptions,
    String currency,
  ) {
    if (subscriptions.isEmpty) {
      return [];
    }

    final totalMonthly = subscriptions
        .where((sub) => sub.isActive)
        .fold<double>(0, (sum, sub) => sum + sub.monthlyCost);

    final dueSoon = subscriptions
        .where((sub) => sub.nextDueDate
            .isBefore(DateTime.now().add(const Duration(days: 14))))
        .toList();

    final message = dueSoon.isNotEmpty
        ? 'You have ${dueSoon.length} subscription(s) billing within the next 14 days.'
        : 'Active subscriptions are stable for now.';

    return [
      Insight(
        id: 'subscription-main',
        title: 'Subscription cost overview',
        explanation:
            'Your active subscriptions cost ${CurrencyUtils.formatAmount(totalMonthly, currency)} per month on average.',
        impact:
            'Recurring expenses can erode monthly savings if they grow faster than income.',
        action:
            'Review subscriptions and cancel or consolidate services that are underused.',
        confidence: 0.72,
        severity: totalMonthly > 200
            ? InsightSeverity.high
            : totalMonthly > 100
                ? InsightSeverity.medium
                : InsightSeverity.low,
        type: InsightType.recommendation,
      ),
      if (dueSoon.isNotEmpty)
        Insight(
          id: 'subscription-due-soon',
          title: 'Upcoming subscription payments',
          explanation: message,
          impact:
              'Upcoming renewal dates could impact your monthly cashflow if not planned properly.',
          action: 'Check the list of upcoming subscriptions and set reminders.',
          confidence: 0.8,
          severity: InsightSeverity.medium,
          type: InsightType.forecast,
        ),
    ];
  }

  Insight _buildSecurityInsight(
    SecuritySetting securitySetting,
    String currency,
  ) {
    final score = _calculateSecurityScore(securitySetting);
    final status = score >= 80
        ? 'strong'
        : score >= 60
            ? 'okay'
            : 'weak';

    return Insight(
      id: 'security-overview',
      title: 'Security posture check',
      explanation: 'Your account security is $status with a score of $score%.',
      impact: score >= 80
          ? 'Your device settings are aligned with good security hygiene.'
          : 'A weak security posture may expose sensitive financial data.',
      action: score >= 80
          ? 'Keep biometric authentication enabled and review access logs regularly.'
          : 'Enable PIN or biometric authentication and monitor login attempts.',
      confidence: 0.9,
      severity: score >= 80
          ? InsightSeverity.low
          : score >= 60
              ? InsightSeverity.medium
              : InsightSeverity.high,
      type: InsightType.recommendation,
    );
  }

  int _calculateSecurityScore(SecuritySetting securitySetting) {
    var score = 50;
    if (securitySetting.biometricEnabled) score += 20;
    if (securitySetting.pinEnabled) score += 15;
    if (securitySetting.maxFailedAttempts <= 5) score += 10;
    if (securitySetting.lockoutDuration >= 300) score += 5;
    if (securitySetting.sessionTimeout <= 600) score += 5;
    return score.clamp(0, 100);
  }

  String _formatMoney(double amount, String currency) {
    return CurrencyUtils.formatAmount(amount, currency);
  }

  List<ForecastDataPoint> _buildForecastSeries(
    List<Transaction> history,
    CashflowPrediction forecast,
    String currency,
  ) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyExpense = <int, double>{};

    for (final tx in history) {
      if (!tx.isExpense) continue;
      if (tx.date.year != now.year || tx.date.month != now.month) continue;
      dailyExpense[tx.date.day] = (dailyExpense[tx.date.day] ?? 0) + tx.amount;
    }

    var cumulativeActual = 0.0;
    final projectionRate = lastDayOfMonth > 0
        ? forecast.projectedMonthlySpend / lastDayOfMonth
        : 0.0;

    return List<ForecastDataPoint>.generate(lastDayOfMonth, (index) {
      final day = index + 1;
      cumulativeActual += dailyExpense[day] ?? 0;
      final actual =
          Money.of(cumulativeActual, currency, baseAmount: cumulativeActual);
      final predicted = Money.of(projectionRate * day, currency,
          baseAmount: projectionRate * day);
      return ForecastDataPoint(
        date: DateTime(now.year, now.month, day),
        actual: actual,
        predicted: predicted,
      );
    });
  }
}
