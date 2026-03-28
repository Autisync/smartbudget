import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/data/models/tables.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionListProvider);
    final dueSubscriptionsAsync = ref.watch(dueSubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/subscriptions/add'),
          ),
        ],
      ),
      body: subscriptionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (subscriptions) => Column(
          children: [
            // Due subscriptions section
            dueSubscriptionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (dueSubscriptions) {
                if (dueSubscriptions.isEmpty) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Due This Month',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...dueSubscriptions.map((subscription) => ListTile(
                            title: Text(subscription.name),
                            subtitle: Text(
                              '${subscription.currency} ${subscription.amount.toStringAsFixed(2)} - Due ${DateFormat('MMM dd').format(subscription.nextBillingDate)}',
                            ),
                            trailing: Text(
                              _getBillingCycleText(subscription.billingCycle),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),

            // All subscriptions list
            Expanded(
              child: subscriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subscriptions_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subscriptions yet',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first subscription to start tracking',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context.go('/subscriptions/add'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Subscription'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: subscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription = subscriptions[index];
                        return SubscriptionCard(subscription: subscription);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBillingCycleText(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }
}

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionCard({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: subscription.currency);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          subscription.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${currencyFormat.format(subscription.amount)} per ${_getBillingCycleText(subscription.billingCycle)}',
            ),
            Text(
              'Next billing: ${DateFormat('MMM dd, yyyy').format(subscription.nextBillingDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (subscription.category.isNotEmpty)
              Chip(
                label: Text(
                  subscription.category,
                  style: const TextStyle(fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currencyFormat.format(_getMonthlyCost(subscription)),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'per month',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () => context.go('/subscriptions/${subscription.id}'),
      ),
    );
  }

  String _getBillingCycleText(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return 'week';
      case BillingCycle.monthly:
        return 'month';
      case BillingCycle.quarterly:
        return 'quarter';
      case BillingCycle.yearly:
        return 'year';
    }
  }

  double _getMonthlyCost(Subscription subscription) {
    switch (subscription.billingCycle) {
      case BillingCycle.weekly:
        return subscription.amount * 4.33; // Average weeks per month
      case BillingCycle.monthly:
        return subscription.amount;
      case BillingCycle.quarterly:
        return subscription.amount / 3;
      case BillingCycle.yearly:
        return subscription.amount / 12;
    }
  }
}
