import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/app_shimmer.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:smartbudget/features/scenario_lab/engines/scenario_engine.dart';
import 'package:smartbudget/features/scenario_lab/models/scenario_models.dart';
import 'package:smartbudget/features/scenario_lab/presentation/providers/scenario_lab_controller.dart';

class ScenarioLabScreen extends ConsumerStatefulWidget {
  const ScenarioLabScreen({super.key});

  @override
  ConsumerState<ScenarioLabScreen> createState() => _ScenarioLabScreenState();
}

class _ScenarioLabScreenState extends ConsumerState<ScenarioLabScreen> {
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
    final resultAsync = ref.watch(scenarioLabResultProvider);
    final baseDataAsync = ref.watch(scenarioLabBaseDataProvider);
    final controller = ref.read(scenarioLabControllerProvider.notifier);

    return AppScaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.scenarioLabTitle,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity( _isAppBarScrolled ? 0.88 : 0,
            ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'scenario-lab-appbar-blur-on',
          offKey: 'scenario-lab-appbar-blur-off',
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
        ),
      ),
      body: resultAsync.when(
        loading: () =>
            const AppShimmerSkeleton(variant: AppShimmerVariant.dashboard),
        // Was a raw developer string ("Scenario error: $error"). Now a calm,
        // user-facing error state with a retry instead of leaking the exception.
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppErrorState(
              title: l10n.scenarioRunError,
              message: l10n.scenarioRunErrorMessage,
              actionLabel: l10n.commonRetry,
              onAction: () => ref.invalidate(scenarioLabResultProvider),
            ),
          ),
        ),
        data: (result) {
          final input = ref.watch(scenarioLabControllerProvider);
          final currency = NumberFormat.currency(
            symbol: '${result.currencyCode} ',
            decimalDigits: 0,
          );

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                _updateAppBarScrollState(notification.metrics.pixels);
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Header(),
                      const SizedBox(height: 16),
                      _PresetChips(
                        selectedPreset: input.selectedPreset,
                        onPresetTap: (type) {
                          final base = baseDataAsync.valueOrNull;
                          if (base == null) return;
                          controller.applyPreset(base, type);
                        },
                      ),
                      const SizedBox(height: 16),
                      _CurrentVsSimulatedSummary(
                        result: result,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      _LifestyleAdjustments(
                        result: result,
                        currency: currency,
                        onChanged: (adjustment, value) {
                          controller.setCategoryAmount(
                            adjustment.category,
                            adjustment.currentMonthlyAmount,
                            value,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _TimelineForecast(
                        result: result,
                        selectedMonths: input.timelineMonths,
                        currency: currency,
                        onMonthsChanged: controller.setTimelineMonths,
                      ),
                      const SizedBox(height: 16),
                      _FinancialStressMeter(result: result),
                      const SizedBox(height: 16),
                      _GoalImpact(result: result, currency: currency),
                      const SizedBox(height: 16),
                      _RiskEvents(
                        result: result,
                        selected: input.enabledRiskEvents,
                        onToggle: controller.toggleRiskEvent,
                      ),
                      const SizedBox(height: 16),
                      _ProbabilityForecastSection(result: result),
                      const SizedBox(height: 16),
                      _BehavioralNudgesSection(result: result),
                      const SizedBox(height: 16),
                      _Recommendations(
                        result: result,
                        currency: currency,
                        onActionTap: (actionType) =>
                            _performAction(context, actionType),
                      ),
                      const SizedBox(height: 16),
                      _SmartActions(
                        onTap: (action) => _performAction(context, action),
                      ),
                      SizedBox(
                        height: 24 + MediaQuery.paddingOf(context).bottom,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _performAction(BuildContext context, ScenarioActionType action) {
    switch (action) {
      case ScenarioActionType.openBudgetAdjustment:
        context.go('/budgets');
        break;
      case ScenarioActionType.createSavingsRule:
        context.go('/savings');
        break;
      case ScenarioActionType.reviewSubscriptions:
        context.go('/subscriptions');
        break;
      case ScenarioActionType.openRecurringBalanceSheet:
        context.go('/balance-sheet');
        break;
      case ScenarioActionType.openTransactionsByCategory:
        context.go('/transactions');
        break;
      case ScenarioActionType.openSavingsGoal:
        context.go('/savings');
        break;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SmartCard(
      radius: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity( 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const AppLottieView(
              assetPath: 'assets/animations/scenario_simulation.json',
              width: 44,
              height: 44,
              repeat: false,
              animate: false,
              fallbackIcon: Icons.science_rounded,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scenario Lab',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Model life changes — a raise, higher rent, fewer subscriptions — and see the impact before you commit.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.selectedPreset,
    required this.onPresetTap,
  });

  final ScenarioPresetType? selectedPreset;
  final ValueChanged<ScenarioPresetType> onPresetTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SmartCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try a preset',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final preset = ScenarioEngine.presets[index];
                return ChoiceChip(
                  label: Text(preset.type.label.replaceAll(' Mode', '')),
                  selected: selectedPreset == preset.type,
                  onSelected: (_) => onPresetTap(preset.type),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: ScenarioEngine.presets.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentVsSimulatedSummary extends StatelessWidget {
  const _CurrentVsSimulatedSummary({
    required this.result,
    required this.currency,
  });

  final ScenarioResult result;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final delta = result.comparison.simulatedMonthlyCashflow -
        result.comparison.currentMonthlyCashflow;
    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current vs Simulated',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const AppLottieView(
                assetPath: 'assets/animations/scenario_simulation.json',
                width: 42,
                height: 42,
                repeat: false,
                animate: false,
                fallbackIcon: Icons.auto_graph_rounded,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  delta >= 0
                      ? 'Simulation improves projected balance by ${currency.format(delta)}.'
                      : 'Simulation reduces projected balance by ${currency.format(delta.abs())}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CompactMetric(
                label: l10n.scenarioMetricMonthlyCashflow,
                currentValue:
                    currency.format(result.comparison.currentMonthlyCashflow),
                simulatedValue:
                    currency.format(result.comparison.simulatedMonthlyCashflow),
              ),
              _CompactMetric(
                label: l10n.scenarioMetricSavingsRate,
                currentValue:
                    '${(result.comparison.currentSavingsRate * 100).toStringAsFixed(1)}%',
                simulatedValue:
                    '${(result.comparison.simulatedSavingsRate * 100).toStringAsFixed(1)}%',
              ),
              _CompactMetric(
                label: l10n.scenarioMetricSubscriptionBurden,
                currentValue:
                    '${(result.comparison.currentSubscriptionBurden * 100).toStringAsFixed(1)}%',
                simulatedValue:
                    '${(result.comparison.simulatedSubscriptionBurden * 100).toStringAsFixed(1)}%',
              ),
              _CompactMetric(
                label: l10n.scenarioMetricEmergencyRunway,
                currentValue:
                    '${result.comparison.currentEmergencyRunwayDays} days',
                simulatedValue:
                    '${result.comparison.simulatedEmergencyRunwayDays} days',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.currentValue,
    required this.simulatedValue,
  });

  final String label;
  final String currentValue;
  final String simulatedValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 185,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            l10n.scenarioCurrent(currentValue),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(l10n.scenarioSim(simulatedValue),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LifestyleAdjustments extends StatelessWidget {
  const _LifestyleAdjustments({
    required this.result,
    required this.currency,
    required this.onChanged,
  });

  final ScenarioResult result;
  final NumberFormat currency;
  final void Function(ScenarioCategoryAdjustment adjustment, double value)
      onChanged;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifestyle Category Simulation',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...result.categoryAdjustments.map((adjustment) {
            final max = (adjustment.currentMonthlyAmount * 2.2)
                .clamp(50, 150000)
                .toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          adjustment.category.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        '${adjustment.percentageChange >= 0 ? '+' : ''}${adjustment.percentageChange.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current ${currency.format(adjustment.currentMonthlyAmount)} | Simulated ${currency.format(adjustment.simulatedMonthlyAmount)} | Cashflow impact ${currency.format(adjustment.impactOnCashflow)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Slider(
                    value: adjustment.simulatedMonthlyAmount.clamp(0, max),
                    max: max,
                    onChanged: (value) => onChanged(adjustment, value),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineForecast extends StatelessWidget {
  const _TimelineForecast({
    required this.result,
    required this.selectedMonths,
    required this.currency,
    required this.onMonthsChanged,
  });

  final ScenarioResult result;
  final int selectedMonths;
  final NumberFormat currency;
  final ValueChanged<int> onMonthsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedPoint = result.timeline.firstWhere(
      (point) => point.months == selectedMonths,
      orElse: () => result.timeline.first,
    );

    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline Forecast',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final month in const [1, 3, 6, 12])
                ChoiceChip(
                  label: Text('${month}M'),
                  selected: selectedMonths == month,
                  onSelected: (_) => onMonthsChanged(month),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Projected surplus/deficit: ${currency.format(selectedPoint.projectedSurplusOrDeficit)}',
          ),
          Text(
              'Savings growth: ${currency.format(selectedPoint.savingsGrowth)}'),
          Text(l10n.scenarioEmergencyRunway('${selectedPoint.emergencyRunwayDays}')),
          Text(
              'Debt pressure: ${(selectedPoint.debtPressure * 100).toStringAsFixed(1)}%'),
          Text(
              'Recurring burden: ${(selectedPoint.recurringBurden * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

class _FinancialStressMeter extends StatelessWidget {
  const _FinancialStressMeter({required this.result});

  final ScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final score = result.stressScore;
    final color = switch (score.status) {
      FinancialStressState.low => Colors.green,
      FinancialStressState.moderate => Colors.orange,
      FinancialStressState.high => Colors.deepOrange,
      FinancialStressState.critical => Colors.red,
    };

    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Stress Meter',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(l10n.scenarioStatus(score.status.name.toUpperCase())),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score.score / 100,
            color: color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(l10n.scenarioScore('${score.score}')),
          Text(l10n.scenarioPressure(score.financialPressure.toStringAsFixed(1))),
          Text(l10n.scenarioBurnRateRisk(score.burnRateRisk.toStringAsFixed(1))),
          Text(
              'Obligation burden ${score.obligationBurden.toStringAsFixed(1)}'),
          Text(l10n.scenarioResilience(score.cashflowResilience.toStringAsFixed(1))),
        ],
      ),
    );
  }
}

class _GoalImpact extends StatelessWidget {
  const _GoalImpact({required this.result, required this.currency});

  final ScenarioResult result;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (result.goalForecasts.isEmpty) {
      return SmartCard(
        radius: 24,
        child: Text(l10n.scenarioNoSavingsGoals),
      );
    }

    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal Impact',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...result.goalForecasts.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.goalTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current: ${goal.currentMonthsRemaining?.toString() ?? 'N/A'} months | '
                    'Scenario: ${goal.simulatedMonthsRemaining?.toString() ?? 'N/A'} months',
                  ),
                  Text(
                    'Saved/Delayed: ${goal.monthsSavedOrDelayed} months | '
                    'Required: ${currency.format(goal.requiredMonthlyContribution)}/month',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskEvents extends StatelessWidget {
  const _RiskEvents({
    required this.result,
    required this.selected,
    required this.onToggle,
  });

  final ScenarioResult result;
  final Set<ScenarioRiskEventType> selected;
  final ValueChanged<ScenarioRiskEventType> onToggle;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Events',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.riskEvents.map((event) {
              return FilterChip(
                label: Text(event.type.label),
                selected: selected.contains(event.type),
                onSelected: (_) => onToggle(event.type),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
              'Emergency runway under income loss: ${result.emergencyRunway.withIncomeLossDays} days'),
          Text(
              'Runway with unexpected expense: ${result.emergencyRunway.withUnexpectedExpenseDays} days'),
        ],
      ),
    );
  }
}

class _ProbabilityForecastSection extends StatelessWidget {
  const _ProbabilityForecastSection({required this.result});

  final ScenarioResult result;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Probability Forecasts',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Likelihood of next-month deficit: ${(result.probabilities.nextMonthDeficitLikelihood * 100).toStringAsFixed(0)}%',
          ),
          Text(
            'Chance of reaching savings goals: ${(result.probabilities.goalReachLikelihood * 100).toStringAsFixed(0)}%',
          ),
          Text(
            'Risk of recurring shortfall: ${(result.probabilities.recurringShortfallRisk * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }
}

class _BehavioralNudgesSection extends StatelessWidget {
  const _BehavioralNudgesSection({required this.result});

  final ScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavioral Nudges',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (result.behavioralAnalysis.nudges.isEmpty)
            Text(l10n.scenarioNoBehavioralRisks)
          else
            ...result.behavioralAnalysis.nudges.map(
              (nudge) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $nudge'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({
    required this.result,
    required this.currency,
    required this.onActionTap,
  });

  final ScenarioResult result;
  final NumberFormat currency;
  final ValueChanged<ScenarioActionType> onActionTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (result.recommendations.isEmpty)
            Text(l10n.scenarioNoRecommendations)
          else
            ...result.recommendations.map(
              (rec) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recTitle(l10n, rec.code),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(_recReason(l10n, rec)),
                    const SizedBox(height: 4),
                    Text(_recAction(l10n, rec)),
                    const SizedBox(height: 6),
                    Text(
                      l10n.scenarioEstimatedImpact(
                          currency.format(rec.impactValue)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => onActionTap(rec.actionType),
                        child: Text(l10n.commonOpen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmartActions extends StatelessWidget {
  const _SmartActions({required this.onTap});

  final ValueChanged<ScenarioActionType> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SmartCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => onTap(ScenarioActionType.openBudgetAdjustment),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(l10n.scenarioActionAdjustBudget),
              ),
              OutlinedButton.icon(
                onPressed: () => onTap(ScenarioActionType.createSavingsRule),
                icon: const Icon(Icons.savings_rounded, size: 18),
                label: Text(l10n.scenarioActionSavingsRule),
              ),
              OutlinedButton.icon(
                onPressed: () => onTap(ScenarioActionType.reviewSubscriptions),
                icon: const Icon(Icons.autorenew_rounded, size: 18),
                label: Text(l10n.scenarioActionReviewSubs),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    onTap(ScenarioActionType.openRecurringBalanceSheet),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text(l10n.scenarioActionOpenBalanceSheet),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    onTap(ScenarioActionType.openTransactionsByCategory),
                icon: const Icon(Icons.category_rounded, size: 18),
                label: Text(l10n.scenarioActionTxByCategory),
              ),
              OutlinedButton.icon(
                onPressed: () => onTap(ScenarioActionType.openSavingsGoal),
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: Text(l10n.scenarioActionOpenSavingsGoal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Localized recommendation copy (engine emits codes; UI resolves text) ---

String _recTitle(AppLocalizations l10n, ScenarioRecommendationCode c) {
  switch (c) {
    case ScenarioRecommendationCode.subscriptionBurden:
      return l10n.scenarioRecSubBurdenTitle;
    case ScenarioRecommendationCode.optimizeFood:
      return l10n.scenarioRecFoodTitle;
    case ScenarioRecommendationCode.breakEvenGap:
      return l10n.scenarioRecBreakEvenTitle;
    case ScenarioRecommendationCode.emergencyRunway:
      return l10n.scenarioRecRunwayTitle;
    case ScenarioRecommendationCode.debtAcceleration:
      return l10n.scenarioRecDebtTitle;
    case ScenarioRecommendationCode.deficitProbability:
      return l10n.scenarioRecDeficitTitle;
  }
}

String _recReason(AppLocalizations l10n, ScenarioRecommendation r) {
  switch (r.code) {
    case ScenarioRecommendationCode.subscriptionBurden:
      return l10n.scenarioRecSubBurdenReason(r.reasonParam);
    case ScenarioRecommendationCode.optimizeFood:
      return l10n.scenarioRecFoodReason(r.reasonParam);
    case ScenarioRecommendationCode.breakEvenGap:
      return l10n.scenarioRecBreakEvenReason(r.reasonParam);
    case ScenarioRecommendationCode.emergencyRunway:
      return l10n.scenarioRecRunwayReason;
    case ScenarioRecommendationCode.debtAcceleration:
      return l10n.scenarioRecDebtReason;
    case ScenarioRecommendationCode.deficitProbability:
      return l10n.scenarioRecDeficitReason(r.reasonParam);
  }
}

String _recAction(AppLocalizations l10n, ScenarioRecommendation r) {
  switch (r.code) {
    case ScenarioRecommendationCode.subscriptionBurden:
      return l10n.scenarioRecSubBurdenAction;
    case ScenarioRecommendationCode.optimizeFood:
      return l10n.scenarioRecFoodAction;
    case ScenarioRecommendationCode.breakEvenGap:
      return l10n.scenarioRecBreakEvenAction;
    case ScenarioRecommendationCode.emergencyRunway:
      return l10n.scenarioRecRunwayAction;
    case ScenarioRecommendationCode.debtAcceleration:
      return l10n.scenarioRecDebtAction(r.actionParam);
    case ScenarioRecommendationCode.deficitProbability:
      return l10n.scenarioRecDeficitAction;
  }
}
