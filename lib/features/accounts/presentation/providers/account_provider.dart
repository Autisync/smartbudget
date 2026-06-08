import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/repositories/account_repository_impl.dart';
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/domain/repositories/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return AccountRepositoryImpl(database);
});

/// Live list of active accounts with derived current balances.
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAccounts();
});

/// One-shot fetch of active accounts (used by the transaction entry picker so
/// it has a value synchronously on first build once resolved).
final accountsListProvider = FutureProvider<List<Account>>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getAccounts();
});

/// Total current balance across active accounts.
final totalAccountBalanceProvider = FutureProvider<double>((ref) async {
  // Recompute whenever the account stream emits (e.g. after a transaction).
  ref.watch(accountsProvider);
  final repo = ref.watch(accountRepositoryProvider);
  return repo.totalBalance();
});
