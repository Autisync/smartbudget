import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/domain/repositories/savings_goal_repository.dart';
import 'package:smartbudget/data/repositories/savings_goal_repository_impl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';

part 'savings_provider.g.dart';

@Riverpod(keepAlive: true)
SavingsGoalRepository savingsGoalRepository(SavingsGoalRepositoryRef ref) {
  final database = ref.watch(databaseProvider);
  return SavingsGoalRepositoryImpl(database);
}

@riverpod
class SavingsGoalList extends _$SavingsGoalList {
  @override
  Future<List<SavingsGoal>> build() async {
    return ref.watch(savingsGoalRepositoryProvider).getSavingsGoals();
  }

  Future<void> refresh() async => state = await AsyncValue.guard(() async {
        return ref.read(savingsGoalRepositoryProvider).getSavingsGoals();
      });

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(savingsGoalRepositoryProvider).addSavingsGoal(goal);
      return ref.read(savingsGoalRepositoryProvider).getSavingsGoals();
    });
  }

  Future<void> deleteSavingsGoal(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(savingsGoalRepositoryProvider).deleteSavingsGoal(id);
      return ref.read(savingsGoalRepositoryProvider).getSavingsGoals();
    });
  }
}
