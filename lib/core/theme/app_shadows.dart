import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card(Color shadowColor, {double opacity = 0.06}) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: opacity),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ];
  }

  static List<BoxShadow> floating(Color shadowColor) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.10),
        blurRadius: 14,
        offset: const Offset(0, 6),
        spreadRadius: -4,
      ),
    ];
  }
}
