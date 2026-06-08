import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color brand = Color(0xFF7377F9);
  static const Color brandDeep = Color(0xFF4C57D6);
  static const Color info = Color(0xFF4B8BFF);
  static const Color success = Color(0xFF1E9E6A);
  static const Color warning = Color(0xFFF29B38);
  static const Color danger = Color(0xFFE05A68);

  // Minimalist neutrals — a near-white canvas, pure-white surfaces, and soft
  // hairline borders. Warmer-neutral grays read calmer than blue-tinted ones.
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFF9FAFB);
  static const Color lightSurfaceHighest = Color(0xFFF1F3F5);
  static const Color lightText = Color(0xFF14161D);
  static const Color lightMuted = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFEDEFF2);

  static const Color darkBackground = Color(0xFF0B0D13);
  static const Color darkSurface = Color(0xFF14161F);
  static const Color darkSurfaceHigh = Color(0xFF191C27);
  static const Color darkSurfaceHighest = Color(0xFF222632);
  static const Color darkText = Color(0xFFF4F5F8);
  static const Color darkMuted = Color(0xFF9AA0AE);
  static const Color darkBorder = Color(0xFF262A36);

  static const ColorScheme lightScheme = ColorScheme.light(
    primary: brand,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE9ECFF),
    onPrimaryContainer: Color(0xFF1F2666),
    secondary: info,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8F1FF),
    onSecondaryContainer: Color(0xFF12315C),
    tertiary: warning,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFF1DE),
    onTertiaryContainer: Color(0xFF6A4300),
    error: danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFFE6E9),
    onErrorContainer: Color(0xFF6B1722),
    surface: lightSurface,
    onSurface: lightText,
    surfaceContainerHigh: lightSurfaceHigh,
    surfaceContainerHighest: lightSurfaceHighest,
    onSurfaceVariant: lightMuted,
    outline: lightBorder,
    outlineVariant: lightBorder,
    shadow: Color(0xFF20253A),
  );

  static const ColorScheme darkScheme = ColorScheme.dark(
    primary: Color(0xFF9CA7FF),
    onPrimary: Color(0xFF182055),
    primaryContainer: Color(0xFF26306D),
    onPrimaryContainer: Color(0xFFE6EAFF),
    secondary: Color(0xFF87B2FF),
    onSecondary: Color(0xFF082C63),
    secondaryContainer: Color(0xFF183B73),
    onSecondaryContainer: Color(0xFFE3EEFF),
    tertiary: Color(0xFFFFBD6B),
    onTertiary: Color(0xFF4A2E00),
    tertiaryContainer: Color(0xFF624100),
    onTertiaryContainer: Color(0xFFFFE7C1),
    error: Color(0xFFFF9CA7),
    onError: Color(0xFF690E1B),
    errorContainer: Color(0xFF7E2431),
    onErrorContainer: Color(0xFFFFE6E9),
    surface: darkSurface,
    onSurface: darkText,
    surfaceContainerHigh: darkSurfaceHigh,
    surfaceContainerHighest: darkSurfaceHighest,
    onSurfaceVariant: darkMuted,
    outline: darkBorder,
    outlineVariant: darkBorder,
    shadow: Colors.black,
  );
}
