import 'package:smartbudget/domain/entities/account.dart';

abstract class AccountRepository {
  /// Seeds the three default money-source accounts (Cash, Bank Transfer,
  /// Credit Card) if they do not already exist, and remaps any legacy
  /// `'default'` transactions onto the Cash account. Idempotent.
  Future<void> ensureDefaultAccounts({required String currency});

  /// All accounts with their derived current balances.
  Future<List<Account>> getAccounts({bool includeInactive = false});

  /// Live stream of accounts with derived current balances.
  Stream<List<Account>> watchAccounts({bool includeInactive = false});

  Future<Account?> getAccount(String id);

  /// Creates a custom account with the given opening balance.
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required String currency,
    double openingBalance = 0,
  });

  /// Updates a custom account's editable fields (name, type, opening balance).
  Future<void> updateAccount(Account account);

  /// Soft-deletes (deactivates) an account. Default accounts cannot be removed.
  Future<void> deactivateAccount(String id);

  /// Sum of current balances across active accounts.
  Future<double> totalBalance();
}
