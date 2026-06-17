import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class SimulationCard extends StatefulWidget {
  final CashflowPrediction forecast;
  final SpendingProfile profile;
  final String currency;

  const SimulationCard({
    super.key,
    required this.forecast,
    required this.profile,
    required this.currency,
  });

  @override
  State<SimulationCard> createState() => _SimulationCardState();
}

class _SimulationCardState extends State<SimulationCard> {
  double _reduction = 0.1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scenarioSpend =
        widget.forecast.projectedMonthlySpend * (1.0 - _reduction);
    final balanceImprovement =
        widget.forecast.projectedMonthlySpend - scenarioSpend;
    final scenarioEndBalance =
        widget.forecast.projectedEndBalance + balanceImprovement;
    final currencyFormat = CurrencyUtils.getFormat(widget.currency);

    final presets = [0.1, 0.2, 0.3, 0.4];
    final improvement = scenarioSpend < widget.forecast.projectedMonthlySpend
        ? widget.forecast.projectedMonthlySpend - scenarioSpend
        : 0.0;

    return SmartCard(
      radius: 28,
      color: const Color(0xFF7A6CF6).withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartSpendHeader(
            title: l10n.scenarioLabTitle,
            subtitle: l10n.simulationSpendReductionSubtitle,
            trailing: AppBadge(
              label: '${(_reduction * 100).round()}% cut',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              return ChoiceChip(
                label: Text('${(preset * 100).round()}%'),
                selected: _reduction == preset,
                onSelected: (_) => setState(() => _reduction = preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.35),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _reduction,
              min: 0,
              max: 0.4,
              divisions: 4,
              label: '${(_reduction * 100).round()}%',
              onChanged: (value) => setState(() => _reduction = value),
            ),
          ),
          const SizedBox(height: 12),
          _ScenarioMetricRow(
            label: l10n.simLabelProjectedMonthlySpend,
            value: currencyFormat.format(scenarioSpend),
          ),
          const SizedBox(height: 8),
          _ScenarioMetricRow(
            label: l10n.simLabelProjectedEndBalance,
            value: currencyFormat.format(scenarioEndBalance),
          ),
          const SizedBox(height: 8),
          _ScenarioMetricRow(
            label: l10n.simLabelPotentialSavings,
            value: currencyFormat.format(improvement),
            tone: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: 14),
          _buildRecommendation(context, scenarioEndBalance),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/scenario-lab'),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(l10n.scenarioOpenFull),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context, double scenarioEndBalance) {
    final l10n = AppLocalizations.of(context)!;
    final message = scenarioEndBalance >= 0
        ? l10n.simulationRecommendationPositive
        : l10n.simulationRecommendationNegative;
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ScenarioMetricRow extends StatelessWidget {
  const _ScenarioMetricRow({
    required this.label,
    required this.value,
    this.tone,
  });

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: tone,
              ),
        ),
      ],
    );
  }
}
