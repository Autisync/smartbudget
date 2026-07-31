// Feature-level cover for P3.6: TransactionListScreen used to load an
// account's entire transaction history via transactionListProvider() (no
// limit) on every open. Seeds a dataset larger than one page, confirms only
// the first page renders initially, that scrolling to the bottom loads the
// next page, and that the existing quick-filter chips still work correctly
// against the paginated, accumulated dataset.
//
// Uses a tall test viewport (rather than a default-sized one) so every
// loaded row can actually build — Flutter's SliverList only builds items
// within the viewport + cache extent, so a default 600px-tall test window
// would under-count "loaded" rows regardless of how many the screen's
// state actually holds. With a tall-enough viewport, the render count IS
// the loaded count.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/encryption_service.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/encryption/field_encryptor.dart';
import 'package:smartbudget/data/models/tables.dart' show AccountType, TransactionType;
import 'package:smartbudget/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  late db.AppDatabase database;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.insertAccount(db.AccountsCompanion.insert(
      id: const Value('acct_cash'),
      name: 'Cash',
      type: AccountType.cash,
      currency: 'USD',
    ));
    // 45 transactions — more than one page (30) so the test can prove
    // pagination without needing a huge fixture.
    for (var i = 1; i <= 45; i++) {
      await database.insertTransaction(db.TransactionsCompanion.insert(
        accountId: 'acct_cash',
        amount: 10 + i.toDouble(),
        currency: 'USD',
        type: i % 5 == 0 ? TransactionType.income : TransactionType.expense,
        category: 'Groceries',
        date: DateTime(2026, 1, 1).add(Duration(days: i)),
      ));
    }
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final encryption = EncryptionService(const FlutterSecureStorage());
    await tester.runAsync(() => encryption.initialize());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          fieldEncryptorProvider.overrideWithValue(FieldEncryptor(encryption)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TransactionListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('only the first page renders initially, not the whole history',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byType(Slidable), findsNWidgets(30));
  });

  testWidgets('scrolling to the bottom loads the next page', (tester) async {
    await pumpScreen(tester);
    expect(find.byType(Slidable), findsNWidgets(30));

    // The tall viewport already renders every loaded row, so a small drag
    // (well past the 400px load-more threshold near the bottom of the
    // already-visible list) is enough to trigger the next page.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(find.byType(Slidable), findsNWidgets(45));
  });

  testWidgets('the income quick filter still narrows the loaded, paginated dataset',
      (tester) async {
    await pumpScreen(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(find.byType(Slidable), findsNWidgets(45));

    // Of 45 transactions, every 5th (indices 5,10,...,45) is income = 9 rows.
    await tester.tap(find.text('Income').first);
    await tester.pumpAndSettle();

    expect(find.byType(Slidable), findsNWidgets(9));
  });
}
