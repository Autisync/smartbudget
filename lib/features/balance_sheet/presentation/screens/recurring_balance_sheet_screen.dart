import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/widgets/app_shimmer.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/data/models/tables.dart'
    show
        BillingCycle,
        SubscriptionImportance,
        TransactionRecurrence,
        TransactionType;
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/models/insight.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

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
  final locale = ref.watch(appLocaleControllerProvider);
  final l10n = lookupAppLocalizations(locale);
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
              : l10n.balanceSheetRecurringType(
                  transaction.isIncome
                      ? l10n.income.toLowerCase()
                      : l10n.expense.toLowerCase(),
                ),
          kind: transaction.isIncome
              ? RecurringBalanceEntryKind.income
              : RecurringBalanceEntryKind.expense,
          chargeAmount: convertedChargeAmount,
          monthlyAmount: _monthlyAmountForRecurrence(
            convertedChargeAmount,
            transaction.recurrence,
          ),
          currencyCode: workingCurrency,
          cadenceLabel: _recurrenceLabel(l10n, transaction.recurrence),
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
          cadenceLabel: _billingCycleLabel(l10n, subscription.billingCycle),
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
      l10n: l10n,
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

String _recurrenceLabel(
  AppLocalizations l10n,
  TransactionRecurrence recurrence,
) {
  switch (recurrence) {
    case TransactionRecurrence.daily:
      return l10n.transactionsRecurrenceDaily;
    case TransactionRecurrence.weekly:
      return l10n.transactionsRecurrenceWeekly;
    case TransactionRecurrence.monthly:
      return l10n.transactionsRecurrenceMonthly;
    case TransactionRecurrence.yearly:
      return l10n.transactionsRecurrenceYearly;
    case TransactionRecurrence.none:
      return l10n.transactionsRecurrenceNone;
  }
}

String _billingCycleLabel(AppLocalizations l10n, BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return l10n.subscriptionsBillingWeekly;
    case BillingCycle.monthly:
      return l10n.subscriptionsBillingMonthly;
    case BillingCycle.quarterly:
      return l10n.subscriptionsBillingQuarterly;
    case BillingCycle.yearly:
      return l10n.subscriptionsBillingYearly;
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
  required AppLocalizations l10n,
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
    return [
      Insight(
        id: 'recurring-empty',
        title: l10n.balanceSheetInsightEmptyTitle,
        explanation: l10n.balanceSheetInsightEmptyExplanation,
        impact: l10n.balanceSheetInsightEmptyImpact,
        action: l10n.balanceSheetInsightEmptyAction,
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
        title: l10n.balanceSheetInsightShortfallTitle,
        explanation: l10n.balanceSheetInsightShortfallExplanation(
          currencyFormat.format(-netBalance),
        ),
        impact: l10n.balanceSheetInsightShortfallImpact,
        action: optionalSubscriptionSavings > 0
            ? l10n.balanceSheetInsightShortfallActionOptional(
                currencyFormat.format(
                    (-netBalance).clamp(0, optionalSubscriptionSavings)),
              )
            : l10n.balanceSheetInsightShortfallAction(
                currencyFormat.format(-netBalance),
              ),
        confidence: 0.92,
        severity: InsightSeverity.high,
        type: InsightType.forecast,
      ),
    );
  } else if (coverageRatio < 1.1) {
    insights.add(
      Insight(
        id: 'recurring-thin-buffer',
        title: l10n.balanceSheetInsightThinBufferTitle,
        explanation: l10n.balanceSheetInsightThinBufferExplanation(
          currencyFormat.format(netBalance),
        ),
        impact: l10n.balanceSheetInsightThinBufferImpact,
        action: l10n.balanceSheetInsightThinBufferAction,
        confidence: 0.84,
        severity: InsightSeverity.medium,
        type: InsightType.recommendation,
      ),
    );
  } else {
    insights.add(
      Insight(
        id: 'recurring-covered',
        title: l10n.balanceSheetInsightCoveredTitle,
        explanation: l10n.balanceSheetInsightCoveredExplanation(
          currencyFormat.format(netBalance),
        ),
        impact: l10n.balanceSheetInsightCoveredImpact,
        action: l10n.balanceSheetInsightCoveredAction,
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
        title: l10n.balanceSheetInsightNearTermTitle,
        explanation: l10n.balanceSheetInsightNearTermExplanation(
          currencyFormat.format(nearTermCommitments),
          currencyFormat.format(nearTermIncome),
        ),
        impact: l10n.balanceSheetInsightNearTermImpact,
        action: l10n.balanceSheetInsightNearTermAction,
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
        title: l10n.balanceSheetInsightSubscriptionShareTitle,
        explanation: l10n.balanceSheetInsightSubscriptionShareExplanation(
          (subscriptionShare * 100).toStringAsFixed(0),
        ),
        impact: l10n.balanceSheetInsightSubscriptionShareImpact,
        action: optionalSubscriptionSavings > 0
            ? l10n.balanceSheetInsightSubscriptionShareActionOptional(
                currencyFormat.format(optionalSubscriptionSavings),
              )
            : l10n.balanceSheetInsightSubscriptionShareAction,
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
        title: l10n.balanceSheetInsightLargestBillTitle,
        explanation: l10n.balanceSheetInsightLargestBillExplanation(
          largestExpense.title,
          currencyFormat.format(largestExpense.monthlyAmount),
        ),
        impact: l10n.balanceSheetInsightLargestBillImpact,
        action: l10n.balanceSheetInsightLargestBillAction(
          largestExpense.title,
        ),
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
  bool _isAppBarScrolled = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshotAsync = ref.watch(recurringBalanceSheetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.dashboardBalanceSheetTitle,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'balance-sheet-appbar-blur-on',
          offKey: 'balance-sheet-appbar-blur-off',
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: snapshotAsync.when(
          loading: () => const AppShimmerSkeleton(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l10n.balanceSheetBuildError(error.toString())),
            ),
          ),
          data: (snapshot) {
            final currencyFormat =
                CurrencyUtils.getFormat(snapshot.currencyCode);
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
              l10n: l10n,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── PAGE HEADER ─────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.dashboardBalanceSheetTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                    height: 1.1,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── CURRENCY FALLBACK BANNER ─────────────────────────
                      if (snapshot.isCurrencyFallback) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  colorScheme.tertiary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            l10n.balanceSheetCurrencyFallback(
                              snapshot.requestedCurrencyCode,
                              snapshot.currencyCode,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── HERO CARD ────────────────────────────────────────
                      _HeroSummaryCard(
                        snapshot: snapshot,
                        currencyFormat: currencyFormat,
                        isDark: isDark,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 24),

                      // ─── COVERAGE OUTLOOK ────────────────────────────────
                      _CoverageOutlookCard(
                        snapshot: snapshot,
                        isDark: isDark,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 24),

                      // ─── SCENARIO LAB ────────────────────────────────────
                      _ScenarioLabCard(
                        snapshot: snapshot,
                        currencyFormat: currencyFormat,
                        isDark: isDark,
                        extraRecurringIncome: _extraRecurringIncome,
                        expenseReduction: _expenseReduction,
                        pausedSubscriptionIds: _pausedSubscriptionIds,
                        simulatedNetBalance: simulatedNetBalance,
                        simulatedIncomeTotal: simulatedIncomeTotal,
                        simulatedExpenseTotal: simulatedExpenseTotal,
                        simulatedSubscriptionTotal: simulatedSubscriptionTotal,
                        scenarioActive: scenarioActive,
                        l10n: l10n,
                        onIncomeChanged: (v) =>
                            setState(() => _extraRecurringIncome = v),
                        onExpenseChanged: (v) =>
                            setState(() => _expenseReduction = v),
                        onSubscriptionToggled: (id) => setState(() {
                          if (_pausedSubscriptionIds.contains(id)) {
                            _pausedSubscriptionIds.remove(id);
                          } else {
                            _pausedSubscriptionIds.add(id);
                          }
                        }),
                        onReset: () => setState(() {
                          _extraRecurringIncome = 0;
                          _expenseReduction = 0;
                          _pausedSubscriptionIds.clear();
                        }),
                      ),
                      const SizedBox(height: 32),

                      // ─── WAYS TO MAKE ENDS MEET ───────────────────────────
                      _PremiumSectionHeader(
                        icon: Icons.wb_incandescent_rounded,
                        title: l10n.balanceSheetWaysToMakeEndsMeet,
                        tone: AppColors.statusFor(
                            isDark ? Brightness.dark : Brightness.light,
                            AppStatus.warning),
                      ),
                      const SizedBox(height: 16),
                      ...(scenarioActive
                              ? simulatedRecommendations
                              : snapshot.recommendations)
                          .map((r) => _PremiumInsightCard(insight: r)),
                      const SizedBox(height: 32),

                      // ─── RECURRING INCOME ─────────────────────────────────
                      _PremiumSectionHeader(
                        icon: Icons.arrow_downward_rounded,
                        title: l10n.balanceSheetRecurringIncome,
                        tone: AppColors.income(
                            isDark ? Brightness.dark : Brightness.light),
                      ),
                      const SizedBox(height: 16),
                      _PremiumEntriesCard(
                        entries: snapshot.incomeEntries,
                        emptyMessage: l10n.balanceSheetNoRecurringIncome,
                        l10n: l10n,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),

                      // ─── RECURRING EXPENSES ───────────────────────────────
                      _PremiumSectionHeader(
                        icon: Icons.receipt_long_rounded,
                        title: l10n.balanceSheetRecurringExpenses,
                        tone: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      _PremiumEntriesCard(
                        entries: snapshot.expenseEntries,
                        emptyMessage: l10n.balanceSheetNoRecurringExpenses,
                        l10n: l10n,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),

                      // ─── SUBSCRIPTIONS ────────────────────────────────────
                      _PremiumSectionHeader(
                        icon: Icons.subscriptions_rounded,
                        title: l10n.balanceSheetSubscriptionsIncluded,
                        tone: colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      _PremiumEntriesCard(
                        entries: snapshot.subscriptionEntries,
                        emptyMessage: l10n.insightsNoActiveSubscriptions,
                        l10n: l10n,
                        isDark: isDark,
                      ),
                      SizedBox(
                          height: 32 + MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── HERO SUMMARY CARD ───────────────────────────────────────────────────────

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.snapshot,
    required this.currencyFormat,
    required this.isDark,
    required this.l10n,
  });

  final RecurringBalanceSnapshot snapshot;
  final NumberFormat currencyFormat;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = snapshot.canCoverRecurring;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: isPositive
              ? isDark
                  ? [const Color(0xFF0D2E1F), const Color(0xFF0A2016)]
                  : [const Color(0xFFF0FDF4), const Color(0xFFEBFAF3)]
              : isDark
                  ? [const Color(0xFF2E0D0D), const Color(0xFF2A0808)]
                  : [const Color(0xFFFFF5F6), const Color(0xFFFFF1F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isPositive
              ? AppColors.income(colorScheme.brightness)
                  .withValues(alpha: isDark ? 0.25 : 0.45)
              : colorScheme.error.withValues(alpha: isDark ? 0.25 : 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.income(colorScheme.brightness)
                          .withValues(alpha: 0.14)
                      : colorScheme.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPositive
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  color: isPositive
                      ? AppColors.income(colorScheme.brightness)
                      : colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPositive
                      ? l10n.balanceSheetCoveredTitle
                      : l10n.balanceSheetDeficitTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.2,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            currencyFormat.format(snapshot.netMonthlyBalance),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              height: 1.0,
              color: isPositive
                  ? AppColors.income(colorScheme.brightness)
                  : colorScheme.error,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPositive
                ? l10n.balanceSheetCoveredSubtitle
                : l10n.balanceSheetDeficitSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          // 2x2 metric grid
          Row(
            children: [
              Expanded(
                child: _MetricGridCell(
                  icon: Icons.arrow_downward_rounded,
                  label: l10n.balanceSheetIncomePerMonth,
                  value: currencyFormat.format(snapshot.recurringIncomeTotal),
                  tone: AppColors.income(
                      isDark ? Brightness.dark : Brightness.light),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricGridCell(
                  icon: Icons.arrow_upward_rounded,
                  label: l10n.balanceSheetExpensesPerMonth,
                  value: currencyFormat.format(snapshot.recurringExpenseTotal),
                  tone: colorScheme.error,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricGridCell(
                  icon: Icons.subscriptions_rounded,
                  label: l10n.balanceSheetSubscriptionsPerMonth,
                  value:
                      currencyFormat.format(snapshot.subscriptionExpenseTotal),
                  tone: colorScheme.secondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricGridCell(
                  icon: Icons.schedule_rounded,
                  label: l10n.balanceSheetDueIn14Days,
                  value: currencyFormat.format(snapshot.nearTermCommitments),
                  tone: AppColors.statusFor(
                      isDark ? Brightness.dark : Brightness.light,
                      AppStatus.warning),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── METRIC GRID CELL ────────────────────────────────────────────────────────

class _MetricGridCell extends StatelessWidget {
  const _MetricGridCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── COVERAGE OUTLOOK CARD ───────────────────────────────────────────────────

class _CoverageOutlookCard extends StatelessWidget {
  const _CoverageOutlookCard({
    required this.snapshot,
    required this.isDark,
    required this.l10n,
  });

  final RecurringBalanceSnapshot snapshot;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = snapshot.coverageRatio >= 1.1
        ? AppColors.statusFor(colorScheme.brightness, AppStatus.success)
        : snapshot.coverageRatio >= 1
            ? AppColors.statusFor(colorScheme.brightness, AppStatus.warning)
            : colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.balanceSheetCoverageOutlook,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: snapshot.coverageRatio.clamp(0.0, 1.4) / 1.4,
              minHeight: 8,
              color: barColor,
              backgroundColor:
                  colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.balanceSheetCoveragePercent(
              (snapshot.coverageRatio * 100).toStringAsFixed(0),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.balanceSheetCoverageFootnote(snapshot.currencyCode),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── SCENARIO LAB CARD ───────────────────────────────────────────────────────

class _ScenarioLabCard extends StatelessWidget {
  const _ScenarioLabCard({
    required this.snapshot,
    required this.currencyFormat,
    required this.isDark,
    required this.extraRecurringIncome,
    required this.expenseReduction,
    required this.pausedSubscriptionIds,
    required this.simulatedNetBalance,
    required this.simulatedIncomeTotal,
    required this.simulatedExpenseTotal,
    required this.simulatedSubscriptionTotal,
    required this.scenarioActive,
    required this.l10n,
    required this.onIncomeChanged,
    required this.onExpenseChanged,
    required this.onSubscriptionToggled,
    required this.onReset,
  });

  final RecurringBalanceSnapshot snapshot;
  final NumberFormat currencyFormat;
  final bool isDark;
  final double extraRecurringIncome;
  final double expenseReduction;
  final Set<String> pausedSubscriptionIds;
  final double simulatedNetBalance;
  final double simulatedIncomeTotal;
  final double simulatedExpenseTotal;
  final double simulatedSubscriptionTotal;
  final bool scenarioActive;
  final AppLocalizations l10n;
  final ValueChanged<double> onIncomeChanged;
  final ValueChanged<double> onExpenseChanged;
  final ValueChanged<String> onSubscriptionToggled;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final optionalSubscriptions = snapshot.subscriptionEntries
        .where((entry) => entry.isOptional)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1A40), const Color(0xFF1A1A2E)]
              : [const Color(0xFFF5F3FF), const Color(0xFFFAF9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? Colors.purple.withValues(alpha: 0.15)
              : const Color(0xFFE8E0FF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.science_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.balanceSheetScenarioLab,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.balanceSheetScenarioSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/scenario-lab'),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open full Scenario Lab'),
            ),
          ),
          const SizedBox(height: 20),
          _PremiumSlider(
            label: l10n.balanceSheetAddRecurringIncome,
            value: extraRecurringIncome,
            max: (snapshot.totalRecurringOutflow * 0.6)
                .clamp(100, 5000)
                .toDouble(),
            formattedValue: currencyFormat.format(extraRecurringIncome),
            activeColor: AppColors.income(colorScheme.brightness),
            onChanged: onIncomeChanged,
          ),
          const SizedBox(height: 16),
          _PremiumSlider(
            label: l10n.balanceSheetReduceRecurringExpenses,
            value: expenseReduction,
            max: snapshot.recurringExpenseTotal <= 0
                ? 100
                : snapshot.recurringExpenseTotal,
            formattedValue: currencyFormat.format(expenseReduction),
            activeColor: colorScheme.error,
            onChanged: onExpenseChanged,
          ),
          if (optionalSubscriptions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.balanceSheetPauseOptionalSubscriptions,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: optionalSubscriptions.map((entry) {
                final selected = pausedSubscriptionIds.contains(entry.id);
                return FilterChip(
                  label: Text(
                    l10n.balanceSheetSubscriptionChip(
                      entry.title,
                      currencyFormat.format(entry.monthlyAmount),
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => onSubscriptionToggled(entry.id),
                );
              }).toList(),
            ),
          ],
          if (scenarioActive) ...[
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: simulatedNetBalance >= 0
                    ? AppColors.income(colorScheme.brightness)
                        .withValues(alpha: 0.1)
                    : colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: simulatedNetBalance >= 0
                      ? AppColors.income(colorScheme.brightness)
                          .withValues(alpha: 0.25)
                      : colorScheme.error.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.balanceSheetSimulatedMonthlyBalance,
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
                    l10n.balanceSheetSimulatedIncomeExpenses(
                      currencyFormat.format(simulatedIncomeTotal),
                      currencyFormat.format(
                        simulatedExpenseTotal + simulatedSubscriptionTotal,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onReset,
                    child: Text(
                      l10n.balanceSheetResetScenario,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── PREMIUM SLIDER ──────────────────────────────────────────────────────────

class _PremiumSlider extends StatelessWidget {
  const _PremiumSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.formattedValue,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final String formattedValue;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveMax = (max <= 0 ? 100.0 : max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                formattedValue,
                key: ValueKey(formattedValue),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: activeColor,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: activeColor,
            inactiveTrackColor: activeColor.withValues(alpha: 0.15),
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.08),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: value.clamp(0, effectiveMax).toDouble(),
            max: effectiveMax,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── PREMIUM SECTION HEADER ──────────────────────────────────────────────────

class _PremiumSectionHeader extends StatelessWidget {
  const _PremiumSectionHeader({
    required this.icon,
    required this.title,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: tone, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.1,
                ),
          ),
        ),
      ],
    );
  }
}

// ─── PREMIUM INSIGHT CARD ────────────────────────────────────────────────────

class _PremiumInsightCard extends StatelessWidget {
  const _PremiumInsightCard({required this.insight});

  final Insight insight;

  Color _toneForSeverity(InsightSeverity severity, ColorScheme cs) {
    return switch (severity) {
      InsightSeverity.high => cs.error,
      InsightSeverity.medium =>
        AppColors.statusFor(cs.brightness, AppStatus.warning),
      InsightSeverity.low =>
        AppColors.statusFor(cs.brightness, AppStatus.success),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = _toneForSeverity(insight.severity, colorScheme);
    final confidencePct = '${(insight.confidence * 100).toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: tone.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  confidencePct,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tone,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 12),
          _InsightSection(label: 'Impact', text: insight.impact),
          const SizedBox(height: 8),
          _InsightSection(label: 'Action', text: insight.action),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

// ─── PREMIUM ENTRIES CARD ────────────────────────────────────────────────────

class _PremiumEntriesCard extends StatelessWidget {
  const _PremiumEntriesCard({
    required this.entries,
    required this.emptyMessage,
    required this.l10n,
    required this.isDark,
  });

  final List<RecurringBalanceEntry> entries;
  final String emptyMessage;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: entries
          .map((e) => _PremiumEntryCard(entry: e, l10n: l10n, isDark: isDark))
          .toList(),
    );
  }
}

// ─── PREMIUM ENTRY CARD ──────────────────────────────────────────────────────

class _PremiumEntryCard extends StatelessWidget {
  const _PremiumEntryCard({
    required this.entry,
    required this.l10n,
    required this.isDark,
  });

  final RecurringBalanceEntry entry;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = CurrencyUtils.getFormat(entry.currencyCode);
    final tone = switch (entry.kind) {
      RecurringBalanceEntryKind.income =>
        AppColors.income(colorScheme.brightness),
      RecurringBalanceEntryKind.expense => colorScheme.error,
      RecurringBalanceEntryKind.subscription => colorScheme.secondary,
    };
    final kindIcon = switch (entry.kind) {
      RecurringBalanceEntryKind.income => Icons.arrow_downward_rounded,
      RecurringBalanceEntryKind.expense => Icons.arrow_upward_rounded,
      RecurringBalanceEntryKind.subscription => Icons.subscriptions_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
            child: Icon(kindIcon, color: tone, size: 20),
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
                const SizedBox(height: 3),
                Text(
                  entry.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _RecurringPill(label: entry.cadenceLabel, tone: tone),
                    _RecurringPill(
                      label: l10n.balanceSheetNextDate(
                        DateFormat('MMM dd').format(entry.nextDate),
                      ),
                      tone: colorScheme.primary,
                    ),
                    if (entry.isOptional)
                      _RecurringPill(
                        label: l10n.balanceSheetOptional,
                        tone: colorScheme.outline,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${currencyFormat.format(entry.chargeAmount)} / ${entry.cadenceLabel.toLowerCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── RECURRING PILL ──────────────────────────────────────────────────────────

class _RecurringPill extends StatelessWidget {
  const _RecurringPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
