import 'package:flutter/material.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

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
              'Spend reduction simulator',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Try preset reduction goals and compare the results.',
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
              'Projected monthly spend: ${currencyFormat.format(scenarioSpend)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Projected end balance: ${currencyFormat.format(scenarioEndBalance)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Potential savings: ${currencyFormat.format(improvement)}',
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
    final message = scenarioEndBalance >= 0
        ? 'This goal helps preserve your buffer and reduces risk.'
        : 'Even with this reduction, you may need deeper cuts to stay cash-positive.';
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
