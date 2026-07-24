import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';
import 'package:smartbudget/data/repositories/transaction_repository_impl.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/domain/repositories/transaction_repository.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/intelligence/engines/financial_insight_engines.dart';

part 'transaction_provider.g.dart';

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) {
  final database = ref.watch(databaseProvider);
  final encryptor = ref.watch(fieldEncryptorProvider);
  return TransactionRepositoryImpl(database, encryptor);
}

@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getTransactions(
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  Future<void> addTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.addTransaction(transaction);

      // Invalidate related providers
      ref.invalidate(spendingProfileProvider);
      ref.invalidate(recentTransactionsProvider);

      return repo.getTransactions();
    });
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.deleteTransaction(id);
      return repo.getTransactions();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      return repo.getTransactions();
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.updateTransaction(transaction);
      ref.invalidate(spendingProfileProvider);
      ref.invalidate(recentTransactionsProvider);
      return repo.getTransactions();
    });
  }
}

@riverpod
Future<List<Transaction>> recentTransactions(Ref ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  return repo.getTransactions(startDate: start, endDate: now);
}

@riverpod
Future<SpendingProfile> spendingProfile(Ref ref) async {
  final transactions = await ref.watch(recentTransactionsProvider.future);
  final analyzer = SpendingAnalyzer();
  final now = DateTime.now();
  return analyzer.analyze(transactions, now);
}

@riverpod
Future<BurnRateInsight> burnRateInsight(Ref ref) async {
  final transactions = await ref.watch(transactionListProvider().future);
  return const BurnRateEngine().calculate(
    transactions: transactions,
  );
}

@riverpod
Future<TransactionDecisionSnapshotData> transactionDecisionSnapshot(
  Ref ref,
) async {
  final transactions = await ref.watch(transactionListProvider().future);
  return const TransactionInsightEngine().build(
    transactions: transactions,
  );
}

@riverpod
Future<CashflowPrediction> cashflowPrediction(Ref ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final transactions = await repo.getTransactions();
  final currentBalance = transactions.fold<double>(0.0, (sum, tx) {
    return tx.isIncome ? sum + tx.amount : sum - tx.amount;
  });

  final predictor = CashflowPredictor();
  return predictor.predict(transactions, DateTime.now(), currentBalance);
}

@riverpod
Future<void> recurringTransactions(Ref ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  await repo.generateRecurringTransactions();
}
