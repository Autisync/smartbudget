import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

enum _SubscriptionFilter {
  critical,
  renewingSoon,
  highPriority,
  lowPriority,
}

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  bool _isAppBarScrolled = false;
  _SubscriptionFilter? _activeFilter;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  String _buildDecisionMessage({
    required int criticalCount,
    required int renewingSoonCount,
    required double lowPriorityMonthlyCost,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (renewingSoonCount > 0 && criticalCount > 0) {
      return l10n.subscriptionsDecisionRenewingCritical(renewingSoonCount);
    }
    if (renewingSoonCount > 0) {
      return l10n.subscriptionsDecisionRenewing(renewingSoonCount);
    }
    if (lowPriorityMonthlyCost > 0) {
      return l10n.subscriptionsDecisionLowPriorityCost(
          lowPriorityMonthlyCost.toStringAsFixed(0));
    }
    if (criticalCount > 0) {
      return l10n.subscriptionsDecisionCritical(criticalCount);
    }
    return l10n.subscriptionsDecisionStable;
  }

  List<Subscription> _filterSubscriptions(
    List<Subscription> subscriptions,
    DateTime today,
    DateTime nextWeek,
  ) {
    switch (_activeFilter) {
      case _SubscriptionFilter.critical:
        return subscriptions
            .where(
              (subscription) =>
                  subscription.importance == SubscriptionImportance.critical,
            )
            .toList();
      case _SubscriptionFilter.renewingSoon:
        return subscriptions.where((subscription) {
          final renewalDate = DateTime(
            subscription.nextBillingDate.year,
            subscription.nextBillingDate.month,
            subscription.nextBillingDate.day,
          );
          return !renewalDate.isBefore(today) && !renewalDate.isAfter(nextWeek);
        }).toList();
      case _SubscriptionFilter.highPriority:
        return subscriptions
            .where(
              (subscription) =>
                  subscription.importance == SubscriptionImportance.high ||
                  subscription.importance == SubscriptionImportance.critical,
            )
            .toList();
      case _SubscriptionFilter.lowPriority:
        return subscriptions
            .where(
              (subscription) =>
                  subscription.importance == SubscriptionImportance.low,
            )
            .toList();
      case null:
        return subscriptions;
    }
  }

  String _filterLabel(_SubscriptionFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    switch (filter) {
      case _SubscriptionFilter.critical:
        return l10n.subscriptionsFilterCritical;
      case _SubscriptionFilter.renewingSoon:
        return l10n.subscriptionsFilterRenewingSoon;
      case _SubscriptionFilter.highPriority:
        return l10n.subscriptionsFilterHighPriority;
      case _SubscriptionFilter.lowPriority:
        return l10n.subscriptionsFilterLowPriority;
    }
  }

  void _toggleFilter(_SubscriptionFilter filter) {
    setState(() {
      _activeFilter = _activeFilter == filter ? null : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final subscriptionsAsync = ref.watch(subscriptionListProvider);
    final dueSubscriptionsAsync = ref.watch(dueSubscriptionsProvider);
    final convertedAmounts = ref
        .watch(subscriptionDisplayAmountsProvider(appCurrency))
        .asData
        ?.value;
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: BrandedTitle(label: l10n.navSubscriptions),
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isAppBarScrolled
                  ? ClipRect(
                      key: const ValueKey('subscriptions-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('subscriptions-appbar-blur-off'),
                    ),
            ),
          ],
        ),
        actions: [
          NotificationBellButton(
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: subscriptionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(l10n.transactionsError(error.toString())),
          ),
          data: (subscriptions) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final nextWeek = today.add(const Duration(days: 7));
            final filteredSubscriptions =
                _filterSubscriptions(subscriptions, today, nextWeek);
            final currencySymbol = subscriptions.isEmpty
                ? CurrencyUtils.symbol(appCurrency)
                : CurrencyUtils.symbol(
                    convertedAmounts != null
                        ? appCurrency
                        : subscriptions.first.currency,
                  );
            double displayAmountFor(Subscription subscription) {
              return convertedAmounts?[subscription.id]?.amount ??
                  subscription.amount;
            }

            double displayMonthlyCostFor(Subscription subscription) {
              return convertedAmounts?[subscription.id]?.monthlyCost ??
                  subscription.monthlyCost;
            }

            String displayCurrencyFor(Subscription subscription) {
              return convertedAmounts?[subscription.id]?.currencyCode ??
                  subscription.currency;
            }

            final criticalCount = subscriptions
                .where(
                  (subscription) =>
                      subscription.importance ==
                      SubscriptionImportance.critical,
                )
                .length;
            final renewingSoonCount = subscriptions.where((subscription) {
              final renewalDate = DateTime(
                subscription.nextBillingDate.year,
                subscription.nextBillingDate.month,
                subscription.nextBillingDate.day,
              );
              return !renewalDate.isBefore(today) &&
                  !renewalDate.isAfter(nextWeek);
            }).length;
            final highPriorityCount = subscriptions
                .where(
                  (subscription) =>
                      subscription.importance == SubscriptionImportance.high ||
                      subscription.importance ==
                          SubscriptionImportance.critical,
                )
                .length;
            final monthlyLoad = subscriptions.fold<double>(
              0,
              (sum, subscription) => sum + displayMonthlyCostFor(subscription),
            );
            final lowPriorityMonthlyCost = subscriptions
                .where(
                  (subscription) =>
                      subscription.importance == SubscriptionImportance.low,
                )
                .fold<double>(
                  0,
                  (sum, subscription) =>
                      sum + displayMonthlyCostFor(subscription),
                );

            return Column(
              children: [
                if (subscriptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: _SubscriptionDecisionSummary(
                      criticalCount: criticalCount,
                      renewingSoonCount: renewingSoonCount,
                      highPriorityCount: highPriorityCount,
                      monthlyLoad: monthlyLoad,
                      lowPriorityMonthlyCost: lowPriorityMonthlyCost,
                      currencySymbol: currencySymbol,
                      activeFilter: _activeFilter,
                      onFilterSelected: _toggleFilter,
                      message: _buildDecisionMessage(
                        criticalCount: criticalCount,
                        renewingSoonCount: renewingSoonCount,
                        lowPriorityMonthlyCost: lowPriorityMonthlyCost,
                      ),
                    ),
                  ),

                // Due subscriptions section
                dueSubscriptionsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                  data: (dueSubscriptions) {
                    final filteredDueSubscriptions =
                        _filterSubscriptions(dueSubscriptions, today, nextWeek);
                    if (filteredDueSubscriptions.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      padding: const EdgeInsets.all(16),
                      decoration: AppSurfaces.elevated(
                        context,
                        radius: 24,
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.72),
                        opacity: 0.06,
                      ),
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
                                l10n.subscriptionsDueThisMonth,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          if (_activeFilter != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.subscriptionsFilteredTo(
                                  _filterLabel(_activeFilter!).toLowerCase()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          ...filteredDueSubscriptions
                              .map((subscription) => ListTile(
                                    title: Text(subscription.name),
                                    subtitle: Text(
                                      l10n.subscriptionsDueLine(
                                        CurrencyUtils.formatAmount(
                                          displayAmountFor(subscription),
                                          displayCurrencyFor(subscription),
                                        ),
                                        DateFormat('MMM dd').format(
                                          subscription.nextBillingDate,
                                        ),
                                      ),
                                    ),
                                    trailing: Text(
                                      _getBillingCycleText(
                                        subscription.billingCycle,
                                      ),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
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
                                l10n.subscriptionsEmpty,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.subscriptionsEmptySubtitle,
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
                              SizedBox(
                                width: (MediaQuery.sizeOf(context).width - 48)
                                    .clamp(220.0, 320.0)
                                    .toDouble(),
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      context.push('/subscriptions/add'),
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.subscriptionsAdd),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            if (_activeFilter != null)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.subscriptionsShowing(
                                            filteredSubscriptions.length,
                                            _filterLabel(_activeFilter!)
                                                .toLowerCase()),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _activeFilter = null;
                                      }),
                                      child: Text(l10n.transactionsClear),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: filteredSubscriptions.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.filter_alt_off,
                                              size: 40,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              l10n.transactionsNoMatching,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              l10n.transactionsTryDifferentFilter,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.only(
                                        bottom: 88 +
                                            MediaQuery.paddingOf(context)
                                                .bottom,
                                      ),
                                      itemCount: filteredSubscriptions.length,
                                      itemBuilder: (context, index) {
                                        final subscription =
                                            filteredSubscriptions[index];
                                        return SubscriptionCard(
                                          subscription: subscription,
                                          displayAmount:
                                              displayAmountFor(subscription),
                                          displayMonthlyCost:
                                              displayMonthlyCostFor(
                                            subscription,
                                          ),
                                          displayCurrencyCode:
                                              displayCurrencyFor(subscription),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/subscriptions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getBillingCycleText(BillingCycle cycle) {
    final l10n = AppLocalizations.of(context)!;
    switch (cycle) {
      case BillingCycle.weekly:
        return l10n.subscriptionsBillingWeekly;
      case BillingCycle.monthly:
        return l10n.subscriptionsBillingMonthly;
      case BillingCycle.quarterly:
        return l10n.subscriptionsBillingQuarterly;
      case BillingCycle.yearly:
        return l10n.subscriptionsBillingYearly;
    }
  }
}

class _SubscriptionDecisionSummary extends StatelessWidget {
  final int criticalCount;
  final int renewingSoonCount;
  final int highPriorityCount;
  final double monthlyLoad;
  final double lowPriorityMonthlyCost;
  final String currencySymbol;
  final String message;
  final _SubscriptionFilter? activeFilter;
  final ValueChanged<_SubscriptionFilter> onFilterSelected;

  const _SubscriptionDecisionSummary({
    required this.criticalCount,
    required this.renewingSoonCount,
    required this.highPriorityCount,
    required this.monthlyLoad,
    required this.lowPriorityMonthlyCost,
    required this.currencySymbol,
    required this.message,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppSurfaces.elevated(
        context,
        radius: 24,
        color: colorScheme.surfaceContainerHigh,
        opacity: 0.06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.insightsDecisionSnapshot,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SubscriptionSummaryChip(
                icon: Icons.priority_high_rounded,
                label: l10n.subscriptionsFilterCritical,
                value: '$criticalCount',
                tone: colorScheme.error,
                isSelected: activeFilter == _SubscriptionFilter.critical,
                onTap: () => onFilterSelected(_SubscriptionFilter.critical),
              ),
              _SubscriptionSummaryChip(
                icon: Icons.event_repeat_rounded,
                label: l10n.subscriptionsNext7Days,
                value: '$renewingSoonCount',
                tone: colorScheme.tertiary,
                isSelected: activeFilter == _SubscriptionFilter.renewingSoon,
                onTap: () => onFilterSelected(_SubscriptionFilter.renewingSoon),
              ),
              _SubscriptionSummaryChip(
                icon: Icons.bolt_rounded,
                label: l10n.subscriptionsFilterHighPriority,
                value: '$highPriorityCount',
                tone: colorScheme.primary,
                isSelected: activeFilter == _SubscriptionFilter.highPriority,
                onTap: () => onFilterSelected(_SubscriptionFilter.highPriority),
              ),
              _SubscriptionSummaryChip(
                icon: Icons.payments_outlined,
                label: l10n.subscriptionsMonthlyLoad,
                value: '$currencySymbol${monthlyLoad.toStringAsFixed(0)}',
                tone: colorScheme.secondary,
              ),
              _SubscriptionSummaryChip(
                icon: Icons.pause_circle_outline_rounded,
                label: l10n.subscriptionsOptionalSavings,
                value:
                    '$currencySymbol${lowPriorityMonthlyCost.toStringAsFixed(0)}',
                tone: colorScheme.outline,
                isSelected: activeFilter == _SubscriptionFilter.lowPriority,
                onTap: () => onFilterSelected(_SubscriptionFilter.lowPriority),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SubscriptionSummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundAlpha = isSelected ? 0.18 : 0.08;
    final borderAlpha = isSelected ? 0.42 : 0.14;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: backgroundAlpha),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: borderAlpha),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: tone),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final double? displayAmount;
  final double? displayMonthlyCost;
  final String? displayCurrencyCode;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.displayAmount,
    this.displayMonthlyCost,
    this.displayCurrencyCode,
  });

  Color _getImportanceColor() {
    switch (subscription.importance) {
      case SubscriptionImportance.low:
        return Colors.blue;
      case SubscriptionImportance.medium:
        return Colors.orange;
      case SubscriptionImportance.high:
        return Colors.deepOrange;
      case SubscriptionImportance.critical:
        return Colors.red;
    }
  }

  String _getCategoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case 'Streaming':
        return l10n.subscriptionsCategoryStreaming;
      case 'Software':
        return l10n.subscriptionsCategorySoftware;
      case 'Cloud Storage':
        return l10n.subscriptionsCategoryCloudStorage;
      case 'Fitness':
        return l10n.subscriptionsCategoryFitness;
      case 'Music':
        return l10n.subscriptionsCategoryMusic;
      case 'News':
        return l10n.subscriptionsCategoryNews;
      case 'Communication':
        return l10n.subscriptionsCategoryCommunication;
      case 'Productivity':
        return l10n.subscriptionsCategoryProductivity;
      case 'Entertainment':
        return l10n.subscriptionsCategoryEntertainment;
      case 'Insurance':
        return l10n.subscriptionsCategoryInsurance;
      case 'Utilities':
        return l10n.subscriptionsCategoryUtilities;
      case 'Transport':
        return l10n.subscriptionsCategoryTransport;
      case 'Health':
        return l10n.subscriptionsCategoryHealth;
      case 'Other':
        return l10n.subscriptionsCategoryOther;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = displayCurrencyCode ?? subscription.currency;
    final currencyFormat = CurrencyUtils.getFormat(currencyCode);
    final amount = displayAmount ?? subscription.amount;
    final monthlyCost = displayMonthlyCost ?? _getMonthlyCost(subscription);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/subscriptions/${subscription.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.subscriptions_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getImportanceColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.subscriptionsPerCycle(
                        currencyFormat.format(amount),
                        _getBillingCycleText(
                            context, subscription.billingCycle),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.subscriptionsNextBilling(
                        DateFormat('MMM dd, yyyy').format(
                          subscription.nextBillingDate,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (subscription.category.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Chip(
                        label: Text(
                          _getCategoryLabel(l10n, subscription.category),
                          style: const TextStyle(fontSize: 12),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(monthlyCost),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    l10n.subscriptionsPerMonth,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBillingCycleText(BuildContext context, BillingCycle cycle) {
    final l10n = AppLocalizations.of(context)!;
    switch (cycle) {
      case BillingCycle.weekly:
        return l10n.subscriptionsCycleWeek;
      case BillingCycle.monthly:
        return l10n.subscriptionsCycleMonth;
      case BillingCycle.quarterly:
        return l10n.subscriptionsCycleQuarter;
      case BillingCycle.yearly:
        return l10n.subscriptionsCycleYear;
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
