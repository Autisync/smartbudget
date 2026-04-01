import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/tables.dart';

part 'app_database.g.dart';

// Helper used by generated code to provide clientDefault UUIDs.
const _uuid = Uuid();

String _generateUuid() {
  return _uuid.v4();
}

@DriftDatabase(tables: [
  Transactions,
  Accounts,
  Budgets,
  SavingsGoals,
  Subscriptions,
  Devices,
  AuthLogs,
  SecuritySettings
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(transactions, transactions.recurrence);
          }
          if (from < 3) {
            await m.addColumn(transactions, transactions.lastGeneratedAt);
            await m.addColumn(transactions, transactions.nextDueAt);
            await m.addColumn(budgets, budgets.alertThreshold);
            await m.addColumn(savingsGoals, savingsGoals.autoAllocate);
            await m.addColumn(savingsGoals, savingsGoals.createdAt);
          }
          if (from < 4) {
            await m.createTable(subscriptions);
          }
          if (from < 5) {
            await m.createTable(devices);
            await m.createTable(authLogs);
            await m.createTable(securitySettings);
          }
          if (from >= 4 && from < 6) {
            await m.addColumn(subscriptions, subscriptions.importance);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(p.join(docs.path, 'smartbudget_db.sqlite'));
      return NativeDatabase(file);
    });
  }

  // Transaction Queries
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountId,
  }) {
    final query = select(transactions);

    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate));
    }
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    if (accountId != null) {
      query.where((t) => t.accountId.equals(accountId));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.get();
  }

  Future<List<Transaction>> getTransactionsByMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return getTransactions(startDate: start, endDate: end);
  }

  // Analytics Queries
  Future<Map<String, double>> getCategoryTotals(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final joined = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ]);
    joined.where(transactions.date.isBetweenValues(start, end));
    joined.where(transactions.type.equals(TransactionType.expense.index));
    joined.groupBy([transactions.category]);
    joined.addColumns([transactions.amount.sum()]);

    final results = await joined.get();
    return {
      for (var row in results)
        row.read(transactions.category)!:
            row.read(transactions.amount.sum()) ?? 0.0,
    };
  }

  Stream<double> watchTotalBalance() {
    final query = select(accounts);
    query.where((a) => a.isActive.equals(true));

    return query.watch().map(
          (accounts) => accounts.fold(0.0, (sum, acc) => sum + acc.balance),
        );
  }

  // Budget Queries
  Future<List<Budget>> getBudgets() {
    final query = select(budgets)..where((b) => b.isActive.equals(true));
    return query.get();
  }

  Future<double> getBudgetSpending(
      String category, DateTime periodStart, DateTime periodEnd) async {
    final query = select(transactions)
      ..where((t) => t.category.equals(category))
      ..where((t) => t.type.equals(TransactionType.expense.index))
      ..where((t) => t.date.isBiggerOrEqualValue(periodStart))
      ..where((t) => t.date.isSmallerOrEqualValue(periodEnd));

    final rows = await query.get();
    return rows.fold<double>(0.0, (sum, row) => sum + row.amount);
  }

  Future<List<Transaction>> getRecurringTransactionsDue(DateTime before) async {
    final query = select(transactions)
      ..where((t) => t.recurrence.isNotIn([TransactionRecurrence.none.index]))
      ..where((t) => t.date.isSmallerOrEqualValue(before));
    return query.get();
  }

  Future<void> insertRecurringTransaction(
      TransactionsCompanion transaction) async {
    await into(transactions)
        .insert(transaction, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertBudget(BudgetsCompanion budget) async {
    await into(budgets).insert(budget, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateBudget(BudgetsCompanion budget) async {
    await update(budgets).replace(budget);
  }

  Future<void> deleteBudget(String id) async {
    await (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  Future<Budget?> getBudgetById(String id) async {
    final query = select(budgets)..where((b) => b.id.equals(id));
    return query.getSingleOrNull();
  }

  // SavingsGoal Queries
  Future<List<SavingsGoal>> getSavingsGoals() {
    final query = select(savingsGoals);
    return query.get();
  }

  Future<void> insertSavingsGoal(SavingsGoalsCompanion goal) async {
    await into(savingsGoals).insert(goal, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateSavingsGoal(SavingsGoalsCompanion goal) async {
    await update(savingsGoals).replace(goal);
  }

  Future<void> deleteSavingsGoal(String id) async {
    await (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
  }

  Future<SavingsGoal?> getSavingsGoalById(String id) async {
    final query = select(savingsGoals)..where((g) => g.id.equals(id));
    return query.getSingleOrNull();
  }

  // Insert with conflict resolution
  Future<void> insertTransaction(TransactionsCompanion transaction) async {
    await into(
      transactions,
    ).insert(transaction, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateSyncStatus(String id, bool synced) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(isSynced: Value(synced)),
    );
  }

  Future<List<Transaction>> getUnsyncedTransactions() async {
    final q = select(transactions);
    q.where((t) => t.isSynced.equals(false));
    return await q.get();
  }

  // Subscription Queries
  Future<List<Subscription>> getSubscriptions() {
    final query = select(subscriptions)..where((s) => s.isActive.equals(true));
    return query.get();
  }

  Future<SecuritySetting?> getSecuritySettings() {
    final query = select(securitySettings)..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> upsertSecuritySettings(SecuritySettingsCompanion setting) async {
    await into(securitySettings)
        .insert(setting, mode: InsertMode.insertOrReplace);
  }

  Future<List<AuthLog>> getAuthLogs({int limit = 20}) {
    final query = select(authLogs)
      ..orderBy([
        (a) => OrderingTerm.desc(a.timestamp),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> insertAuthLog(AuthLogsCompanion log) async {
    await into(authLogs).insert(log);
  }

  Future<List<Subscription>> getDueSubscriptions(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0);

    final query = select(subscriptions)
      ..where((s) => s.isActive.equals(true))
      ..where(
          (s) => s.nextBillingDate.isBetweenValues(startOfMonth, endOfMonth));

    return query.get();
  }

  Future<void> insertSubscription(SubscriptionsCompanion subscription) async {
    await into(subscriptions)
        .insert(subscription, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateSubscription(SubscriptionsCompanion subscription) async {
    await update(subscriptions).replace(subscription);
  }

  Future<void> deleteSubscription(String id) async {
    await (delete(subscriptions)..where((s) => s.id.equals(id))).go();
  }

  Future<Subscription?> getSubscriptionById(String id) async {
    final query = select(subscriptions)..where((s) => s.id.equals(id));
    return query.getSingleOrNull();
  }
}
