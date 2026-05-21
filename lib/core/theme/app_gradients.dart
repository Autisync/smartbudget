import 'package:flutter/material.dart';

class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6B7CFF),
      Color(0xFF7A6CF6),
      Color(0xFF8F7CFF),
    ],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2040),
      Color(0xFF3E4FCB),
      Color(0xFF7A6CF6),
    ],
  );
}
