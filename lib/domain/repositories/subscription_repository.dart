import 'package:smartbudget/domain/entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> getSubscriptions();
  Future<Subscription?> getSubscription(String id);
  Future<void> addSubscription(Subscription subscription);
  Future<void> updateSubscription(Subscription subscription);
  Future<void> deleteSubscription(String id);
  Future<List<Subscription>> getDueSubscriptions(DateTime date);
}