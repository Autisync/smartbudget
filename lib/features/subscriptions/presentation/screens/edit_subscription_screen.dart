import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';

class EditSubscriptionScreen extends ConsumerWidget {
  final String subscriptionId;

  const EditSubscriptionScreen({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subscriptionAsync = ref.watch(subscriptionProvider(subscriptionId));

    return subscriptionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
            title: BrandedTitle(label: l10n.subscriptionsEditSubscription)),
        body:
            Center(child: Text(l10n.subscriptionsLoadError(error.toString()))),
      ),
      data: (subscription) {
        if (subscription == null) {
          return Scaffold(
            appBar: AppBar(
                title: BrandedTitle(label: l10n.subscriptionsEditSubscription)),
            body: Center(child: Text(l10n.subscriptionsNotFound)),
          );
        }

        return AddSubscriptionScreen(existingSubscription: subscription);
      },
    );
  }
}
