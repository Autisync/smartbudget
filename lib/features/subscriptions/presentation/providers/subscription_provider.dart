import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/domain/entities/subscription.dart';

part 'subscription_provider.g.dart';

class SubscriptionDisplayAmounts {
  const SubscriptionDisplayAmounts({
    required this.amount,
    required this.monthlyCost,
    required this.currencyCode,
  });

  final double amount;
  final double monthlyCost;
  final String currencyCode;
}

final subscriptionDisplayAmountsProvider =
    FutureProvider.family<Map<String, SubscriptionDisplayAmounts>, String>(
  (ref, targetCurrency) async {
    final subscriptions = await ref.watch(subscriptionListProvider.future);
    final exchangeRateService = ref.watch(exchangeRateServiceProvider);
    final normalizedTargetCurrency = targetCurrency.toUpperCase();
    final rates = <String, double>{};

    final sourceCurrencies = subscriptions
        .map((subscription) => subscription.currency.toUpperCase())
        .where((currencyCode) => currencyCode != normalizedTargetCurrency)
        .toSet();

    for (final sourceCurrency in sourceCurrencies) {
      final quote = await exchangeRateService.fetchRate(
        base: sourceCurrency,
        target: normalizedTargetCurrency,
      );
      rates[sourceCurrency] = quote.rate;
    }

    return {
      for (final subscription in subscriptions)
        subscription.id: SubscriptionDisplayAmounts(
          amount: _convertSubscriptionValue(
            amount: subscription.amount,
            sourceCurrency: subscription.currency,
            targetCurrency: normalizedTargetCurrency,
            rates: rates,
          ),
          monthlyCost: _convertSubscriptionValue(
            amount: subscription.monthlyCost,
            sourceCurrency: subscription.currency,
            targetCurrency: normalizedTargetCurrency,
            rates: rates,
          ),
          currencyCode: normalizedTargetCurrency,
        ),
    };
  },
);

double _convertSubscriptionValue({
  required double amount,
  required String sourceCurrency,
  required String targetCurrency,
  required Map<String, double> rates,
}) {
  final normalizedSourceCurrency = sourceCurrency.toUpperCase();
  if (normalizedSourceCurrency == targetCurrency) {
    return amount;
  }

  final rate = rates[normalizedSourceCurrency];
  if (rate == null) {
    throw Exception(
      'Missing exchange rate for $normalizedSourceCurrency to $targetCurrency.',
    );
  }

  return amount * rate;
}

@riverpod
class SubscriptionList extends _$SubscriptionList {
  @override
  Future<List<Subscription>> build() async {
    final repo = ref.watch(subscriptionRepositoryProvider);
    return repo.getSubscriptions();
  }

  Future<void> addSubscription(Subscription subscription) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(subscriptionRepositoryProvider)
          .addSubscription(subscription);
      return ref.read(subscriptionRepositoryProvider).getSubscriptions();
    });
  }

  Future<void> updateSubscription(Subscription subscription) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(subscriptionRepositoryProvider)
          .updateSubscription(subscription);
      return ref.read(subscriptionRepositoryProvider).getSubscriptions();
    });
  }

  Future<void> deleteSubscription(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(subscriptionRepositoryProvider).deleteSubscription(id);
      return ref.read(subscriptionRepositoryProvider).getSubscriptions();
    });
  }
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




