import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  });

  final String label;
  final String value;
  final Color? tone;
  final MinimalInsightMetricEmphasis emphasis;
  final VoidCallback? onTap;
  final bool isSelected;
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
        color: tone.withValues(alpha: isSelected ? 0.22 : 0.12),
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
              scheme.surfaceContainerHigh.withValues(alpha: 0.96),
              scheme.surfaceContainer.withValues(alpha: 0.92),
            ],
          )
        : gradient;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : scheme.outlineVariant.withValues(alpha: 0.42);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: effectiveIconTint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: effectiveIconTint, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          const SizedBox(height: 16),
          Text(
            insightText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.32,
                ),
          ),
          const SizedBox(height: 18),
          _MinimalMetricGrid(metrics: metrics),
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
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
            crossAxisSpacing: 14,
            mainAxisSpacing: 12,
            mainAxisExtent: 70,
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
        ? tone.withValues(alpha: isDark ? 0.24 : 0.16)
        : scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12);

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
              child: Text(
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
          fontSize: 28,
          color: tone,
          letterSpacing: -0.4,
          height: 1.0,
        );
      case MinimalInsightMetricEmphasis.prominent:
        return theme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: tone,
          letterSpacing: -0.2,
          height: 1.05,
        );
      case MinimalInsightMetricEmphasis.standard:
        return theme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 22,
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
    final formatter = CurrencyUtils.getFormat(currencyCode);
    final metrics = [
      MinimalInsightMetric(
        label: 'Income',
        value: formatter.format(monthIncome),
        tone: const Color(0xFF198754),
        emphasis: MinimalInsightMetricEmphasis.monetary,
        onTap: onIncomeTap,
        isSelected: isIncomeSelected,
      ),
      MinimalInsightMetric(
        label: 'Spent',
        value: formatter.format(monthExpense),
        tone: const Color(0xFFC94B2A),
        emphasis: MinimalInsightMetricEmphasis.monetary,
        onTap: onSpentTap,
        isSelected: isSpentSelected,
      ),
      MinimalInsightMetric(
        label: 'Recurring',
        value: '$recurringCount',
        tone: const Color(0xFF5A3FC0),
        emphasis: MinimalInsightMetricEmphasis.prominent,
        onTap: onRecurringTap,
        isSelected: isRecurringSelected,
      ),
      MinimalInsightMetric(
        label: 'Net Flow',
        value: formatter.format(netFlow),
        tone: netFlow >= 0 ? const Color(0xFF198754) : const Color(0xFFC94B2A),
        emphasis: MinimalInsightMetricEmphasis.prominent,
      ),
      MinimalInsightMetric(
        label: 'Top Category',
        value: topCategory ?? emptyFallback,
        emphasis: MinimalInsightMetricEmphasis.standard,
      ),
    ];

    return MinimalInsightCard(
      title: 'Decision Snapshot',
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
    final remainingLabel = projectedOverspend > 0 ? 'Overspend' : 'Remaining';
    final remainingValue =
        projectedOverspend > 0 ? projectedOverspend : totalRemaining;
    final remainingTone = projectedOverspend > 0
        ? const Color(0xFFC94B2A)
        : const Color(0xFF198754);

    final statusChip = atRiskCount > 0
        ? MinimalStatusChip(
            label: '$atRiskCount at risk',
            tone: const Color(0xFFB36A10),
            isSelected: true,
          )
        : const MinimalStatusChip(
            label: 'On track',
            tone: Color(0xFF198754),
          );

    final metrics = [
      MinimalInsightMetric(
        label: remainingLabel,
        value: currencyFormat.format(remainingValue),
        tone: remainingTone,
        emphasis: MinimalInsightMetricEmphasis.monetary,
        isSelected: projectedOverspend > 0,
      ),
      MinimalInsightMetric(
        label: 'Spent',
        value: currencyFormat.format(totalSpent),
        emphasis: MinimalInsightMetricEmphasis.prominent,
      ),
      MinimalInsightMetric(
        label: 'At Risk',
        value: atRiskCount.toString(),
        tone:
            atRiskCount > 0 ? const Color(0xFFB36A10) : const Color(0xFF198754),
        isSelected: atRiskCount > 0,
      ),
      MinimalInsightMetric(
        label: 'Days Left',
        value: daysLeftLabel,
      ),
    ];

    return MinimalInsightCard(
      title: 'Budget Portfolio',
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
    final surplusValue = monthlySurplus ?? 0;
    final surplusTone =
        surplusValue >= 0 ? const Color(0xFF198754) : const Color(0xFFC94B2A);

    final statusChip = atRiskGoals > 0
        ? MinimalStatusChip(
            label: '$atRiskGoals at risk',
            tone: const Color(0xFFB36A10),
            isSelected: true,
          )
        : const MinimalStatusChip(
            label: 'Healthy pace', tone: Color(0xFF198754));

    final metrics = [
      MinimalInsightMetric(
        label: 'Saved',
        value: currencyFormat.format(totalSaved),
        tone: const Color(0xFF198754),
        emphasis: MinimalInsightMetricEmphasis.monetary,
      ),
      MinimalInsightMetric(
        label: 'Target',
        value: currencyFormat.format(totalTarget),
        emphasis: MinimalInsightMetricEmphasis.prominent,
      ),
      MinimalInsightMetric(
        label: 'Monthly Surplus',
        value: currencyFormat.format(surplusValue),
        tone: surplusTone,
        isSelected: surplusValue < 0,
      ),
      MinimalInsightMetric(
        label: 'At Risk',
        value: atRiskGoals.toString(),
        tone:
            atRiskGoals > 0 ? const Color(0xFFB36A10) : const Color(0xFF198754),
        isSelected: atRiskGoals > 0,
      ),
    ];

    return MinimalInsightCard(
      title: 'Savings Portfolio',
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

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: currencySymbol);

    final statusChip = criticalCount > 0
        ? MinimalStatusChip(
            label: '$criticalCount critical',
            tone: const Color(0xFFC94B2A),
            isSelected: true,
          )
        : const MinimalStatusChip(
            label: 'Stable',
            tone: Color(0xFF198754),
          );

    final metrics = [
      MinimalInsightMetric(
        label: 'Monthly Load',
        value: formatter.format(monthlyLoad),
        emphasis: MinimalInsightMetricEmphasis.monetary,
      ),
      MinimalInsightMetric(
        label: 'Active',
        value: activeCount.toString(),
      ),
      MinimalInsightMetric(
        label: 'Next Renewal',
        value: '$renewingSoonCount due',
        tone: renewingSoonCount > 0 ? const Color(0xFFB36A10) : null,
        isSelected: renewingSoonCount > 0,
      ),
      MinimalInsightMetric(
        label: 'Optional Savings',
        value: formatter.format(lowPriorityMonthlyCost),
        tone: lowPriorityMonthlyCost > 0 ? const Color(0xFF198754) : null,
        isSelected: lowPriorityMonthlyCost > 0,
      ),
    ];

    return MinimalInsightCard(
      title: 'Subscription Portfolio',
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
      footer: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SubscriptionFilterChip(
              label: 'All',
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
      ),
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
              ? const Color(0xFF4F5FA7).withValues(alpha: 0.30)
              : scheme.surface.withValues(alpha: 0.72),
          border: Border.all(
            color: selected
                ? const Color(0xFF4F5FA7).withValues(alpha: 0.55)
                : scheme.outlineVariant.withValues(alpha: 0.35),
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
  });
}
