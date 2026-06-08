import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/repositories/account_repository_impl.dart';
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionType;

void main() {
  late db.AppDatabase database;
  late AccountRepositoryImpl repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = AccountRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> addTx({
    required String accountId,
    required double amount,
    required TransactionType type,
  }) {
    return database.insertTransaction(db.TransactionsCompanion.insert(
      accountId: accountId,
      amount: amount,
      currency: 'USD',
      type: type,
      category: 'Test',
      date: DateTime(2026, 1, 1),
    ));
  }

  group('ensureDefaultAccounts', () {
    test('seeds Cash, Bank Transfer, and Credit Card', () async {
      await repo.ensureDefaultAccounts(currency: 'USD');
      final accounts = await repo.getAccounts();
      expect(accounts.map((a) => a.id), containsAll(<String>[
        DefaultAccountIds.cash,
        DefaultAccountIds.bankTransfer,
        DefaultAccountIds.creditCard,
      ]));
      expect(accounts.every((a) => a.currency == 'USD'), isTrue);
    });

    test('is idempotent — running twice does not duplicate', () async {
      await repo.ensureDefaultAccounts(currency: 'USD');
      await repo.ensureDefaultAccounts(currency: 'USD');
      final accounts = await repo.getAccounts();
      expect(accounts.length, 3);
    });

    test('remaps legacy "default" transactions onto the Cash account',
        () async {
      await addTx(
        accountId: DefaultAccountIds.legacyDefault,
        amount: 50,
        type: TransactionType.expense,
      );
      await repo.ensureDefaultAccounts(currency: 'USD');
      final cash = await repo.getAccount(DefaultAccountIds.cash);
      // The legacy expense now belongs to Cash → balance reflects −50.
      expect(cash!.currentBalance, -50);
    });
  });

  group('derived current balance', () {
    setUp(() => repo.ensureDefaultAccounts(currency: 'USD'));

    test('income adds and expense subtracts from opening balance', () async {
      await addTx(
        accountId: DefaultAccountIds.cash,
        amount: 200,
        type: TransactionType.income,
      );
      await addTx(
        accountId: DefaultAccountIds.cash,
        amount: 75,
        type: TransactionType.expense,
      );
      final cash = await repo.getAccount(DefaultAccountIds.cash);
      expect(cash!.currentBalance, 125); // 0 + 200 − 75
    });

    test('transfers are excluded from the balance', () async {
      await addTx(
        accountId: DefaultAccountIds.bankTransfer,
        amount: 999,
        type: TransactionType.transfer,
      );
      final bank = await repo.getAccount(DefaultAccountIds.bankTransfer);
      expect(bank!.currentBalance, 0);
    });

    test('opening balance is included in current balance', () async {
      final created = await repo.createAccount(
        name: 'Savings Jar',
        type: AccountType.cash,
        currency: 'USD',
        openingBalance: 500,
      );
      await addTx(
        accountId: created.id,
        amount: 100,
        type: TransactionType.income,
      );
      final reloaded = await repo.getAccount(created.id);
      expect(reloaded!.currentBalance, 600);
    });

    test('totalBalance sums current balances across accounts', () async {
      await addTx(
        accountId: DefaultAccountIds.cash,
        amount: 300,
        type: TransactionType.income,
      );
      await addTx(
        accountId: DefaultAccountIds.creditCard,
        amount: 120,
        type: TransactionType.expense,
      );
      expect(await repo.totalBalance(), 180); // 300 − 120
    });
  });

  group('custom account lifecycle', () {
    setUp(() => repo.ensureDefaultAccounts(currency: 'USD'));

    test('create then update name and opening balance', () async {
      final created = await repo.createAccount(
        name: 'Wallet',
        type: AccountType.cash,
        currency: 'USD',
        openingBalance: 10,
      );
      await repo.updateAccount(
        created.copyWith(name: 'Travel Wallet', openingBalance: 40),
      );
      final reloaded = await repo.getAccount(created.id);
      expect(reloaded!.name, 'Travel Wallet');
      expect(reloaded.openingBalance, 40);
    });

    test('deactivate hides custom account but keeps default accounts',
        () async {
      final created = await repo.createAccount(
        name: 'Temp',
        type: AccountType.cash,
        currency: 'USD',
      );
      await repo.deactivateAccount(created.id);
      final active = await repo.getAccounts();
      expect(active.any((a) => a.id == created.id), isFalse);

      // Default accounts are structural and cannot be deactivated.
      await repo.deactivateAccount(DefaultAccountIds.cash);
      final stillActive = await repo.getAccounts();
      expect(stillActive.any((a) => a.id == DefaultAccountIds.cash), isTrue);
    });
  });
}
