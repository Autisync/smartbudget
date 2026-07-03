import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smartbudget/components/app_ui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChartEntrance — shared entrance wrapper for every chart widget.
//
// Fades + scales in on first mount and exposes an [Animation<double>] progress
// (0 → 1) so callers can scale their data for a "rise from zero" effect.
// ─────────────────────────────────────────────────────────────────────────────

class ChartEntrance extends StatefulWidget {
  const ChartEntrance({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
  });

  final Widget Function(BuildContext context, Animation<double> progress)
      builder;
  final Duration duration;
  final Curve curve;

  @override
  State<ChartEntrance> createState() => _ChartEntranceState();
}

class _ChartEntranceState extends State<ChartEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _curved = CurvedAnimation(parent: _ctrl, curve: widget.curve);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) => Opacity(
        opacity: _curved.value,
        child: Transform.scale(
          scale: 0.93 + 0.07 * _curved.value,
          child: widget.builder(context, _curved),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppLineSparkChart — animated sparkline with entrance effect
// ─────────────────────────────────────────────────────────────────────────────

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
    final minVal = series.reduce((a, b) => a < b ? a : b);
    final maxVal = series.reduce((a, b) => a > b ? a : b);
    final spread = (maxVal - minVal).abs();
    final safePad = spread == 0 ? (maxVal.abs() * 0.1 + 1) : spread * 0.15;

    return AppSkeletonLoader(
      enabled: loading,
      child: ChartEntrance(
        builder: (context, progress) => SizedBox(
          height: height,
          child: LineChart(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            LineChartData(
              minX: 0,
              maxX: (series.length - 1).toDouble(),
              minY: minVal - safePad,
              maxY: maxVal + safePad,
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
                    color: lineColor.withOpacity( 0.12),
                  ),
                  // Scale y-values from baseline upward on entrance
                  spots: List.generate(
                    series.length,
                    (i) => FlSpot(
                      i.toDouble(),
                      minVal + (series[i] - minVal) * progress.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppDonutChart — animated donut chart with entrance effect
// ─────────────────────────────────────────────────────────────────────────────

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
      child: ChartEntrance(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        builder: (context, progress) => SizedBox(
          width: radius * 2.6,
          height: radius * 2.6,
          child: PieChart(
            swapAnimationDuration: const Duration(milliseconds: 500),
            swapAnimationCurve: Curves.easeInOutCubic,
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: centerSpaceRadius,
              startDegreeOffset: -90,
              sections: segments
                  .map(
                    (segment) => PieChartSectionData(
                      // Expand from 0 → actual value on entrance
                      value: segment.value * progress.value,
                      color: segment.color,
                      title: '',
                      radius: radius,
                    ),
                  )
                  .toList(),
            ),
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
