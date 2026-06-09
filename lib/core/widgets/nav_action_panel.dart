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

    return TweenAnimationBuilder<double>(
      duration: UiTokens.motionMedium,
      curve: UiTokens.motionCurve,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.95 + 0.05 * t,
          alignment: Alignment.bottomRight,
          child: child,
        ),
      ),
      child: DecoratedBox(
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
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
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
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  // Responsive aspect ratio: wider panels (fewer cols) can afford
                  // squarer tiles; narrow columns need taller tiles for text.
                  childAspectRatio: crossAxisCount <= 2 ? 1.0 : 0.82,
                  children: [
                    for (final item in items) _NavActionTile(item: item),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavActionTile extends StatelessWidget {
  const _NavActionTile({required this.item});

  final NavActionItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Icon container scales with screen width:
    //   • compact  (<360 dp) → 48 dp
    //   • normal   (360–420) → 54 dp
    //   • large    (>420 dp) → 60 dp
    final containerSize = screenWidth < 360
        ? 48.0
        : screenWidth > 420
            ? 60.0
            : 54.0;
    final iconSize = containerSize * 0.48; // ~50 % of container
    final containerRadius = containerSize * 0.30;

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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
            const SizedBox(height: 6),
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
                      fontSize: screenWidth < 360 ? 10 : 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
