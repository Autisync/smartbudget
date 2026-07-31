import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/notification_preferences_service.dart';
import 'package:smartbudget/core/services/rollover_policy_service.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/budgets/presentation/screens/budget_screen.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/screens/financial_health_screen.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/features/savings/presentation/screens/savings_screen.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  testWidgets('Money-control screens navigate without lifecycle assertion',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final start = DateTime(2026, 3, 1);
    final end = DateTime(2026, 4, 1);

    final budget = Budget(
      id: 'b-1',
      category: 'Food',
      limitAmount: 500,
      currency: 'USD',
      period: BudgetPeriod.monthly,
      startDate: start,
      endDate: end,
      alertThreshold: 80,
      isActive: true,
    );

    final txs = <Transaction>[
      Transaction(
        id: 't-1',
        accountId: 'default',
        amount: 120,
        currency: 'USD',
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 3, 4),
      ),
      Transaction(
        id: 't-2',
        accountId: 'default',
        amount: 1000,
        currency: 'USD',
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 3, 1),
      ),
    ];

    final goal = SavingsGoal(
      id: 'g-1',
      title: 'Vacation',
      targetAmount: 1200,
      savedAmount: 450,
      deadline: DateTime(2026, 12, 31),
      priority: GoalPriority.medium,
      autoAllocate: false,
      createdAt: DateTime(2026, 1, 1),
    );

    const nudge = SavingsNudge(
      goalId: 'g-1',
      title: 'Nudge',
      message: 'Top up this goal to stay on track.',
      severity: SavingsNudgeSeverity.warning,
    );

    final alert = BudgetAlert(
      budgetId: 'b-1',
      category: 'Food',
      progress: 0.65,
      threshold: 80,
      nearLimit: false,
      overLimit: false,
      generatedAt: DateTime(2026, 3, 10),
    );

    final snapshot = const FinancialHealthSnapshot(
      totalScore: 78,
      budgetDisciplineScore: 82,
      savingsMomentumScore: 70,
      budgetUtilizationScore: 75,
      recommendations: ['Keep contributions steady each month.'],
      activeBudgets: 1,
      activeGoals: 1,
    );

    final overrides = <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
      rolloverPolicyServiceProvider
          .overrideWithValue(_FakeRolloverPolicyService(prefs)),
      notificationPreferencesServiceProvider
          .overrideWithValue(_FakeNotificationPreferencesService(prefs)),
      budgetListProvider.overrideWith(() => _FakeBudgetList([budget])),
      budgetSpendingProvider(
        category: budget.category,
        start: budget.startDate,
        end: budget.endDate!,
      ).overrideWith((ref) async => 120.0),
      budgetAlertsProvider.overrideWith((ref) async => [alert]),
      transactionListProvider(
        startDate: budget.startDate,
        endDate: budget.endDate,
        category: budget.category,
      ).overrideWith(() => _FakeBudgetCategoryTransactions(txs)),
      recentTransactionsProvider.overrideWith((ref) async => txs),
      savingsGoalListProvider.overrideWith(() => _FakeSavingsGoalList([goal])),
      savingsNudgesProvider.overrideWith(() => _FakeSavingsNudges([nudge])),
      financialHealthProvider.overrideWith((ref) async => snapshot),
    ];

    await tester.pumpWidget(
      _testHost(
        home: const BudgetScreen(),
        overrides: overrides,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Budget Portfolio'), findsOneWidget);
    // The action-menu trigger icon is wrapped in a Tooltip, which on current
    // Flutter renders via an OverlayPortal. Default finders treat that subtree
    // as offstage, so we must opt in with skipOffstage: false. The button is
    // painted and hit-testable for real users; warnIfMissed: false avoids a
    // false-positive miss warning from the offstage classification.
    final menuTrigger =
        find.byIcon(Icons.more_horiz, skipOffstage: false).first;
    await tester.ensureVisible(menuTrigger);
    await tester.pumpAndSettle();
    await tester.tap(menuTrigger, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View transactions').last);
    await tester.pumpAndSettle();
    expect(find.text('Food transactions'), findsOneWidget);
    // The redesigned detail view surfaces the amount in several places
    // (header total, list row, summary). The smoke check only needs to confirm
    // the $120 transaction made it onto the screen.
    expect(find.textContaining(r'$120.00'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _testHost(
        home: const SavingsScreen(),
        overrides: overrides,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Savings'), findsWidgets);

    await tester.pumpWidget(
      _testHost(
        home: const FinancialHealthScreen(),
        overrides: overrides,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Health'), findsWidgets);

    // Repeat transitions to stress lifecycle/deactivation paths.
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(
        _testHost(
          home: const BudgetScreen(),
          overrides: overrides,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(
        _testHost(
          home: const SavingsScreen(),
          overrides: overrides,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(tester.takeException(), isNull);
  });
}

Widget _testHost({required Widget home, required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    ),
  );
}

class _FakeBudgetList extends BudgetList {
  _FakeBudgetList(this._budgets);

  final List<Budget> _budgets;

  @override
  Future<List<Budget>> build() async => _budgets;

  @override
  Future<void> rolloverExpiredBudgets({int? rolloverDay}) async {}
}

class _FakeBudgetCategoryTransactions extends TransactionList {
  _FakeBudgetCategoryTransactions(this._transactions);

  final List<Transaction> _transactions;

  @override
  Future<List<Transaction>> build({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return _transactions.where((tx) {
      final matchesCategory = category == null || tx.category == category;
      final matchesStart = startDate == null ||
          tx.date.isAfter(startDate) ||
          tx.date.isAtSameMomentAs(startDate);
      final matchesEnd = endDate == null ||
          tx.date.isBefore(endDate) ||
          tx.date.isAtSameMomentAs(endDate);
      return matchesCategory && matchesStart && matchesEnd;
    }).toList();
  }
}

class _FakeSavingsGoalList extends SavingsGoalList {
  _FakeSavingsGoalList(this._goals);

  final List<SavingsGoal> _goals;

  @override
  Future<List<SavingsGoal>> build() async => _goals;
}

class _FakeSavingsNudges extends SavingsNudges {
  _FakeSavingsNudges(this._nudges);

  final List<SavingsNudge> _nudges;

  @override
  Future<List<SavingsNudge>> build() async => _nudges;
}

class _FakeRolloverPolicyService extends RolloverPolicyService {
  _FakeRolloverPolicyService(super.prefs);

  @override
  Future<RolloverPolicy> loadPolicy() async => RolloverPolicy.defaults;

  @override
  Future<void> savePolicy(RolloverPolicy policy) async {}
}

class _FakeNotificationPreferencesService
    extends NotificationPreferencesService {
  _FakeNotificationPreferencesService(super.prefs);

  @override
  Future<NotificationPreferences> loadPreferences() async =>
      NotificationPreferences.defaults;

  @override
  Future<void> savePreferences(NotificationPreferences preferences) async {}

  @override
  Future<bool> shouldDispatch(String categoryKey, {DateTime? now}) async =>
      false;
}
