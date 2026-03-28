import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart'
    show SecuritySetting;
import 'package:smartbudget/features/insights/presentation/providers/insight_provider.dart';
import 'package:smartbudget/features/insights/presentation/widgets/alert_banner.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/features/insights/presentation/widgets/forecast_chart_widget.dart';
import 'package:smartbudget/features/insights/presentation/widgets/insight_card.dart';
import 'package:smartbudget/features/insights/presentation/widgets/simulation_card.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightResultsAsync = ref.watch(insightResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Copilot')),
      body: insightResultsAsync.when(
        data: (result) {
          final currencyFormat = CurrencyUtils.getFormat(result.currency);
          final activeSubscriptions =
              result.subscriptions.where((sub) => sub.isActive).toList();
          final subscriptionMonthlyCost = activeSubscriptions.fold<double>(
              0, (sum, sub) => sum + sub.monthlyCost);
          final upcomingSubscriptions = activeSubscriptions
              .where((sub) => sub.nextDueDate
                  .isBefore(DateTime.now().add(const Duration(days: 14))))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.forecast.riskLevel == RiskLevel.critical)
                  AlertBanner(
                    message:
                        'Critical cashflow risk detected. Review spending immediately.',
                    color: Colors.red.shade700,
                  )
                else if (result.forecast.riskLevel == RiskLevel.high)
                  AlertBanner(
                    message:
                        'Elevated cashflow risk detected. Monitor spending closely.',
                    color: Colors.orange.shade700,
                  )
                else if (upcomingSubscriptions.isNotEmpty)
                  AlertBanner(
                    message:
                        '${upcomingSubscriptions.length} upcoming subscription renewal(s) due soon.',
                    color: Colors.orange.shade700,
                  )
                else if (result.securitySetting != null &&
                    _computeSecurityScore(result.securitySetting!) < 60)
                  AlertBanner(
                    message:
                        'Security settings are weak. Enable PIN or biometrics today.',
                    color: Colors.orange.shade700,
                  ),
                const SizedBox(height: 12),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial snapshot',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Risk level: ${result.forecast.riskLevel.name.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subscription spend: ${currencyFormat.format(subscriptionMonthlyCost)} / mo',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.securitySetting != null
                              ? 'Security score: ${_computeSecurityScore(result.securitySetting!)}%'
                              : 'Security score: unavailable',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ForecastChartWidget(dataPoints: result.forecastSeries),
                const SizedBox(height: 16),
                SimulationCard(
                  forecast: result.forecast,
                  profile: result.spendingProfile,
                  currency: result.currency,
                ),
                const SizedBox(height: 16),
                Text(
                  'Actionable insights',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ...result.insights
                    .map((insight) => InsightCard(insight: insight)),
                const SizedBox(height: 16),
                Text(
                  'Category distribution',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (result.spendingProfile.categoryDistribution.isEmpty)
                  const Text('No category data available yet.')
                else
                  ...result.spendingProfile.categoryDistribution.entries.map(
                    (entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text('${entry.value.toStringAsFixed(1)}%'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Anomalies & impact',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (result.spendingProfile.anomalies.isEmpty)
                  const Text('No unusual spending detected.')
                else
                  ...result.spendingProfile.anomalies.map(
                    (anomaly) => ListTile(
                      title: Text(anomaly.reason),
                      subtitle: Text(
                        '${anomaly.transaction.category} ${currencyFormat.format(anomaly.transaction.amount)}',
                      ),
                      trailing: Text(
                        anomaly.severity.name.toUpperCase(),
                        style: TextStyle(
                          color: anomaly.severity == AnomalySeverity.critical
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Subscription intelligence',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (activeSubscriptions.isEmpty)
                  const Text('No active subscriptions are being tracked yet.')
                else
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total monthly subscription spend: ${currencyFormat.format(subscriptionMonthlyCost)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            upcomingSubscriptions.isNotEmpty
                                ? '${upcomingSubscriptions.length} subscription(s) renew within the next 14 days.'
                                : 'No subscription renewals due in the next 14 days.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Security posture',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.securitySetting != null
                              ? 'Biometric: ${result.securitySetting!.biometricEnabled ? 'enabled' : 'disabled'} • PIN: ${result.securitySetting!.pinEnabled ? 'enabled' : 'disabled'}'
                              : 'Security configuration not available.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.securitySetting != null
                              ? 'Last update: ${result.securitySetting!.lastSecurityUpdate.toLocal().toString().split(' ').first}'
                              : 'Connect your security settings for tailored recommendations.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading insights: $err')),
      ),
    );
  }

  int _computeSecurityScore(SecuritySetting securitySetting) {
    var score = 50;
    if (securitySetting.biometricEnabled) score += 20;
    if (securitySetting.pinEnabled) score += 15;
    if (securitySetting.maxFailedAttempts <= 5) score += 10;
    if (securitySetting.lockoutDuration >= 300) score += 5;
    if (securitySetting.sessionTimeout <= 600) score += 5;
    return score.clamp(0, 100);
  }
}
