import 'package:flutter/material.dart';

class AppSurfaces {
  static BoxDecoration elevated(
    BuildContext context, {
    double radius = 22,
    Color? color,
    double blur = 24,
    double offsetY = 8,
    double opacity = 0.09,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: isDark
          ? null
          : Border.all(
              color: const Color(0xFF0F172A).withValues(alpha: 0.055),
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
}
