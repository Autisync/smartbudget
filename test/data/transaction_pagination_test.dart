// Regression cover for P3.6: getTransactions() previously always loaded the
// entire matching result set into memory — TransactionListScreen rendered
// an account's whole transaction history on every open. limit/offset are
// optional and default to unbounded so every non-UI caller (analytics,
// cashflow prediction, etc.) keeps getting the full set unchanged.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/models/tables.dart' show TransactionType, AccountType;

void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.insertAccount(db.AccountsCompanion.insert(
      id: const Value('acct_cash'),
      name: 'Cash',
      type: AccountType.cash,
      currency: 'USD',
    ));
    // 50 transactions, one per day, oldest first — descending date order
    // (the query's own sort) makes index 0 the newest (day 50).
    for (var i = 1; i <= 50; i++) {
      await database.insertTransaction(db.TransactionsCompanion.insert(
        accountId: 'acct_cash',
        amount: i.toDouble(),
        currency: 'USD',
        type: TransactionType.expense,
        category: 'Groceries',
        date: DateTime(2026, 1, 1).add(Duration(days: i)),
      ));
    }
  });

  tearDown(() async {
    await database.close();
  });

  test('no limit returns every matching row, unchanged from before pagination existed', () async {
    final all = await database.getTransactions();
    expect(all, hasLength(50));
  });

  test('limit alone returns the first page from the newest transaction', () async {
    final page = await database.getTransactions(limit: 20);
    expect(page, hasLength(20));
    expect(page.first.amount, 50); // newest (day 50) first
    expect(page.last.amount, 31);
  });

  test('limit + offset returns the correct, non-overlapping second page', () async {
    final firstPage = await database.getTransactions(limit: 20, offset: 0);
    final secondPage = await database.getTransactions(limit: 20, offset: 20);

    expect(firstPage, hasLength(20));
    expect(secondPage, hasLength(20));

    final firstIds = firstPage.map((t) => t.id).toSet();
    final secondIds = secondPage.map((t) => t.id).toSet();
    expect(firstIds.intersection(secondIds), isEmpty);

    expect(secondPage.first.amount, 30);
    expect(secondPage.last.amount, 11);
  });

  test('the final partial page returns only the remaining rows', () async {
    final thirdPage = await database.getTransactions(limit: 20, offset: 40);
    expect(thirdPage, hasLength(10));
    expect(thirdPage.first.amount, 10);
    expect(thirdPage.last.amount, 1);
  });

  test('an offset past the end returns an empty page, not an error', () async {
    final page = await database.getTransactions(limit: 20, offset: 100);
    expect(page, isEmpty);
  });

  test('pagination composes with the existing category filter', () async {
    await database.insertTransaction(db.TransactionsCompanion.insert(
      accountId: 'acct_cash',
      amount: 999,
      currency: 'USD',
      type: TransactionType.expense,
      category: 'Rent',
      date: DateTime(2026, 3, 1),
    ));

    final page = await database.getTransactions(
      category: 'Groceries',
      limit: 10,
      offset: 0,
    );

    expect(page, hasLength(10));
    expect(page.every((t) => t.category == 'Groceries'), isTrue);
  });
}
