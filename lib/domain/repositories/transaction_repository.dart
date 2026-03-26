import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  });

  Future<Transaction?> getTransactionById(String id);
  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<void> syncTransactions();
  Future<void> generateRecurringTransactions();

  Stream<List<Transaction>> watchTransactions();
}
