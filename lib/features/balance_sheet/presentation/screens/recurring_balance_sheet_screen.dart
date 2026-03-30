import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/data/models/tables.dart'
    show
        BillingCycle,
        SubscriptionImportance,
        TransactionRecurrence,
        TransactionType;
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/insights/presentation/widgets/insight_card.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/models/insight.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

enum RecurringBalanceEntryKind { income, expense, subscription }

class RecurringBalanceEntry {
  const RecurringBalanceEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.chargeAmount,
    required this.monthlyAmount,
    required this.currencyCode,
    required this.cadenceLabel,
    required this.nextDate,
    this.isOptional = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final RecurringBalanceEntryKind kind;
  final double chargeAmount;
  final double monthlyAmount;
  final String currencyCode;
  final String cadenceLabel;
  final DateTime nextDate;
  final bool isOptional;
}

class RecurringBalanceSnapshot {
  const RecurringBalanceSnapshot({
    required this.currencyCode,
    required this.requestedCurrencyCode,
    required this.isCurrencyFallback,
    required this.entries,
    required this.recurringIncomeTotal,
    required this.recurringExpenseTotal,
    required this.subscriptionExpenseTotal,
    required this.nearTermIncome,
    required this.nearTermCommitments,
    required this.recommendations,
  });

  final String currencyCode;
  final String requestedCurrencyCode;
  final bool isCurrencyFallback;
  final List<RecurringBalanceEntry> entries;
  final double recurringIncomeTotal;
  final double recurringExpenseTotal;
  final double subscriptionExpenseTotal;
  final double nearTermIncome;
  final double nearTermCommitments;
  final List<Insight> recommendations;

  double get totalRecurringOutflow =>
      recurringExpenseTotal + subscriptionExpenseTotal;

  double get netMonthlyBalance => recurringIncomeTotal - totalRecurringOutflow;

  double get coverageRatio => totalRecurringOutflow <= 0
      ? 1
      : recurringIncomeTotal / totalRecurringOutflow;

  bool get canCoverRecurring => netMonthlyBalance >= 0;

  List<RecurringBalanceEntry> get incomeEntries => entries
      .where((entry) => entry.kind == RecurringBalanceEntryKind.income)
      .toList()
    ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));

  List<RecurringBalanceEntry> get expenseEntries => entries
      .where((entry) => entry.kind == RecurringBalanceEntryKind.expense)
      .toList()
    ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));

  List<RecurringBalanceEntry> get subscriptionEntries => entries
      .where((entry) => entry.kind == RecurringBalanceEntryKind.subscription)
      .toList()
    ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));

  int get dueSoonCount => entries
      .where((entry) =>
          entry.kind != RecurringBalanceEntryKind.income &&
          !entry.nextDate.isAfter(DateTime.now().add(const Duration(days: 14))))
      .length;
}

final recurringBalanceSheetProvider =
    FutureProvider<RecurringBalanceSnapshot>((ref) async {
  final appCurrency = ref.watch(appCurrencyControllerProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);
  var workingCurrency = appCurrency;
  var isCurrencyFallback = false;

  if (appCurrency != 'USD') {
    try {
      await exchangeRateService.fetchRate(
        base: 'USD',
        target: appCurrency,
      );
    } catch (_) {
      // Some app currencies are not available in the exchange provider.
      // Use USD as a stable fallback so the screen still renders.
      workingCurrency = 'USD';
      isCurrencyFallback = true;
    }
  }

  final transactions = await ref.watch(transactionListProvider().future);
  final subscriptions = await ref.watch(subscriptionListProvider.future);
  Map<String, SubscriptionDisplayAmounts> convertedSubscriptions = {};
  try {
    convertedSubscriptions = await ref
        .watch(subscriptionDisplayAmountsProvider(workingCurrency).future);
  } catch (_) {
    convertedSubscriptions = {};
  }

  final recurringTransactions = transactions
      .where(
        (transaction) =>
            transaction.isRecurring &&
            transaction.type != TransactionType.transfer,
      )
      .toList();

  final requiredRates = recurringTransactions
      .map((transaction) => transaction.currency.toUpperCase())
      .where((currencyCode) => currencyCode != workingCurrency)
      .toSet();
  final rates = <String, double>{};

  for (final currencyCode in requiredRates) {
    try {
      final quote = await exchangeRateService.fetchRate(
        base: currencyCode,
        target: workingCurrency,
      );
      rates[currencyCode] = quote.rate;
    } catch (_) {
      // Keep source values if a specific pair is not available.
    }
  }

  final entries = <RecurringBalanceEntry>[
    ...recurringTransactions.map(
      (transaction) {
        final convertedChargeAmount = _convertAmount(
          amount: transaction.amount,
          sourceCurrency: transaction.currency,
          targetCurrency: workingCurrency,
          rates: rates,
        );
        return RecurringBalanceEntry(
          id: transaction.id,
          title: transaction.category,
          subtitle: transaction.note?.trim().isNotEmpty == true
              ? transaction.note!.trim()
              : 'Recurring ${transaction.isIncome ? 'income' : 'expense'}',
          kind: transaction.isIncome
              ? RecurringBalanceEntryKind.income
              : RecurringBalanceEntryKind.expense,
          chargeAmount: convertedChargeAmount,
          monthlyAmount: _monthlyAmountForRecurrence(
            convertedChargeAmount,
            transaction.recurrence,
          ),
          currencyCode: workingCurrency,
          cadenceLabel: _recurrenceLabel(transaction.recurrence),
          nextDate: _nextOccurrence(transaction.date, transaction.recurrence),
        );
      },
    ),
    ...subscriptions.where((subscription) => subscription.isActive).map(
      (subscription) {
        final displayAmounts = convertedSubscriptions[subscription.id];
        final chargeAmount = displayAmounts?.amount ?? subscription.amount;
        final monthlyAmount =
            displayAmounts?.monthlyCost ?? subscription.monthlyCost;
        return RecurringBalanceEntry(
          id: 'subscription-${subscription.id}',
          title: subscription.name,
          subtitle: subscription.category,
          kind: RecurringBalanceEntryKind.subscription,
          chargeAmount: chargeAmount,
          monthlyAmount: monthlyAmount,
          currencyCode: workingCurrency,
          cadenceLabel: _billingCycleLabel(subscription.billingCycle),
          nextDate: subscription.nextDueDate,
          isOptional: subscription.importance == SubscriptionImportance.low,
        );
      },
    ),
  ];

  final recurringIncomeTotal = entries
      .where((entry) => entry.kind == RecurringBalanceEntryKind.income)
      .fold<double>(0, (sum, entry) => sum + entry.monthlyAmount);
  final recurringExpenseTotal = entries
      .where((entry) => entry.kind == RecurringBalanceEntryKind.expense)
      .fold<double>(0, (sum, entry) => sum + entry.monthlyAmount);
  final subscriptionExpenseTotal = entries
      .where((entry) => entry.kind == RecurringBalanceEntryKind.subscription)
      .fold<double>(0, (sum, entry) => sum + entry.monthlyAmount);

  final now = DateTime.now();
  final nearTermIncome = entries
      .where((entry) =>
          entry.kind == RecurringBalanceEntryKind.income &&
          !entry.nextDate.isAfter(now.add(const Duration(days: 14))))
      .fold<double>(0, (sum, entry) => sum + entry.chargeAmount);
  final nearTermCommitments = entries
      .where((entry) =>
          entry.kind != RecurringBalanceEntryKind.income &&
          !entry.nextDate.isAfter(now.add(const Duration(days: 14))))
      .fold<double>(0, (sum, entry) => sum + entry.chargeAmount);

  return RecurringBalanceSnapshot(
    currencyCode: workingCurrency,
    requestedCurrencyCode: appCurrency,
    isCurrencyFallback: isCurrencyFallback,
    entries: entries,
    recurringIncomeTotal: recurringIncomeTotal,
    recurringExpenseTotal: recurringExpenseTotal,
    subscriptionExpenseTotal: subscriptionExpenseTotal,
    nearTermIncome: nearTermIncome,
    nearTermCommitments: nearTermCommitments,
    recommendations: _buildRecommendations(
      entries: entries,
      currencyCode: workingCurrency,
      recurringIncomeTotal: recurringIncomeTotal,
      recurringExpenseTotal: recurringExpenseTotal,
      subscriptionExpenseTotal: subscriptionExpenseTotal,
      nearTermIncome: nearTermIncome,
      nearTermCommitments: nearTermCommitments,
    ),
  );
});

double _convertAmount({
  required double amount,
  required String sourceCurrency,
  required String targetCurrency,
  required Map<String, double> rates,
}) {
  final normalizedSource = sourceCurrency.toUpperCase();
  if (normalizedSource == targetCurrency) {
    return amount;
  }

  final rate = rates[normalizedSource];
  if (rate == null) {
    return amount;
  }

  return amount * rate;
}

double _monthlyAmountForRecurrence(
  double amount,
  TransactionRecurrence recurrence,
) {
  switch (recurrence) {
    case TransactionRecurrence.daily:
      return amount * 30.4;
    case TransactionRecurrence.weekly:
      return amount * 4.33;
    case TransactionRecurrence.monthly:
      return amount;
    case TransactionRecurrence.yearly:
      return amount / 12;
    case TransactionRecurrence.none:
      return 0;
  }
}

String _recurrenceLabel(TransactionRecurrence recurrence) {
  switch (recurrence) {
    case TransactionRecurrence.daily:
      return 'Daily';
    case TransactionRecurrence.weekly:
      return 'Weekly';
    case TransactionRecurrence.monthly:
      return 'Monthly';
    case TransactionRecurrence.yearly:
      return 'Yearly';
    case TransactionRecurrence.none:
      return 'One-off';
  }
}

String _billingCycleLabel(BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return 'Weekly';
    case BillingCycle.monthly:
      return 'Monthly';
    case BillingCycle.quarterly:
      return 'Quarterly';
    case BillingCycle.yearly:
      return 'Yearly';
  }
}

DateTime _nextOccurrence(DateTime startDate, TransactionRecurrence recurrence) {
  if (recurrence == TransactionRecurrence.none) {
    return startDate;
  }

  var candidate = DateTime(startDate.year, startDate.month, startDate.day);
  final today = DateTime.now();

  while (candidate.isBefore(today)) {
    switch (recurrence) {
      case TransactionRecurrence.daily:
        candidate = candidate.add(const Duration(days: 1));
        break;
      case TransactionRecurrence.weekly:
        candidate = candidate.add(const Duration(days: 7));
        break;
      case TransactionRecurrence.monthly:
        candidate =
            DateTime(candidate.year, candidate.month + 1, candidate.day);
        break;
      case TransactionRecurrence.yearly:
        candidate =
            DateTime(candidate.year + 1, candidate.month, candidate.day);
        break;
      case TransactionRecurrence.none:
        break;
    }
  }

  return candidate;
}

List<Insight> _buildRecommendations({
  required List<RecurringBalanceEntry> entries,
  required String currencyCode,
  required double recurringIncomeTotal,
  required double recurringExpenseTotal,
  required double subscriptionExpenseTotal,
  required double nearTermIncome,
  required double nearTermCommitments,
}) {
  final currencyFormat = CurrencyUtils.getFormat(currencyCode);
  final totalOutflow = recurringExpenseTotal + subscriptionExpenseTotal;
  final netBalance = recurringIncomeTotal - totalOutflow;
  final coverageRatio =
      totalOutflow <= 0 ? 1.0 : recurringIncomeTotal / totalOutflow;
  final optionalSubscriptionSavings = entries
      .where((entry) =>
          entry.kind == RecurringBalanceEntryKind.subscription &&
          entry.isOptional)
      .fold<double>(0, (sum, entry) => sum + entry.monthlyAmount);
  final largestExpense = entries
      .where((entry) => entry.kind != RecurringBalanceEntryKind.income)
      .fold<RecurringBalanceEntry?>(null, (current, entry) {
    if (current == null || entry.monthlyAmount > current.monthlyAmount) {
      return entry;
    }
    return current;
  });
  final subscriptionShare =
      totalOutflow <= 0 ? 0.0 : subscriptionExpenseTotal / totalOutflow;

  if (entries.isEmpty) {
    return const [
      Insight(
        id: 'recurring-empty',
        title: 'No recurring plan available yet',
        explanation:
            'Add recurring transactions or subscriptions to generate a balance sheet.',
        impact:
            'Without recurring entries, the app cannot estimate fixed monthly commitments.',
        action:
            'Mark salary, rent, loan payments, and subscriptions as recurring to unlock planning.',
        confidence: 0.95,
        severity: InsightSeverity.low,
        type: InsightType.recommendation,
      ),
    ];
  }

  final insights = <Insight>[];

  if (netBalance < 0) {
    insights.add(
      Insight(
        id: 'recurring-shortfall',
        title: 'Recurring plan is running a deficit',
        explanation:
            'Your recurring income misses monthly obligations by ${currencyFormat.format(-netBalance)}.',
        impact:
            'If nothing changes, fixed commitments alone can force you to borrow or cut essentials.',
        action: optionalSubscriptionSavings > 0
            ? 'Reduce at least ${currencyFormat.format((-netBalance).clamp(0, optionalSubscriptionSavings))} from optional subscriptions, then review large recurring bills.'
            : 'Increase recurring income or reduce fixed expenses by at least ${currencyFormat.format(-netBalance)}.',
        confidence: 0.92,
        severity: InsightSeverity.high,
        type: InsightType.forecast,
      ),
    );
  } else if (coverageRatio < 1.1) {
    insights.add(
      Insight(
        id: 'recurring-thin-buffer',
        title: 'Recurring coverage is positive but thin',
        explanation:
            'Your fixed-income plan covers obligations with only ${currencyFormat.format(netBalance)} left each month.',
        impact:
            'A small change in income or a missed payment could remove your margin quickly.',
        action:
            'Build an extra buffer by trimming one recurring expense or redirecting new income into essentials first.',
        confidence: 0.84,
        severity: InsightSeverity.medium,
        type: InsightType.recommendation,
      ),
    );
  } else {
    insights.add(
      Insight(
        id: 'recurring-covered',
        title: 'Recurring obligations are currently covered',
        explanation:
            'Your monthly recurring plan leaves an estimated ${currencyFormat.format(netBalance)} after fixed commitments.',
        impact:
            'You have room to absorb smaller fluctuations without falling behind on recurring bills.',
        action:
            'Protect that margin by keeping discretionary recurring charges under review.',
        confidence: 0.82,
        severity: InsightSeverity.low,
        type: InsightType.recommendation,
      ),
    );
  }

  if (nearTermCommitments > nearTermIncome) {
    insights.add(
      Insight(
        id: 'recurring-near-term-pressure',
        title: 'Next 14 days look cashflow-heavy',
        explanation:
            'Near-term recurring commitments total ${currencyFormat.format(nearTermCommitments)} against ${currencyFormat.format(nearTermIncome)} in recurring income.',
        impact:
            'You may feel payment pressure before month-end even if the monthly picture is acceptable.',
        action:
            'Prioritize due-soon essentials first and reschedule optional payments where possible.',
        confidence: 0.86,
        severity:
            netBalance < 0 ? InsightSeverity.high : InsightSeverity.medium,
        type: InsightType.forecast,
      ),
    );
  }

  if (subscriptionShare >= 0.25) {
    insights.add(
      Insight(
        id: 'recurring-subscription-share',
        title: 'Subscriptions take a large share of fixed outflow',
        explanation:
            'Subscriptions account for ${(subscriptionShare * 100).toStringAsFixed(0)}% of your recurring obligations.',
        impact:
            'Smaller digital charges can quietly crowd out money needed for core bills.',
        action: optionalSubscriptionSavings > 0
            ? 'Review optional subscriptions first. You could free up about ${currencyFormat.format(optionalSubscriptionSavings)} per month.'
            : 'Review annual and quarterly subscriptions for services you can pause or consolidate.',
        confidence: 0.79,
        severity: subscriptionShare >= 0.4
            ? InsightSeverity.medium
            : InsightSeverity.low,
        type: InsightType.recommendation,
      ),
    );
  }

  if (largestExpense != null) {
    insights.add(
      Insight(
        id: 'recurring-largest-bill',
        title: 'Start with the largest recurring bill',
        explanation:
            '${largestExpense.title} is your largest recurring commitment at about ${currencyFormat.format(largestExpense.monthlyAmount)} per month.',
        impact:
            'Any reduction here has more impact than cutting multiple smaller charges.',
        action:
            'Review whether ${largestExpense.title} can be renegotiated, downgraded, or offset with a matching recurring income increase.',
        confidence: 0.74,
        severity: netBalance < 0 ? InsightSeverity.medium : InsightSeverity.low,
        type: InsightType.recommendation,
      ),
    );
  }

  return insights;
}

class RecurringBalanceSheetScreen extends ConsumerStatefulWidget {
  const RecurringBalanceSheetScreen({super.key});

  @override
  ConsumerState<RecurringBalanceSheetScreen> createState() =>
      _RecurringBalanceSheetScreenState();
}

class _RecurringBalanceSheetScreenState
    extends ConsumerState<RecurringBalanceSheetScreen> {
  double _extraRecurringIncome = 0;
  double _expenseReduction = 0;
  final Set<String> _pausedSubscriptionIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(recurringBalanceSheetProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.account_balance_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Recurring Balance Sheet'),
          ],
        ),
      ),
      body: snapshotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: UiTokens.screenPadding,
            child: Text('Unable to build recurring balance sheet: $error'),
          ),
        ),
        data: (snapshot) {
          final currencyFormat = CurrencyUtils.getFormat(snapshot.currencyCode);
          final colorScheme = Theme.of(context).colorScheme;
          final optionalSubscriptions = snapshot.subscriptionEntries
              .where((entry) => entry.isOptional)
              .toList();
          final pausedSubscriptions = optionalSubscriptions
              .where((entry) => _pausedSubscriptionIds.contains(entry.id))
              .toList();
          final pausedSubscriptionSavings = pausedSubscriptions.fold<double>(
            0,
            (sum, entry) => sum + entry.monthlyAmount,
          );
          final simulatedIncomeTotal =
              snapshot.recurringIncomeTotal + _extraRecurringIncome;
          final simulatedExpenseTotal =
              (snapshot.recurringExpenseTotal - _expenseReduction)
                  .clamp(0, double.infinity)
                  .toDouble();
          final simulatedSubscriptionTotal =
              (snapshot.subscriptionExpenseTotal - pausedSubscriptionSavings)
                  .clamp(0, double.infinity)
                  .toDouble();
          final simulatedEntries = snapshot.entries.where((entry) {
            if (entry.kind != RecurringBalanceEntryKind.subscription) {
              return true;
            }
            return !_pausedSubscriptionIds.contains(entry.id);
          }).toList();
          final simulatedNearTermCommitments = (snapshot.nearTermCommitments -
                  pausedSubscriptions
                      .where((entry) => !entry.nextDate.isAfter(
                          DateTime.now().add(const Duration(days: 14))))
                      .fold<double>(
                          0, (sum, entry) => sum + entry.chargeAmount))
              .clamp(0, double.infinity)
              .toDouble();
          final simulatedRecommendations = _buildRecommendations(
            entries: simulatedEntries,
            currencyCode: snapshot.currencyCode,
            recurringIncomeTotal: simulatedIncomeTotal,
            recurringExpenseTotal: simulatedExpenseTotal,
            subscriptionExpenseTotal: simulatedSubscriptionTotal,
            nearTermIncome: snapshot.nearTermIncome,
            nearTermCommitments: simulatedNearTermCommitments,
          );
          final simulatedNetBalance = simulatedIncomeTotal -
              simulatedExpenseTotal -
              simulatedSubscriptionTotal;
          final scenarioActive = _extraRecurringIncome > 0 ||
              _expenseReduction > 0 ||
              _pausedSubscriptionIds.isNotEmpty;

          return SingleChildScrollView(
            padding: UiTokens.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.isCurrencyFallback)
                  Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.only(bottom: UiTokens.sectionGapMd),
                    padding: const EdgeInsets.all(12),
                    decoration: AppSurfaces.elevated(
                      context,
                      radius: 16,
                      color:
                          colorScheme.tertiaryContainer.withValues(alpha: 0.75),
                      opacity: 0.05,
                    ),
                    child: Text(
                      'Live exchange rates are unavailable for ${snapshot.requestedCurrencyCode}. This view is shown in ${snapshot.currencyCode} for now.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppSurfaces.elevated(
                    context,
                    radius: UiTokens.radiusXl,
                    color: snapshot.canCoverRecurring
                        ? const Color(0xFF059669).withValues(alpha: 0.08)
                        : colorScheme.errorContainer.withValues(alpha: 0.8),
                    opacity: 0.06,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            snapshot.canCoverRecurring
                                ? Icons.verified_rounded
                                : Icons.warning_amber_rounded,
                            color: snapshot.canCoverRecurring
                                ? const Color(0xFF059669)
                                : colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              snapshot.canCoverRecurring
                                  ? 'Recurring income currently covers your obligations'
                                  : 'Recurring obligations currently outpace recurring income',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormat.format(snapshot.netMonthlyBalance),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: snapshot.canCoverRecurring
                                  ? const Color(0xFF047857)
                                  : colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.canCoverRecurring
                            ? 'Estimated monthly room left after recurring commitments.'
                            : 'Estimated monthly shortfall before variable spending begins.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: UiTokens.chipSpacing,
                        runSpacing: UiTokens.chipRunSpacing,
                        children: [
                          _RecurringMetricChip(
                            icon: Icons.arrow_downward_rounded,
                            label: 'Income / mo',
                            value: currencyFormat
                                .format(snapshot.recurringIncomeTotal),
                            tone: const Color(0xFF059669),
                          ),
                          _RecurringMetricChip(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Expenses / mo',
                            value: currencyFormat
                                .format(snapshot.recurringExpenseTotal),
                            tone: colorScheme.error,
                          ),
                          _RecurringMetricChip(
                            icon: Icons.subscriptions_rounded,
                            label: 'Subscriptions / mo',
                            value: currencyFormat
                                .format(snapshot.subscriptionExpenseTotal),
                            tone: colorScheme.secondary,
                          ),
                          _RecurringMetricChip(
                            icon: Icons.schedule_rounded,
                            label: 'Due in 14 days',
                            value: currencyFormat
                                .format(snapshot.nearTermCommitments),
                            tone: colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UiTokens.sectionGapMd),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppSurfaces.elevated(context, radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coverage outlook',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: snapshot.coverageRatio.clamp(0, 1.4) / 1.4,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(999),
                        color: snapshot.coverageRatio >= 1.1
                            ? const Color(0xFF059669)
                            : snapshot.coverageRatio >= 1
                                ? Colors.orange
                                : colorScheme.error,
                        backgroundColor:
                            colorScheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Recurring income covers ${(snapshot.coverageRatio * 100).toStringAsFixed(0)}% of recurring obligations.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The sheet uses monthly equivalents for active recurring transactions and subscriptions in ${snapshot.currencyCode}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UiTokens.sectionGapLg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppSurfaces.elevated(context, radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scenario Lab',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Test small changes before you make them. Increase recurring income, cut recurring expenses, or pause optional subscriptions.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _ScenarioSlider(
                        label: 'Add recurring income',
                        value: _extraRecurringIncome,
                        max: (snapshot.totalRecurringOutflow * 0.6)
                            .clamp(100, 5000)
                            .toDouble(),
                        formattedValue:
                            currencyFormat.format(_extraRecurringIncome),
                        onChanged: (value) {
                          setState(() => _extraRecurringIncome = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      _ScenarioSlider(
                        label: 'Reduce recurring expenses',
                        value: _expenseReduction,
                        max: snapshot.recurringExpenseTotal <= 0
                            ? 100
                            : snapshot.recurringExpenseTotal,
                        formattedValue:
                            currencyFormat.format(_expenseReduction),
                        onChanged: (value) {
                          setState(() => _expenseReduction = value);
                        },
                      ),
                      if (optionalSubscriptions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Pause optional subscriptions',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: optionalSubscriptions.map((entry) {
                            final selected =
                                _pausedSubscriptionIds.contains(entry.id);
                            return FilterChip(
                              label: Text(
                                '${entry.title} · ${currencyFormat.format(entry.monthlyAmount)}/mo',
                              ),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  if (selected) {
                                    _pausedSubscriptionIds.remove(entry.id);
                                  } else {
                                    _pausedSubscriptionIds.add(entry.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      if (scenarioActive) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: simulatedNetBalance >= 0
                                ? const Color(0xFF059669)
                                    .withValues(alpha: 0.08)
                                : colorScheme.errorContainer
                                    .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Simulated monthly balance',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currencyFormat.format(simulatedNetBalance),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Income ${currencyFormat.format(simulatedIncomeTotal)} · Expenses ${currencyFormat.format(simulatedExpenseTotal + simulatedSubscriptionTotal)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _extraRecurringIncome = 0;
                                    _expenseReduction = 0;
                                    _pausedSubscriptionIds.clear();
                                  });
                                },
                                child: const Text('Reset scenario'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: UiTokens.sectionGapLg),
                const _RecurringSectionHeader(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Ways to make ends meet',
                ),
                const SizedBox(height: 12),
                ...(scenarioActive
                        ? simulatedRecommendations
                        : snapshot.recommendations)
                    .map((recommendation) =>
                        InsightCard(insight: recommendation)),
                const SizedBox(height: UiTokens.sectionGapLg),
                const _RecurringSectionHeader(
                  icon: Icons.arrow_downward_rounded,
                  title: 'Recurring income',
                ),
                const SizedBox(height: 12),
                if (snapshot.incomeEntries.isEmpty)
                  const _EmptyRecurringState(
                    message: 'No recurring income has been configured yet.',
                  )
                else
                  ...snapshot.incomeEntries
                      .map((entry) => _RecurringEntryCard(entry: entry)),
                const SizedBox(height: UiTokens.sectionGapLg),
                const _RecurringSectionHeader(
                  icon: Icons.receipt_long_rounded,
                  title: 'Recurring expenses',
                ),
                const SizedBox(height: 12),
                if (snapshot.expenseEntries.isEmpty)
                  const _EmptyRecurringState(
                    message: 'No recurring expenses have been configured yet.',
                  )
                else
                  ...snapshot.expenseEntries
                      .map((entry) => _RecurringEntryCard(entry: entry)),
                const SizedBox(height: UiTokens.sectionGapLg),
                const _RecurringSectionHeader(
                  icon: Icons.subscriptions_rounded,
                  title: 'Subscriptions included',
                ),
                const SizedBox(height: 12),
                if (snapshot.subscriptionEntries.isEmpty)
                  const _EmptyRecurringState(
                    message: 'No active subscriptions are being tracked yet.',
                  )
                else
                  ...snapshot.subscriptionEntries
                      .map((entry) => _RecurringEntryCard(entry: entry)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecurringMetricChip extends StatelessWidget {
  const _RecurringMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UiTokens.radiusLg),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringSectionHeader extends StatelessWidget {
  const _RecurringSectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _RecurringEntryCard extends StatelessWidget {
  const _RecurringEntryCard({required this.entry});

  final RecurringBalanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = CurrencyUtils.getFormat(entry.currencyCode);
    final tone = switch (entry.kind) {
      RecurringBalanceEntryKind.income => const Color(0xFF059669),
      RecurringBalanceEntryKind.expense => Theme.of(context).colorScheme.error,
      RecurringBalanceEntryKind.subscription =>
        Theme.of(context).colorScheme.secondary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppSurfaces.elevated(context, radius: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                switch (entry.kind) {
                  RecurringBalanceEntryKind.income =>
                    Icons.arrow_downward_rounded,
                  RecurringBalanceEntryKind.expense =>
                    Icons.arrow_upward_rounded,
                  RecurringBalanceEntryKind.subscription =>
                    Icons.subscriptions_rounded,
                },
                color: tone,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RecurringPill(label: entry.cadenceLabel, tone: tone),
                      _RecurringPill(
                        label:
                            'Next ${DateFormat('MMM dd').format(entry.nextDate)}',
                        tone: Theme.of(context).colorScheme.primary,
                      ),
                      if (entry.isOptional)
                        _RecurringPill(
                          label: 'Optional',
                          tone: Theme.of(context).colorScheme.outline,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(entry.monthlyAmount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currencyFormat.format(entry.chargeAmount)} / ${entry.cadenceLabel.toLowerCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringPill extends StatelessWidget {
  const _RecurringPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyRecurringState extends StatelessWidget {
  const _EmptyRecurringState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppSurfaces.elevated(context, radius: 18),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ScenarioSlider extends StatelessWidget {
  const _ScenarioSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.formattedValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final String formattedValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveMax = (max <= 0 ? 100.0 : max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              formattedValue,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, effectiveMax).toDouble(),
          max: effectiveMax,
          divisions: 20,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
