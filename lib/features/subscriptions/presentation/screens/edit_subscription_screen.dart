import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';

class EditSubscriptionScreen extends ConsumerWidget {
  final String subscriptionId;

  const EditSubscriptionScreen({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider(subscriptionId));

    return subscriptionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Edit Subscription')),
        body: Center(child: Text('Error loading subscription: $error')),
      ),
      data: (subscription) {
        if (subscription == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Subscription')),
            body: const Center(child: Text('Subscription not found')),
          );
        }

        return AddSubscriptionScreen(existingSubscription: subscription);
      },
    );
  }
}
