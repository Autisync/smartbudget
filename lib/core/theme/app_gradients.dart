import 'package:flutter/material.dart';

class AppGradients {
  const AppGradients._();

  // Subtle, near-monochromatic brand gradients. Tight two-stop ramps read more
  // modern and calm than wide multi-hue sweeps.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6E72F2),
      Color(0xFF595FE6),
    ],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2B2F63),
      Color(0xFF5258D9),
    ],
  );
}
