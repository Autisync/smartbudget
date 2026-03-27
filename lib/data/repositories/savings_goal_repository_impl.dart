import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/domain/repositories/savings_goal_repository.dart';
import 'package:drift/drift.dart';

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  final db.AppDatabase _db;

  SavingsGoalRepositoryImpl(this._db);

  @override
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _db.insertSavingsGoal(db.SavingsGoalsCompanion(
      id: Value(goal.id),
      title: Value(goal.title),
      targetAmount: Value(goal.targetAmount),
      savedAmount: Value(goal.savedAmount),
      deadline: Value(goal.deadline),
      priority: Value(goal.priority),
      color: Value(goal.color),
      autoAllocate: Value(goal.autoAllocate),
      createdAt: Value(goal.createdAt ?? DateTime.now()),
    ));
  }

  @override
  Future<void> deleteSavingsGoal(String id) async {
    await _db.deleteSavingsGoal(id);
  }

  @override
  Future<List<SavingsGoal>> getSavingsGoals() async {
    final rows = await _db.getSavingsGoals();
    return rows
        .map((row) => SavingsGoal(
              id: row.id,
              title: row.title,
              targetAmount: row.targetAmount,
              savedAmount: row.savedAmount,
              deadline: row.deadline,
              priority: row.priority,
              color: row.color,
            ))
        .toList();
  }

  @override
  Future<SavingsGoal?> getSavingsGoalById(String id) async {
    final row = await _db.getSavingsGoalById(id);
    if (row == null) return null;
    return SavingsGoal(
      id: row.id,
      title: row.title,
      targetAmount: row.targetAmount,
      savedAmount: row.savedAmount,
      deadline: row.deadline,
      priority: row.priority,
      color: row.color,
      autoAllocate: row.autoAllocate,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _db.updateSavingsGoal(db.SavingsGoalsCompanion(
      id: Value(goal.id),
      title: Value(goal.title),
      targetAmount: Value(goal.targetAmount),
      savedAmount: Value(goal.savedAmount),
      deadline: Value(goal.deadline),
      priority: Value(goal.priority),
      color: Value(goal.color),
    ));
  }
}
