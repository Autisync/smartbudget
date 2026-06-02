import 'package:flutter/material.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/intelligence/models/insight.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;

  const InsightCard({super.key, required this.insight});

  Color get _severityColor {
    switch (insight.severity) {
      case InsightSeverity.high:
        return const Color(0xFFF57C00);
      case InsightSeverity.medium:
        return const Color(0xFF4B8BFF);
      case InsightSeverity.low:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = _severityColor;
    final icon = switch (insight.severity) {
      InsightSeverity.high => Icons.auto_awesome_rounded,
      InsightSeverity.medium => Icons.psychology_alt_rounded,
      InsightSeverity.low => Icons.tips_and_updates_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SmartInsightCard(
        title: insight.title,
        explanation: insight.explanation,
        impact: '${l10n.insightsImpact}: ${insight.impact}',
        action: '${l10n.insightsAction}: ${insight.action}',
        badge: '${(insight.confidence * 100).toStringAsFixed(0)}%',
        tone: tone,
        icon: icon,
      ),
    );
  }
}
