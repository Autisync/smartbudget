import 'package:drift/drift.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';
import 'package:smartbudget/data/encryption/field_encryptor.dart';
import 'package:smartbudget/domain/entities/subscription.dart' as entity;
import 'package:smartbudget/domain/repositories/subscription_repository.dart';
import 'package:smartbudget/core/utils/money_utils.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final AppDatabase database;
  final FieldEncryptor? encryptor;

  // C-2: [encryptor] is optional for backwards-compat; always provide it in prod.
  SubscriptionRepositoryImpl(this.database, {this.encryptor});

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
    // C-2: decrypt sensitive free-text fields; plaintext fallback for legacy records.
    return entity.Subscription(
      id: data.id,
      name: data.name,
      description: encryptor?.decryptNullable(data.description) ?? data.description,
      amount: data.amount,
      currency: data.currency,
      billingCycle: data.billingCycle,
      startDate: data.startDate,
      nextBillingDate: data.nextBillingDate,
      endDate: data.endDate,
      category: data.category,
      importance: data.importance,
      isActive: data.isActive,
      paymentMethod: encryptor?.decryptNullable(data.paymentMethod) ?? data.paymentMethod,
      website: encryptor?.decryptNullable(data.website) ?? data.website,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  SubscriptionsCompanion _mapToCompanion(entity.Subscription subscription) {
    // C-2: encrypt sensitive free-text fields before persisting to SQLite.
    return SubscriptionsCompanion(
      id: subscription.id.isEmpty
          ? const Value.absent()
          : Value(subscription.id),
      name: Value(subscription.name),
      description: Value(encryptor?.encryptNullable(subscription.description) ?? subscription.description),
      amount:
          Value(MoneyUtils.quantize(subscription.amount, subscription.currency)),
      currency: Value(subscription.currency),
      billingCycle: Value(subscription.billingCycle),
      startDate: Value(subscription.startDate),
      nextBillingDate: Value(subscription.nextBillingDate),
      endDate: Value(subscription.endDate),
      category: Value(subscription.category),
      importance: Value(subscription.importance),
      isActive: Value(subscription.isActive),
      paymentMethod: Value(encryptor?.encryptNullable(subscription.paymentMethod) ?? subscription.paymentMethod),
      website: Value(encryptor?.encryptNullable(subscription.website) ?? subscription.website),
      createdAt: Value(subscription.createdAt),
      updatedAt: Value(subscription.updatedAt),
    );
  }
}




