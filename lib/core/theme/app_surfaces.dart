import 'package:flutter/material.dart';
import 'package:smartbudget/core/theme/app_gradients.dart';
import 'package:smartbudget/core/theme/app_radius.dart';
import 'package:smartbudget/core/theme/app_shadows.dart';

class AppSurfaces {
  static BoxDecoration elevated(
    BuildContext context, {
    double radius = AppRadius.xl,
    Color? color,
    double blur = 12,
    double offsetY = 4,
    double opacity = 0.06,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? colorScheme.outline.withValues(alpha: 0.28)
            : colorScheme.outline.withValues(alpha: 0.5),
        width: 0.6,
      ),
      boxShadow: AppShadows.card(
        colorScheme.shadow,
        opacity: isDark ? opacity : opacity * 0.95,
      ).map((shadow) {
        return shadow.copyWith(
          blurRadius: blur,
          offset: Offset(0, offsetY),
        );
      }).toList(),
    );
  }

  static BoxDecoration gradientCard(
    BuildContext context, {
    List<Color> colors = const [Color(0xFF1A2040), Color(0xFF7A6CF6)],
    double radius = AppRadius.xxl,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppShadows.floating(colors.last),
    );
  }

  static BoxDecoration heroCard(BuildContext context,
      {double radius = AppRadius.xxl}) {
    return BoxDecoration(
      gradient: AppGradients.hero,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppShadows.floating(Theme.of(context).colorScheme.shadow),
    );
  }
}
