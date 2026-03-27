import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(spendingProfileProvider);
    final predictionAsync = ref.watch(cashflowPredictionProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: profileAsync.when(
        data: (profile) {
          return predictionAsync.when(
            data: (prediction) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _InsightCard(
                      title: 'Monthly Burn Rate',
                      value: currencyFormat.format(profile.monthlyBurnRate),
                      caption: 'The total expense for this month so far.',
                    ),
                    _InsightCard(
                      title: 'Average Daily Spend',
                      value: currencyFormat.format(profile.averageDailySpend),
                      caption: 'Your average daily expense pace.',
                    ),
                    _InsightCard(
                      title: 'Spending Trend',
                      value: profile.trend.name.toUpperCase(),
                      caption: 'Compared to last month.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Forecast',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _InsightCard(
                      title: 'Projected Spend',
                      value: currencyFormat
                          .format(prediction.projectedMonthlySpend),
                      caption: 'Estimated spending for the current month.',
                    ),
                    _InsightCard(
                      title: 'Projected End Balance',
                      value:
                          currencyFormat.format(prediction.projectedEndBalance),
                      caption:
                          'Your anticipated balance after projected spending.',
                    ),
                    _InsightCard(
                      title: 'Confidence',
                      value:
                          '${(prediction.confidenceInterval * 100).toStringAsFixed(0)}%',
                      caption: 'Forecast reliability based on your history.',
                    ),
                    _InsightCard(
                      title: 'Risk Level',
                      value: prediction.riskLevel.name.toUpperCase(),
                      caption: prediction.recommendation,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category distribution',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (profile.categoryDistribution.isEmpty)
                      const Text('No category data available yet.')
                    else
                      ...profile.categoryDistribution.entries.map(
                        (entry) => ListTile(
                          title: Text(entry.key),
                          trailing: Text(
                            '${entry.value.toStringAsFixed(1)}%',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Anomalies',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (profile.anomalies.isEmpty)
                      const Text('No unusual spending detected.')
                    else
                      ...profile.anomalies.map(
                        (a) => ListTile(
                          title: Text(a.reason),
                          subtitle: Text(
                              '${a.transaction.category} ${currencyFormat.format(a.transaction.amount)}'),
                          trailing: Text(
                            a.severity.name.toUpperCase(),
                            style: TextStyle(
                              color: a.severity == AnomalySeverity.critical
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) =>
                Center(child: Text('Error loading forecast: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading insights: $err')),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
