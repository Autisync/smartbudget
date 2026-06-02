import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionRecurrence, TransactionType;
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/intelligence/engines/financial_insight_engines.dart';

Transaction _tx({
  required String id,
  required double amount,
  required TransactionType type,
  required DateTime date,
  String category = 'General',
  TransactionRecurrence recurrence = TransactionRecurrence.none,
}) {
  return Transaction(
    id: id,
    accountId: 'a1',
    amount: amount,
    currency: 'USD',
    type: type,
    category: category,
    date: date,
    recurrence: recurrence,
  );
}

void main() {
  group('BurnRateEngine', () {
    test('returns empty insight when month has no expenses', () {
      final now = DateTime(2026, 1, 20);
      final insight = const BurnRateEngine().calculate(
        transactions: [
          _tx(
            id: '1',
            amount: 1000,
            type: TransactionType.income,
            date: now,
          ),
        ],
        now: now,
      );

      expect(insight.hasData, false);
      expect(insight.monthlySpend, 0);
      expect(insight.status, BurnRateStatus.healthy);
    });

    test('flags high/critical status when projection exceeds budget', () {
      final now = DateTime(2026, 1, 10);
      final insight = const BurnRateEngine().calculate(
        transactions: [
          _tx(
            id: '1',
            amount: 900,
            type: TransactionType.expense,
            date: now,
            category: 'Food',
          ),
        ],
        now: now,
        monthlyBudgetLimit: 1500,
      );

      expect(insight.hasData, true);
      expect(insight.projectedMonthEndSpend, greaterThan(1500));
      expect(
        insight.status == BurnRateStatus.high ||
            insight.status == BurnRateStatus.critical,
        true,
      );
    });
  });

  group('TransactionInsightEngine', () {
    test('includes recurring count and top category', () {
      final now = DateTime(2026, 2, 16);
      final snapshot = const TransactionInsightEngine().build(
        transactions: [
          _tx(
            id: '1',
            amount: 2200,
            type: TransactionType.income,
            date: now,
            category: 'Salary',
          ),
          _tx(
            id: '2',
            amount: 500,
            type: TransactionType.expense,
            date: now,
            category: 'Rent',
            recurrence: TransactionRecurrence.monthly,
          ),
          _tx(
            id: '3',
            amount: 120,
            type: TransactionType.expense,
            date: now,
            category: 'Groceries',
          ),
        ],
        now: now,
      );

      expect(snapshot.hasTransactions, true);
      expect(snapshot.monthIncome, 2200);
      expect(snapshot.monthExpense, 620);
      expect(snapshot.recurringCount, 1);
      expect(snapshot.topCategory, 'Rent');
      expect(snapshot.netFlow, 1580);
    });
  });
}
