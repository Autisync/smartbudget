import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  const AppTypography._();

  /// L-7 fix: google_fonts fetches font files from Google's CDN at runtime
  /// by default whenever the requested font isn't bundled as a local asset.
  /// This app doesn't bundle Inter, so every themed screen was making a
  /// network request on first render — a privacy leak (contacting Google
  /// with the user's IP on every fresh install) and a reliability gap (the
  /// UI's font depended on network access). Disabling runtime fetching
  /// makes google_fonts fall back to the platform default font instead of
  /// making that request; call this once, before the first GoogleFonts.*
  /// call (see main.dart's _boot()).
  static void disableRuntimeFetching() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  static TextTheme textTheme(TextTheme base, Color body, Color muted) {
    final inter = GoogleFonts.interTextTheme(base);
    return inter.copyWith(
      displayLarge: TextStyle(
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: body,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: body,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: body,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: body,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        height: 1.24,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.28,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: body,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.42,
        fontWeight: FontWeight.w400,
        color: body,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
    );
  }
}
