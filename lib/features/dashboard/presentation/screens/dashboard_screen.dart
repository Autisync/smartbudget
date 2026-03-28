import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/data/models/tables.dart' show TransactionType;

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

  @override
  void initState() {
    super.initState();
    _alertSubscription = ref.listenManual<AsyncValue<List<BudgetAlert>>>(
      budgetAlertsProvider,
      (previous, next) {
        next.whenData((alerts) async {
          final notificationService = ref.read(notificationServiceProvider);
          final preferencesService = ref.read(notificationPreferencesServiceProvider);

          for (final alert in alerts) {
            final key = '${alert.budgetId}-${alert.overLimit}-${alert.nearLimit}';
            if (_notifiedBudgetAlertIds.contains(key)) continue;

            final canSend = await preferencesService.shouldDispatch('budgetAlerts');
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

    _healthSubscription =
        ref.listenManual<AsyncValue<FinancialHealthSnapshot>>(
      financialHealthProvider,
      (previous, next) {
        next.whenData((health) async {
          if (_healthInsightSent) return;
          if (health.totalScore >= 60) return;

          final preferencesService =
              ref.read(notificationPreferencesServiceProvider);
          final canSend = await preferencesService.shouldDispatch('healthInsights');
          if (!canSend) return;

          _healthInsightSent = true;
          await ref.read(notificationServiceProvider).showSavingsNudge(
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final allTxAsync = ref.watch(transactionListProvider());
    final alertsAsync = ref.watch(budgetAlertsProvider);
    final healthAsync = ref.watch(financialHealthProvider);
    ref.watch(recurringTransactionsProvider);
    final spendingAsync = ref.watch(spendingProfileProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'SmartBudget',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  _BalanceCard(
                    currencyFormat: currencyFormat,
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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 24),

                  // Spending Insights
                  Text(
                    'This Month',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  spendingAsync.when(
                    data: (profile) => _SpendingOverview(
                      profile: profile,
                      currencyFormat: currencyFormat,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (err, st) => const _ErrorCard(),
                  ),

                  const SizedBox(height: 24),

                  // Budget Alerts
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
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: color, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${alert.category} ${alert.overLimit ? 'exceeded' : 'nearing'} ${alert.threshold}% (${(alert.progress * 100).toStringAsFixed(1)}%)',
                                    style: TextStyle(color: color),
                                  ),
                                ),
                              ],
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

                  const SizedBox(height: 24),

                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/transactions'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          recentAsync.when(
            data: (transactions) => SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tx = transactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tx.type == TransactionType.expense
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    child: Icon(
                      tx.type == TransactionType.expense
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(tx.category),
                  subtitle: Text(
                    tx.note ?? 'No note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Text(
                    '${tx.type == TransactionType.expense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                    style: TextStyle(
                      color: tx.type == TransactionType.expense
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final NumberFormat currencyFormat;
  final double income;
  final double expenses;

  const _BalanceCard({
    required this.currencyFormat,
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
              ),
              const SizedBox(width: 24),
              _buildQuickStat(
                icon: Icons.arrow_upward,
                label: 'Expenses',
                amount: expenses,
                color: Colors.redAccent,
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
                NumberFormat.compactCurrency(symbol: '\$').format(amount),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                border:
                    Border.all(color: const Color.fromRGBO(255, 165, 0, 0.3)),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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
            backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.4),
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
