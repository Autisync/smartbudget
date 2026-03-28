import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/dashboard/presentation/providers/financial_health_provider.dart';

class FinancialHealthScreen extends ConsumerStatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  ConsumerState<FinancialHealthScreen> createState() =>
      _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends ConsumerState<FinancialHealthScreen> {
  int _selectedWeeks = 8;

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(financialHealthProvider);
    final trendAsync =
        ref.watch(financialHealthHistoryProvider(weeks: _selectedWeeks));

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Health')),
      body: healthAsync.when(
        data: (health) {
          final rounded = health.totalScore.round();
          final toneColor = rounded >= 80
              ? Colors.green
              : rounded >= 60
                  ? Colors.orange
                  : Colors.red;
          final statusText = rounded >= 80
              ? 'Strong'
              : rounded >= 60
                  ? 'Needs attention'
                  : 'At risk';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health portfolio',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _HealthSummaryMetric(
                            label: 'Score',
                            value: '$rounded/100',
                            valueColor: toneColor,
                          ),
                        ),
                        Expanded(
                          child: _HealthSummaryMetric(
                            label: 'Budgets',
                            value: '${health.activeBudgets}',
                          ),
                        ),
                        Expanded(
                          child: _HealthSummaryMetric(
                            label: 'Goals',
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
                        const _HealthPill(
                            label: 'Update weekly', color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$rounded / 100',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                      backgroundColor:
                          Theme.of(context).dividerColor.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Active budgets: ${health.activeBudgets} • Active goals: ${health.activeGoals}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FactorTile(
                label: 'Budget discipline',
                score: health.budgetDisciplineScore,
                description:
                    'Measures pressure from near-limit and exceeded budgets.',
              ),
              _FactorTile(
                label: 'Savings momentum',
                score: health.savingsMomentumScore,
                description: 'Measures goal progress and schedule adherence.',
              ),
              _FactorTile(
                label: 'Budget utilization',
                score: health.budgetUtilizationScore,
                description:
                    'Measures category-level spending efficiency across budget periods.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Trend window',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: _selectedWeeks,
                    items: const [
                      DropdownMenuItem(value: 4, child: Text('4 weeks')),
                      DropdownMenuItem(value: 8, child: Text('8 weeks')),
                      DropdownMenuItem(value: 12, child: Text('12 weeks')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedWeeks = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              trendAsync.when(
                data: (trend) => _HealthTrendCard(trend: trend),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Text(
                'Recommendations',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...health.recommendations.map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(item),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  Theme.of(context).dividerColor.withValues(alpha: 0.35),
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
        color: color.withValues(alpha: 0.16),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly health trajectory',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
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
            ),
            const SizedBox(height: 10),
            Text(
              'Overall change: ${trend.overallDelta >= 0 ? '+' : ''}${trend.overallDelta.toStringAsFixed(1)} points over ${points.length} weeks.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (trend.biggestGain != null)
              Text(
                'Biggest gain: ${trend.biggestGain!.deltaFromPrevious >= 0 ? '+' : ''}${trend.biggestGain!.deltaFromPrevious.toStringAsFixed(1)} on ${trend.biggestGain!.weekStart.month}/${trend.biggestGain!.weekStart.day}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (trend.biggestDrop != null)
              Text(
                'Biggest drop: ${trend.biggestDrop!.deltaFromPrevious.toStringAsFixed(1)} on ${trend.biggestDrop!.weekStart.month}/${trend.biggestDrop!.weekStart.day}.',
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
