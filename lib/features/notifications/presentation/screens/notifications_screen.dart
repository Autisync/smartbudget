import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/services/notification_service.dart';
import 'package:smartbudget/core/widgets/animated_list_item.dart';
import 'package:smartbudget/core/widgets/app_shimmer.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isAppBarScrolled = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final inboxAsync = ref.watch(notificationInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.notificationsTitle,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'notifications-appbar-blur-on',
          offKey: 'notifications-appbar-blur-off',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () {
              ref.read(notificationServiceProvider).markAllRead();
            },
          ),
          ...buildPageHeaderActions(
            context: context,
            isScrolled: _isAppBarScrolled,
            includeTrailingSpace: false,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              ref.read(notificationServiceProvider).clearInbox();
            },
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
        child: inboxAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return AppAnimatedEmptyState(
                icon: Icons.notifications_none_rounded,
                title: l10n.notificationsEmpty,
                message: l10n.notificationsEmptySubtitle,
                lottieAsset: 'assets/animations/notification.json',
              );
            }

            final grouped = _groupByDate(items);
            final orderedKeys = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: orderedKeys.length,
              itemBuilder: (context, index) {
                final key = orderedKeys[index];
                final sectionItems = grouped[key]!;
                return AnimatedListItem(
                  index: index,
                  child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 8),
                        child: Text(
                          DateFormat('EEE, MMM dd').format(key),
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      ...sectionItems.map((item) {
                        final icon = _iconFor(item.category);
                        final tone = _toneFor(context, item.category);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey('notif-${item.id}-${item.createdAt}'),
                            background: _swipeBackground(
                              context,
                              icon: Icons.mark_email_read_rounded,
                              alignment: Alignment.centerLeft,
                              color: const Color(0xFF0F9D58),
                              label: l10n.notificationsMarkRead,
                            ),
                            secondaryBackground: _swipeBackground(
                              context,
                              icon: Icons.archive_rounded,
                              alignment: Alignment.centerRight,
                              color: colorScheme.error,
                              label: l10n.commonArchive,
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                ref
                                    .read(notificationServiceProvider)
                                    .markRead(item.id);
                              } else {
                                ref
                                    .read(notificationServiceProvider)
                                    .archive(item.id);
                              }
                              return false;
                            },
                            child: Container(
                              decoration:
                                  AppSurfaces.elevated(context, radius: 16),
                              child: Material(
                                type: MaterialType.transparency,
                                child: ListTile(
                                onTap: () {
                                  ref
                                      .read(notificationServiceProvider)
                                      .markRead(item.id);
                                  final route = item.payload.startsWith('/')
                                      ? item.payload
                                      : NotificationService.routeForType(
                                          item.type);
                                  context.push(route);
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: tone.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(icon, color: tone, size: 22),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.body),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat('HH:mm')
                                            .format(item.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  ), // AnimatedListItem
                );
              },
            );
          },
          loading: () => const AppShimmerSkeleton(
              variant: AppShimmerVariant.list, itemCount: 6),
          error: (err, st) => Center(
            child: Text(l10n.notificationsLoadError(err.toString())),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AppNotificationCategory category) {
    switch (category) {
      case AppNotificationCategory.budget:
        return Icons.account_balance_wallet_outlined;
      case AppNotificationCategory.savings:
        return Icons.savings_outlined;
      case AppNotificationCategory.health:
        return Icons.monitor_heart_outlined;
      case AppNotificationCategory.security:
        return Icons.security_rounded;
      case AppNotificationCategory.reports:
        return Icons.description_rounded;
    }
  }

  Color _toneFor(BuildContext context, AppNotificationCategory category) {
    final scheme = Theme.of(context).colorScheme;
    switch (category) {
      case AppNotificationCategory.budget:
        return scheme.error;
      case AppNotificationCategory.savings:
        return const Color(0xFF059669);
      case AppNotificationCategory.health:
        return scheme.tertiary;
      case AppNotificationCategory.security:
        return const Color(0xFFE67E22);
      case AppNotificationCategory.reports:
        return scheme.primary;
    }
  }

  Map<DateTime, List<AppNotificationEntry>> _groupByDate(
    List<AppNotificationEntry> items,
  ) {
    final grouped = <DateTime, List<AppNotificationEntry>>{};
    for (final item
        in items.where((e) => e.state != NotificationState.archived)) {
      final key = DateTime(
          item.createdAt.year, item.createdAt.month, item.createdAt.day);
      grouped.putIfAbsent(key, () => <AppNotificationEntry>[]).add(item);
    }
    return grouped;
  }

  Widget _swipeBackground(
    BuildContext context, {
    required IconData icon,
    required Alignment alignment,
    required Color color,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight)
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          const SizedBox(width: 6),
          Icon(icon, color: color),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ],
      ),
    );
  }
}
