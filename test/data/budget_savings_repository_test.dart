import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/repositories/budget_repository_impl.dart';
import 'package:smartbudget/data/repositories/savings_goal_repository_impl.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/data/models/tables.dart'
    show BudgetPeriod, GoalPriority, TransactionType, AccountType;

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async => database.close());

  group('BudgetRepositoryImpl', () {
    late BudgetRepositoryImpl repo;
    setUp(() => repo = BudgetRepositoryImpl(database));

    test('add, fetch, update, delete round-trip', () async {
      final budget = Budget(
        id: 'b1',
        category: 'Food',
        limitAmount: 300,
        currency: 'USD',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 1),
      );
      await repo.addBudget(budget);
      expect((await repo.getBudgetById('b1'))!.limitAmount, 300);

      await repo.updateBudget(budget.copyWith(limitAmount: 450));
      expect((await repo.getBudgetById('b1'))!.limitAmount, 450);

      await repo.deleteBudget('b1');
      expect(await repo.getBudgetById('b1'), isNull);
    });

    test('getBudgetSpending sums only expenses within the period', () async {
      await database.insertAccount(db.AccountsCompanion.insert(
        id: const Value('acct_cash'),
        name: 'Cash',
        type: AccountType.cash,
        currency: 'USD',
      ));
      // In-period expense
      await _tx(database, 'Food', 40, TransactionType.expense, DateTime(2026, 1, 10));
      // In-period income (must be ignored)
      await _tx(database, 'Food', 999, TransactionType.income, DateTime(2026, 1, 11));
      // Out-of-period expense (must be ignored)
      await _tx(database, 'Food', 50, TransactionType.expense, DateTime(2026, 3, 1));

      final spent = await repo.getBudgetSpending(
        'Food',
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 31),
      );
      expect(spent, 40);
    });
  });

  group('SavingsGoalRepositoryImpl', () {
    late SavingsGoalRepositoryImpl repo;
    setUp(() => repo = SavingsGoalRepositoryImpl(database));

    test('add, update progress, delete round-trip', () async {
      final goal = SavingsGoal(
        id: 'g1',
        title: 'Vacation',
        targetAmount: 1000,
        savedAmount: 100,
        priority: GoalPriority.medium,
        createdAt: DateTime(2026, 1, 1),
      );
      await repo.addSavingsGoal(goal);
      expect((await repo.getSavingsGoalById('g1'))!.savedAmount, 100);

      await repo.updateSavingsGoal(goal.copyWith(savedAmount: 650));
      expect((await repo.getSavingsGoalById('g1'))!.savedAmount, 650);

      await repo.deleteSavingsGoal('g1');
      expect(await repo.getSavingsGoalById('g1'), isNull);
    });
  });
}

Future<void> _tx(
  db.AppDatabase database,
  String category,
  double amount,
  TransactionType type,
  DateTime date,
) {
  return database.insertTransaction(db.TransactionsCompanion.insert(
    accountId: 'acct_cash',
    amount: amount,
    currency: 'USD',
    type: type,
    category: category,
    date: date,
  ));
}
