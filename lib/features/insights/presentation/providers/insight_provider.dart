import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/insights/domain/models/insight.dart'
    as copilot;
import 'package:smartbudget/features/auth/presentation/providers/security_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/models/insight.dart' as intelligence;
import 'package:smartbudget/intelligence/models/insight_results.dart';
import 'package:smartbudget/intelligence/services/insight_engine.dart';

final insightResultsProvider = FutureProvider<InsightResults>((ref) async {
  final profile = await ref.watch(spendingProfileProvider.future);
  final forecast = await ref.watch(cashflowPredictionProvider.future);
  final history = await ref.watch(transactionListProvider().future);
  final subscriptions = await ref.watch(subscriptionListProvider.future);
  final securitySettings = await ref.watch(securitySettingProvider.future);

  final engine = const InsightEngine();
  return engine.buildResults(
    profile: profile,
    forecast: forecast,
    history: history,
    subscriptions: subscriptions,
    securitySetting: securitySettings,
  );
});

final insightsProvider = FutureProvider<List<copilot.Insight>>((ref) async {
  final results = await ref.watch(insightResultsProvider.future);
  return results.insights.map(_toCopilotInsight).toList(growable: false);
});

copilot.Insight _toCopilotInsight(intelligence.Insight insight) {
  final type = _toCopilotType(insight);
  return copilot.Insight(
    id: insight.id,
    title: insight.title,
    description: insight.explanation,
    type: type,
    impact: _toCopilotImpact(insight.severity),
    createdAt: DateTime.now(),
    actionLabel: insight.action,
    route: _routeForType(type),
    metadata: {
      'confidence': insight.confidence,
      'monthlyImpact': insight.impact,
    },
  );
}

copilot.InsightImpact _toCopilotImpact(
  intelligence.InsightSeverity severity,
) {
  return switch (severity) {
    intelligence.InsightSeverity.high => copilot.InsightImpact.high,
    intelligence.InsightSeverity.medium => copilot.InsightImpact.medium,
    intelligence.InsightSeverity.low => copilot.InsightImpact.low,
  };
}

copilot.InsightType _toCopilotType(intelligence.Insight insight) {
  final searchable =
      '${insight.id} ${insight.title} ${insight.explanation}'.toLowerCase();
  if (searchable.contains('subscription')) {
    return copilot.InsightType.subscription;
  }
  if (searchable.contains('budget')) {
    return copilot.InsightType.budget;
  }
  if (searchable.contains('saving') || searchable.contains('savings')) {
    return copilot.InsightType.saving;
  }
  return switch (insight.type) {
    intelligence.InsightType.forecast => copilot.InsightType.trend,
    intelligence.InsightType.anomaly => copilot.InsightType.spending,
    intelligence.InsightType.recommendation => copilot.InsightType.spending,
  };
}

String _routeForType(copilot.InsightType type) {
  return switch (type) {
    copilot.InsightType.spending => '/transactions',
    copilot.InsightType.saving => '/savings',
    copilot.InsightType.budget => '/budgets',
    copilot.InsightType.subscription => '/subscriptions',
    copilot.InsightType.trend => '/insights',
  };
}
