import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/features/reports/presentation/screens/reports_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

Future<void> _pumpReportsScreen(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  ReportsGenerationExecutor? executor,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewPadding = FakeViewPadding(
    left: viewPadding.left,
    top: viewPadding.top,
    right: viewPadding.right,
    bottom: viewPadding.bottom,
  );

  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewPadding);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportsScreen(generationExecutor: executor),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _openGenerationSheet(WidgetTester tester) async {
  final card = find.byKey(const ValueKey('report-card-financial_summary'));
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();

  final generateButton = find.descendant(
    of: card,
    matching: find.widgetWithText(AppButton, 'Generate'),
  );
  await tester.tap(generateButton, warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  group('ReportsScreen redesign', () {
    testWidgets('renders base layout and overview card', (tester) async {
      await _pumpReportsScreen(tester);

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(
          find.byKey(const ValueKey('reports-overview-card')), findsOneWidget);
      expect(find.text('Available Reports'), findsOneWidget);
      expect(find.text('Recent Report Activity'), findsOneWidget);
      expect(find.text('Generated Reports'), findsOneWidget);
    });

    testWidgets('applies quick filters and custom date path', (tester) async {
      await _pumpReportsScreen(tester);

      await tester.tap(find.byKey(const ValueKey('reports-filter-this-week')));
      await tester.pump();
      expect(find.textContaining('Filter applied'), findsOneWidget);

      await tester
          .ensureVisible(find.byKey(const ValueKey('reports-date-from')));
      await tester.tap(find.byKey(const ValueKey('reports-date-from')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('renders all available report cards', (tester) async {
      await _pumpReportsScreen(tester);

      for (final key in <String>[
        'financial_summary',
        'transaction_history',
        'budget_analysis',
        'subscription_costs',
        'savings_progress',
        'cashflow_forecast',
        'category_insights',
        'tax_ready_export',
      ]) {
        expect(find.byKey(ValueKey('report-card-$key')), findsOneWidget);
      }
    });

    testWidgets('opens generation modal and shows format selector',
        (tester) async {
      await _pumpReportsScreen(tester);

      await _openGenerationSheet(tester);

      expect(
          find.byKey(const ValueKey('report-format-dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm-generate-report')),
          findsOneWidget);
    });

    testWidgets('shows loading state while generation is in progress',
        (tester) async {
      final completer = Completer<void>();

      await _pumpReportsScreen(
        tester,
        executor: (_, __, ___) => completer.future,
      );

      await _openGenerationSheet(tester);
      await tester.tap(
        find.byKey(const ValueKey('confirm-generate-report')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(AppLottieView), findsWidgets);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows success toast and activity after successful generation',
        (tester) async {
      await _pumpReportsScreen(
        tester,
        executor: (_, __, ___) async {},
      );

      await _openGenerationSheet(tester);
      await tester.tap(
        find.byKey(const ValueKey('confirm-generate-report')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.text('Report generated successfully'), findsOneWidget);
      expect(find.textContaining('generated'), findsWidgets);
    });

    testWidgets('shows failure toast when generation executor throws',
        (tester) async {
      await _pumpReportsScreen(
        tester,
        executor: (_, __, ___) async {
          throw Exception('generation failed');
        },
      );

      await _openGenerationSheet(tester);
      await tester.tap(
        find.byKey(const ValueKey('confirm-generate-report')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.text('Report generation failed'), findsOneWidget);
      expect(find.textContaining('failed'), findsWidgets);
    });

    testWidgets(
        'renders empty states initially for activity and generated reports',
        (tester) async {
      await _pumpReportsScreen(tester);

      expect(find.text('No report activity yet'), findsOneWidget);
      expect(find.text('No generated reports yet'), findsOneWidget);
      expect(find.byType(AppAnimatedEmptyState), findsAtLeastNWidgets(1));
    });

    testWidgets('compact viewport does not overflow and remains scrollable',
        (tester) async {
      await _pumpReportsScreen(
        tester,
        size: const Size(320, 640),
      );

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    testWidgets('handles bottom safe area padding without overflow',
        (tester) async {
      await _pumpReportsScreen(
        tester,
        size: const Size(390, 844),
        viewPadding: const EdgeInsets.only(bottom: 34),
      );

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ReportsScreen), findsOneWidget);
    });
  });
}
