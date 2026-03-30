import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/exchange_rate_service.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionType;
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

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

          for (final alert in alerts) {
            final key =
                '${alert.budgetId}-${alert.overLimit}-${alert.nearLimit}';
            if (_notifiedBudgetAlertIds.contains(key)) continue;

            final canSend =
                await preferencesService.shouldDispatch('budgetAlerts');
            if (!canSend) break;

            _notifiedBudgetAlertIds.add(key);
            final title = alert.overLimit ? 'Budget Exceeded!' : 'Budget Alert';
            final body =
                '${alert.category} spending is at ${(alert.progress * 100).toStringAsFixed(1)}% of limit';
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
          final canSend =
              await preferencesService.shouldDispatch('healthInsights');
          if (!canSend) return;

          _healthInsightSent = true;
          await ref.read(notificationServiceProvider).showHealthInsight(
                title: 'Financial health needs attention',
                body:
                    'Your score is ${health.totalScore.toStringAsFixed(0)}. Review the Health details for actions.',
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
              backgroundColor: colorScheme.surface.withValues(
                alpha: _isAppBarScrolled ? 0.88 : 0,
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
                                    colorScheme.surface.withValues(alpha: 0.08),
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
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: _isAppBarScrolled ? 0.9 : 0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SmartBudget',
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
                      .withValues(alpha: _isAppBarScrolled ? 0.9 : 0),
                  onPressed: () => context.push('/notifications'),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colorScheme.surfaceContainerHighest.withValues(
                      alpha: _isAppBarScrolled ? 0.9 : 0,
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
                padding: UiTokens.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _BalanceCard(
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
                            label: 'Transactions',
                            value: allTxAsync.maybeWhen(
                              data: (transactions) => '${transactions.length}',
                              orElse: () => '0',
                            ),
                          ),
                          _DashboardMetricChip(
                            icon: Icons.warning_amber_rounded,
                            label: 'Budget alerts',
                            value: alertsAsync.maybeWhen(
                              data: (alerts) => '${alerts.length}',
                              orElse: () => '0',
                            ),
                          ),
                          _DashboardMetricChip(
                            icon: Icons.monitor_heart_rounded,
                            label: 'Health score',
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
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recurring Balance Sheet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'See if recurring income covers recurring bills and subscriptions.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              maximumSize: const Size(120, 40),
                              fixedSize: const Size(86, 40),
                            ),
                            onPressed: () => context.push('/balance-sheet'),
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UiTokens.sectionGapLg),

                    healthAsync.when(
                      data: (health) => _FinancialHealthCard(
                        score: health.totalScore,
                        budgetComponent: health.budgetDisciplineScore,
                        savingsComponent: health.savingsMomentumScore,
                        onViewDetails: () => context.push('/health'),
                      ),
                      loading: () => const _LoadingCard(),
                      error: (_, __) => const _ErrorCard(),
                    ),
                    const SizedBox(height: UiTokens.sectionGapLg),

                    // Spending Insights
                    const _DashboardSectionHeader(
                      icon: Icons.calendar_month_rounded,
                      title: 'This Month',
                    ),
                    const SizedBox(height: UiTokens.sectionGapMd),

                    spendingAsync.when(
                      data: (profile) => _SpendingOverview(
                        profile: profile,
                        currencyFormat: currencyFormat,
                      ),
                      loading: () => const _LoadingCard(),
                      error: (err, st) => const _ErrorCard(),
                    ),

                    const SizedBox(height: UiTokens.sectionGapLg),

                    // Budget Alerts
                    const _DashboardSectionHeader(
                      icon: Icons.warning_amber_rounded,
                      title: 'Budget Alerts',
                    ),
                    const SizedBox(height: UiTokens.sectionGapSm),
                    alertsAsync.when(
                      data: (alerts) {
                        if (alerts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No active budget alerts'),
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
                                        '${alert.category} ${alert.overLimit ? 'exceeded' : 'nearing'} ${alert.threshold}% (${(alert.progress * 100).toStringAsFixed(1)}%)',
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
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Checking alerts...'),
                      ),
                      error: (err, st) => Text('Alert error: $err'),
                    ),

                    const SizedBox(height: UiTokens.sectionGapLg),

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _DashboardSectionHeader(
                          icon: Icons.history_rounded,
                          title: 'Recent Transactions',
                        ),
                        TextButton(
                          onPressed: () => context.push('/transactions'),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: UiTokens.chipSpacing),
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
                                .withValues(alpha: 0.08),
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
                                  color: amountColor.withValues(alpha: 0.14),
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
                                      tx.note ?? 'No note',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                                style: TextStyle(
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
              error: (err, st) => const SliverToBoxAdapter(
                child: Text('Error loading transactions'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: _DashboardLiveRateCard(
                  baseCurrency: liveRateBaseCurrency,
                  targetCurrency: appCurrency,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        icon: const Icon(Icons.add),
        label: const Text(''),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final NumberFormat currencyFormat;
  final String currencyCode;
  final double income;
  final double expenses;

  const _BalanceCard({
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(99, 102, 241, 0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color.fromRGBO(255, 255, 255, 0.8),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildQuickStat(
                icon: Icons.arrow_downward,
                label: 'Income',
                amount: income,
                color: Colors.greenAccent,
                currencyCode: currencyCode,
              ),
              const SizedBox(width: 24),
              _buildQuickStat(
                icon: Icons.arrow_upward,
                label: 'Expenses',
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
                style: const TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                CurrencyUtils.getCompactFormat(currencyCode).format(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendingOverview extends StatelessWidget {
  final dynamic profile;
  final NumberFormat currencyFormat;

  const _SpendingOverview({
    required this.profile,
    required this.currencyFormat,
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
            color: colorScheme.shadow.withValues(alpha: 0.08),
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
                'Burn Rate',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.72),
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
          Text(
            currencyFormat.format(profile.monthlyBurnRate),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      '${profile.anomalies.length} unusual transactions detected',
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
        return '↑ Rising';
      case 'TrendDirection.decreasing':
        return '↓ Falling';
      default:
        return '→ Stable';
    }
  }
}

class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({
    required this.score,
    required this.budgetComponent,
    required this.savingsComponent,
    required this.onViewDetails,
  });

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
        ? 'Strong'
        : roundedScore >= 60
            ? 'Needs attention'
            : 'At risk';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
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
                'Financial Health',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Chip(
                label: Text('$roundedScore/100 • $label'),
                backgroundColor: toneColor.withValues(alpha: 0.14),
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
                Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Budget discipline: ${budgetComponent.toStringAsFixed(0)} • Savings momentum: ${savingsComponent.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewDetails,
              child: const Text('View details'),
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
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Text('Failed to load insights')),
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
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(UiTokens.radiusMd),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
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
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardLiveRateCard extends ConsumerWidget {
  const _DashboardLiveRateCard({
    required this.baseCurrency,
    required this.targetCurrency,
  });

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
                  'Live Rate Check',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh rate',
                onPressed: () =>
                    ref.invalidate(_dashboardLiveRateQuoteProvider(pairKey)),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Quick quote for your selected app currency.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          quoteAsync.when(
            data: (quote) => _DashboardLiveRateQuote(
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
                    'Rate unavailable right now. Try again or open the full tool.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.push('/exchange-rates'),
                  child: const Text('Open'),
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
    required this.quote,
    required this.onOpenFullTool,
  });

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
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Updated ${DateFormat('MMM dd').format(quote.date)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onOpenFullTool,
              child: const Text('Open full tool'),
            ),
          ],
        ),
      ],
    );
  }
}
