// Feature-level cover for L-7: with GoogleFonts runtime fetching disabled
// and the network fully unavailable, a themed screen must still render its
// text (falling back to the platform default font) with no exception
// surfaced to the user.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/core/theme/app_typography.dart';

class _NetworkDisabledHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('Network access attempted while fully disabled in test');
  }
}

void main() {
  tearDown(() {
    GoogleFonts.config.allowRuntimeFetching = true;
    HttpOverrides.global = null;
  });

  testWidgets(
    'a themed screen renders its text with no exception when the network is fully disabled',
    (tester) async {
      AppTypography.disableRuntimeFetching();
      HttpOverrides.global = _NetworkDisabledHttpOverrides();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(child: Text('SmartSpend renders fine offline')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('SmartSpend renders fine offline'), findsOneWidget);
    },
  );
}
