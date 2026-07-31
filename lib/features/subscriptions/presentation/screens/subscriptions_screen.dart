import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/financial/insight_portfolio_card.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/components/shared/slidable_edge_clip.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/utils/verification_gate.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/core/widgets/animated_list_item.dart';
import 'package:smartbudget/core/widgets/app_shimmer.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

enum SubscriptionFilter {
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
  bool _isScrolled = false;
  SubscriptionFilter? _activeFilter;
  String _searchQuery = '';
  bool _hasShownRenewalWarning = false;

  void _updateAppBarScrollState(double offset) {
    final shouldShowFill = offset > 8;
    if (shouldShowFill == _isScrolled) {
      return;
    }
    setState(() => _isScrolled = shouldShowFill);
  }

  Future<void> _refresh() async {
    ref.invalidate(subscriptionListProvider);
    await ref.read(subscriptionListProvider.future);
  }

  Future<void> _openAddSubscriptionModal() async {
    if (!await VerificationGate.allow(
        context, ProviderScope.containerOf(context))) {
      return;
    }
    if (!mounted) return;
    await AppFormSheet.show<void>(
      context,
      builder: (_) => const SubscriptionFormSheet(
        mode: SubscriptionFormMode.create,
        asModal: true,
      ),
    );
  }

  Future<void> _openEditSubscriptionModal(Subscription subscription) async {
    await AppFormSheet.show<void>(
      context,
      builder: (_) => SubscriptionFormSheet(
        mode: SubscriptionFormMode.update,
        initialData: subscription,
        asModal: true,
      ),
    );
  }

  Future<void> _handleMenuAction(
      Subscription subscription, String action) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(subscriptionListProvider.notifier);

    if (action == 'edit') {
      if (!mounted) {
        return;
      }
      await _openEditSubscriptionModal(subscription);
      return;
    }

    if (action == 'toggle') {
      final updated = subscription.copyWith(
        isActive: !subscription.isActive,
        updatedAt: DateTime.now(),
      );
      await notifier.updateSubscription(updated);
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n?.delete ?? 'Delete'),
            content: Text(
              'Delete ${subscription.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n?.cancel ?? 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n?.delete ?? 'Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await notifier.deleteSubscription(subscription.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final displayAmountsAsync =
        ref.watch(subscriptionDisplayAmountsProvider(appCurrency));
    final subscriptionsAsync = ref.watch(subscriptionListProvider);

    return AppScaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n?.navSubscriptions ?? 'Subscriptions',
          isScrolled: _isScrolled,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity( _isScrolled ? 0.88 : 0,
            ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isScrolled,
          onKey: 'subscriptions-appbar-blur-on',
          offKey: 'subscriptions-appbar-blur-off',
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isScrolled,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: subscriptionsAsync.when(
            loading: () => const AppShimmerSkeleton(
                variant: AppShimmerVariant.cards, itemCount: 5),
            error: (error, stackTrace) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 160),
              children: [
                Text(
                  l10n?.subscriptionsLoadError(AppErrorMapper.from(error)) ??
                      'Error loading subscription: ${AppErrorMapper.from(error)}',
                ),
              ],
            ),
            data: (subscriptions) {
              final displayAmounts = displayAmountsAsync.valueOrNull ??
                  <String, SubscriptionDisplayAmounts>{};
              final computed = subscriptions
                  .map(
                    (subscription) => _ComputedSubscription(
                      subscription: subscription,
                      display: displayAmounts[subscription.id],
                    ),
                  )
                  .toList(growable: false);

              final now = DateTime.now();
              final criticalCount = computed
                  .where(
                    (entry) =>
                        entry.subscription.isActive &&
                        entry.subscription.importance ==
                            SubscriptionImportance.critical,
                  )
                  .length;
              final renewingSoonCount = computed
                  .where(
                    (entry) =>
                        entry.subscription.isActive &&
                        entry.subscription.nextBillingDate.isAfter(
                          now.subtract(const Duration(days: 1)),
                        ) &&
                        entry.subscription.nextBillingDate
                            .isBefore(now.add(const Duration(days: 8))),
                  )
                  .length;
              if (renewingSoonCount > 0 && !_hasShownRenewalWarning) {
                _hasShownRenewalWarning = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  AppFeedbackService.showWarning(
                    context,
                    '$renewingSoonCount subscription renewal(s) due within 7 days.',
                  );
                });
              }
              final highPriorityCount = computed
                  .where(
                    (entry) =>
                        entry.subscription.isActive &&
                        (entry.subscription.importance ==
                                SubscriptionImportance.high ||
                            entry.subscription.importance ==
                                SubscriptionImportance.critical),
                  )
                  .length;
              final activeCount =
                  computed.where((entry) => entry.subscription.isActive).length;
              final monthlyLoad = computed.fold<double>(
                0,
                (sum, entry) =>
                    entry.subscription.isActive ? sum + entry.monthlyCost : sum,
              );
              final lowPriorityMonthlyCost = computed.fold<double>(
                0,
                (sum, entry) => entry.subscription.isActive &&
                        entry.subscription.importance ==
                            SubscriptionImportance.low
                    ? sum + entry.monthlyCost
                    : sum,
              );
              final subscriptionInsight = _buildSubscriptionInsight(
                activeCount: activeCount,
                criticalCount: criticalCount,
                renewingSoonCount: renewingSoonCount,
                monthlyLoad: monthlyLoad,
                lowPriorityMonthlyCost: lowPriorityMonthlyCost,
                currencyCode: appCurrency,
              );

              final filtered = computed.where((entry) {
                final sub = entry.subscription;
                switch (_activeFilter) {
                  case null:
                    return true;
                  case SubscriptionFilter.critical:
                    return sub.importance == SubscriptionImportance.critical;
                  case SubscriptionFilter.renewingSoon:
                    return sub.nextBillingDate
                            .isAfter(now.subtract(const Duration(days: 1))) &&
                        sub.nextBillingDate
                            .isBefore(now.add(const Duration(days: 8)));
                  case SubscriptionFilter.highPriority:
                    return sub.importance == SubscriptionImportance.high ||
                        sub.importance == SubscriptionImportance.critical;
                  case SubscriptionFilter.lowPriority:
                    return sub.importance == SubscriptionImportance.low;
                }
              }).toList(growable: false)
                ..sort(
                  (a, b) => a.subscription.nextBillingDate.compareTo(
                    b.subscription.nextBillingDate,
                  ),
                );

              // Apply search query on top of category/importance filter.
              final query = _searchQuery.trim().toLowerCase();
              final searched = query.isEmpty
                  ? filtered
                  : filtered.where((e) {
                      final sub = e.subscription;
                      return sub.name.toLowerCase().contains(query) ||
                          sub.category.toLowerCase().contains(query);
                    }).toList(growable: false);

              final snapshotCard = SubscriptionDecisionSnapshotCard(
                activeCount: subscriptions.isEmpty ? 0 : activeCount,
                criticalCount: subscriptions.isEmpty ? 0 : criticalCount,
                renewingSoonCount:
                    subscriptions.isEmpty ? 0 : renewingSoonCount,
                highPriorityCount:
                    subscriptions.isEmpty ? 0 : highPriorityCount,
                monthlyLoad: subscriptions.isEmpty ? 0 : monthlyLoad,
                lowPriorityMonthlyCost:
                    subscriptions.isEmpty ? 0 : lowPriorityMonthlyCost,
                currencySymbol: CurrencyUtils.symbol(appCurrency),
                insightText: subscriptions.isEmpty
                    ? 'Add subscriptions to understand your monthly recurring load.'
                    : subscriptionInsight,
                filters: SubscriptionFilter.values,
                activeFilter: _activeFilter,
                filterLabelBuilder: (filter) => _filterLabel(filter, l10n),
                onFilterSelected: (filter) =>
                    setState(() => _activeFilter = filter),
                showChipsInFooter: false,
              );

              if (subscriptions.isEmpty) {
                // Show only the empty state — no snapshot card or filter chips.
                // Previously the snapshot card + chips consumed the visible area,
                // pushing SmartEmptyState below the fold and making it invisible.
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
                        child: SmartEmptyState(
                          icon: Icons.subscriptions_outlined,
                          title: l10n?.subscriptionsEmpty ??
                              'No subscriptions yet',
                          message: l10n?.subscriptionsEmptySubtitle ??
                              'Add your first subscription to start tracking',
                          lottieAsset:
                              'assets/animations/empty_subscriptions.json',
                          action: SizedBox(
                            width: (MediaQuery.sizeOf(context).width - 48)
                                .clamp(220.0, 320.0)
                                .toDouble(),
                            child: FilledButton.icon(
                              onPressed: _openAddSubscriptionModal,
                              icon: const Icon(Icons.add_rounded),
                              label: Text(
                                l10n?.subscriptionsAdd ?? 'Add subscription',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SubscriptionSearchHeaderDelegate(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _SubscriptionSearchField(
                          value: _searchQuery,
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(child: snapshotCard),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _SubscriptionFilterChipRow(
                        filters: SubscriptionFilter.values,
                        activeFilter: _activeFilter,
                        filterLabelBuilder: (f) => _filterLabel(f, l10n),
                        onFilterSelected: (f) =>
                            setState(() => _activeFilter = f),
                      ),
                    ),
                  ),
                  if (searched.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off,
                                size: 40,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nothing here',
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                query.isNotEmpty
                                    ? 'No subscriptions match "$query".'
                                    : 'Try another filter to see subscriptions.',
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
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _activeFilter = null;
                                  _searchQuery = '';
                                }),
                                child: Text(l10n?.subscriptionsClearFilters ??
                                    'Clear filters'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 172),
                      sliver: SliverList.separated(
                        itemCount: searched.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final entry = searched[idx];
                          return AnimatedListItem(
                            index: idx,
                            child: Slidable(
                              key: ValueKey(
                                  'subscription-${entry.subscription.id}'),
                              startActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.30,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _handleMenuAction(
                                        entry.subscription, 'toggle'),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    foregroundColor: Colors.white,
                                    icon: entry.subscription.isActive
                                        ? Icons.pause_circle_outline_rounded
                                        : Icons.play_circle_outline_rounded,
                                    label: entry.subscription.isActive
                                        ? 'Pause'
                                        : 'Resume',
                                    borderRadius: BorderRadius.circular(
                                        UiTokens.radiusXl),
                                  ),
                                ],
                              ),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.30,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _handleMenuAction(
                                        entry.subscription, 'delete'),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_outline_rounded,
                                    label: l10n?.delete ?? 'Delete',
                                    borderRadius: BorderRadius.circular(
                                        UiTokens.radiusXl),
                                  ),
                                ],
                              ),
                              child: SwipeableCard(
                                radius: UiTokens.radiusXl,
                                child: SubscriptionItemCard(
                                  subscription: entry.subscription,
                                  amount: entry.amount,
                                  currencyCode: entry.currencyCode,
                                  categoryLabel: entry.subscription.category,
                                  cycleLabel: _cycleShort(
                                    entry.subscription.billingCycle,
                                    l10n,
                                  ),
                                  onTap: () => _openEditSubscriptionModal(
                                      entry.subscription),
                                  onMenuAction: (action) => _handleMenuAction(
                                      entry.subscription, action),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _filterLabel(SubscriptionFilter filter, AppLocalizations? l10n) {
    switch (filter) {
      case SubscriptionFilter.critical:
        return l10n?.subscriptionsFilterCritical ?? 'Critical';
      case SubscriptionFilter.renewingSoon:
        return l10n?.subscriptionsFilterRenewingSoon ?? 'Renewing Soon';
      case SubscriptionFilter.highPriority:
        return l10n?.subscriptionsFilterHighPriority ?? 'High Priority';
      case SubscriptionFilter.lowPriority:
        return l10n?.subscriptionsFilterLowPriority ?? 'Low Priority';
    }
  }

  String _cycleShort(BillingCycle cycle, AppLocalizations? l10n) {
    switch (cycle) {
      case BillingCycle.weekly:
        return l10n?.subscriptionsCycleWeek ?? 'week';
      case BillingCycle.monthly:
        return l10n?.subscriptionsCycleMonth ?? 'month';
      case BillingCycle.quarterly:
        return l10n?.subscriptionsCycleQuarter ?? 'quarter';
      case BillingCycle.yearly:
        return l10n?.subscriptionsCycleYear ?? 'year';
    }
  }

  String _buildSubscriptionInsight({
    required int activeCount,
    required int criticalCount,
    required int renewingSoonCount,
    required double monthlyLoad,
    required double lowPriorityMonthlyCost,
    required String currencyCode,
  }) {
    final money = CurrencyUtils.getFormat(currencyCode);
    if (activeCount == 0) {
      return 'Add subscriptions to understand your monthly recurring load.';
    }
    if (criticalCount > 0) {
      return 'Subscriptions are taking a large share of fixed outflow. Review services you can pause or cancel.';
    }
    if (renewingSoonCount > 0) {
      return 'You have renewals coming soon. Check whether these services are still useful.';
    }
    if (lowPriorityMonthlyCost > 0) {
      return 'Your subscription stack looks stable. ${money.format(lowPriorityMonthlyCost)} can still be saved by pausing optional services.';
    }
    return 'Your subscription stack looks stable. Current monthly load is ${money.format(monthlyLoad)}.';
  }
}

class SubscriptionDecisionSnapshotCard extends StatelessWidget {
  const SubscriptionDecisionSnapshotCard({
    super.key,
    required this.activeCount,
    required this.criticalCount,
    required this.renewingSoonCount,
    required this.highPriorityCount,
    required this.monthlyLoad,
    required this.lowPriorityMonthlyCost,
    required this.currencySymbol,
    required this.insightText,
    required this.filters,
    required this.activeFilter,
    required this.filterLabelBuilder,
    required this.onFilterSelected,
    this.showChipsInFooter = true,
  });

  final int activeCount;
  final int criticalCount;
  final int renewingSoonCount;
  final int highPriorityCount;
  final double monthlyLoad;
  final double lowPriorityMonthlyCost;
  final String currencySymbol;
  final String insightText;
  final List<SubscriptionFilter> filters;
  final SubscriptionFilter? activeFilter;
  final String Function(SubscriptionFilter filter) filterLabelBuilder;
  final ValueChanged<SubscriptionFilter?> onFilterSelected;
  final bool showChipsInFooter;

  @override
  Widget build(BuildContext context) {
    return SubscriptionPortfolioCard<SubscriptionFilter>(
      activeCount: activeCount,
      criticalCount: criticalCount,
      renewingSoonCount: renewingSoonCount,
      highPriorityCount: highPriorityCount,
      monthlyLoad: monthlyLoad,
      lowPriorityMonthlyCost: lowPriorityMonthlyCost,
      currencySymbol: currencySymbol,
      insightText: insightText,
      filters: filters,
      activeFilter: activeFilter,
      filterLabelBuilder: filterLabelBuilder,
      onFilterSelected: onFilterSelected,
      showChipsInFooter: showChipsInFooter,
    );
  }
}

class SubscriptionItemCard extends StatelessWidget {
  const SubscriptionItemCard({
    super.key,
    required this.subscription,
    required this.amount,
    required this.currencyCode,
    required this.categoryLabel,
    required this.cycleLabel,
    required this.onTap,
    required this.onMenuAction,
  });

  final Subscription subscription;
  final double amount;
  final String currencyCode;
  final String categoryLabel;
  final String cycleLabel;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final amountFormat = CurrencyUtils.getFormat(currencyCode);
    final dateFormat = DateFormat('MMM d');

    final importanceColor = switch (subscription.importance) {
      SubscriptionImportance.low =>
        AppColors.statusFor(theme.brightness, AppStatus.success),
      SubscriptionImportance.medium =>
        AppColors.statusFor(theme.brightness, AppStatus.info),
      SubscriptionImportance.high =>
        AppColors.statusFor(theme.brightness, AppStatus.warning),
      SubscriptionImportance.critical =>
        AppColors.statusFor(theme.brightness, AppStatus.danger),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiTokens.radiusXl),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface
                : Colors.white,
            borderRadius: BorderRadius.circular(UiTokens.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity( 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: importanceColor.withOpacity( 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.subscriptions_rounded,
                  color: importanceColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$categoryLabel - ${subscription.isActive ? 'Active' : 'Paused'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Next billing ${dateFormat.format(subscription.nextBillingDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountFormat.format(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/ $cycleLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppActionMenu(
                    title: l10n?.subscriptionsActionsTitle ??
                        'Subscription actions',
                    onSelected: onMenuAction,
                    items: [
                      AppActionItem(
                        value: 'edit',
                        label: l10n?.edit ?? 'Edit',
                        icon: Icons.edit_rounded,
                      ),
                      AppActionItem(
                        value: 'toggle',
                        label: subscription.isActive
                            ? (l10n?.subscriptionsPause ?? 'Pause')
                            : (l10n?.subscriptionsResume ?? 'Resume'),
                        icon: subscription.isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                      ),
                      AppActionItem(
                        value: 'delete',
                        label: l10n?.delete ?? 'Delete',
                        icon: Icons.delete_outline_rounded,
                        destructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search header delegate ─────────────────────────────────────────────────

class _SubscriptionSearchHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  _SubscriptionSearchHeaderDelegate({
    required this.child,
    required this.backgroundColor,
  });

  final Widget child;
  final Color backgroundColor;

  static const double _extent = 64;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(
      covariant _SubscriptionSearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

// ─── Search field ────────────────────────────────────────────────────────────

class _SubscriptionSearchField extends StatefulWidget {
  const _SubscriptionSearchField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SubscriptionSearchField> createState() =>
      _SubscriptionSearchFieldState();
}

class _SubscriptionSearchFieldState extends State<_SubscriptionSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SubscriptionSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHighest.withOpacity( 0.6),
        hintText:
            l10n?.subscriptionsSearchHint ?? 'Search by name or category',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity( 0.16)
                : Colors.black.withOpacity( 0.16),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity( 0.16)
                : Colors.black.withOpacity( 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                tooltip: l10n?.commonClearSearch ?? 'Clear search',
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

// ─── Filter chip row ─────────────────────────────────────────────────────────

class _SubscriptionFilterChipRow extends StatelessWidget {
  const _SubscriptionFilterChipRow({
    required this.filters,
    required this.activeFilter,
    required this.filterLabelBuilder,
    required this.onFilterSelected,
  });

  final List<SubscriptionFilter> filters;
  final SubscriptionFilter? activeFilter;
  final String Function(SubscriptionFilter) filterLabelBuilder;
  final ValueChanged<SubscriptionFilter?> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SubFilterChip(
          label: l10n?.commonAll ?? 'All',
          selected: activeFilter == null,
          onTap: () => onFilterSelected(null),
        ),
        ...filters.map(
          (f) => _SubFilterChip(
            label: filterLabelBuilder(f),
            selected: activeFilter == f,
            onTap: () => onFilterSelected(activeFilter == f ? null : f),
          ),
        ),
      ],
    );
  }
}

class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withOpacity( 0.14)
              : scheme.surfaceContainerHighest.withOpacity( 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

// ─── Computed data ────────────────────────────────────────────────────────────

class _ComputedSubscription {
  _ComputedSubscription({
    required this.subscription,
    required SubscriptionDisplayAmounts? display,
  })  : amount = display?.amount ?? subscription.amount,
        monthlyCost = display?.monthlyCost ?? subscription.monthlyCost,
        currencyCode = display?.currencyCode ?? subscription.currency;

  final Subscription subscription;
  final double amount;
  final double monthlyCost;
  final String currencyCode;
}
