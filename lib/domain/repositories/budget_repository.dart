import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgets();
  Future<Budget?> getBudgetById(String id);
  Future<void> addBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);

  Future<double> getBudgetSpending(
      String category, DateTime start, DateTime end);
}




