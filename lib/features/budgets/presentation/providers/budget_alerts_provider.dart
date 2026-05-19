import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';

part 'budget_alerts_provider.g.dart';

@riverpod
Future<List<BudgetAlert>> budgetAlerts(BudgetAlertsRef ref) async {
  final budgets = await ref.watch(budgetListProvider.future);
  final alerts = <BudgetAlert>[];

  for (final budget in budgets) {
    final spent = await ref.watch(budgetSpendingProvider(
      category: budget.category,
      start: budget.startDate,
      end: budget.endDate ?? DateTime.now(),
    ).future);

    final progress = budget.limitAmount > 0
        ? (spent / budget.limitAmount).clamp(0.0, 1.0)
        : 0.0;

    final overLimit = progress >= 1.0;
    final nearLimit = progress >= (budget.alertThreshold / 100);

    if (overLimit || nearLimit) {
      final alert = BudgetAlert(
        budgetId: budget.id,
        category: budget.category,
        progress: progress,
        threshold: budget.alertThreshold,
        nearLimit: nearLimit,
        overLimit: overLimit,
        generatedAt: DateTime.now(),
      );

      alerts.add(alert);
    }
  }

  return alerts;
}




