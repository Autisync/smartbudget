import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class _FakeCurrencyService extends CurrencyService {
  _FakeCurrencyService() : super(const FlutterSecureStorage());

  @override
  Future<String> loadCurrencyCode() async => 'USD';

  @override
  Future<void> saveCurrencyCode(String code) async {}
}

Widget _testShell({
  required Widget child,
  required MediaQueryData mediaQuery,
}) {
  return ProviderScope(
    overrides: [
      currencyServiceProvider.overrideWith((_) => _FakeCurrencyService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: mediaQuery,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('subscription edit modal remains keyboard-safe on small screens',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));

    final now = DateTime(2026, 1, 1);
    final subscription = Subscription(
      id: 'sub-1',
      name: 'Netflix',
      description: 'Streaming',
      amount: 18.99,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      startDate: now,
      nextBillingDate: now.add(const Duration(days: 28)),
      category: 'Streaming',
      importance: SubscriptionImportance.high,
      isActive: true,
      paymentMethod: 'Card',
      website: 'netflix.com',
      createdAt: now,
      updatedAt: now,
    );

    const mediaQuery = MediaQueryData(
      size: Size(320, 568),
      viewInsets: EdgeInsets.only(bottom: 260),
    );

    await tester.pumpWidget(
      _testShell(
        mediaQuery: mediaQuery,
        child: SubscriptionFormSheet(
          mode: SubscriptionFormMode.update,
          initialData: subscription,
          asModal: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.takeException(), isNull);

    expect(find.byType(TextField), findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('transaction create and update modals remain equivalent',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    const mediaQuery = MediaQueryData(size: Size(390, 844));
    await tester.pumpWidget(
      _testShell(
        mediaQuery: mediaQuery,
        child: const AddTransactionScreen(
          key: ValueKey('create-transaction-modal'),
          asModal: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(SegmentedButton<TransactionType>), findsOneWidget);
    expect(tester.takeException(), isNull);

    final existing = Transaction(
      id: 'tx-1',
      accountId: 'default',
      amount: 42.5,
      currency: 'USD',
      type: TransactionType.expense,
      category: 'Food',
      date: DateTime(2026, 1, 2),
      recurrence: TransactionRecurrence.none,
      isSynced: false,
      note: 'Lunch',
    );

    await tester.pumpWidget(
      _testShell(
        mediaQuery: mediaQuery,
        child: AddTransactionScreen(
          key: const ValueKey('update-transaction-modal'),
          asModal: true,
          existingTransaction: existing,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(SegmentedButton<TransactionType>), findsOneWidget);
    final editableTexts = tester.widgetList<EditableText>(
      find.byType(EditableText),
    );
    final hasPrefilledAmount = editableTexts
        .any((editable) => editable.controller.text.trim().startsWith('42'));
    expect(hasPrefilledAmount, isTrue);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  test('budget and savings modal forms use shared form sheet wrappers', () {
    final files = {
      'lib/features/budgets/presentation/screens/budget_screen.dart',
      'lib/features/savings/presentation/screens/savings_screen.dart',
      'lib/features/transactions/presentation/screens/add_transaction_screen.dart',
      'lib/features/subscriptions/presentation/screens/add_subscription_screen.dart',
    };

    for (final path in files) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      final content = file.readAsStringSync();
      expect(
          content.contains('KeyboardAwareFormSheet(') ||
              content.contains('AppFormSheet('),
          isTrue,
          reason: 'Expected keyboard-aware modal in $path');
    }
  });
}
