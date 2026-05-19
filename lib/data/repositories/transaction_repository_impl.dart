import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/models/tables.dart' show TransactionRecurrence;
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/domain/repositories/transaction_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final db.AppDatabase _db;

  TransactionRepositoryImpl(this._db);

  @override
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final results = await _db.getTransactions(
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
    return results.map((row) => _mapToEntity(row)).toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final companion = db.TransactionsCompanion(
      id: Value(transaction.id),
      accountId: Value(transaction.accountId),
      amount: Value(transaction.amount),
      currency: Value(transaction.currency),
      type: Value(transaction.type),
      category: Value(transaction.category),
      date: Value(transaction.date),
      note: Value(transaction.note),
      recurrence: Value(transaction.recurrence),
      isSynced: const Value(false),
    );

    await _db.insertTransaction(companion);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final query = _db.select(_db.transactions)..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final companion = db.TransactionsCompanion(
      id: Value(transaction.id),
      accountId: Value(transaction.accountId),
      amount: Value(transaction.amount),
      currency: Value(transaction.currency),
      type: Value(transaction.type),
      category: Value(transaction.category),
      date: Value(transaction.date),
      note: Value(transaction.note),
      recurrence: Value(transaction.recurrence),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );

    await _db.update(_db.transactions).replace(companion);
  }

  @override
  Future<void> syncTransactions() async {
    // Implementation for cloud sync
    final unsynced = await _db.getUnsyncedTransactions();
    // TODO: Send to API and mark as synced
    for (final tx in unsynced) {
      await _db.updateSyncStatus(tx.id, true);
    }
  }

  @override
  Future<void> generateRecurringTransactions() async {
    final now = DateTime.now();
    final dueTxs = await _db.getRecurringTransactionsDue(now);

    for (final tx in dueTxs) {
      final nextDate = _nextOccurrence(tx.date, tx.recurrence);
      if (nextDate.isAfter(now)) continue;

      final newTransaction = Transaction(
        id: const Uuid().v4(),
        accountId: tx.accountId,
        amount: tx.amount,
        currency: tx.currency,
        type: tx.type,
        category: tx.category,
        date: nextDate,
        note: tx.note,
        recurrence: tx.recurrence,
        isSynced: false,
      );
      await addTransaction(newTransaction);
    }
  }

  DateTime _nextOccurrence(DateTime date, TransactionRecurrence recurrence) {
    switch (recurrence) {
      case TransactionRecurrence.daily:
        return date.add(const Duration(days: 1));
      case TransactionRecurrence.weekly:
        return date.add(const Duration(days: 7));
      case TransactionRecurrence.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case TransactionRecurrence.yearly:
        return DateTime(date.year + 1, date.month, date.day);
      case TransactionRecurrence.none:
        return date;
    }
  }

  @override
  Stream<List<Transaction>> watchTransactions() {
    final query = _db.select(_db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return query.watch().map((rows) => rows.map(_mapToEntity).toList());
  }

  Transaction _mapToEntity(db.Transaction row) {
    return Transaction(
      id: row.id,
      accountId: row.accountId,
      amount: row.amount,
      currency: row.currency,
      type: row.type,
      category: row.category,
      date: row.date,
      note: row.note,
      recurrence: row.recurrence,
      isSynced: row.isSynced,
    );
  }
}




