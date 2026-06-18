import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/financial/insight_portfolio_card.dart';

enum _DemoFilter { a, b }

void main() {
  Widget wrap(Widget child, {Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('InsightPortfolioCard renders title, insight, and metrics',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const InsightPortfolioCard(
          title: 'Decision Snapshot',
          icon: Icons.tips_and_updates_outlined,
          gradient: LinearGradient(
            colors: [Color(0xFFEFE8FF), Color(0xFFF8FAFF)],
          ),
          insightText: 'Spending is outpacing income.',
          metrics: [
            InsightPortfolioMetric(label: 'Income', value: 'Kz 120,000'),
            InsightPortfolioMetric(label: 'Spent', value: 'Kz 142,000'),
          ],
        ),
      ),
    );

    expect(find.text('Decision Snapshot'), findsOneWidget);
    expect(find.text('Spending is outpacing income.'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
  });

  testWidgets('InsightPortfolioCard handles empty metrics', (tester) async {
    await tester.pumpWidget(
      wrap(
        const InsightPortfolioCard(
          title: 'Decision Snapshot',
          icon: Icons.tips_and_updates_outlined,
          gradient: LinearGradient(
            colors: [Color(0xFFEFE8FF), Color(0xFFF8FAFF)],
          ),
          insightText: 'No transactions yet.',
          metrics: [],
        ),
      ),
    );

    expect(find.text('No metrics available yet.'), findsOneWidget);
  });

  testWidgets('InsightPortfolioCard handles large currency values',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const InsightPortfolioCard(
          title: 'Budget Portfolio',
          icon: Icons.track_changes_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFEFE8FF), Color(0xFFF8FAFF)],
          ),
          insightText: 'Your budget setup is stable.',
          metrics: [
            InsightPortfolioMetric(
              label: 'Total Limit',
              value: 'Kz 999,999,999,999.99',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Kz 999,999,999,999.99'), findsOneWidget);
  });

  testWidgets('InsightPortfolioCard avoids overflow on small screens',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const InsightPortfolioCard(
          title: 'Subscription Portfolio',
          icon: Icons.subscriptions_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFEAF0FF), Color(0xFFF7F9FF)],
          ),
          insightText:
              'Subscriptions are taking a large share of fixed outflow. Review services you can pause or cancel.',
          metrics: [
            InsightPortfolioMetric(label: 'Active', value: '24'),
            InsightPortfolioMetric(
                label: 'Monthly Load', value: 'Kz 452,109.22'),
            InsightPortfolioMetric(label: 'Next 7 Days', value: '9'),
            InsightPortfolioMetric(label: 'High Priority', value: '7'),
            InsightPortfolioMetric(
                label: 'Optional Savings', value: 'Kz 120,300.11'),
            InsightPortfolioMetric(label: 'Critical', value: '2'),
          ],
        ),
        size: const Size(320, 700),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('TransactionInsightCard shows spending metrics', (tester) async {
    await tester.pumpWidget(
      wrap(
        TransactionInsightCard(
          message: 'Most spending is in Transport.',
          monthIncome: 2400,
          monthExpense: 1800,
          recurringCount: 4,
          netFlow: 600,
          topCategory: 'Transport',
          currencyCode: 'USD',
          isIncomeSelected: false,
          isSpentSelected: false,
          isRecurringSelected: false,
          onIncomeTap: () {},
          onSpentTap: () {},
          onRecurringTap: () {},
          emptyFallback: 'None',
        ),
      ),
    );

    expect(find.text('Decision Snapshot'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.text('Net Flow'), findsOneWidget);
    expect(find.text('Top Category'), findsOneWidget);
  });

  testWidgets('BudgetPortfolioCard shows budget metrics', (tester) async {
    await tester.pumpWidget(
      wrap(
        BudgetPortfolioCard(
          categoriesCount: 5,
          atRiskCount: 2,
          totalLimit: 5000,
          totalSpent: 3600,
          totalRemaining: 1400,
          averageAlertThreshold: 80,
          projectedOverspend: 0,
          currencyFormat: NumberFormat.currency(symbol: 'Kz '),
          description:
              'Your budget setup is stable. You still have Kz 1,400 available across active categories.',
          daysLeftLabel: '12 days',
          rolloverLabel: 'Rollover',
          onRollover: () {},
        ),
      ),
    );

    expect(find.text('Budget Portfolio'), findsOneWidget);
    expect(find.textContaining('at risk'), findsOneWidget);
    expect(find.text('Days Left'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('At Risk'), findsOneWidget);
  });

  testWidgets('SavingsPortfolioCard shows savings metrics', (tester) async {
    await tester.pumpWidget(
      wrap(
        SavingsPortfolioCard(
          totalTarget: 12000,
          totalSaved: 7200,
          atRiskGoals: 1,
          goalsCount: 3,
          decisionMessage: 'Your savings progress is steady.',
          currencyFormat: NumberFormat.currency(symbol: 'Kz '),
          monthlySurplus: 450,
        ),
      ),
    );

    expect(find.text('Savings Portfolio'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('Monthly Surplus'), findsOneWidget);
    expect(find.text('At Risk'), findsOneWidget);
  });

  testWidgets('SubscriptionPortfolioCard shows required metrics',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        SubscriptionPortfolioCard<_DemoFilter>(
          activeCount: 7,
          criticalCount: 1,
          renewingSoonCount: 2,
          highPriorityCount: 3,
          monthlyLoad: 432.4,
          lowPriorityMonthlyCost: 55,
          currencySymbol: r'$',
          insightText: 'You have renewals coming soon.',
          filters: _DemoFilter.values,
          activeFilter: null,
          filterLabelBuilder: (filter) => filter.name,
          onFilterSelected: (_) {},
        ),
      ),
    );

    expect(find.text('Subscription Portfolio'), findsOneWidget);
    expect(find.text('1 critical'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Monthly Load'), findsOneWidget);
    expect(find.text('Next Renewal'), findsOneWidget);
    expect(find.text('Optional Savings'), findsOneWidget);
  });

  testWidgets('MinimalStatusChip exposes semantic tone', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MinimalStatusChip(
          label: 'Needs attention',
          tone: Color(0xFFC94B2A),
        ),
      ),
    );

    final chip =
        tester.widget<MinimalStatusChip>(find.byType(MinimalStatusChip));
    expect(chip.label, 'Needs attention');
    expect(chip.tone, const Color(0xFFC94B2A));
  });
}
