import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/widgets/animated_count_text.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

enum InsightCardSemanticTone {
  general,
  positive,
  caution,
  warning,
}

enum MinimalInsightMetricEmphasis {
  standard,
  prominent,
  monetary,
}

class MinimalInsightMetric {
  const MinimalInsightMetric({
    required this.label,
    required this.value,
    this.tone,
    this.emphasis = MinimalInsightMetricEmphasis.standard,
    this.onTap,
    this.isSelected = false,
    this.animatedValue,
    this.valueFormatter,
  });

  final String label;
  final String value;
  final Color? tone;
  final MinimalInsightMetricEmphasis emphasis;
  final VoidCallback? onTap;
  final bool isSelected;

  /// When provided (together with [valueFormatter]), the metric's value counts
  /// smoothly up/down as it changes instead of snapping — used for figures that
  /// react live to edits (e.g. income/spent/net after adding a transaction).
  final double? animatedValue;
  final String Function(double value)? valueFormatter;
}

class MinimalStatusChip extends StatelessWidget {
  const MinimalStatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.isSelected = false,
  });

  final String label;
  final Color tone;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withOpacity(isSelected ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class MinimalInsightCard extends StatelessWidget {
  const MinimalInsightCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.insightText,
    required this.metrics,
    this.semanticTone = InsightCardSemanticTone.general,
    this.iconTint,
    this.statusChip,
    this.footer,
    this.chart,
  });

  final String title;
  final IconData icon;
  final Gradient gradient;
  final String insightText;
  final InsightCardSemanticTone semanticTone;
  final List<MinimalInsightMetric> metrics;
  final Color? iconTint;
  final Widget? statusChip;
  final Widget? footer;

  /// Optional compact visualization (e.g. a progress ring) rendered beside the
  /// decision callout to give an at-a-glance read of the headline ratio.
  final Widget? chart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconTint = iconTint ?? _defaultToneColor(scheme);
    final effectiveGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHigh.withOpacity(0.96),
              scheme.surfaceContainer.withOpacity(0.92),
            ],
          )
        : gradient;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.20)
        : scheme.outlineVariant.withOpacity(0.42);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: effectiveIconTint.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: effectiveIconTint, size: 15),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                ),
              ),
              if (statusChip != null) ...[
                const SizedBox(width: 8),
                Flexible(child: statusChip!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // ── Decision callout + compact chart side-by-side ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _DecisionCallout(
                  text: insightText,
                  tone: effectiveIconTint,
                  semanticTone: semanticTone,
                ),
              ),
              if (chart != null) ...[
                const SizedBox(width: 12),
                chart!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          _MinimalMetricGrid(metrics: metrics),
          if (footer != null) ...[
            const SizedBox(height: 6),
            footer!,
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Color _defaultToneColor(ColorScheme scheme) {
    switch (semanticTone) {
      case InsightCardSemanticTone.positive:
        return const Color(0xFF198754);
      case InsightCardSemanticTone.caution:
        return const Color(0xFFB36A10);
      case InsightCardSemanticTone.warning:
        return scheme.error;
      case InsightCardSemanticTone.general:
        return const Color(0xFF4F5FA7);
    }
  }
}

/// A tinted callout that frames the card's headline recommendation so the
/// "what should I do" message reads as an actionable insight rather than body
/// copy. The leading indicator + tint are driven by the card's semantic tone.
class _DecisionCallout extends StatelessWidget {
  const _DecisionCallout({
    required this.text,
    required this.tone,
    required this.semanticTone,
  });

  final String text;
  final Color tone;
  final InsightCardSemanticTone semanticTone;

  IconData get _glyph {
    switch (semanticTone) {
      case InsightCardSemanticTone.positive:
        return Icons.check_circle_rounded;
      case InsightCardSemanticTone.caution:
        return Icons.error_rounded;
      case InsightCardSemanticTone.warning:
        return Icons.warning_rounded;
      case InsightCardSemanticTone.general:
        return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      decoration: BoxDecoration(
        color: tone.withOpacity(isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tone.withOpacity(isDark ? 0.34 : 0.20),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_glyph, size: 16, color: tone),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurface
                        : tone.withOpacity(0.92),
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small, discrete progress-ring chart (fl_chart donut) used inside insight
/// cards to visualize the single most decision-relevant ratio at a glance.
class InsightRingChart extends StatelessWidget {
  const InsightRingChart({
    super.key,
    required this.fraction,
    required this.color,
    required this.centerLabel,
    this.caption,
    this.size = 58,
  });

  /// 0..1 portion of the ring filled with [color].
  final double fraction;
  final Color color;

  /// Text shown in the middle of the ring (e.g. "62%").
  final String centerLabel;

  /// Optional tiny caption under the center label (e.g. "spent").
  final String? caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
    final track = color.withOpacity(0.14);
    final ringWidth = size * 0.12;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: f <= 0 || f >= 1 ? 0 : 2,
              centerSpaceRadius: size / 2 - ringWidth,
              sections: [
                PieChartSectionData(
                  value: f <= 0 ? 0.0001 : f,
                  color: color,
                  radius: ringWidth,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (1 - f) <= 0 ? 0.0001 : (1 - f),
                  color: track,
                  radius: ringWidth,
                  showTitle: false,
                ),
              ],
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.3,
                      height: 1.0,
                    ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                        height: 1.1,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MinimalMetricGrid extends StatelessWidget {
  const _MinimalMetricGrid({required this.metrics});

  final List<MinimalInsightMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return Text(
        'No metrics available yet.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 260;
        final crossAxisCount = twoColumns ? 2 : 1;
        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
            mainAxisExtent: 50,
          ),
          itemBuilder: (context, index) {
            return _MinimalMetricItem(metric: metrics[index]);
          },
        );
      },
    );
  }
}

class _MinimalMetricItem extends StatelessWidget {
  const _MinimalMetricItem({required this.metric});

  final MinimalInsightMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = metric.tone ?? scheme.onSurface;
    final selectedBg = metric.tone != null
        ? tone.withOpacity(isDark ? 0.24 : 0.16)
        : scheme.primary.withOpacity(isDark ? 0.20 : 0.12);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: (metric.animatedValue != null &&
                      metric.valueFormatter != null)
                  ? AnimatedCountText(
                      value: metric.animatedValue!,
                      formatter: metric.valueFormatter!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _valueStyle(context, tone),
                    )
                  : Text(
                      metric.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _valueStyle(context, tone),
                    ),
            ),
          ),
        ),
      ],
    );

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: metric.isSelected ? selectedBg : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: content,
    );

    if (metric.onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: metric.onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

  TextStyle? _valueStyle(BuildContext context, Color tone) {
    final theme = Theme.of(context).textTheme;
    switch (metric.emphasis) {
      case MinimalInsightMetricEmphasis.monetary:
        return theme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: tone,
          letterSpacing: -0.3,
          height: 1.0,
        );
      case MinimalInsightMetricEmphasis.prominent:
        return theme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 19,
          color: tone,
          letterSpacing: -0.2,
          height: 1.05,
        );
      case MinimalInsightMetricEmphasis.standard:
        return theme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: tone,
          letterSpacing: -0.2,
          height: 1.05,
        );
    }
  }
}

class TransactionDecisionSnapshot extends StatelessWidget {
  const TransactionDecisionSnapshot({
    super.key,
    required this.message,
    required this.monthIncome,
    required this.monthExpense,
    required this.recurringCount,
    required this.netFlow,
    required this.topCategory,
    required this.currencyCode,
    required this.isIncomeSelected,
    required this.isSpentSelected,
    required this.isRecurringSelected,
    required this.onIncomeTap,
    required this.onSpentTap,
    required this.onRecurringTap,
    required this.emptyFallback,
  });

  final String message;
  final double monthIncome;
  final double monthExpense;
  final int recurringCount;
  final double netFlow;
  final String? topCategory;
  final String currencyCode;
  final bool isIncomeSelected;
  final bool isSpentSelected;
  final bool isRecurringSelected;
  final VoidCallback onIncomeTap;
  final VoidCallback onSpentTap;
  final VoidCallback onRecurringTap;
  final String emptyFallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = CurrencyUtils.getFormat(currencyCode);
    final metrics = [
      MinimalInsightMetric(
        label: l10n.income,
        value: formatter.format(monthIncome),
        animatedValue: monthIncome,
        valueFormatter: formatter.format,
        tone: const Color(0xFF198754),
        emphasis: MinimalInsightMetricEmphasis.monetary,
        onTap: onIncomeTap,
        isSelected: isIncomeSelected,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioSpent,
        value: formatter.format(monthExpense),
        animatedValue: monthExpense,
        valueFormatter: formatter.format,
        tone: const Color(0xFFC94B2A),
        emphasis: MinimalInsightMetricEmphasis.monetary,
        onTap: onSpentTap,
        isSelected: isSpentSelected,
      ),
      MinimalInsightMetric(
        label: l10n.commonRecurring,
        value: '$recurringCount',
        tone: const Color(0xFF5A3FC0),
        emphasis: MinimalInsightMetricEmphasis.prominent,
        onTap: onRecurringTap,
        isSelected: isRecurringSelected,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioNetFlow,
        value: formatter.format(netFlow),
        animatedValue: netFlow,
        valueFormatter: formatter.format,
        tone: netFlow >= 0 ? const Color(0xFF198754) : const Color(0xFFC94B2A),
        emphasis: MinimalInsightMetricEmphasis.prominent,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioTopCategory,
        value: topCategory ?? emptyFallback,
        emphasis: MinimalInsightMetricEmphasis.standard,
      ),
    ];

    return MinimalInsightCard(
      title: l10n.portfolioDecisionSnapshot,
      icon: Icons.insights_rounded,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5F7FF),
          Color(0xFFF9FAFF),
          Color(0xFFFCFDFF),
        ],
      ),
      insightText: message,
      semanticTone: InsightCardSemanticTone.general,
      metrics: metrics,
      iconTint: const Color(0xFF4F5FA7),
      chart: InsightRingChart(
        fraction: monthIncome > 0
            ? monthExpense / monthIncome
            : (monthExpense > 0 ? 1.0 : 0.0),
        color: netFlow >= 0 ? const Color(0xFF198754) : const Color(0xFFC94B2A),
        centerLabel: monthIncome > 0
            ? '${((monthExpense / monthIncome) * 100).round()}%'
            : '—',
        caption: l10n.portfolioCaptionSpent,
      ),
    );
  }
}

class BudgetPortfolioInsight extends StatelessWidget {
  const BudgetPortfolioInsight({
    super.key,
    required this.atRiskCount,
    required this.totalSpent,
    required this.totalRemaining,
    required this.projectedOverspend,
    required this.currencyFormat,
    required this.description,
    required this.daysLeftLabel,
    required this.rolloverLabel,
    required this.onRollover,
  });

  final int atRiskCount;
  final double totalSpent;
  final double totalRemaining;
  final double projectedOverspend;
  final NumberFormat currencyFormat;
  final String description;
  final String daysLeftLabel;
  final String rolloverLabel;
  final VoidCallback onRollover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remainingLabel = projectedOverspend > 0 ? 'Overspend' : 'Remaining';
    final remainingValue =
        projectedOverspend > 0 ? projectedOverspend : totalRemaining;
    final remainingTone = projectedOverspend > 0
        ? const Color(0xFFC94B2A)
        : const Color(0xFF198754);

    final statusChip = atRiskCount > 0
        ? MinimalStatusChip(
            label: l10n.portfolioAtRiskCount('$atRiskCount'),
            tone: const Color(0xFFB36A10),
            isSelected: true,
          )
        : MinimalStatusChip(
            label: l10n.portfolioOnTrack,
            tone: const Color(0xFF198754),
          );

    final metrics = [
      MinimalInsightMetric(
        label: remainingLabel,
        value: currencyFormat.format(remainingValue),
        animatedValue: remainingValue,
        valueFormatter: currencyFormat.format,
        tone: remainingTone,
        emphasis: MinimalInsightMetricEmphasis.monetary,
        isSelected: projectedOverspend > 0,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioSpent,
        value: currencyFormat.format(totalSpent),
        animatedValue: totalSpent,
        valueFormatter: currencyFormat.format,
        emphasis: MinimalInsightMetricEmphasis.prominent,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioAtRisk,
        value: atRiskCount.toString(),
        tone:
            atRiskCount > 0 ? const Color(0xFFB36A10) : const Color(0xFF198754),
        isSelected: atRiskCount > 0,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioDaysLeft,
        value: daysLeftLabel,
      ),
    ];

    return MinimalInsightCard(
      title: l10n.budgetPortfolioTitle,
      icon: Icons.track_changes_rounded,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF6F7FF),
          Color(0xFFFAFAFF),
          Color(0xFFFEFEFF),
        ],
      ),
      insightText: description,
      semanticTone: projectedOverspend > 0
          ? InsightCardSemanticTone.warning
          : atRiskCount > 0
              ? InsightCardSemanticTone.caution
              : InsightCardSemanticTone.positive,
      metrics: metrics,
      statusChip: statusChip,
      iconTint: const Color(0xFF4F5FA7),
      chart: Builder(builder: (context) {
        final limit = totalSpent + (totalRemaining > 0 ? totalRemaining : 0);
        final used =
            limit > 0 ? totalSpent / limit : (totalSpent > 0 ? 1.0 : 0.0);
        return InsightRingChart(
          fraction: projectedOverspend > 0 ? 1.0 : used,
          color: remainingTone,
          centerLabel: limit > 0 ? '${(used * 100).round()}%' : '—',
          caption: l10n.portfolioCaptionUsed,
        );
      }),
      footer: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onRollover,
          child: Text(rolloverLabel),
        ),
      ),
    );
  }
}

class SavingsPortfolioInsight extends StatelessWidget {
  const SavingsPortfolioInsight({
    super.key,
    required this.totalTarget,
    required this.totalSaved,
    required this.atRiskGoals,
    required this.decisionMessage,
    required this.currencyFormat,
    this.monthlySurplus,
  });

  final double totalTarget;
  final double totalSaved;
  final int atRiskGoals;
  final String decisionMessage;
  final NumberFormat currencyFormat;
  final double? monthlySurplus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surplusValue = monthlySurplus ?? 0;
    final surplusTone =
        surplusValue >= 0 ? const Color(0xFF198754) : const Color(0xFFC94B2A);

    final statusChip = atRiskGoals > 0
        ? MinimalStatusChip(
            label: l10n.portfolioAtRiskCount('$atRiskGoals'),
            tone: const Color(0xFFB36A10),
            isSelected: true,
          )
        : MinimalStatusChip(
            label: l10n.portfolioHealthyPace, tone: const Color(0xFF198754));

    final metrics = [
      MinimalInsightMetric(
        label: l10n.portfolioSaved,
        value: currencyFormat.format(totalSaved),
        animatedValue: totalSaved,
        valueFormatter: currencyFormat.format,
        tone: const Color(0xFF198754),
        emphasis: MinimalInsightMetricEmphasis.monetary,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioTarget,
        value: currencyFormat.format(totalTarget),
        animatedValue: totalTarget,
        valueFormatter: currencyFormat.format,
        emphasis: MinimalInsightMetricEmphasis.prominent,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioMonthlySurplus,
        value: currencyFormat.format(surplusValue),
        tone: surplusTone,
        isSelected: surplusValue < 0,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioAtRisk,
        value: atRiskGoals.toString(),
        tone:
            atRiskGoals > 0 ? const Color(0xFFB36A10) : const Color(0xFF198754),
        isSelected: atRiskGoals > 0,
      ),
    ];

    return MinimalInsightCard(
      title: l10n.savingsPortfolioTitle,
      icon: Icons.savings_outlined,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF2FAF5),
          Color(0xFFF7FCF9),
          Color(0xFFFCFFFD),
        ],
      ),
      insightText: decisionMessage,
      semanticTone: atRiskGoals > 0
          ? InsightCardSemanticTone.caution
          : InsightCardSemanticTone.positive,
      metrics: metrics,
      statusChip: statusChip,
      iconTint: const Color(0xFF198754),
      chart: InsightRingChart(
        fraction: totalTarget > 0 ? totalSaved / totalTarget : 0,
        color: const Color(0xFF198754),
        centerLabel: totalTarget > 0
            ? '${((totalSaved / totalTarget) * 100).round()}%'
            : '—',
        caption: l10n.portfolioCaptionSaved,
      ),
    );
  }
}

class SubscriptionPortfolioInsight<T> extends StatelessWidget {
  const SubscriptionPortfolioInsight({
    super.key,
    required this.activeCount,
    required this.renewingSoonCount,
    required this.monthlyLoad,
    required this.lowPriorityMonthlyCost,
    required this.currencySymbol,
    required this.insightText,
    required this.filters,
    required this.activeFilter,
    required this.filterLabelBuilder,
    required this.onFilterSelected,
    this.criticalCount = 0,
    this.showChipsInFooter = true,
  });

  final int activeCount;
  final int renewingSoonCount;
  final double monthlyLoad;
  final double lowPriorityMonthlyCost;
  final String currencySymbol;
  final String insightText;
  final List<T> filters;
  final T? activeFilter;
  final String Function(T filter) filterLabelBuilder;
  final ValueChanged<T?> onFilterSelected;
  final int criticalCount;

  /// When false the filter chips are not rendered inside the card footer,
  /// allowing the caller to render them separately (e.g. as a standalone Wrap).
  final bool showChipsInFooter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = NumberFormat.currency(symbol: currencySymbol);

    final statusChip = criticalCount > 0
        ? MinimalStatusChip(
            label: l10n.portfolioCriticalCount('$criticalCount'),
            tone: const Color(0xFFC94B2A),
            isSelected: true,
          )
        : MinimalStatusChip(
            label: l10n.portfolioStable,
            tone: const Color(0xFF198754),
          );

    final metrics = [
      MinimalInsightMetric(
        label: l10n.portfolioMonthlyLoad,
        value: formatter.format(monthlyLoad),
        emphasis: MinimalInsightMetricEmphasis.monetary,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioActive,
        value: activeCount.toString(),
      ),
      MinimalInsightMetric(
        label: l10n.portfolioNextRenewal,
        value: '$renewingSoonCount due',
        tone: renewingSoonCount > 0 ? const Color(0xFFB36A10) : null,
        isSelected: renewingSoonCount > 0,
      ),
      MinimalInsightMetric(
        label: l10n.portfolioOptionalSavings,
        value: formatter.format(lowPriorityMonthlyCost),
        tone: lowPriorityMonthlyCost > 0 ? const Color(0xFF198754) : null,
        isSelected: lowPriorityMonthlyCost > 0,
      ),
    ];

    return MinimalInsightCard(
      title: l10n.subscriptionPortfolioTitle,
      icon: Icons.subscriptions_rounded,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF4F7FF),
          Color(0xFFF9FAFF),
          Color(0xFFFCFDFF),
        ],
      ),
      insightText: insightText,
      semanticTone: criticalCount > 0
          ? InsightCardSemanticTone.warning
          : renewingSoonCount > 0
              ? InsightCardSemanticTone.caution
              : InsightCardSemanticTone.general,
      metrics: metrics,
      statusChip: statusChip,
      iconTint: const Color(0xFF4F5FA7),
      chart: InsightRingChart(
        fraction: monthlyLoad > 0 ? lowPriorityMonthlyCost / monthlyLoad : 0,
        color: lowPriorityMonthlyCost > 0
            ? const Color(0xFFB36A10)
            : const Color(0xFF198754),
        centerLabel: monthlyLoad > 0
            ? '${((lowPriorityMonthlyCost / monthlyLoad) * 100).round()}%'
            : '—',
        caption: l10n.portfolioCaptionOptional,
      ),
      footer: showChipsInFooter
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SubscriptionFilterChip(
                    label: l10n.commonAll,
                    selected: activeFilter == null,
                    onTap: () => onFilterSelected(null),
                  ),
                  const SizedBox(width: 8),
                  ...filters.map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _SubscriptionFilterChip(
                        label: filterLabelBuilder(filter),
                        selected: activeFilter == filter,
                        onTap: () => onFilterSelected(filter),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _SubscriptionFilterChip extends StatelessWidget {
  const _SubscriptionFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4F5FA7).withOpacity(0.30)
              : scheme.surface.withOpacity(0.72),
          border: Border.all(
            color: selected
                ? const Color(0xFF4F5FA7).withOpacity(0.55)
                : scheme.outlineVariant.withOpacity(0.35),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF384A87) : scheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class InsightPortfolioMetric extends MinimalInsightMetric {
  const InsightPortfolioMetric({
    required super.label,
    required super.value,
    super.tone,
    super.onTap,
    super.isSelected,
  });
}

class InsightPortfolioCard extends MinimalInsightCard {
  const InsightPortfolioCard({
    super.key,
    required super.title,
    required super.icon,
    required super.gradient,
    required super.insightText,
    required List<InsightPortfolioMetric> metrics,
    super.semanticTone,
    super.iconTint,
    super.footer,
    this.ctaLabel,
    this.onCtaTap,
  }) : super(
          metrics: metrics,
        );

  final String? ctaLabel;
  final VoidCallback? onCtaTap;
}

class TransactionInsightCard extends TransactionDecisionSnapshot {
  const TransactionInsightCard({
    super.key,
    required super.message,
    required super.monthIncome,
    required super.monthExpense,
    required super.recurringCount,
    required super.netFlow,
    required super.topCategory,
    required super.currencyCode,
    required super.isIncomeSelected,
    required super.isSpentSelected,
    required super.isRecurringSelected,
    required super.onIncomeTap,
    required super.onSpentTap,
    required super.onRecurringTap,
    required super.emptyFallback,
  });
}

class BudgetPortfolioCard extends BudgetPortfolioInsight {
  const BudgetPortfolioCard({
    super.key,
    required int categoriesCount,
    required super.atRiskCount,
    required double totalLimit,
    required super.totalSpent,
    required super.totalRemaining,
    required int averageAlertThreshold,
    required super.projectedOverspend,
    required super.currencyFormat,
    required super.description,
    required super.daysLeftLabel,
    required super.rolloverLabel,
    required super.onRollover,
  });
}

class SavingsPortfolioCard extends SavingsPortfolioInsight {
  const SavingsPortfolioCard({
    super.key,
    required super.totalTarget,
    required super.totalSaved,
    required super.atRiskGoals,
    required int goalsCount,
    required super.decisionMessage,
    required super.currencyFormat,
    super.monthlySurplus,
  });
}

class SubscriptionPortfolioCard<T> extends SubscriptionPortfolioInsight<T> {
  const SubscriptionPortfolioCard({
    super.key,
    required super.activeCount,
    required super.criticalCount,
    required super.renewingSoonCount,
    required int highPriorityCount,
    required super.monthlyLoad,
    required super.lowPriorityMonthlyCost,
    required super.currencySymbol,
    required super.insightText,
    required super.filters,
    required super.activeFilter,
    required super.filterLabelBuilder,
    required super.onFilterSelected,
    super.showChipsInFooter,
  });
}
