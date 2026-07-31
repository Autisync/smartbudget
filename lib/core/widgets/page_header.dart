import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

Widget buildFrostedAppBarTitle({
  required BuildContext context,
  required String title,
  required bool isScrolled,
  Widget? child,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final normalizedTitleStyle = theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    height: 1.1,
    color: colorScheme.onSurface.withOpacity( 0.92),
  );
  return AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withOpacity( isScrolled ? 0.9 : 0,
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child ?? BrandedTitle(label: title, style: normalizedTitleStyle),
  );
}

Widget buildFrostedFlexibleSpace({
  required BuildContext context,
  required bool isScrolled,
  String? onKey,
  String? offKey,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return AnimatedContainer(
    duration: UiTokens.motionFast,
    curve: Curves.easeOut,
    decoration: BoxDecoration(
      color: isScrolled
          ? colorScheme.surface.withOpacity( 0.92)
          : Colors.transparent,
      border: isScrolled
          ? Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity( 0.5),
                width: 1,
              ),
            )
          : null,
    ),
    child: isScrolled
        ? ClipRect(
            key: ValueKey(onKey ?? 'page-appbar-blur-on'),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox.expand(),
            ),
          )
        : SizedBox(
            key: ValueKey(offKey ?? 'page-appbar-blur-off'),
            child: const SizedBox.expand(),
          ),
  );
}

List<Widget> buildPageHeaderActions({
  required BuildContext context,
  required bool isScrolled,
  bool includeTrailingSpace = true,
  bool useProviderNotificationBell = true,
  bool includeSettings = true,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final l10n = AppLocalizations.of(context)!;
  final actionBackground = colorScheme.surfaceContainerHighest.withOpacity( isScrolled ? 0.9 : 0,
  );
  return [
    if (includeSettings)
      IconButton(
        tooltip: l10n.settings,
        style: IconButton.styleFrom(
          backgroundColor: actionBackground,
        ),
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => context.push('/settings'),
      ),
    if (useProviderNotificationBell)
      NotificationBellButton(
        backgroundColor: actionBackground,
        onPressed: () => context.push('/notifications'),
      )
    else
      IconButton(
        tooltip: l10n.notificationsTitle,
        style: IconButton.styleFrom(backgroundColor: actionBackground),
        icon: const Icon(Icons.notifications_none_rounded),
        onPressed: () => context.push('/notifications'),
      ),
    if (includeTrailingSpace) const SizedBox(width: 8),
  ];
}
