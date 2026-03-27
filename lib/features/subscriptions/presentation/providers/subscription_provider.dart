import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/domain/entities/subscription.dart';

part 'subscription_provider.g.dart';

@riverpod
Future<List<Subscription>> subscriptionList(SubscriptionListRef ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getSubscriptions();
}

@riverpod
Future<List<Subscription>> dueSubscriptions(DueSubscriptionsRef ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getDueSubscriptions(DateTime.now());
}

@riverpod
Future<Subscription?> subscription(SubscriptionRef ref, String id) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getSubscription(id);
}
