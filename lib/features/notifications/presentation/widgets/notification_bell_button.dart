import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({
    super.key,
    required this.onPressed,
    this.backgroundColor,
  });

  final VoidCallback onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationInboxProvider).maybeWhen(
          data: (items) => items.where((e) => !e.isRead).length,
          orElse: () => 0,
        );

    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: l10n.notificationsTitle,
      style: IconButton.styleFrom(backgroundColor: backgroundColor),
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                key: const ValueKey('notification-badge'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1,
                  ),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        height: 1,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}




