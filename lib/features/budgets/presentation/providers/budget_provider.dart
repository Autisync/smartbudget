import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/data/models/tables.dart' show BudgetPeriod;
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/repositories/budget_repository.dart';
import 'package:smartbudget/data/repositories/budget_repository_impl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';

part 'budget_provider.g.dart';

final activeBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final budgets = await ref.watch(budgetListProvider.future);
  return budgets.where((budget) => budget.isActive).toList(growable: false);
});

@Riverpod(keepAlive: true)
BudgetRepository budgetRepository(Ref ref) {
  final database = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(database);
}

@riverpod
class BudgetList extends _$BudgetList {
  @override
  Future<List<Budget>> build() async {
    final repo = ref.watch(budgetRepositoryProvider);
    return repo.getBudgets();
  }

  Future<void> rolloverExpiredBudgets({int? rolloverDay}) async {
    final repo = ref.read(budgetRepositoryProvider);
    final budgets = await repo.getBudgets();
    await _rolloverBudgetsIfNeeded(
      repo,
      budgets,
      rolloverDay: rolloverDay,
    );
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(budgetRepositoryProvider).getBudgets();
    });
  }

  Future<void> addBudget(Budget budget) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).addBudget(budget);
      return ref.read(budgetRepositoryProvider).getBudgets();
    });
  }

  Future<void> deleteBudget(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).deleteBudget(id);
      return ref.read(budgetRepositoryProvider).getBudgets();
    });
  }

  Future<void> updateBudget(Budget budget) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).updateBudget(budget);
      return ref.read(budgetRepositoryProvider).getBudgets();
    });
  }

  Future<void> _rolloverBudgetsIfNeeded(
      BudgetRepository repo, List<Budget> budgets,
      {int? rolloverDay}) async {
    final now = DateTime.now();

    for (final budget in budgets) {
      final initialEnd = budget.endDate ??
          _calculateEndDate(
            budget.startDate,
            budget.period,
            rolloverDay: rolloverDay,
          );
      if (!now.isAfter(initialEnd)) {
        continue;
      }

      var nextStart = budget.startDate;
      var nextEnd = initialEnd;

      while (now.isAfter(nextEnd)) {
        nextStart = nextEnd;
        nextEnd = _calculateEndDate(
          nextStart,
          budget.period,
          rolloverDay: rolloverDay,
        );
      }

      final rolledBudget = budget.copyWith(
        startDate: nextStart,
        endDate: nextEnd,
      );
      await repo.updateBudget(rolledBudget);
    }
  }

  DateTime _calculateEndDate(
    DateTime startDate,
    BudgetPeriod period, {
    int? rolloverDay,
  }) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        final nextMonth = DateTime(startDate.year, startDate.month + 1, 1);
        final day = (rolloverDay ?? startDate.day).clamp(1, 31);
        final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        return DateTime(
            nextMonth.year, nextMonth.month, day > maxDay ? maxDay : day);
      case BudgetPeriod.yearly:
        final day = (rolloverDay ?? startDate.day).clamp(1, 31);
        final maxDay = DateTime(startDate.year + 1, startDate.month + 1, 0).day;
        return DateTime(
          startDate.year + 1,
          startDate.month,
          day > maxDay ? maxDay : day,
        );
    }
  }
}

@riverpod
Future<double> budgetSpending(Ref ref,
    {required String category,
    required DateTime start,
    required DateTime end}) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgetSpending(category, start, end);
}
