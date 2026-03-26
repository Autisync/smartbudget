import '../entities/savings_goal.dart';

abstract class SavingsGoalRepository {
  Future<List<SavingsGoal>> getSavingsGoals();
  Future<SavingsGoal?> getSavingsGoalById(String id);
  Future<void> addSavingsGoal(SavingsGoal goal);
  Future<void> updateSavingsGoal(SavingsGoal goal);
  Future<void> deleteSavingsGoal(String id);
}
