import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  // Minimalist elevation: a single, soft, low-opacity diffuse shadow. Cards
  // read as flat planes lifted gently off the background rather than
  // heavily-shadowed boxes.
  static List<BoxShadow> card(Color shadowColor, {double opacity = 0.04}) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: opacity),
        blurRadius: 18,
        offset: const Offset(0, 8),
        spreadRadius: -10,
      ),
    ];
  }

  static List<BoxShadow> floating(Color shadowColor) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 12),
        spreadRadius: -12,
      ),
    ];
  }
}
