import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _lightSurface = Color(0xFFF6F7FB);
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _darkSurface = Color(0xFF1E1E2E);
  static const _darkBackground = Color(0xFF0F0F1A);
  static const _accent = Color(0xFF6366F1);
  // success and warning colors may be added when used by components
  static const _danger = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        surface: _lightSurface,
        primary: _accent,
        secondary: Color(0xFF8B5CF6),
        error: _danger,
        onSurface: Color(0xFF1A1A22),
        surfaceContainerHighest: Color(0xFFE8EAF6),
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        headlineLarge: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _accent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E4EF),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: _darkSurface,
        primary: _accent,
        secondary: Color(0xFF8B5CF6),
        error: _danger,
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF2D2D44),
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16),
      ),
      // Use default CardTheme for compatibility with current Material APIs.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _accent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D2D44),
        thickness: 1,
      ),
    );
  }
}
