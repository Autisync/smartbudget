import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/domain/entities/budget.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const Center(child: Text('No budgets yet'));
          }

          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              final endDate = budget.endDate ?? DateTime.now();
              final spentAsync = ref.watch(budgetSpendingProvider(
                category: budget.category,
                start: budget.startDate,
                end: endDate,
              ));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${budget.category} • ${budget.period.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await ref
                                  .read(budgetListProvider.notifier)
                                  .deleteBudget(budget.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Limit: ${budget.limitAmount.toStringAsFixed(2)} ${budget.currency}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      spentAsync.when(
                        data: (spent) {
                          final progress =
                              (spent / budget.limitAmount).clamp(0.0, 1.0);
                          final status = progress < 0.7
                              ? 'Good'
                              : progress < 1.0
                                  ? 'Warning'
                                  : 'Exceeded';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: progress,
                                color: progress < 0.7
                                    ? Colors.green
                                    : progress < 1.0
                                        ? Colors.orange
                                        : Colors.red,
                                backgroundColor: Colors.grey.shade200,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${budget.period.name} spent: ${spent.toStringAsFixed(2)} ${budget.currency} • $status',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, st) =>
                            const Text('Error loading progress'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newBudget = Budget(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            category: 'Food',
            limitAmount: 500,
            currency: 'USD',
            period: BudgetPeriod.monthly,
            startDate: DateTime.now(),
          );
          await ref.read(budgetListProvider.notifier).addBudget(newBudget);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
