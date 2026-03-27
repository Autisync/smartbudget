import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/data/models/tables.dart' show GoalPriority;

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsGoalListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: savingsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(child: Text('No savings goals yet'));
          }

          return ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progress = goal.targetAmount > 0
                  ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
                  : 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(goal.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${goal.savedAmount.toStringAsFixed(2)} / ${goal.targetAmount.toStringAsFixed(2)}'),
                      LinearProgressIndicator(value: progress),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => ref
                        .read(savingsGoalListProvider.notifier)
                        .deleteSavingsGoal(goal.id),
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
          final newGoal = SavingsGoal(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'New Goal',
            targetAmount: 1000,
            savedAmount: 0,
            priority: GoalPriority.medium,
            autoAllocate: false,
            createdAt: DateTime.now(),
          );
          await ref
              .read(savingsGoalListProvider.notifier)
              .addSavingsGoal(newGoal);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
