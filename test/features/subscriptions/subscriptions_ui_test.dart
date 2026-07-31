import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/subscriptions_screen.dart';

class _FakeCurrencyService extends CurrencyService {
  _FakeCurrencyService(super.prefs);

  @override
  Future<String> loadCurrencyCode() async => 'USD';

  @override
  Future<void> saveCurrencyCode(String code) async {}
}

void main() {
  testWidgets('Decision snapshot card renders key metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionDecisionSnapshotCard(
            activeCount: 6,
            criticalCount: 3,
            renewingSoonCount: 2,
            highPriorityCount: 4,
            monthlyLoad: 284.3,
            lowPriorityMonthlyCost: 55,
            currencySymbol: r'$',
            insightText:
                'Your subscription stack looks stable. Review monthly load and low-priority services to keep it that way.',
            filters: SubscriptionFilter.values,
            activeFilter: null,
            filterLabelBuilder: (filter) => filter.name,
            onFilterSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Subscription Portfolio'), findsOneWidget);
    expect(find.text('3 critical'), findsOneWidget);
    expect(find.textContaining('284'), findsOneWidget);
    expect(find.text('Next Renewal'), findsOneWidget);
    expect(find.text('Optional Savings'), findsOneWidget);
  });

  testWidgets('Subscription card handles long titles and actions',
      (tester) async {
    final now = DateTime(2026, 1, 1);
    final sub = Subscription(
      id: 'sub-1',
      name:
          'Very Long Subscription Name That Should Truncate Cleanly Without Overflowing Layout',
      description: 'Design QA',
      amount: 14.99,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      startDate: now,
      nextBillingDate: now.add(const Duration(days: 8)),
      category: 'Streaming',
      importance: SubscriptionImportance.high,
      isActive: true,
      paymentMethod: 'Card',
      website: 'example.com',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 330,
            child: SubscriptionItemCard(
              subscription: sub,
              amount: 14.99,
              currencyCode: 'USD',
              categoryLabel: 'Streaming',
              cycleLabel: 'month',
              onTap: () {},
              onMenuAction: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Very Long Subscription Name'), findsOneWidget);
    expect(find.byType(AppActionMenu), findsOneWidget);
  });

  testWidgets('Subscription form modal uses shared modern fields',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currencyServiceProvider.overrideWith((_) => _FakeCurrencyService(prefs)),
        ],
        child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AddSubscriptionScreen(asModal: true),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ModernInput), findsWidgets);
    expect(find.bySubtype<ModernDropdown<dynamic>>(), findsWidgets);
    expect(find.text('Add Subscription'), findsWidgets);
  });

  test('Subscriptions use shared component primitives across features', () {
    final paths = [
      'lib/features/transactions/presentation/screens/add_transaction_screen.dart',
      'lib/features/budgets/presentation/screens/budget_screen.dart',
      'lib/features/savings/presentation/screens/savings_screen.dart',
      'lib/features/subscriptions/presentation/screens/add_subscription_screen.dart',
    ];

    for (final path in paths) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      final content = file.readAsStringSync();
      expect(content.contains('ModernInput('), isTrue,
          reason: 'Expected ModernInput in $path');
      // A "selection" field may be a dropdown OR a chip selector — for small
      // enums (e.g. a 3-way savings-goal priority) chips are the better,
      // intentional UX, so accept either shared pattern.
      expect(
          content.contains('ModernSelect<') ||
              content.contains('ModernDropdown<') ||
              content.contains('ChipSelector('),
          isTrue,
          reason: 'Expected modern select/dropdown/chip selector in $path');
    }
  });
}
