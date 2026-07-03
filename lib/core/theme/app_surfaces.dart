import 'package:flutter/material.dart';
import 'package:smartbudget/core/theme/app_gradients.dart';
import 'package:smartbudget/core/theme/app_radius.dart';
import 'package:smartbudget/core/theme/app_shadows.dart';

class AppSurfaces {
  static BoxDecoration elevated(
    BuildContext context, {
    double radius = AppRadius.xl,
    Color? color,
    double blur = 18,
    double offsetY = 8,
    double opacity = 0.04,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      // Crisp 1px hairline. In light mode the border carries the structure so
      // the shadow can stay almost invisible (flat, minimal look); in dark mode
      // the border is a touch stronger since shadows barely register.
      border: Border.all(
        color: isDark
            ? colorScheme.outline.withOpacity( 0.55)
            : colorScheme.outline.withOpacity( 0.9),
        width: 1,
      ),
      boxShadow: AppShadows.card(
        colorScheme.shadow,
        opacity: isDark ? opacity * 0.8 : opacity,
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
