import 'package:flutter/material.dart';

/// Semantic status levels shared across badges, alerts, and meters.
enum AppStatus { success, warning, danger, info }

class AppColors {
  const AppColors._();

  static const Color brand = Color(0xFF7377F9);
  static const Color brandDeep = Color(0xFF4C57D6);
  static const Color info = Color(0xFF4B8BFF);
  static const Color success = Color(0xFF1E9E6A);
  static const Color warning = Color(0xFFF29B38);
  static const Color danger = Color(0xFFE05A68);

  // ---------------------------------------------------------------------------
  // Semantic money colors — the SINGLE source of truth for income / expense /
  // status. Before this existed, each screen invented its own green and red
  // (6+ greens app-wide), which is the #1 reason the UI read as inconsistent.
  // Every screen must resolve money colors through the helpers below, never via
  // raw hex. Values are tuned for WCAG AA: the light variants clear 4.5:1 on
  // white for small amount text; dark variants clear it on the dark surface.
  // ---------------------------------------------------------------------------
  static const Color _incomeLight = Color(0xFF0E7A4E); // emerald, AA on white
  static const Color _incomeDark = Color(0xFF3DD68C);
  static const Color _expenseLight = Color(0xFFC53B3B); // red, AA on white
  static const Color _expenseDark = Color(0xFFFF8A8A);

  /// Positive / income color for the given [brightness].
  static Color income(Brightness brightness) =>
      brightness == Brightness.dark ? _incomeDark : _incomeLight;

  /// Negative / expense color for the given [brightness].
  static Color expense(Brightness brightness) =>
      brightness == Brightness.dark ? _expenseDark : _expenseLight;

  /// Color for a signed monetary amount: expense → red, income → green.
  static Color amount(Brightness brightness, {required bool isExpense}) =>
      isExpense ? expense(brightness) : income(brightness);

  /// Soft tinted background for an income icon / chip.
  static Color incomeTint(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF34D399).withOpacity( 0.16)
      : const Color(0xFFE6F4EC);

  /// Soft tinted background for an expense icon / chip.
  static Color expenseTint(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFFF8A8A).withOpacity( 0.16)
          : const Color(0xFFFCE9E7);

  /// Resolve a status ramp (success / warning / danger / info) to an
  /// AA-legible foreground color for the given [brightness]. Use for badges,
  /// burn-rate states, health states — never hardcode status hex per screen.
  static Color statusFor(Brightness brightness, AppStatus status) {
    final dark = brightness == Brightness.dark;
    switch (status) {
      case AppStatus.success:
        return dark ? const Color(0xFF3DD68C) : const Color(0xFF0E7A4E);
      case AppStatus.warning:
        return dark ? const Color(0xFFF6B860) : const Color(0xFFB26A0A);
      case AppStatus.danger:
        return dark ? const Color(0xFFFF8A8A) : const Color(0xFFC53B3B);
      case AppStatus.info:
        return dark ? const Color(0xFF87B2FF) : const Color(0xFF2563C9);
    }
  }

  /// Soft tinted background matching a status ramp.
  static Color statusTint(Brightness brightness, AppStatus status) {
    final base = statusFor(brightness, status);
    return base.withOpacity( brightness == Brightness.dark ? 0.16 : 0.12);
  }

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
