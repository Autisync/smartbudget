import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/repositories/budget_repository.dart';
import 'package:smartbudget/data/repositories/budget_repository_impl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';

part 'budget_provider.g.dart';

@Riverpod(keepAlive: true)
BudgetRepository budgetRepository(BudgetRepositoryRef ref) {
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
}

@riverpod
Future<double> budgetSpending(BudgetSpendingRef ref,
    {required String category,
    required DateTime start,
    required DateTime end}) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgetSpending(category, start, end);
}
