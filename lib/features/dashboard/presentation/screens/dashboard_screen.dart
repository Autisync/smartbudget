import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/exchange_rate_service.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionType;
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

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
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
    final colorScheme = Theme.of(context).colorScheme;
    final allTxAsync = ref.watch(transactionListProvider());
    final alertsAsync = ref.watch(budgetAlertsProvider);
    final healthAsync = ref.watch(financialHealthProvider);
    ref.watch(recurringTransactionsProvider);
    final spendingAsync = ref.watch(spendingProfileProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
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
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: colorScheme.surface.withOpacity(_isAppBarScrolled ? 0.88 : 0,
              ),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _isAppBarScrolled
                        ? ClipRect(
                            key: const ValueKey('app-bar-blur-on'),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                color:
                                    colorScheme.surface.withOpacity(0.08),
                              ),
                            ),
                          )
                        : const SizedBox(key: ValueKey('app-bar-blur-off')),
                  ),
                  FlexibleSpaceBar(
                    title: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(_isAppBarScrolled ? 0.9 : 0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: BrandedTitle(
                        label: l10n.appTitle,
                        logoSize: 22,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                NotificationBellButton(
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withOpacity(_isAppBarScrolled ? 0.9 : 0),
                  onPressed: () => context.push('/notifications'),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colorScheme.surfaceContainerHighest.withOpacity(_isAppBarScrolled ? 0.9 : 0,
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: UiTokens.adaptiveScreenPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _BalanceCard(
                      l10n: l10n,
                      currencyFormat: currencyFormat,
                      currencyCode: appCurrency,
                      income: allTxAsync.maybeWhen(
                        data: (transactions) => transactions
                            .where((tx) => tx.type == TransactionType.income)
                            .fold(0.0, (sum, t) => sum + t.amount),
                        orElse: () => 0.0,
                      ),
                      expenses: allTxAsync.maybeWhen(
                        data: (transactions) => transactions
                            .where((tx) => tx.type == TransactionType.expense)
                            .fold(0.0, (sum, t) => sum + t.amount),
                        orElse: () => 0.0,
                      ),
                    ),
                    const SizedBox(height: UiTokens.sectionGapMd),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: AppSurfaces.elevated(
                        context,
                        radius: 18,
                        color: colorScheme.surfaceContainerHigh,
                        opacity: 0.06,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DashboardMetricChip(
                            icon: Icons.receipt_long_rounded,
                            label: l10n.dashboardMetricsTransactions,
                            value: allTxAsync.maybeWhen(
                              data: (transactions) => '${transactions.length}',
                              orElse: () => '0',
                            ),
                          ),
                          _DashboardMetricChip(
                            icon: Icons.warning_amber_rounded,
                            label: l10n.dashboardMetricsBudgetAlerts,
                            value: alertsAsync.maybeWhen(
                              data: (alerts) => '${alerts.length}',
                              orElse: () => '0',
                            ),
                          ),
                          _DashboardMetricChip(
                            icon: Icons.monitor_heart_rounded,
                            label: l10n.dashboardMetricsHealthScore,
                            value: healthAsync.maybeWhen(
                              data: (health) =>
                                  health.totalScore.toStringAsFixed(0),
                              orElse: () => '--',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UiTokens.sectionGapMd),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: AppSurfaces.elevated(
                        context,
                        radius: 18,
                        color: colorScheme.surfaceContainerHigh,
                        opacity: 0.06,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 520;

                          final leading = Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: colorScheme.primary,
                            ),
                          );

                          final content = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.dashboardBalanceSheetTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.dashboardBalanceSheetSubtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          );

                          final cta = FilledButton.tonalIcon(
                            onPressed: () => context.push('/balance-sheet'),
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 18),
                            label: Text(l10n.commonOpen),
                          );

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    leading,
                                    const SizedBox(width: 14),
                                    Expanded(child: content),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: cta,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              leading,
                              const SizedBox(width: 14),
                              Expanded(child: content),
                              const SizedBox(width: 12),
                              cta,
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: UiTokens.sectionGapLg),

                    healthAsync.when(
                      data: (health) => _FinancialHealthCard(
                        l10n: l10n,
                        score: health.totalScore,
                        budgetComponent: health.budgetDisciplineScore,
                        savingsComponent: health.savingsMomentumScore,
                        onViewDetails: () => context.push('/health'),
                      ),
                      loading: () => const _LoadingCard(),
                      error: (_, __) => _ErrorCard(l10n: l10n),
                    ),
                    const SizedBox(height: UiTokens.sectionGapLg),

                    // Spending Insights
                    _DashboardSectionHeader(
                      icon: Icons.calendar_month_rounded,
                      title: l10n.dashboardSectionThisMonth,
                    ),
                    const SizedBox(height: UiTokens.sectionGapMd),

                    spendingAsync.when(
                      data: (profile) => _SpendingOverview(
                        l10n: l10n,
                        profile: profile,
                        currencyFormat: currencyFormat,
                        currencyCode: appCurrency,
                      ),
                      loading: () => const _LoadingCard(),
                      error: (err, st) => _ErrorCard(l10n: l10n),
                    ),

                    const SizedBox(height: UiTokens.sectionGapLg),

                    // Budget Alerts
                    _DashboardSectionHeader(
                      icon: Icons.warning_amber_rounded,
                      title: l10n.dashboardSectionBudgetAlerts,
                    ),
                    const SizedBox(height: UiTokens.sectionGapSm),
                    alertsAsync.when(
                      data: (alerts) {
                        if (alerts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(l10n.dashboardNoActiveBudgetAlerts),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: alerts.map((alert) {
                            final color =
                                alert.overLimit ? Colors.red : Colors.orange;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Container(
                                decoration:
                                    AppSurfaces.elevated(context, radius: 14),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_rounded,
                                      color: color,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        alert.overLimit
                                            ? l10n.dashboardAlertExceeded(
                                                alert.category,
                                                '${alert.threshold}',
                                                (alert.progress * 100)
                                                    .toStringAsFixed(1),
                                              )
                                            : l10n.dashboardAlertNearing(
                                                alert.category,
                                                '${alert.threshold}',
                                                (alert.progress * 100)
                                                    .toStringAsFixed(1),
                                              ),
                                        style: TextStyle(color: color),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l10n.dashboardCheckingAlerts),
                      ),
                      error: (err, st) =>
                          Text(l10n.dashboardAlertError(err.toString())),
                    ),

                    const SizedBox(height: UiTokens.sectionGapLg),

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _DashboardSectionHeader(
                            icon: Icons.history_rounded,
                            title: l10n.dashboardRecentTransactions,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/transactions'),
                          child: Text(l10n.commonSeeAll),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            recentAsync.when(
              data: (transactions) => SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tx = transactions[index];
                  final isExpense = tx.type == TransactionType.expense;
                  final amountColor = isExpense
                      ? Theme.of(context).colorScheme.error
                      : const Color(0xFF059669);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              context.push('/transactions/edit/${tx.id}'),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: amountColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  isExpense
                                      ? Icons.arrow_outward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: amountColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx.note ?? l10n.transactionsNoNote,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: amountColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: transactions.take(5).length),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, st) => SliverToBoxAdapter(
                child: Text(l10n.dashboardErrorLoadingTransactions),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AppLocalizations l10n;
  final NumberFormat currencyFormat;
  final String currencyCode;
  final double income;
  final double expenses;

  const _BalanceCard({
    required this.l10n,
    required this.currencyFormat,
    required this.currencyCode,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final balance = income - expenses;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppSurfaces.gradientCard(
        context,
        colors: const [
          Color(0xFF24184E),
          Color(0xFF5B55E7),
          Color(0xFF9B5CFF),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color.fromRGBO(255, 255, 255, 0.8),
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currencyCode,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FinanceAmount(
            value: currencyFormat.format(balance),
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildQuickStat(
                context: context,
                icon: Icons.arrow_downward,
                label: l10n.income,
                amount: income,
                color: Colors.greenAccent,
                currencyCode: currencyCode,
              ),
              const SizedBox(width: 24),
              _buildQuickStat(
                context: context,
                icon: Icons.arrow_upward,
                label: l10n.expense,
                amount: expenses,
                color: Colors.redAccent,
                currencyCode: currencyCode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required BuildContext context,
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required String currencyCode,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color.fromRGBO(255, 255, 255, 0.8),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                CurrencyUtils.getCompactFormat(currencyCode).format(amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendingOverview extends StatelessWidget {
  final AppLocalizations l10n;
  final dynamic profile;
  final NumberFormat currencyFormat;
  final String currencyCode;

  const _SpendingOverview({
    required this.l10n,
    required this.profile,
    required this.currencyFormat,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardBurnRate,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.72),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTrendColor(profile.trend)
                      .withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getTrendText(profile.trend),
                  style: TextStyle(
                    color: _getTrendColor(profile.trend),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  currencyFormat.format(profile.monthlyBurnRate),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currencyCode,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile.anomalies.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 165, 0, 0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(255, 165, 0, 0.12),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.dashboardUnusualTransactionsDetected(
                        profile.anomalies.length,
                      ),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
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

  Color _getTrendColor(dynamic trend) {
    switch (trend.toString()) {
      case 'TrendDirection.increasing':
        return Colors.redAccent;
      case 'TrendDirection.decreasing':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  String _getTrendText(dynamic trend) {
    switch (trend.toString()) {
      case 'TrendDirection.increasing':
        return l10n.dashboardTrendRising;
      case 'TrendDirection.decreasing':
        return l10n.dashboardTrendFalling;
      default:
        return l10n.dashboardTrendStable;
    }
  }
}

class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({
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
    final colorScheme = Theme.of(context).colorScheme;
    final roundedScore = score.round();
    final toneColor = roundedScore >= 80
        ? Colors.green
        : roundedScore >= 60
            ? Colors.orange
            : Colors.red;
    final label = roundedScore >= 80
        ? l10n.financialHealthStatusStrong
        : roundedScore >= 60
            ? l10n.financialHealthStatusNeedsAttention
            : l10n.financialHealthStatusAtRisk;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.financialHealthTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Chip(
                label: Text('$roundedScore/100 • $label'),
                backgroundColor: toneColor.withOpacity(0.14),
                labelStyle: TextStyle(color: toneColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            color: toneColor,
            backgroundColor:
                Theme.of(context).dividerColor.withOpacity(0.4),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.dashboardHealthBreakdown(
              budgetComponent.toStringAsFixed(0),
              savingsComponent.toStringAsFixed(0),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewDetails,
              child: Text(l10n.commonViewDetails),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppSkeleton(height: 180);
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(l10n.dashboardFailedToLoadInsights)),
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({
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

class _DashboardMetricChip extends StatelessWidget {
  const _DashboardMetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(UiTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: AppSurfaces.elevated(
        context,
        radius: 20,
        color: colorScheme.surfaceContainerHigh,
        opacity: 0.06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.dashboardLiveRateCheck,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: l10n.dashboardRefreshRate,
                onPressed: () =>
                    ref.invalidate(_dashboardLiveRateQuoteProvider(pairKey)),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.dashboardQuickQuoteSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              child: Center(child: CircularProgressIndicator()),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '1 ${quote.target} = ${inverseRate.toStringAsFixed(4)} ${quote.base}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.dashboardRateUpdated(
                  DateFormat('MMM dd').format(quote.date),
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
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




