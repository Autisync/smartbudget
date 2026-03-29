import 'package:flutter/material.dart';

class AppSurfaces {
  static BoxDecoration elevated(
    BuildContext context, {
    double radius = 22,
    Color? color,
    double blur = 18,
    double offsetY = 10,
    double opacity = 0.08,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: color ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: opacity),
          blurRadius: blur,
          offset: Offset(0, offsetY),
        ),
      ],
    );
  }
}
