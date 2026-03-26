import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(spendingProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: profileAsync.when(
        data: (profile) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Monthly Burn Rate: \$${profile.monthlyBurnRate.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text(
                    'Average Daily Spend: \$${profile.averageDailySpend.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Text('Category distribution'),
                ...profile.categoryDistribution.entries.map((entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text('${entry.value.toStringAsFixed(1)}%'),
                    )),
                const SizedBox(height: 16),
                if (profile.anomalies.isNotEmpty) ...[
                  const Text('Anomalies detected:'),
                  ...profile.anomalies.map((a) => ListTile(
                        title: Text(a.reason),
                        subtitle: Text(
                            '${a.transaction.category} \$${a.transaction.amount.toStringAsFixed(2)}'),
                      )),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading insights: $err')),
      ),
    );
  }
}
