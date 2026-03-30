import 'package:drift/drift.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/core/services/exchange_rate_service.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';

class CurrencyMigrationService {
  CurrencyMigrationService(
    this._database,
    this._exchangeRateService,
    this._currencyService,
  );

  final AppDatabase _database;
  final ExchangeRateService _exchangeRateService;
  final CurrencyService _currencyService;

  Future<void> migrateAllData({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final normalizedFrom = fromCurrency.toUpperCase();
    final normalizedTo = toCurrency.toUpperCase();
    if (normalizedFrom == normalizedTo) return;

    final transactions = await _database.select(_database.transactions).get();
    final budgets = await _database.select(_database.budgets).get();
    final subscriptions = await _database.select(_database.subscriptions).get();
    final accounts = await _database.select(_database.accounts).get();
    final savingsGoals = await _database.select(_database.savingsGoals).get();

    final savingsCurrency = await _currencyService.loadSavingsCurrencyCode(
      fallback: normalizedFrom,
    );

    final sourceCurrencies = <String>{
      ...transactions.map((row) => row.currency.toUpperCase()),
      ...budgets.map((row) => row.currency.toUpperCase()),
      ...subscriptions.map((row) => row.currency.toUpperCase()),
      ...accounts.map((row) => row.currency.toUpperCase()),
      savingsCurrency.toUpperCase(),
    }..remove(normalizedTo);

    final rates = <String, double>{};
    for (final sourceCurrency in sourceCurrencies) {
      final quote = await _exchangeRateService.fetchRate(
        base: sourceCurrency,
        target: normalizedTo,
      );
      rates[sourceCurrency] = quote.rate;
    }

    await _database.transaction(() async {
      for (final row in transactions) {
        final sourceCurrency = row.currency.toUpperCase();
        if (sourceCurrency == normalizedTo) continue;
        await (_database.update(_database.transactions)
              ..where((t) => t.id.equals(row.id)))
            .write(
          TransactionsCompanion(
            amount: Value(_convert(row.amount, rates[sourceCurrency]!)),
            currency: Value(normalizedTo),
            updatedAt: Value(DateTime.now()),
            isSynced: const Value(false),
          ),
        );
      }

      for (final row in budgets) {
        final sourceCurrency = row.currency.toUpperCase();
        if (sourceCurrency == normalizedTo) continue;
        await (_database.update(_database.budgets)
              ..where((b) => b.id.equals(row.id)))
            .write(
          BudgetsCompanion(
            limitAmount:
                Value(_convert(row.limitAmount, rates[sourceCurrency]!)),
            currency: Value(normalizedTo),
          ),
        );
      }

      for (final row in subscriptions) {
        final sourceCurrency = row.currency.toUpperCase();
        if (sourceCurrency == normalizedTo) continue;
        await (_database.update(_database.subscriptions)
              ..where((s) => s.id.equals(row.id)))
            .write(
          SubscriptionsCompanion(
            amount: Value(_convert(row.amount, rates[sourceCurrency]!)),
            currency: Value(normalizedTo),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      for (final row in accounts) {
        final sourceCurrency = row.currency.toUpperCase();
        if (sourceCurrency == normalizedTo) continue;
        await (_database.update(_database.accounts)
              ..where((a) => a.id.equals(row.id)))
            .write(
          AccountsCompanion(
            balance: Value(_convert(row.balance, rates[sourceCurrency]!)),
            currency: Value(normalizedTo),
          ),
        );
      }

      final normalizedSavingsCurrency = savingsCurrency.toUpperCase();
      if (normalizedSavingsCurrency != normalizedTo) {
        final savingsRate = rates[normalizedSavingsCurrency]!;
        for (final row in savingsGoals) {
          await (_database.update(_database.savingsGoals)
                ..where((g) => g.id.equals(row.id)))
              .write(
            SavingsGoalsCompanion(
              targetAmount: Value(_convert(row.targetAmount, savingsRate)),
              savedAmount: Value(_convert(row.savedAmount, savingsRate)),
            ),
          );
        }
      }
    });

    await _currencyService.saveSavingsCurrencyCode(normalizedTo);
  }

  double _convert(double amount, double rate) {
    return double.parse((amount * rate).toStringAsFixed(2));
  }
}
