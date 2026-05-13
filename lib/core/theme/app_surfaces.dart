import 'package:flutter/material.dart';

class AppSurfaces {
  static BoxDecoration elevated(
    BuildContext context, {
    double radius = 24,
    Color? color,
    double blur = 28,
    double offsetY = 12,
    double opacity = 0.08,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: isDark
          ? null
          : Border.all(
              color: const Color(0xFF111827).withValues(alpha: 0.06),
              width: 0.5,
            ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow
              .withValues(alpha: isDark ? opacity : opacity * 1.4),
          blurRadius: blur,
          offset: Offset(0, offsetY),
          spreadRadius: -2,
        ),
      ],
    );
  }

  static BoxDecoration gradientCard(
    BuildContext context, {
    List<Color> colors = const [Color(0xFF312E81), Color(0xFF7C3AED)],
    double radius = 28,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: 0.30),
          blurRadius: 34,
          offset: const Offset(0, 18),
          spreadRadius: -8,
        ),
      ],
    );
  }
}
