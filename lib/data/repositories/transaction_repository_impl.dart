import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/encryption/field_encryptor.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionRecurrence;
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/domain/repositories/transaction_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final db.AppDatabase _db;
  final FieldEncryptor _enc;

  // C-2: Requires a [FieldEncryptor] to encrypt/decrypt the `note` field.
  TransactionRepositoryImpl(this._db, this._enc);

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
      note: Value(_enc.encryptNullable(transaction.note)), // C-2: encrypted
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
      note: Value(_enc.encryptNullable(transaction.note)), // C-2: encrypted
      recurrence: Value(transaction.recurrence),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );

    await _db.update(_db.transactions).replace(companion);
  }

  @override
  Future<void> syncTransactions() async {
    // Cloud sync not yet implemented. Transactions intentionally remain marked
    // isSynced=false until the backend sync endpoint is integrated. Do NOT mark
    // records as synced here — callers rely on isSynced=false to know what
    // still needs to be sent to the server.
  }

  @override
  Future<void> generateRecurringTransactions() async {
    final now = DateTime.now();
    final dueTxs = await _db.getRecurringTransactionsDue(now);

    for (final tx in dueTxs) {
      // Load the set of dates this rule already has occurrences for ONCE, then
      // dedupe in memory. Previously this issued one query per missed
      // occurrence — O(n) round-trips (e.g. ~365 for a year of daily). Now it
      // is a single query per rule.
      final existingDates = await _existingOccurrenceDates(tx);
      // tx.note is the encrypted ciphertext from the raw DB layer; decrypt once
      // before re-inserting, otherwise addTransaction would double-encrypt it.
      final decryptedNote = _enc.decryptNullable(tx.note);

      var nextDate = _nextOccurrence(tx.date, tx.recurrence);
      var iterations = 0;
      while (!nextDate.isAfter(now) && iterations < 4000) {
        if (!existingDates.contains(nextDate)) {
          await addTransaction(Transaction(
            id: const Uuid().v4(),
            accountId: tx.accountId,
            amount: tx.amount,
            currency: tx.currency,
            type: tx.type,
            category: tx.category,
            date: nextDate,
            note: decryptedNote,
            recurrence: tx.recurrence,
            isSynced: false,
          ));
          existingDates.add(nextDate); // guard against same-run duplicates
        }

        nextDate = _nextOccurrence(nextDate, tx.recurrence);
        iterations++;
      }
    }
  }

  /// All dates that already have a transaction matching [source]'s recurring
  /// rule. Loaded in a single query so the generator can dedupe in memory.
  ///
  /// Matching is on structural fields only (accountId, amount, currency, type,
  /// category, recurrence). The note column is excluded because AES-GCM uses a
  /// random nonce — identical notes produce different ciphertexts — and the
  /// structural fields already uniquely identify an occurrence on a date.
  Future<Set<DateTime>> _existingOccurrenceDates(db.Transaction source) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.accountId.equals(source.accountId))
      ..where((t) => t.amount.equals(source.amount))
      ..where((t) => t.currency.equals(source.currency))
      ..where((t) => t.type.equals(source.type.index))
      ..where((t) => t.category.equals(source.category))
      ..where((t) => t.recurrence.equals(source.recurrence.index));

    final rows = await query.get();
    return rows.map((r) => r.date).toSet();
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
      note: _enc.decryptNullable(row.note), // C-2: decrypt with plaintext fallback
      recurrence: row.recurrence,
      isSynced: row.isSynced,
    );
  }
}
