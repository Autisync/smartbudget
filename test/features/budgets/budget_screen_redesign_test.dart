import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/financial/insight_portfolio_card.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/features/budgets/presentation/screens/budget_screen.dart';

void main() {
  group('BudgetPortfolioCard', () {
    testWidgets(
        'renders on compact width without overflow for large money values',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: BudgetPortfolioCard(
                categoriesCount: 8,
                atRiskCount: 2,
                totalLimit: 12450000.75,
                totalSpent: 9345000.25,
                totalRemaining: 3115000.50,
                averageAlertThreshold: 82,
                projectedOverspend: 0,
                currencyFormat: NumberFormat.currency(symbol: 'Kz '),
                description:
                    'Your budget setup is stable. You still have Kz 3,115,000.50 available across active categories.',
                daysLeftLabel: '12 days left',
                rolloverLabel: 'Rollover now',
                onRollover: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Budget Portfolio'), findsOneWidget);
      expect(find.text('Rollover now'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });

    test('returns exceeded before lower-risk states', () {
      final budgets = [
        Budget(
          id: 'budget-1',
          category: 'Food',
          limitAmount: 1000,
          currency: 'AOA',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 31),
          alertThreshold: 80,
          isActive: true,
        ),
      ];

      final status = getBudgetPortfolioStatus(
        budgets: budgets,
        spendingValues: const [1100],
        totalLimit: 1000,
        totalSpent: 1100,
      );

      expect(status, BudgetPortfolioStatus.exceeded);
    });
  });
}
