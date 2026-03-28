import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/auth/presentation/providers/security_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
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
