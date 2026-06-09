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

    final radius = BorderRadius.circular(UiTokens.radius2xl);
    // Near-transparent, frosted panel so the screen shows through it.
    final panelColor = cs.surface.withValues(alpha: isDark ? 0.55 : 0.62);

    return TweenAnimationBuilder<double>(
      duration: UiTokens.motionMedium,
      curve: UiTokens.motionCurve,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.95 + 0.05 * t,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        // Shadow lives outside the clip so the blur doesn't swallow it.
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.floating(cs.shadow),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: radius,
                  border: Border.all(
                    color: cs.outline.withValues(alpha: isDark ? 0.5 : 0.8),
                    width: 1,
                  ),
                ),
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.82,
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
    // Slightly stronger than the frosted panel so each tile stays distinct.
    final tileBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : cs.onSurface.withValues(alpha: 0.06);

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, size: 24, color: item.tint ?? cs.onSurface),
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
                      height: 1.1,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
