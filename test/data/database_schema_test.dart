import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, AccountType, BudgetPeriod;

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('schema version is 7', () {
    expect(database.schemaVersion, 7);
  });

  test('all core tables are created and queryable at the current schema',
      () async {
    // A bare query against each table forces it to exist; a missing table
    // would throw. This guards against forgetting an onUpgrade createTable.
    expect(await database.getAccounts(includeInactive: true), isEmpty);
    expect(await database.getTransactions(), isEmpty);
    expect(await database.getBudgets(), isEmpty);
    expect(await database.getSavingsGoals(), isEmpty);
    expect(await database.getSubscriptions(), isEmpty);
    expect(await database.getAuthLogs(), isEmpty);
    expect(await database.getSecuritySettings(), isNull);
  });

  test('cross-table insert + account balance derivation round-trips',
      () async {
    await database.insertAccount(db.AccountsCompanion.insert(
      id: const Value('acct_cash'),
      name: 'Cash',
      type: AccountType.cash,
      currency: 'USD',
      balance: const Value(100),
    ));
    await database.insertTransaction(db.TransactionsCompanion.insert(
      accountId: 'acct_cash',
      amount: 25,
      currency: 'USD',
      type: TransactionType.income,
      category: 'Gift',
      date: DateTime(2026, 1, 1),
    ));
    await database.insertBudget(db.BudgetsCompanion.insert(
      category: 'Food',
      limitAmount: 300,
      currency: 'USD',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 1, 1),
    ));

    final balances = await database.computeAccountBalances();
    expect(balances['acct_cash'], 125); // 100 opening + 25 income
    expect((await database.getBudgets()).single.category, 'Food');
  });
}
