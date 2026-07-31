// Regression cover for L-7: google_fonts fetches font files from Google's
// CDN at runtime by default whenever the requested font isn't bundled
// locally — this app doesn't bundle Inter, so every themed screen made a
// network request on first render (a privacy leak and a reliability gap).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartbudget/core/theme/app_typography.dart';

void main() {
  tearDown(() {
    // Don't leak this global across other test files in the same run.
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  test('disableRuntimeFetching turns off GoogleFonts runtime fetching', () {
    GoogleFonts.config.allowRuntimeFetching = true;

    AppTypography.disableRuntimeFetching();

    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test('textTheme still returns a usable TextTheme with fetching disabled', () {
    GoogleFonts.config.allowRuntimeFetching = false;

    final theme = AppTypography.textTheme(
      const TextTheme(),
      const Color(0xFF000000),
      const Color(0xFF888888),
    );

    expect(theme.bodyLarge, isNotNull);
    expect(theme.bodyLarge!.fontSize, 15);
    expect(theme.headlineLarge, isNotNull);
  });
}
