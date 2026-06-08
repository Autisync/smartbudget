import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/services/encryption_service.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart' as db;
import 'package:smartbudget/data/encryption/field_encryptor.dart';
import 'package:smartbudget/data/repositories/transaction_repository_impl.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;

void _installFakeSecureStorage() {
  final store = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
    final key = args['key'] as String?;
    switch (call.method) {
      case 'write':
        store[key!] = args['value'] as String;
        return null;
      case 'read':
        return store[key];
      case 'delete':
        store.remove(key);
        return null;
      case 'readAll':
        return Map<String, String>.from(store);
      default:
        return null;
    }
  });
}

void main() {
  late db.AppDatabase database;
  late TransactionRepositoryImpl repo;

  setUp(() async {
    _installFakeSecureStorage();
    final encryption = EncryptionService(const FlutterSecureStorage());
    await encryption.initialize();
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepositoryImpl(database, FieldEncryptor(encryption));
  });

  tearDown(() async {
    await database.close();
  });

  test('generates missed daily occurrences up to now and dedupes', () async {
    // A daily recurring expense that started 5 days ago.
    final start = DateTime.now().subtract(const Duration(days: 5));
    await repo.addTransaction(Transaction(
      id: 'seed',
      accountId: 'acct_cash',
      amount: 10,
      currency: 'USD',
      type: TransactionType.expense,
      category: 'Coffee',
      date: DateTime(start.year, start.month, start.day),
      note: 'Latte',
      recurrence: TransactionRecurrence.daily,
    ));

    await repo.generateRecurringTransactions();
    final afterFirst = await repo.getTransactions();

    // Running again must NOT create duplicates (idempotent dedup).
    await repo.generateRecurringTransactions();
    final afterSecond = await repo.getTransactions();

    expect(afterSecond.length, afterFirst.length);
    expect(afterFirst.length, greaterThan(1));
  });

  test('generated occurrences carry decrypted (not double-encrypted) notes',
      () async {
    final start = DateTime.now().subtract(const Duration(days: 2));
    await repo.addTransaction(Transaction(
      id: 'seed2',
      accountId: 'acct_cash',
      amount: 5,
      currency: 'USD',
      type: TransactionType.expense,
      category: 'Snack',
      date: DateTime(start.year, start.month, start.day),
      note: 'Daily snack',
      recurrence: TransactionRecurrence.daily,
    ));

    await repo.generateRecurringTransactions();
    final all = await repo.getTransactions();

    // Every generated row must decrypt back to the original plaintext note,
    // proving the note was decrypted once before re-insert (no double-encrypt).
    expect(all.every((t) => t.note == 'Daily snack'), isTrue);
  });
}
