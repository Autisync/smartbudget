import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smartbudget/components/charts/app_finance_charts.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/intelligence/models/forecast_data_point.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class ForecastChartWidget extends StatelessWidget {
  final List<ForecastDataPoint> dataPoints;

  const ForecastChartWidget({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (dataPoints.isEmpty) {
      return AppEmptyState(
        icon: Icons.show_chart_rounded,
        title: l10n.insightsForecastChart,
        message: l10n.insightsNoForecastData,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.insightsForecastChart,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: UiTokens.space4),
            Text(
              '${l10n.insightsActual} / ${l10n.insightsPredicted}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            ChartEntrance(
              builder: (context, _) => SizedBox(
              height: 260,
              child: LineChart(
                duration: UiTokens.motionSlow,
                curve: UiTokens.motionCurve,
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
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.65,
                          ),
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
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      getTooltipItems: (spots) => spots.map((spot) {
                        final isActual = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isActual ? l10n.insightsActual : l10n.insightsPredicted}\n${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: isActual
                                ? colorScheme.primary
                                : colorScheme.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: actualSpots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.18),
                            colorScheme.primary.withValues(alpha: 0.01),
                          ],
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: predictedSpots,
                      isCurved: true,
                      color: colorScheme.secondary,
                      barWidth: 3,
                      dashArray: const [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
              ), // ChartEntrance SizedBox
            ), // ChartEntrance
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(
                  color: colorScheme.primary,
                  label: l10n.insightsActual,
                ),
                const SizedBox(width: 16),
                _LegendDot(
                  color: colorScheme.secondary,
                  label: l10n.insightsPredicted,
                ),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}




