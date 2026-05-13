import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartbudget/core/theme/input_styles.dart';

class AppTheme {
  static const _lightSurface = Color(0xFFFFFCF8);
  static const _lightSurfaceHigh = Color(0xFFFFFFFF);
  static const _lightBackground = Color(0xFFF7F5F2);
  static const _darkSurface = Color(0xFF17151F);
  static const _darkSurfaceHigh = Color(0xFF211F2B);
  static const _darkBackground = Color(0xFF0F0D16);
  static const _accent = Color(0xFF6D5DF6);
  static const _secondary = Color(0xFF2EA7FF);
  static const _success = Color(0xFF10A66A);
  static const _danger = Color(0xFFE25563);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        surface: _lightSurface,
        primary: _accent,
        secondary: _secondary,
        error: _danger,
        tertiary: _success,
        onSurface: Color(0xFF171421),
        onSurfaceVariant: Color(0xFF676171),
        surfaceContainerHighest: Color(0xFFEDEAF3),
        surfaceContainerHigh: Color(0xFFF2EFF7),
        primaryContainer: Color(0xFFE9E6FF),
        onPrimaryContainer: Color(0xFF251B72),
        shadow: Color(0xFF181225),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        // Display styles - for hero/main content
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.2,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.25,
        ),
        // Headline styles - for section headers (SEO: h1, h2, h3)
        headlineLarge: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.35,
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.4,
        ),
        // Title styles - for card titles, important labels
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        titleSmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        // Body styles - for main content (SEO: clear, readable)
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.57,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.67,
        ),
        // Label styles - for buttons, chips, badges (SEO: bold for emphasis)
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1.67,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _lightSurfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: const Color(0xFF181225).withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: Color(0x14181225),
            width: 0.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: _lightSurfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: const Color(0xFFE9E6FF),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _accent : const Color(0xFF676171),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _accent : const Color(0xFF676171),
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 10,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightSurfaceHigh,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFEAFB),
        selectedColor: const Color(0xFFE9E6FF),
        disabledColor: const Color(0xFFE5E7EB),
        labelStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      inputDecorationTheme: InputStyles.inputDecorationTheme(
        brightness: Brightness.light,
        primaryColor: _accent,
        errorColor: _danger,
      ),
      sliderTheme: InputStyles.sliderTheme(
        primaryColor: _accent,
        inactiveColor: const Color(0xFFD1D5DB),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightSurfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E0EA),
        thickness: 0.8,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: _darkSurface,
        surfaceContainerHigh: _darkSurfaceHigh,
        primary: _accent,
        secondary: _secondary,
        error: _danger,
        tertiary: _success,
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFB4AEBD),
        surfaceContainerHighest: Color(0xFF2B2836),
        primaryContainer: Color(0xFF292359),
        onPrimaryContainer: Color(0xFFE9E6FF),
        shadow: Colors.black,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        // Display styles - for hero/main content
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.2,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.25,
        ),
        // Headline styles - for section headers (SEO: h1, h2, h3)
        headlineLarge: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.35,
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.4,
        ),
        // Title styles - for card titles, important labels
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        titleSmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        // Body styles - for main content (SEO: clear, readable)
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.57,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.67,
        ),
        // Label styles - for buttons, chips, badges (SEO: bold for emphasis)
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1.67,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _darkSurfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: _darkSurfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFF1D4ED8),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF94A3B8),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.white : const Color(0xFF94A3B8),
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 10,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkSurfaceHigh,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF243041),
        selectedColor: const Color(0xFF1D4ED8),
        disabledColor: const Color(0xFF334155),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      inputDecorationTheme: InputStyles.inputDecorationTheme(
        brightness: Brightness.dark,
        primaryColor: _accent,
        errorColor: _danger,
      ),
      sliderTheme: InputStyles.sliderTheme(
        primaryColor: _accent,
        inactiveColor: const Color(0xFF475569),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF39435A),
        thickness: 0.8,
      ),
    );
  }
}
