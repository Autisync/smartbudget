import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartbudget/components/charts/app_finance_charts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/components/forms/modern_select.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/widgets/app_shimmer.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class FinancialHealthScreen extends ConsumerStatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  ConsumerState<FinancialHealthScreen> createState() =>
      _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends ConsumerState<FinancialHealthScreen> {
  int _selectedWeeks = 8;
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
    final healthAsync = ref.watch(financialHealthProvider);
    final trendAsync =
        ref.watch(financialHealthHistoryProvider(weeks: _selectedWeeks));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.financialHealthTitle,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withOpacity( _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'health-appbar-blur-on',
          offKey: 'health-appbar-blur-off',
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
        child: healthAsync.when(
          data: (health) {
            final rounded = health.totalScore.round();
            final toneColor = rounded >= 80
                ? Colors.green
                : rounded >= 60
                    ? Colors.orange
                    : Colors.red;
            final statusText = rounded >= 80
                ? l10n.financialHealthStatusStrong
                : rounded >= 60
                    ? l10n.financialHealthStatusNeedsAttention
                    : l10n.financialHealthStatusAtRisk;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppSurfaces.elevated(context, radius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.financialHealthPortfolio,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _HealthSummaryMetric(
                              label: l10n.financialHealthScore,
                              value: '$rounded/100',
                              valueColor: toneColor,
                            ),
                          ),
                          Expanded(
                            child: _HealthSummaryMetric(
                              label: l10n.navBudgets,
                              value: '${health.activeBudgets}',
                            ),
                          ),
                          Expanded(
                            child: _HealthSummaryMetric(
                              label: l10n.financialHealthGoals,
                              value: '${health.activeGoals}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _HealthPill(label: statusText, color: toneColor),
                          _HealthPill(
                            label: l10n.financialHealthUpdateWeekly,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppSurfaces.elevated(context, radius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$rounded / 100',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: toneColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: health.totalScore / 100,
                        minHeight: 8,
                        color: toneColor,
                        backgroundColor: Theme.of(context)
                            .dividerColor
                            .withOpacity( 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.financialHealthActiveCounts(
                          health.activeBudgets,
                          health.activeGoals,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FactorTile(
                  label: l10n.financialHealthBudgetDiscipline,
                  score: health.budgetDisciplineScore,
                  description: l10n.financialHealthBudgetDisciplineDescription,
                ),
                const SizedBox(height: 12),
                _FactorTile(
                  label: l10n.financialHealthSavingsMomentum,
                  score: health.savingsMomentumScore,
                  description: l10n.financialHealthSavingsMomentumDescription,
                ),
                const SizedBox(height: 12),
                _FactorTile(
                  label: l10n.financialHealthBudgetUtilization,
                  score: health.budgetUtilizationScore,
                  description: l10n.financialHealthBudgetUtilizationDescription,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      l10n.financialHealthTrendWindow,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 142,
                      child: ModernSelect<int>(
                        value: _selectedWeeks,
                        label: l10n.financialHealthTrendWindow,
                        items: [
                          DropdownMenuItem<int>(
                            value: 4,
                            child: Text(l10n.financialHealthWeeks(4)),
                          ),
                          DropdownMenuItem<int>(
                            value: 8,
                            child: Text(l10n.financialHealthWeeks(8)),
                          ),
                          DropdownMenuItem<int>(
                            value: 12,
                            child: Text(l10n.financialHealthWeeks(12)),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedWeeks = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                trendAsync.when(
                  data: (trend) => _HealthTrendCard(trend: trend),
                  loading: () => const SizedBox(
                    height: 80,
                    child: AppShimmerSkeleton(
                        variant: AppShimmerVariant.cards, itemCount: 1),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.financialHealthRecommendations,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...health.recommendations.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: AppSurfaces.elevated(context, radius: 18),
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.lightbulb_outline),
                          title: Text(item),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const AppShimmerSkeleton(),
          error: (err, st) => Center(
            child: Text(l10n.transactionsError(err.toString())),
          ),
        ),
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({
    required this.label,
    required this.score,
    required this.description,
  });

  final String label;
  final double score;
  final String description;

  @override
  Widget build(BuildContext context) {
    final rounded = score.round();
    final color = rounded >= 80
        ? Colors.green
        : rounded >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      decoration: AppSurfaces.elevated(context, radius: 20),
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '$rounded',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: score / 100,
              minHeight: 7,
              color: color,
              backgroundColor:
                  Theme.of(context).dividerColor.withOpacity( 0.35),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthSummaryMetric extends StatelessWidget {
  const _HealthSummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HealthTrendCard extends StatelessWidget {
  const _HealthTrendCard({required this.trend});

  final FinancialHealthTrendSnapshot trend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = trend.points;
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final minY = points
            .map((p) => p.score)
            .fold<double>(100, (a, b) => a < b ? a : b)
            .floorToDouble() -
        5;
    final maxY = points
            .map((p) => p.score)
            .fold<double>(0, (a, b) => a > b ? a : b)
            .ceilToDouble() +
        5;

    return Container(
      decoration: AppSurfaces.elevated(context, radius: 20),
      padding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.financialHealthWeeklyTrajectory,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ChartEntrance(
              builder: (ctx, _) => SizedBox(
              height: 180,
              child: LineChart(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        ),
                        reservedSize: 28,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final label =
                              '${points[index].weekStart.month}/${points[index].weekStart.day}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label,
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].score),
                      ],
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
              ), // SizedBox
            ), // ChartEntrance
            const SizedBox(height: 10),
            Text(
              l10n.financialHealthOverallChange(
                '${trend.overallDelta >= 0 ? '+' : ''}${trend.overallDelta.toStringAsFixed(1)}',
                points.length,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (trend.biggestGain != null)
              Text(
                l10n.financialHealthBiggestGain(
                  '${trend.biggestGain!.deltaFromPrevious >= 0 ? '+' : ''}${trend.biggestGain!.deltaFromPrevious.toStringAsFixed(1)}',
                  '${trend.biggestGain!.weekStart.month}/${trend.biggestGain!.weekStart.day}',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (trend.biggestDrop != null)
              Text(
                l10n.financialHealthBiggestDrop(
                  trend.biggestDrop!.deltaFromPrevious.toStringAsFixed(1),
                  '${trend.biggestDrop!.weekStart.month}/${trend.biggestDrop!.weekStart.day}',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 6),
            Text(
              points.last.note,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
