import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/repositories/budget_repository.dart';
import 'package:drift/drift.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final db.AppDatabase _db;

  BudgetRepositoryImpl(this._db);

  @override
  Future<void> addBudget(Budget budget) async {
    await _db.insertBudget(db.BudgetsCompanion(
      id: Value(budget.id),
      category: Value(budget.category),
      limitAmount: Value(budget.limitAmount),
      currency: Value(budget.currency),
      period: Value(budget.period),
      startDate: Value(budget.startDate),
      endDate: Value(budget.endDate),
      alertThreshold: Value(budget.alertThreshold),
      isActive: Value(budget.isActive),
    ));
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    final row = await _db.getBudgetById(id);
    if (row == null) return null;
    return Budget(
      id: row.id,
      category: row.category,
      limitAmount: row.limitAmount,
      currency: row.currency,
      period: row.period,
      startDate: row.startDate,
      endDate: row.endDate,
      alertThreshold: row.alertThreshold,
      isActive: row.isActive,
    );
  }

  @override
  Future<List<Budget>> getBudgets() async {
    final rows = await _db.getBudgets();
    return rows
        .map((row) => Budget(
              id: row.id,
              category: row.category,
              limitAmount: row.limitAmount,
              currency: row.currency,
              period: row.period,
              startDate: row.startDate,
              endDate: row.endDate,
              isActive: row.isActive,
            ))
        .toList();
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await _db.updateBudget(db.BudgetsCompanion(
      id: Value(budget.id),
      category: Value(budget.category),
      limitAmount: Value(budget.limitAmount),
      currency: Value(budget.currency),
      period: Value(budget.period),
      startDate: Value(budget.startDate),
      endDate: Value(budget.endDate),
      alertThreshold: Value(budget.alertThreshold),
      isActive: Value(budget.isActive),
    ));
  }

  @override
  Future<double> getBudgetSpending(
      String category, DateTime start, DateTime end) async {
    return await _db.getBudgetSpending(category, start, end);
  }
}
