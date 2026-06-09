import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:smartbudget/core/theme/app_shadows.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';

/// One action tile inside a [NavActionPanel].
class NavActionItem {
  const NavActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Override the icon colour. Defaults to [ColorScheme.primary].
  final Color? tint;
}

/// A floating, rounded grid panel that expands above the bottom navigation bar.
///
/// Used for both the "+" quick-add menu and the "More" menu so the two share an
/// identical look (uniform tiles: a rounded-square icon with a label beneath).
class NavActionPanel extends StatelessWidget {
  const NavActionPanel({
    super.key,
    required this.items,
    this.crossAxisCount = 4,
  });

  final List<NavActionItem> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // Panel background tinted toward the app's surface token so it reads as
    // part of the same design language rather than an alien white sheet.
    final panelColor = isDark
        ? cs.surfaceContainerHigh.withValues(alpha: 0.82)
        : cs.surface.withValues(alpha: 0.88);

    final radius = BorderRadius.circular(UiTokens.radius2xl);

    return DecoratedBox(
        // Shadow outside the clip so blur doesn't eat it.
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.floating(cs.shadow),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: radius,
                  border: Border.all(
                    color: cs.outline.withValues(alpha: isDark ? 0.35 : 0.55),
                    width: 1,
                  ),
                ),
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  // Ratio tuned to actual content height so GridView doesn't
                  // over-allocate and leave dead vertical space.
                  childAspectRatio: 0.9,
                  children: [
                    for (final item in items)
                      _NavActionTile(item: item, columnCount: crossAxisCount),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _NavActionTile extends StatelessWidget {
  const _NavActionTile({required this.item, required this.columnCount});

  final NavActionItem item;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Compact icon container — smaller so tile content matches the allocated
    // grid cell height without dead space above/below.
    final containerSize = screenWidth < 360 ? 38.0 : screenWidth > 420 ? 48.0 : 42.0;
    final iconSize = containerSize * 0.52;
    final containerRadius = containerSize * 0.28;

    // Tile background uses the app's primary container token so it inherits
    // the brand palette automatically in both light and dark modes.
    final tileBg = isDark
        ? cs.primaryContainer.withValues(alpha: 0.35)
        : cs.primaryContainer.withValues(alpha: 0.55);

    // Icon colour: brand primary in both modes (muted by container alpha).
    final iconColor = item.tint ?? (isDark ? cs.primary : cs.primary);

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(containerRadius + 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 3.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(containerRadius),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, size: iconSize, color: iconColor),
            ),
            const SizedBox(height: 4.0),
            Flexible(
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      // 9.5sp: "Subscription" (12 chars × ~5.4px) ≈ 65px
                      // which fits inside the ~65px tile width at 4 columns.
                      fontSize: screenWidth < 360 ? 9.0 : 9.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
