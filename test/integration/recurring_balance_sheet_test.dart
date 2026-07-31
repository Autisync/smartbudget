import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/core/services/notification_service.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionType;
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/balance_sheet/presentation/screens/recurring_balance_sheet_screen.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets('recurring balance sheet renders scenario lab and simulation',
      (tester) async {
    final snapshot = RecurringBalanceSnapshot(
      currencyCode: 'USD',
      requestedCurrencyCode: 'USD',
      isCurrencyFallback: false,
      entries: [
        RecurringBalanceEntry(
          id: 'income-salary',
          title: 'Salary',
          subtitle: 'Main payroll',
          kind: RecurringBalanceEntryKind.income,
          chargeAmount: 2000,
          monthlyAmount: 2000,
          currencyCode: 'USD',
          cadenceLabel: 'Monthly',
          nextDate: DateTime(2026, 4, 1),
        ),
        RecurringBalanceEntry(
          id: 'expense-rent',
          title: 'Rent',
          subtitle: 'Recurring expense',
          kind: RecurringBalanceEntryKind.expense,
          chargeAmount: 1200,
          monthlyAmount: 1200,
          currencyCode: 'USD',
          cadenceLabel: 'Monthly',
          nextDate: DateTime(2026, 4, 3),
        ),
        RecurringBalanceEntry(
          id: 'subscription-streaming',
          title: 'Streaming',
          subtitle: 'Entertainment',
          kind: RecurringBalanceEntryKind.subscription,
          chargeAmount: 20,
          monthlyAmount: 20,
          currencyCode: 'USD',
          cadenceLabel: 'Monthly',
          nextDate: DateTime(2026, 4, 4),
          isOptional: true,
        ),
      ],
      recurringIncomeTotal: 2000,
      recurringExpenseTotal: 1200,
      subscriptionExpenseTotal: 20,
      nearTermIncome: 2000,
      nearTermCommitments: 1220,
      recommendations: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringBalanceSheetProvider.overrideWith((ref) async => snapshot),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: RecurringBalanceSheetScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recurring Balance Sheet'), findsWidgets);
    expect(find.text('Scenario Lab'), findsOneWidget);
    expect(find.textContaining('Streaming'), findsWidgets);

    await tester.ensureVisible(find.byType(FilterChip).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilterChip).first);
    await tester.pumpAndSettle();

    expect(find.text('Simulated monthly balance'), findsOneWidget);
    expect(find.text('Reset scenario'), findsOneWidget);
  });

  testWidgets('dashboard balance sheet CTA navigates to route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/balance-sheet',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Balance Sheet Route Hit')),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/exchange-rates',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/health',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appCurrencyControllerProvider
              .overrideWith((ref) => _TestCurrencyController(prefs)),
          transactionListProvider().overrideWith(() => _FakeTransactionList()),
          budgetAlertsProvider.overrideWith((ref) async => const []),
          financialHealthProvider
              .overrideWith((ref) async => const FinancialHealthSnapshot(
                    totalScore: 82,
                    budgetDisciplineScore: 82,
                    savingsMomentumScore: 80,
                    budgetUtilizationScore: 84,
                    recommendations: ['Stay steady.'],
                    activeBudgets: 0,
                    activeGoals: 0,
                  )),
          recurringTransactionsProvider.overrideWith((ref) async {}),
          spendingProfileProvider
              .overrideWith((ref) async => const SpendingProfile(
                    monthlyBurnRate: 0,
                    averageDailySpend: 0,
                    categoryDistribution: {},
                    anomalies: [],
                    trend: TrendDirection.stable,
                    topCategoryPercentage: 0,
                  )),
          recentTransactionsProvider.overrideWith((ref) async => const []),
          notificationInboxProvider.overrideWith(
              (ref) => Stream<List<AppNotificationEntry>>.value(const [])),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );

    // DashboardScreen runs continuous animations (animated balances), so
    // pumpAndSettle never settles — pump a bounded number of frames so the
    // async providers resolve without waiting for animations to stop.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Recurring Balance Sheet'), findsOneWidget);
    final openButton =
        find.widgetWithText(OutlinedButton, 'Open').hitTestable().first;
    await tester.tap(openButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Balance Sheet Route Hit'), findsOneWidget);
  });
}

class _FakeTransactionList extends TransactionList {
  @override
  Future<List<Transaction>> build({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return [
      Transaction(
        id: 'income-1',
        accountId: 'default',
        amount: 1200,
        currency: 'USD',
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 3, 1),
      ),
      Transaction(
        id: 'expense-1',
        accountId: 'default',
        amount: 400,
        currency: 'USD',
        type: TransactionType.expense,
        category: 'Bills',
        date: DateTime(2026, 3, 2),
      ),
    ];
  }
}

class _TestCurrencyController extends AppCurrencyController {
  _TestCurrencyController(SharedPreferences prefs)
      : super(_TestCurrencyService(prefs)) {
    state = 'USD';
  }
}

class _TestCurrencyService extends CurrencyService {
  _TestCurrencyService(super.prefs);

  @override
  Future<String> loadCurrencyCode() async => 'USD';

  @override
  Future<void> saveCurrencyCode(String code) async {}
}
