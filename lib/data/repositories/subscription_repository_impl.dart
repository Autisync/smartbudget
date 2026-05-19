import 'package:drift/drift.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';
import 'package:smartbudget/domain/entities/subscription.dart' as entity;
import 'package:smartbudget/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final AppDatabase database;

  SubscriptionRepositoryImpl(this.database);

  @override
  Future<List<entity.Subscription>> getSubscriptions() async {
    final subscriptions = await database.getSubscriptions();
    return subscriptions.map((s) => _mapToEntity(s)).toList();
  }

  @override
  Future<entity.Subscription?> getSubscription(String id) async {
    final subscription = await (database.select(database.subscriptions)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return subscription != null ? _mapToEntity(subscription) : null;
  }

  @override
  Future<void> addSubscription(entity.Subscription subscription) async {
    await database.insertSubscription(_mapToCompanion(subscription));
  }

  @override
  Future<void> updateSubscription(entity.Subscription subscription) async {
    await (database.update(database.subscriptions)
          ..where((s) => s.id.equals(subscription.id)))
        .write(_mapToCompanion(subscription));
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await (database.delete(database.subscriptions)
          ..where((s) => s.id.equals(id)))
        .go();
  }

  @override
  Future<List<entity.Subscription>> getDueSubscriptions(DateTime date) async {
    final subscriptions = await database.getDueSubscriptions(date);
    return subscriptions.map((s) => _mapToEntity(s)).toList();
  }

  entity.Subscription _mapToEntity(Subscription data) {
    return entity.Subscription(
      id: data.id,
      name: data.name,
      description: data.description,
      amount: data.amount,
      currency: data.currency,
      billingCycle: data.billingCycle,
      startDate: data.startDate,
      nextBillingDate: data.nextBillingDate,
      endDate: data.endDate,
      category: data.category,
      importance: data.importance,
      isActive: data.isActive,
      paymentMethod: data.paymentMethod,
      website: data.website,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  SubscriptionsCompanion _mapToCompanion(entity.Subscription subscription) {
    return SubscriptionsCompanion(
      id: subscription.id.isEmpty
          ? const Value.absent()
          : Value(subscription.id),
      name: Value(subscription.name),
      description: Value(subscription.description),
      amount: Value(subscription.amount),
      currency: Value(subscription.currency),
      billingCycle: Value(subscription.billingCycle),
      startDate: Value(subscription.startDate),
      nextBillingDate: Value(subscription.nextBillingDate),
      endDate: Value(subscription.endDate),
      category: Value(subscription.category),
      importance: Value(subscription.importance),
      isActive: Value(subscription.isActive),
      paymentMethod: Value(subscription.paymentMethod),
      website: Value(subscription.website),
      createdAt: Value(subscription.createdAt),
      updatedAt: Value(subscription.updatedAt),
    );
  }
}




