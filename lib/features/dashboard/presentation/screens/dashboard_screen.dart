import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/charts/app_finance_charts.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/exchange_rate_service.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionType;
import 'package:smartbudget/data/models/tables.dart' show TransactionRecurrence;
import 'package:smartbudget/intelligence/engines/financial_insight_engines.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

final _dashboardLiveRateQuoteProvider =
    FutureProvider.family<ExchangeRateQuote, String>((ref, pairKey) async {
  final parts = pairKey.split(':');
  if (parts.length != 2) {
    throw ArgumentError('Invalid currency pair: $pairKey');
  }
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);
  return exchangeRateService.fetchRate(
    base: parts.first,
    target: parts.last,
  );
});

final _dashboardBurnRateProvider = FutureProvider<BurnRateInsight>((ref) async {
  final transactions = await ref.watch(transactionListProvider().future);
  final budgets = await ref.watch(activeBudgetsProvider.future);
  final totalBudget = budgets
      .where((budget) => budget.isActive)
      .fold<double>(0.0, (sum, budget) => sum + budget.limitAmount);

  return const BurnRateEngine().calculate(
    transactions: transactions,
    monthlyBudgetLimit: totalBudget > 0 ? totalBudget : null,
  );
});

const List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.04),
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ProviderSubscription<AsyncValue<List<BudgetAlert>>>? _alertSubscription;
  ProviderSubscription<AsyncValue<FinancialHealthSnapshot>>?
      _healthSubscription;
  final Set<String> _notifiedBudgetAlertIds = <String>{};
  bool _healthInsightSent = false;
  bool _isAppBarScrolled = false;

  Future<void> _openAddTransactionModal() async {
    await AppFormSheet.show<void>(
      context,
      builder: (_) => const TransactionFormSheet(
        mode: TransactionFormMode.create,
        asModal: true,
      ),
    );
  }

  Future<void> _openEditTransactionModal(Transaction transaction) async {
    await AppFormSheet.show<void>(
      context,
      builder: (_) => TransactionFormSheet(
        mode: TransactionFormMode.update,
        initialData: transaction,
        asModal: true,
      ),
    );
  }

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _buildDisplayName() {
    final session = ref.read(sessionControllerProvider);
    final name = [
      session.user?.firstName ?? '',
      session.user?.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    return name.isEmpty ? 'SmartSpend User' : name;
  }

  @override
  void initState() {
    super.initState();
    _alertSubscription = ref.listenManual<AsyncValue<List<BudgetAlert>>>(
      budgetAlertsProvider,
      (previous, next) {
        next.whenData((alerts) async {
          final notificationService = ref.read(notificationServiceProvider);
          final preferencesService =
              ref.read(notificationPreferencesServiceProvider);
          final locale = ref.read(appLocaleControllerProvider);
          final l10n = lookupAppLocalizations(locale);
          for (final alert in alerts) {
            final key =
                '${alert.budgetId}-${alert.overLimit}-${alert.nearLimit}';
            if (_notifiedBudgetAlertIds.contains(key)) continue;
            final canSend =
                await preferencesService.shouldDispatch('budgetAlerts');
            if (!canSend) break;
            _notifiedBudgetAlertIds.add(key);
            final title = alert.overLimit
                ? l10n.dashboardBudgetExceededTitle
                : l10n.dashboardBudgetAlertTitle;
            final body = l10n.dashboardBudgetAlertBody(
              alert.category,
              (alert.progress * 100).toStringAsFixed(1),
            );
            await notificationService.showBudgetAlert(
              title: title,
              body: body,
              payload: alert.budgetId,
            );
          }
        });
      },
    );
    _healthSubscription = ref.listenManual<AsyncValue<FinancialHealthSnapshot>>(
      financialHealthProvider,
      (previous, next) {
        next.whenData((health) async {
          if (_healthInsightSent) return;
          if (health.totalScore >= 60) return;
          final preferencesService =
              ref.read(notificationPreferencesServiceProvider);
          final locale = ref.read(appLocaleControllerProvider);
          final l10n = lookupAppLocalizations(locale);
          final canSend =
              await preferencesService.shouldDispatch('healthInsights');
          if (!canSend) return;
          _healthInsightSent = true;
          await ref.read(notificationServiceProvider).showHealthInsight(
                title: l10n.dashboardHealthNeedsAttentionTitle,
                body: l10n.dashboardHealthNeedsAttentionBody(
                  health.totalScore.toStringAsFixed(0),
                ),
                payload: 'health_insight',
              );
        });
      },
    );
  }

  @override
  void dispose() {
    _alertSubscription?.close();
    _healthSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final liveRateBaseCurrency = appCurrency == 'USD' ? 'EUR' : 'USD';
    final allTxAsync = ref.watch(transactionListProvider());
    final alertsAsync = ref.watch(budgetAlertsProvider);
    final healthAsync = ref.watch(financialHealthProvider);
    ref.watch(recurringTransactionsProvider);
    final burnRateAsync = ref.watch(_dashboardBurnRateProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    final income = allTxAsync.maybeWhen(
      data: (transactions) => transactions
          .where((tx) => tx.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount),
      orElse: () => 0.0,
    );
    final expenses = allTxAsync.maybeWhen(
      data: (transactions) => transactions
          .where((tx) => tx.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount),
      orElse: () => 0.0,
    );
    final greeting = _buildGreeting();
    final displayName = _buildDisplayName();

    final isDashboardDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      backgroundColor: isDashboardDark ? null : const Color(0xFFF8F8FA),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 70,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: buildFrostedFlexibleSpace(
                context: context,
                isScrolled: _isAppBarScrolled,
                onKey: 'dashboard-appbar-blur-on',
                offKey: 'dashboard-appbar-blur-off',
              ),
              title: buildFrostedAppBarTitle(
                context: context,
                title: l10n.navHome,
                isScrolled: _isAppBarScrolled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.78),
                          ),
                    ),
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              actions: buildPageHeaderActions(
                context: context,
                isScrolled: _isAppBarScrolled,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeBalanceCard(
                      l10n: l10n,
                      currencyFormat: currencyFormat,
                      currencyCode: appCurrency,
                      income: income,
                      expenses: expenses,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: HomeMetricCard(
                            icon: Icons.receipt_long_rounded,
                            label: l10n.dashboardMetricsTransactions,
                            value: allTxAsync.maybeWhen(
                              data: (tx) => '${tx.length}',
                              orElse: () => '\u2014',
                            ),
                            iconColor: const Color(0xFF1E88E5),
                            iconBg: const Color(0xFFE3F0FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HomeMetricCard(
                            icon: Icons.warning_amber_rounded,
                            label: l10n.dashboardMetricsBudgetAlerts,
                            value: alertsAsync.maybeWhen(
                              data: (a) => '${a.length}',
                              orElse: () => '\u2014',
                            ),
                            iconColor: const Color(0xFFF57C00),
                            iconBg: const Color(0xFFFFF3E0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HomeMetricCard(
                            icon: Icons.monitor_heart_rounded,
                            label: l10n.dashboardMetricsHealthScore,
                            value: healthAsync.maybeWhen(
                              data: (h) => h.totalScore.toStringAsFixed(0),
                              orElse: () => '\u2014',
                            ),
                            iconColor: const Color(0xFF2E7D32),
                            iconBg: const Color(0xFFE8F5E9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    healthAsync.when(
                      data: (health) => HomeFinancialHealthCard(
                        l10n: l10n,
                        score: health.totalScore,
                        budgetComponent: health.budgetDisciplineScore,
                        savingsComponent: health.savingsMomentumScore,
                        onViewDetails: () => context.go('/health'),
                      ),
                      loading: () => const _LoadingCard(),
                      error: (_, __) => _ErrorCard(l10n: l10n),
                    ),
                    const SizedBox(height: 24),
                    HomeRecurringBalanceCard(
                      l10n: l10n,
                      onOpen: () => context.push('/balance-sheet'),
                    ),
                    const SizedBox(height: 24),
                    burnRateAsync.when(
                      data: (burnRate) => _HomeSpendingCard(
                        l10n: l10n,
                        burnRate: burnRate,
                        currencyFormat: currencyFormat,
                        currencyCode: appCurrency,
                      ),
                      loading: () => const _LoadingCard(),
                      error: (_, __) => AppErrorState(
                        title: 'Unable to load burn rate',
                        message:
                            'Try again in a moment to view spending pace insights.',
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.invalidate(_dashboardBurnRateProvider),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.dashboardRecentTransactions,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/transactions'),
                          child: Text(
                            l10n.commonSeeAll,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            recentAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.noTransactions,
                        message: l10n.noTransactionsSubtitle,
                        lottieAsset:
                            'assets/animations/empty_transactions.json',
                        action: FilledButton.icon(
                          onPressed: _openAddTransactionModal,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.addTransaction),
                        ),
                      ),
                    ),
                  );
                }
                final items = transactions.take(5).toList();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = items[index];
                      final isExpense = tx.type == TransactionType.expense;
                      final amountColor = isExpense
                          ? const Color(0xFFE53935)
                          : const Color(0xFF2E7D32);
                      final recurrenceLabel =
                          tx.recurrence == TransactionRecurrence.none
                              ? null
                              : tx.recurrence.name.toUpperCase();
                      final subtitle = tx.note?.trim().isNotEmpty == true
                          ? tx.note!
                          : l10n.transactionsNoNote;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                        child: AppTransactionTile(
                          icon: isExpense
                              ? Icons.arrow_outward_rounded
                              : Icons.arrow_downward_rounded,
                          title: tx.category,
                          subtitle: recurrenceLabel == null
                              ? subtitle
                              : '$subtitle • $recurrenceLabel',
                          amount:
                              '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                          amountColor: amountColor,
                          onTap: () => _openEditTransactionModal(tx),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: _LoadingCard(),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: AppErrorState(
                    title: 'Could not load recent transactions',
                    message: l10n.dashboardErrorLoadingTransactions,
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(recentTransactionsProvider),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  88 + MediaQuery.paddingOf(context).bottom,
                ),
                child: _DashboardLiveRateCard(
                  l10n: l10n,
                  baseCurrency: liveRateBaseCurrency,
                  targetCurrency: appCurrency,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({
    super.key,
    required this.l10n,
    required this.currencyFormat,
    required this.currencyCode,
    required this.income,
    required this.expenses,
  });

  final AppLocalizations l10n;
  final NumberFormat currencyFormat;
  final String currencyCode;
  final double income;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final balance = income - expenses;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E1A40), Color(0xFF2D1545)]
              : const [Color(0xFFD4D5FF), Color(0xFFEDD5FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(120, 100, 200, 0.10),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.totalBalance,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B6B8A),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currencyCode,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currencyFormat.format(balance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          AppLineSparkChart(
            values: [income, expenses, balance],
            color: const Color(0xFF5C6BFF),
            height: 64,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  icon: Icons.arrow_downward_rounded,
                  label: l10n.income,
                  value: CurrencyUtils.getCompactFormat(currencyCode)
                      .format(income),
                  iconColor: const Color(0xFF2E7D32),
                  iconBg: const Color(0xFFD0F0DA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BalanceMetric(
                  icon: Icons.arrow_upward_rounded,
                  label: l10n.expense,
                  value: CurrencyUtils.getCompactFormat(currencyCode)
                      .format(expenses),
                  iconColor: const Color(0xFFB71C1C),
                  iconBg: const Color(0xFFFFE4E4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeMetricCard extends StatelessWidget {
  const HomeMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adaptedIconBg = isDark ? iconColor.withValues(alpha: 0.2) : iconBg;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: adaptedIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeFinancialHealthCard extends StatelessWidget {
  const HomeFinancialHealthCard({
    super.key,
    required this.l10n,
    required this.score,
    required this.budgetComponent,
    required this.savingsComponent,
    required this.onViewDetails,
  });

  final AppLocalizations l10n;
  final double score;
  final double budgetComponent;
  final double savingsComponent;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final roundedScore = score.round();
    final isStrong = roundedScore >= 80;
    final isOk = roundedScore >= 60;
    final statusColor = isStrong
        ? const Color(0xFF2E7D32)
        : isOk
            ? const Color(0xFFF57C00)
            : const Color(0xFFB71C1C);
    final statusLabel = isStrong
        ? l10n.financialHealthStatusStrong
        : isOk
            ? l10n.financialHealthStatusNeedsAttention
            : l10n.financialHealthStatusAtRisk;
    final barColor = isStrong
        ? const Color(0xFF43A047)
        : isOk
            ? const Color(0xFFFB8C00)
            : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.financialHealthTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall score',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$roundedScore/100',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ThinProgressBar(value: score / 100, color: barColor),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.dashboardHealthBreakdown(
                budgetComponent.toStringAsFixed(0),
                savingsComponent.toStringAsFixed(0),
              ),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                l10n.commonViewDetails,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeRecurringBalanceCard extends StatelessWidget {
  const HomeRecurringBalanceCard({
    super.key,
    required this.l10n,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1A1A) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF5C2020) : const Color(0xFFFFCDD2),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(229, 57, 53, 0.06),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4A1A1A)
                      : const Color(0xFFFFE4E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFFB71C1C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardBalanceSheetTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.dashboardBalanceSheetSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onOpen,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF5C2020)
                      : const Color(0xFFFFCDD2),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                l10n.commonOpen,
                style: const TextStyle(
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSpendingCard extends StatelessWidget {
  const _HomeSpendingCard({
    required this.l10n,
    required this.burnRate,
    required this.currencyFormat,
    required this.currencyCode,
  });

  final AppLocalizations l10n;
  final BurnRateInsight burnRate;
  final NumberFormat currencyFormat;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(burnRate.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardBurnRate,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(burnRate.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  currencyFormat.format(burnRate.monthlySpend),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currencyCode,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _burnRateMessage(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BurnRateStatus status) {
    switch (status) {
      case BurnRateStatus.critical:
        return const Color(0xFFC62828);
      case BurnRateStatus.high:
        return const Color(0xFFEF6C00);
      case BurnRateStatus.watch:
        return const Color(0xFFB28704);
      case BurnRateStatus.healthy:
        return const Color(0xFF2E7D32);
    }
  }

  String _statusLabel(BurnRateStatus status) {
    switch (status) {
      case BurnRateStatus.critical:
        return 'Critical';
      case BurnRateStatus.high:
        return 'High';
      case BurnRateStatus.watch:
        return 'Watch';
      case BurnRateStatus.healthy:
        return 'Healthy';
    }
  }

  String _burnRateMessage() {
    if (!burnRate.hasData) {
      return 'No spending activity this month yet. Add transactions to track your burn pace.';
    }
    final projected = currencyFormat.format(burnRate.projectedMonthEndSpend);
    final perDay = currencyFormat.format(burnRate.averageDailySpend);
    if (burnRate.safeDailySpend > 0) {
      final safe = currencyFormat.format(burnRate.safeDailySpend);
      return 'Avg/day $perDay. Projected month-end: $projected. Keep daily spending near $safe for a safer runway.';
    }
    return 'Avg/day $perDay. Projected month-end: $projected.';
  }
}

class _ThinProgressBar extends StatelessWidget {
  const _ThinProgressBar({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.4),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 6,
                width: constraints.maxWidth * clamped,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardLiveRateCard extends ConsumerWidget {
  const _DashboardLiveRateCard({
    required this.l10n,
    required this.baseCurrency,
    required this.targetCurrency,
  });

  final AppLocalizations l10n;
  final String baseCurrency;
  final String targetCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pairKey = '$baseCurrency:$targetCurrency';
    final quoteAsync = ref.watch(_dashboardLiveRateQuoteProvider(pairKey));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
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
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.currency_exchange_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.dashboardLiveRateCheck,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.dashboardRefreshRate,
                onPressed: () =>
                    ref.invalidate(_dashboardLiveRateQuoteProvider(pairKey)),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dashboardQuickQuoteSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          quoteAsync.when(
            data: (quote) => _DashboardLiveRateQuote(
              l10n: l10n,
              quote: quote,
              onOpenFullTool: () => context.push('/exchange-rates'),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: AppLottieView(
                  assetPath: 'assets/animations/loading.json',
                  width: 52,
                  height: 52,
                  repeat: false,
                  animate: true,
                  semanticLabel: 'Loading exchange rate',
                  fallbackIcon: Icons.sync,
                ),
              ),
            ),
            error: (_, __) => Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dashboardRateUnavailable,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.push('/exchange-rates'),
                  child: Text(l10n.commonOpen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLiveRateQuote extends StatelessWidget {
  const _DashboardLiveRateQuote({
    required this.l10n,
    required this.quote,
    required this.onOpenFullTool,
  });

  final AppLocalizations l10n;
  final ExchangeRateQuote quote;
  final VoidCallback onOpenFullTool;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inverseRate = quote.rate == 0 ? 0 : 1 / quote.rate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1 ${quote.base} = ${quote.rate.toStringAsFixed(4)} ${quote.target}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '1 ${quote.target} = ${inverseRate.toStringAsFixed(4)} ${quote.base}',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.dashboardRateUpdated(
                  DateFormat('MMM dd').format(quote.date),
                ),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onOpenFullTool,
              child: Text(l10n.dashboardOpenFullTool),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          AppLottieView(
            assetPath: 'assets/animations/loading.json',
            width: 44,
            height: 44,
            repeat: false,
            animate: true,
            semanticLabel: 'Loading dashboard',
            fallbackIcon: Icons.sync,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Syncing dashboard data...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(child: Text(l10n.dashboardFailedToLoadInsights)),
    );
  }
}
