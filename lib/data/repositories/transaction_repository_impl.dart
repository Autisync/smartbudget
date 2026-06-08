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
      var nextDate = _nextOccurrence(tx.date, tx.recurrence);
      var iterations = 0;

      // Generate all past-due occurrences idempotently: skip any (rule + date)
      // combination that already exists in the DB.
      while (!nextDate.isAfter(now) && iterations < 4000) {
        final exists = await _hasRecurringOccurrence(tx, nextDate);
        if (!exists) {
          // tx comes from the raw DB layer — tx.note is the encrypted ciphertext.
          // Decrypt before handing to addTransaction, which will re-encrypt it.
          // Passing the ciphertext directly would cause double-encryption and
          // make the stored note unreadable.
          final newTransaction = Transaction(
            id: const Uuid().v4(),
            accountId: tx.accountId,
            amount: tx.amount,
            currency: tx.currency,
            type: tx.type,
            category: tx.category,
            date: nextDate,
            note: _enc.decryptNullable(tx.note), // decrypt raw DB value first
            recurrence: tx.recurrence,
            isSynced: false,
          );
          await addTransaction(newTransaction);
        }

        nextDate = _nextOccurrence(nextDate, tx.recurrence);
        iterations++;
      }
    }
  }

  /// Returns true if a transaction already exists for [source]'s rule at
  /// [occurrenceDate].
  ///
  /// Deduplication is intentionally done on structural fields only
  /// (accountId, amount, currency, type, category, recurrence, date).
  /// The note column is excluded because:
  ///   1. It is encrypted with a random nonce (AES-GCM), so two encryptions
  ///      of the same plaintext produce different ciphertexts — a ciphertext
  ///      comparison would never match even for identical notes.
  ///   2. The structural fields alone uniquely identify one occurrence of a
  ///      recurring rule on a specific date.
  Future<bool> _hasRecurringOccurrence(
    db.Transaction source,
    DateTime occurrenceDate,
  ) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.accountId.equals(source.accountId))
      ..where((t) => t.amount.equals(source.amount))
      ..where((t) => t.currency.equals(source.currency))
      ..where((t) => t.type.equals(source.type.index))
      ..where((t) => t.category.equals(source.category))
      ..where((t) => t.recurrence.equals(source.recurrence.index))
      ..where((t) => t.date.equals(occurrenceDate));

    final existing = await query.getSingleOrNull();
    return existing != null;
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
