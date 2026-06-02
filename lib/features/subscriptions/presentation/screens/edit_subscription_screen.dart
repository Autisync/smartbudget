import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class EditSubscriptionScreen extends ConsumerWidget {
  const EditSubscriptionScreen({
    super.key,
    required this.subscriptionId,
  });

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subscriptionAsync = ref.watch(subscriptionProvider(subscriptionId));

    return subscriptionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: buildFrostedAppBarTitle(
            context: context,
            title: l10n?.subscriptionsEditSubscription ?? 'Edit Subscription',
            isScrolled: false,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: buildFrostedFlexibleSpace(
            context: context,
            isScrolled: false,
            onKey: 'edit-subscription-appbar-blur-on',
            offKey: 'edit-subscription-appbar-blur-off',
          ),
          actions: buildPageHeaderActions(
            context: context,
            isScrolled: false,
          ),
        ),
        body: Center(
          child: Text(
            l10n?.subscriptionsLoadError(error.toString()) ??
                'Error loading subscription: $error',
          ),
        ),
      ),
      data: (subscription) {
        if (subscription == null) {
          return Scaffold(
            appBar: AppBar(
              title: buildFrostedAppBarTitle(
                context: context,
                title:
                    l10n?.subscriptionsEditSubscription ?? 'Edit Subscription',
                isScrolled: false,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: buildFrostedFlexibleSpace(
                context: context,
                isScrolled: false,
                onKey: 'edit-subscription-not-found-appbar-blur-on',
                offKey: 'edit-subscription-not-found-appbar-blur-off',
              ),
              actions: buildPageHeaderActions(
                context: context,
                isScrolled: false,
              ),
            ),
            body: Center(
              child:
                  Text(l10n?.subscriptionsNotFound ?? 'Subscription not found'),
            ),
          );
        }

        return SubscriptionFormSheet(
          mode: SubscriptionFormMode.update,
          initialData: subscription,
          asModal: true,
        );
      },
    );
  }
}
