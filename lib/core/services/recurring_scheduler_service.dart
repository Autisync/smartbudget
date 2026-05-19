import 'package:drift/drift.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionRecurrence;

class RecurringSchedulerService {
  final AppDatabase database;

  RecurringSchedulerService(this.database);

  DateTime _nextDueDate(DateTime date, TransactionRecurrence recurrence) {
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

  Future<void> syncRecurringTransactions({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final due = await database.getRecurringTransactionsDue(today);

    for (final tx in due) {
      if (tx.recurrence == TransactionRecurrence.none) continue;

      final currentDate = tx.date;
      final nextDate = _nextDueDate(currentDate, tx.recurrence);
      final nextNextDate = _nextDueDate(nextDate, tx.recurrence);

      await database.insertTransaction(
        TransactionsCompanion(
          id: Value('${tx.id}-${today.millisecondsSinceEpoch}'),
          accountId: Value(tx.accountId),
          amount: Value(tx.amount),
          currency: Value(tx.currency),
          type: Value(tx.type),
          category: Value(tx.category),
          date: Value(nextDate),
          note: Value(tx.note),
          recurrence: Value(tx.recurrence),
          isRecurring: const Value(true),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          nextDueAt: Value(nextNextDate),
          lastGeneratedAt: Value(today),
          isSynced: const Value(false),
        ),
      );

      await (database.update(database.transactions)
            ..where((t) => t.id.equals(tx.id)))
          .write(
        TransactionsCompanion(
          nextDueAt: Value(nextNextDate),
          lastGeneratedAt: Value(today),
        ),
      );
    }
  }
}




