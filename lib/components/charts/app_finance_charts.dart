import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smartbudget/components/app_ui.dart';

class AppLineSparkChart extends StatelessWidget {
  const AppLineSparkChart({
    super.key,
    required this.values,
    this.color,
    this.height = 72,
    this.loading = false,
  });

  final List<double> values;
  final Color? color;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final series = values.isEmpty ? const [0.0] : values;
    final lineColor = color ?? Theme.of(context).colorScheme.primary;
    final min = series.reduce((a, b) => a < b ? a : b);
    final max = series.reduce((a, b) => a > b ? a : b);
    final spread = (max - min).abs();
    final safePadding = spread == 0 ? (max.abs() * 0.1 + 1) : spread * 0.15;

    return AppSkeletonLoader(
      enabled: loading,
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (series.length - 1).toDouble(),
            minY: min - safePadding,
            maxY: max + safePadding,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: lineColor.withValues(alpha: 0.12),
                ),
                spots: List.generate(
                  series.length,
                  (index) => FlSpot(index.toDouble(), series[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDonutChart extends StatelessWidget {
  const AppDonutChart({
    super.key,
    required this.segments,
    this.radius = 38,
    this.centerSpaceRadius = 22,
    this.loading = false,
  });

  final List<AppDonutSegment> segments;
  final double radius;
  final double centerSpaceRadius;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonLoader(
      enabled: loading,
      child: SizedBox(
        width: radius * 2.6,
        height: radius * 2.6,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: centerSpaceRadius,
            startDegreeOffset: -90,
            sections: segments
                .map(
                  (segment) => PieChartSectionData(
                    value: segment.value,
                    color: segment.color,
                    title: '',
                    radius: radius,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class AppDonutSegment {
  const AppDonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}
