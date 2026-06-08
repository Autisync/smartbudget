import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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

  /// Test-only constructor that accepts a custom executor (e.g. an in-memory
  /// database) so the schema and queries can be exercised without touching disk.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Downgrades are unsupported: a newer DB may contain tables/columns
          // this build cannot understand, and silently opening it risks data
          // loss. Fail loudly instead so the issue is caught immediately.
          if (from > to) {
            throw StateError(
              'Cannot open SmartSpend database: stored schema v$from is newer '
              'than this app build (v$to). Update the app to continue.',
            );
          }
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

  // ---------------------------------------------------------------------------
  // Account Queries
  //
  // Accounts model the *source* of money (Cash, Bank Transfer, Credit Card, …).
  // The stored `balance` column is treated as the account's OPENING balance.
  // The live "current balance" is always DERIVED as:
  //     opening + Σ(income to account) − Σ(expense from account)
  // Deriving on read (rather than mutating a stored running total on every
  // write) guarantees the balance can never drift out of sync with the ledger.
  // Transfers are excluded because the single-accountId schema cannot model the
  // counterparty side of a transfer.
  // ---------------------------------------------------------------------------

  Future<List<Account>> getAccounts({bool includeInactive = false}) {
    final query = select(accounts);
    if (!includeInactive) {
      query.where((a) => a.isActive.equals(true));
    }
    query.orderBy([(a) => OrderingTerm.asc(a.createdAt)]);
    return query.get();
  }

  Stream<List<Account>> watchAccounts({bool includeInactive = false}) {
    final query = select(accounts);
    if (!includeInactive) {
      query.where((a) => a.isActive.equals(true));
    }
    query.orderBy([(a) => OrderingTerm.asc(a.createdAt)]);
    return query.watch();
  }

  Future<Account?> getAccountById(String id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertAccount(AccountsCompanion account) async {
    await into(accounts).insert(account, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateAccount(AccountsCompanion account) async {
    await update(accounts).replace(account);
  }

  /// Soft-deletes an account by marking it inactive. We never hard-delete an
  /// account that may still be referenced by historical transactions.
  Future<void> deactivateAccount(String id) async {
    await (update(accounts)..where((a) => a.id.equals(id))).write(
      const AccountsCompanion(isActive: Value(false)),
    );
  }

  /// Returns the net transaction delta (income − expense, transfers excluded)
  /// grouped by accountId. Used to derive current balances.
  Future<Map<String, double>> getNetTransactionDeltaByAccount() async {
    final rows = await select(transactions).get();
    final deltas = <String, double>{};
    for (final tx in rows) {
      switch (tx.type) {
        case TransactionType.income:
          deltas[tx.accountId] = (deltas[tx.accountId] ?? 0) + tx.amount;
        case TransactionType.expense:
          deltas[tx.accountId] = (deltas[tx.accountId] ?? 0) - tx.amount;
        case TransactionType.transfer:
          break; // counterparty cannot be modelled with a single accountId
      }
    }
    return deltas;
  }

  /// Current balance per account id: opening balance + net transaction delta.
  Future<Map<String, double>> computeAccountBalances({
    bool includeInactive = false,
  }) async {
    final accs = await getAccounts(includeInactive: includeInactive);
    final deltas = await getNetTransactionDeltaByAccount();
    return {
      for (final a in accs) a.id: a.balance + (deltas[a.id] ?? 0),
    };
  }

  /// One-time, idempotent remap of legacy transactions that were written with
  /// the placeholder accountId `'default'` (before real accounts existed) onto
  /// a concrete account. Without this, the accounts↔transactions inner joins
  /// used by analytics return zero rows for legacy data.
  Future<int> remapLegacyAccountId({
    required String fromId,
    required String toId,
  }) async {
    return (update(transactions)..where((t) => t.accountId.equals(fromId)))
        .write(TransactionsCompanion(accountId: Value(toId)));
  }

  Stream<double> watchTotalBalance() {
    // Total current balance across active accounts (opening + net ledger).
    return watchAccounts().asyncMap((accs) async {
      final deltas = await getNetTransactionDeltaByAccount();
      return accs.fold<double>(
        0.0,
        (sum, acc) => sum + acc.balance + (deltas[acc.id] ?? 0),
      );
    });
  }

  // Budget Queries
  Future<List<Budget>> getBudgets() {
    final query = select(budgets);
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

  /// H-2: Returns count of failed auth attempts for [deviceId] within [window].
  /// Used by SecurityService.isLockedOut() to enforce client-side lockout.
  Future<int> countRecentAuthFailures({
    required Duration window,
    String deviceId = 'local_device',
  }) async {
    final since = DateTime.now().subtract(window);
    final query = select(authLogs)
      ..where((a) => a.deviceId.equals(deviceId))
      ..where((a) => a.status.equals(AuthStatus.failed.index))
      ..where((a) => a.timestamp.isBiggerOrEqualValue(since));
    final results = await query.get();
    return results.length;
  }

  /// M-4: Deletes auth log entries older than [retentionDays] days.
  Future<void> pruneAuthLogs({int retentionDays = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    await (delete(authLogs)
          ..where((a) => a.timestamp.isSmallerThanValue(cutoff)))
        .go();
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
