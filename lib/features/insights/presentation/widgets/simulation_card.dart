import 'package:flutter/material.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: AppSurfaces.elevated(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.simulationSpendReductionTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.simulationSpendReductionSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              children: presets.map((preset) {
                return ChoiceChip(
                  label: Text('${(preset * 100).round()}%'),
                  selected: _reduction == preset,
                  onSelected: (_) => setState(() => _reduction = preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _reduction,
              min: 0,
              max: 0.4,
              divisions: 4,
              label: '${(_reduction * 100).round()}%',
              onChanged: (value) => setState(() => _reduction = value),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.simulationProjectedMonthlySpend(
                currencyFormat.format(scenarioSpend),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.simulationProjectedEndBalance(
                currencyFormat.format(scenarioEndBalance),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.simulationPotentialSavings(
                currencyFormat.format(improvement),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildRecommendation(context, scenarioEndBalance),
          ],
        ),
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
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
