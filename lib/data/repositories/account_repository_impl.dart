import 'package:drift/drift.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._db);

  final db.AppDatabase _db;

  @override
  Future<void> ensureDefaultAccounts({required String currency}) async {
    final existing = await _db.getAccountById(DefaultAccountIds.cash);
    if (existing == null) {
      final now = DateTime.now();
      // Seed the three money sources the user picks from at entry time.
      await _db.insertAccount(db.AccountsCompanion.insert(
        id: const Value(DefaultAccountIds.cash),
        name: 'Cash',
        type: AccountType.cash,
        currency: currency,
        createdAt: Value(now),
      ));
      await _db.insertAccount(db.AccountsCompanion.insert(
        id: const Value(DefaultAccountIds.bankTransfer),
        name: 'Bank Transfer',
        type: AccountType.bank,
        currency: currency,
        createdAt: Value(now.add(const Duration(milliseconds: 1))),
      ));
      await _db.insertAccount(db.AccountsCompanion.insert(
        id: const Value(DefaultAccountIds.creditCard),
        name: 'Credit Card',
        type: AccountType.creditCard,
        currency: currency,
        createdAt: Value(now.add(const Duration(milliseconds: 2))),
      ));
    }

    // Idempotent: migrate legacy placeholder transactions onto the Cash account
    // so the accounts↔transactions analytics joins resolve.
    await _db.remapLegacyAccountId(
      fromId: DefaultAccountIds.legacyDefault,
      toId: DefaultAccountIds.cash,
    );
  }

  @override
  Future<List<Account>> getAccounts({bool includeInactive = false}) async {
    final rows = await _db.getAccounts(includeInactive: includeInactive);
    final balances =
        await _db.computeAccountBalances(includeInactive: includeInactive);
    return rows.map((r) => _toEntity(r, balances[r.id] ?? r.balance)).toList();
  }

  @override
  Stream<List<Account>> watchAccounts({bool includeInactive = false}) {
    return _db.watchAccounts(includeInactive: includeInactive).asyncMap(
      (rows) async {
        final deltas = await _db.getNetTransactionDeltaByAccount();
        return rows
            .map((r) => _toEntity(r, r.balance + (deltas[r.id] ?? 0)))
            .toList();
      },
    );
  }

  @override
  Future<Account?> getAccount(String id) async {
    final row = await _db.getAccountById(id);
    if (row == null) return null;
    final balances = await _db.computeAccountBalances(includeInactive: true);
    return _toEntity(row, balances[id] ?? row.balance);
  }

  @override
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required String currency,
    double openingBalance = 0,
  }) async {
    final companion = db.AccountsCompanion.insert(
      name: name,
      type: type,
      currency: currency,
      balance: Value(openingBalance),
    );
    await _db.insertAccount(companion);
    // Re-read to obtain the generated id and createdAt.
    final created = (await _db.getAccounts(includeInactive: true))
        .firstWhere((a) => a.name == name && a.balance == openingBalance);
    return _toEntity(created, created.balance);
  }

  @override
  Future<void> updateAccount(Account account) async {
    final row = await _db.getAccountById(account.id);
    if (row == null) return;
    await _db.updateAccount(
      row
          .copyWith(
            name: account.name,
            type: account.type,
            balance: account.openingBalance,
            currency: account.currency,
            isActive: account.isActive,
          )
          .toCompanion(true),
    );
  }

  @override
  Future<void> deactivateAccount(String id) async {
    // Default money sources are structural and cannot be removed.
    if (id == DefaultAccountIds.cash ||
        id == DefaultAccountIds.bankTransfer ||
        id == DefaultAccountIds.creditCard) {
      return;
    }
    await _db.deactivateAccount(id);
  }

  @override
  Future<double> totalBalance() async {
    final balances = await _db.computeAccountBalances();
    return balances.values.fold<double>(0, (sum, b) => sum + b);
  }

  Account _toEntity(db.Account row, double currentBalance) {
    return Account(
      id: row.id,
      name: row.name,
      type: row.type,
      currency: row.currency,
      openingBalance: row.balance,
      currentBalance: currentBalance,
      isActive: row.isActive,
      createdAt: row.createdAt,
    );
  }
}
