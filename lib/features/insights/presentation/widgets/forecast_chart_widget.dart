import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smartbudget/intelligence/models/forecast_data_point.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class ForecastChartWidget extends StatelessWidget {
  final List<ForecastDataPoint> dataPoints;

  const ForecastChartWidget({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dataPoints.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(child: Text(l10n.insightsNoForecastData)),
      );
    }

    final actualSpots = dataPoints
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble() + 1,
              entry.value.actual.amount,
            ))
        .toList();
    final predictedSpots = dataPoints
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble() + 1,
              entry.value.predicted.amount,
            ))
        .toList();

    final maxY = [
      actualSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b),
      predictedSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b),
    ].reduce((a, b) => a > b ? a : b);
    final safeMaxY = math.max(maxY * 1.1, 1.0);
    final safeHorizontalInterval = math.max(safeMaxY / 4, 0.25);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.insightsForecastChart,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: dataPoints.length.toDouble(),
                  minY: 0,
                  maxY: safeMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: safeHorizontalInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(0),
                              style: Theme.of(context).textTheme.bodySmall);
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (dataPoints.length / 4).clamp(1, 7),
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineTouchData: const LineTouchData(enabled: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: actualSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: predictedSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.secondary,
                      barWidth: 3,
                      dashArray: const [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(
                    color: Theme.of(context).colorScheme.primary,
                    label: l10n.insightsActual),
                const SizedBox(width: 16),
                _LegendDot(
                    color: Theme.of(context).colorScheme.secondary,
                    label: l10n.insightsPredicted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
