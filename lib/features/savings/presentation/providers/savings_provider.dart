import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/domain/repositories/savings_goal_repository.dart';
import 'package:smartbudget/data/repositories/savings_goal_repository_impl.dart';

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

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(savingsGoalRepositoryProvider).updateSavingsGoal(goal);
      return ref.read(savingsGoalRepositoryProvider).getSavingsGoals();
    });
  }
}

class SavingsNudge {
  const SavingsNudge({
    required this.goalId,
    required this.title,
    required this.message,
    this.severity = SavingsNudgeSeverity.info,
  });

  final String goalId;
  final String title;
  final String message;
  final SavingsNudgeSeverity severity;
}

enum SavingsNudgeSeverity { info, warning, critical }

@Riverpod(keepAlive: true)
class SavingsNudges extends _$SavingsNudges {
  @override
  Future<List<SavingsNudge>> build() async {
    final goals = await ref.watch(savingsGoalListProvider.future);
    final now = DateTime.now();
    final nudges = <SavingsNudge>[];

    for (final goal in goals) {
      final progress = goal.targetAmount > 0
          ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
          : 0.0;

      if (goal.deadline != null) {
        final createdAt = goal.createdAt ?? now;
        final totalDays = goal.deadline!.difference(createdAt).inDays;
        final elapsedDays = now.difference(createdAt).inDays;
        final expectedProgress = totalDays <= 0
            ? 1.0
            : (elapsedDays / totalDays).clamp(0.0, 1.0);

        if (progress + 0.05 < expectedProgress) {
          final behindAmount =
              ((expectedProgress - progress) * goal.targetAmount).clamp(0, double.infinity);
          nudges.add(
            SavingsNudge(
              goalId: goal.id,
              title: 'You are behind on ${goal.title}',
              message:
                  'You are about ${behindAmount.toStringAsFixed(0)} behind schedule. Consider increasing monthly savings.',
              severity: expectedProgress - progress > 0.2
                  ? SavingsNudgeSeverity.critical
                  : SavingsNudgeSeverity.warning,
            ),
          );
        }
      }

      if (!goal.autoAllocate && progress < 1.0) {
        nudges.add(
          SavingsNudge(
            goalId: goal.id,
            title: 'Enable auto-allocation for ${goal.title}',
            message:
                'Auto-allocation can help keep contributions consistent each month.',
            severity: SavingsNudgeSeverity.info,
          ),
        );
      }
    }

    return nudges;
  }
}
