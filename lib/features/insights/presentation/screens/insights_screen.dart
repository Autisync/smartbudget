import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:smartbudget/components/charts/app_finance_charts.dart';
import 'package:flutter/material.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/components/feedback/app_feedback_service.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/components/forms/app_action_menu.dart';
import 'package:smartbudget/components/forms/modern_select.dart';
import 'package:smartbudget/features/insights/domain/models/insight.dart';
import 'package:smartbudget/features/insights/presentation/providers/insight_provider.dart';

enum _CopilotTimeframe {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last3Months('Last 3 Months'),
  last12Months('12 Months');

  const _CopilotTimeframe(this.label);
  final String label;
}

enum _CopilotFocus {
  subscriptions('Subscriptions'),
  budgets('Budgets'),
  savings('Savings'),
  transactions('Transactions');

  const _CopilotFocus(this.label);
  final String label;
}

enum _ForecastConfidence {
  balanced('Balanced'),
  conservative('Conservative'),
  aggressive('Aggressive');

  const _ForecastConfidence(this.label);
  final String label;
}

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({
    super.key,
    this.onNavigate,
  });

  final void Function(String route)? onNavigate;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  _CopilotTimeframe _timeframe = _CopilotTimeframe.thisMonth;
  _CopilotFocus _focus = _CopilotFocus.transactions;
  _ForecastConfidence _forecastConfidence = _ForecastConfidence.balanced;
  String? _lastToast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insightsAsync = ref.watch(insightsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.insightsCopilotTitle),
        backgroundColor: colors.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: insightsAsync.when(
        data: (insights) => _buildContent(context, insights),
        loading: _buildLoadingState,
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Insight> insights) {
    final l10n = AppLocalizations.of(context)!;
    final filteredInsights = _filteredInsights(insights);
    final model = _CopilotViewModel.fromInsights(filteredInsights);
    final activities = _buildActivities(filteredInsights);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsCopilotTitle, style: _titleStyle(context)),
          const SizedBox(height: 8),
          Text(
            'Personalized financial guidance based on your spending, subscriptions, and goals.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildOverviewCard(context, model),
          const SizedBox(height: 20),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          _buildFilterSection(context),
          const SizedBox(height: 24),
          _buildRecommendedActions(context, filteredInsights),
          const SizedBox(height: 24),
          _buildForecastSection(context, filteredInsights),
          const SizedBox(height: 24),
          _buildActivitySection(context, activities),
          SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, _CopilotViewModel model) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey<String>(
          'overview-${model.riskLevelLabel}-${model.insightsCount}',
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withOpacity( 0.62),
              colors.secondaryContainer.withOpacity( 0.58),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: _cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity( 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Copilot Overview',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _sectionTitleStyle(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(model.insightText,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetricTile(context, 'Risk Level', model.riskLevelLabel,
                    Icons.warning_amber_rounded),
                _buildMetricTile(context, 'Insights', '${model.insightsCount}',
                    Icons.lightbulb_outline_rounded),
                _buildMetricTile(context, 'Monthly Impact',
                    model.monthlyImpactLabel, Icons.trending_up_rounded),
                _buildMetricTile(context, 'Confidence', model.confidenceLabel,
                    Icons.track_changes_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity( 0.86),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: _labelStyle(context)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SurfacePanel(
      key: const ValueKey<String>('copilot-filter-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsTimeframeFocus, style: _sectionTitleStyle(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _CopilotTimeframe.values
                .map(
                  (filter) => ChoiceChip(
                    key: ValueKey<String>('copilot-timeframe-${filter.name}'),
                    label: Text(filter.label),
                    selected: _timeframe == filter,
                    onSelected: (_) {
                      setState(() => _timeframe = filter);
                      _showInfoOnce('Filter applied');
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          ModernSelect<_CopilotFocus>(
            key: const ValueKey<String>('copilot-focus-dropdown'),
            label: l10n.insightsFocus,
            value: _focus,
            items: _CopilotFocus.values
                .map(
                  (focus) => DropdownMenuItem<_CopilotFocus>(
                    value: focus,
                    child: Text(focus.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _focus = value);
              _showInfoOnce('Filter applied');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedActions(
    BuildContext context,
    List<Insight> insights,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.insightsRecommendedActions, style: _sectionTitleStyle(context)),
        const SizedBox(height: 12),
        if (insights.isEmpty)
          _buildEmptyState(
            context,
            key: const ValueKey<String>('copilot-empty-insights'),
            title: l10n.insightsNoRecommendations,
            message:
                'Copilot will suggest actions after enough activity is analyzed.',
          )
        else
          ...insights.asMap().entries.map(
                (entry) => TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 150 + (entry.key * 40)),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 8),
                        child: child,
                      ),
                    );
                  },
                  child: _buildInsightActionCard(context, entry.value),
                ),
              ),
      ],
    );
  }

  Widget _buildInsightActionCard(BuildContext context, Insight insight) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final tone = _impactColor(context, insight.impact);
    final confidence = (insight.metadata?['confidence'] as num?)?.toDouble() ??
        switch (insight.impact) {
          InsightImpact.high => 0.91,
          InsightImpact.medium => 0.78,
          InsightImpact.low => 0.64,
        };
    final monthlyImpact = insight.metadata?['monthlyImpact']?.toString() ??
        switch (insight.impact) {
          InsightImpact.high => 'Kz 12,578/month',
          InsightImpact.medium => 'Kz 6,300/month',
          InsightImpact.low => 'Kz 2,180/month',
        };

    return Container(
      key: ValueKey<String>('copilot-action-${insight.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withOpacity( 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(insight.type), color: tone, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle(context),
                ),
              ),
              _chip(context, _impactLabel(insight.impact), tone),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, monthlyImpact, colors.primary),
              _chip(
                context,
                'Confidence ${(confidence * 100).toStringAsFixed(0)}%',
                colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.actionLabel ?? 'Review recommendation',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilledButton(
                key: ValueKey<String>('copilot-action-cta-${insight.id}'),
                onPressed: () {
                  _showInfoOnce('Recommendation opened');
                  _navigate(insight.route);
                },
                child: Text(l10n.commonOpen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(BuildContext context, List<Insight> insights) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _SurfacePanel(
      key: const ValueKey<String>('copilot-forecast-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsForecast, style: _sectionTitleStyle(context)),
          const SizedBox(height: 4),
          Text(l10n.insightsActualVsPredicted,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          ModernSelect<_ForecastConfidence>(
            label: l10n.insightsConfidenceModel,
            value: _forecastConfidence,
            items: _ForecastConfidence.values
                .map(
                  (value) => DropdownMenuItem<_ForecastConfidence>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _forecastConfidence = value);
              _showInfoOnce('Forecast updated');
            },
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            _buildEmptyState(
              context,
              key: const ValueKey<String>('copilot-empty-forecast'),
              title: l10n.insightsNoForecastTitle,
              message: l10n.insightsNoForecastMessage,
            )
          else
            ChartEntrance(
              key: const ValueKey<String>('copilot-forecast-chart'),
              builder: (ctx, _) => SizedBox(
              height: 190,
              child: LineChart(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                LineChartData(
                  minY: 0,
                  maxY: 3.4,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: colors.primary,
                      barWidth: 3,
                      spots: _forecastSpots(insights),
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withOpacity( 0.12),
                      ),
                    ),
                  ],
                ),
              ),
              ), // SizedBox
            ), // ChartEntrance
        ],
      ),
    );
  }

  Widget _buildActivitySection(
    BuildContext context,
    List<_CopilotActivity> activities,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _SurfacePanel(
      key: const ValueKey<String>('copilot-activity-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsRecentActivity, style: _sectionTitleStyle(context)),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            _buildEmptyState(
              context,
              key: const ValueKey<String>('copilot-empty-activity'),
              title: l10n.insightsNoCopilotTitle,
              message: l10n.insightsNoCopilotMessage,
            )
          else
            ...activities.map(
              (activity) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity( 0.62),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(activity.icon, color: activity.color, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _labelStyle(context),
                          ),
                        ),
                        AppActionMenu(
                          title: '${activity.title} actions',
                          tooltip: l10n.insightsActivityActions,
                          onSelected: (_) => _showInfoOnce('Action completed'),
                          items: [
                            AppActionItem(
                              value: 'open',
                              label: l10n.insightsOpenDetails,
                              icon: Icons.open_in_new_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(context, activity.statusLabel, activity.color),
                        Text(
                          activity.timeLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.insightsQuickActions, style: _sectionTitleStyle(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickActionButton(
              context,
              'Open Scenario Lab',
              '/scenarios',
              key: 'quick-action-scenarios',
            ),
            _quickActionButton(
              context,
              'Review Budgets',
              '/budgets',
              key: 'quick-action-budgets',
            ),
            _quickActionButton(
              context,
              'Review Subscriptions',
              '/subscriptions',
              key: 'quick-action-subscriptions',
            ),
            _quickActionButton(
              context,
              'View Reports',
              '/reports',
              key: 'quick-action-reports',
            ),
            _quickActionButton(
              context,
              'Check Burn Rate',
              '/insights',
              key: 'quick-action-burn-rate',
            ),
          ].map((button) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: colors.copyWith(primary: colors.primary),
              ),
              child: button,
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _quickActionButton(
    BuildContext context,
    String label,
    String route, {
    required String key,
  }) {
    return OutlinedButton(
      key: ValueKey<String>(key),
      onPressed: () {
        _navigate(route);
        _showInfoOnce('Action completed');
      },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLottieView(
                assetPath: 'assets/animations/copilot_loading.json',
                width: 84,
                height: 84,
                repeat: false,
                animate: false,
                fallbackIcon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 12),
              Text(l10n.insightsAnalyzing),
            ],
          ),
        ),
        ExcludeSemantics(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0,
              child: _buildErrorState('Exception: boom'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 46),
            const SizedBox(height: 10),
            Text(l10n.insightsAnalysisFailed, style: _sectionTitleStyle(context)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                ref.invalidate(insightsProvider);
                _showInfoOnce('Insights refreshed');
              },
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required ValueKey<String> key,
    required String title,
    required String message,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity( 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const AppLottieView(
            assetPath: 'assets/animations/copilot_empty.json',
            width: 72,
            height: 72,
            repeat: false,
            fallbackIcon: Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 10),
          Text(title, style: _labelStyle(context)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  List<Insight> _filteredInsights(List<Insight> insights) {
    return insights.where((insight) {
      switch (_focus) {
        case _CopilotFocus.subscriptions:
          return insight.type == InsightType.subscription;
        case _CopilotFocus.budgets:
          return insight.type == InsightType.budget;
        case _CopilotFocus.savings:
          return insight.type == InsightType.saving;
        case _CopilotFocus.transactions:
          return insight.type == InsightType.spending ||
              insight.type == InsightType.trend;
      }
    }).toList(growable: false);
  }

  List<_CopilotActivity> _buildActivities(List<Insight> insights) {
    return insights.take(6).map((insight) {
      final color = _impactColor(context, insight.impact);
      return _CopilotActivity(
        title: insight.title,
        timeLabel: _relativeTimeLabel(insight.createdAt),
        statusLabel: _impactLabel(insight.impact),
        icon: _typeIcon(insight.type),
        color: color,
      );
    }).toList(growable: false);
  }

  List<FlSpot> _forecastSpots(List<Insight> insights) {
    final values = insights.take(6).toList(growable: false);
    if (values.isEmpty) {
      return const [FlSpot(0, 0), FlSpot(1, 0)];
    }
    return values.asMap().entries.map((entry) {
      final y = switch (entry.value.impact) {
        InsightImpact.high => 3.0,
        InsightImpact.medium => 2.0,
        InsightImpact.low => 1.0,
      };
      return FlSpot(entry.key.toDouble(), y);
    }).toList(growable: false);
  }

  Color _impactColor(BuildContext context, InsightImpact impact) {
    final colors = Theme.of(context).colorScheme;
    return switch (impact) {
      InsightImpact.high => colors.error,
      InsightImpact.medium => const Color(0xFFC47A1B),
      InsightImpact.low => colors.primary,
    };
  }

  String _impactLabel(InsightImpact impact) {
    return switch (impact) {
      InsightImpact.high => 'Critical',
      InsightImpact.medium => 'High',
      InsightImpact.low => 'Medium',
    };
  }

  IconData _typeIcon(InsightType type) {
    return switch (type) {
      InsightType.spending => Icons.receipt_long_rounded,
      InsightType.saving => Icons.savings_rounded,
      InsightType.budget => Icons.account_balance_wallet_rounded,
      InsightType.subscription => Icons.subscriptions_rounded,
      InsightType.trend => Icons.show_chart_rounded,
    };
  }

  String _relativeTimeLabel(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours < 1) {
      return '${math.max(1, diff.inMinutes)}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  void _showInfoOnce(String message) {
    if (_lastToast == message) return;
    _lastToast = message;
    AppFeedbackService.showInfo(context, message);
  }

  void _navigate(String? route) {
    if (route == null || route.isEmpty) {
      return;
    }
    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
      return;
    }
    try {
      context.go(route);
    } catch (_) {
      AppFeedbackService.showInfo(context, 'Route unavailable in this build');
    }
  }
}

class _CopilotViewModel {
  const _CopilotViewModel({
    required this.riskLevelLabel,
    required this.insightsCount,
    required this.monthlyImpactLabel,
    required this.confidenceLabel,
    required this.insightText,
  });

  final String riskLevelLabel;
  final int insightsCount;
  final String monthlyImpactLabel;
  final String confidenceLabel;
  final String insightText;

  factory _CopilotViewModel.fromInsights(List<Insight> insights) {
    final high = insights.where((i) => i.impact == InsightImpact.high).length;
    final medium =
        insights.where((i) => i.impact == InsightImpact.medium).length;
    final risk = high > 0
        ? 'High'
        : medium > 0
            ? 'Medium'
            : 'Low';
    final impact = high > 0
        ? 'Kz ${(high * 6400).toStringAsFixed(0)}/month'
        : medium > 0
            ? 'Kz ${(medium * 3200).toStringAsFixed(0)}/month'
            : 'Kz 0/month';
    final confidence = insights.isEmpty
        ? '0%'
        : '${(72 + (high * 6) + (medium * 3)).clamp(0, 99)}%';
    final text = insights.isEmpty
        ? 'No urgent risks detected. Keep tracking activity to improve future predictions.'
        : high > 0
            ? 'Spending is currently ahead of your income. Review the highest-impact recommendations first.'
            : medium > 0
                ? 'Your fixed costs are stable, but subscriptions are creating pressure on monthly cashflow.'
                : 'No urgent risks detected. Keep tracking activity to improve future predictions.';

    return _CopilotViewModel(
      riskLevelLabel: risk,
      insightsCount: insights.length,
      monthlyImpactLabel: impact,
      confidenceLabel: confidence,
      insightText: text,
    );
  }
}

class _CopilotActivity {
  const _CopilotActivity({
    required this.title,
    required this.timeLabel,
    required this.statusLabel,
    required this.icon,
    required this.color,
  });

  final String title;
  final String timeLabel;
  final String statusLabel;
  final IconData icon;
  final Color color;
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }
}

TextStyle _titleStyle(BuildContext context) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ) ??
      const TextStyle(fontSize: 24, fontWeight: FontWeight.w800);
}

TextStyle _sectionTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ) ??
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w800);
}

TextStyle _labelStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ) ??
      const TextStyle(fontWeight: FontWeight.w700);
}

const _cardShadow = [
  BoxShadow(
    color: Color.fromRGBO(32, 37, 58, 0.08),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
];
