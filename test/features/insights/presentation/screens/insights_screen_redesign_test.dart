import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/features/insights/domain/models/insight.dart';
import 'package:smartbudget/features/insights/presentation/providers/insight_provider.dart';
import 'package:smartbudget/features/insights/presentation/screens/insights_screen.dart';
import 'package:smartbudget/features/insights/presentation/widgets/insight_card.dart';

void main() {
  Insight insight({
    required String id,
    required String title,
    required String description,
    required InsightType type,
    required InsightImpact impact,
    String? route,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) {
    return Insight(
      id: id,
      title: title,
      description: description,
      type: type,
      impact: impact,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      actionLabel: actionLabel,
      route: route,
      metadata: metadata,
      isRead: false,
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required AsyncValue<List<Insight>> state,
    void Function(String route)? onNavigate,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsProvider.overrideWith(
            (ref) => state.when(
              data: (value) async => value,
              loading: () => Completer<List<Insight>>().future,
              error: (error, stack) async => throw error,
            ),
          ),
        ],
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: InsightsScreen(onNavigate: onNavigate),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders redesigned sections and hides legacy insight cards',
      (tester) async {
    final insights = [
      insight(
        id: 'a',
        title: 'Subscription spike',
        description: 'Streaming subscriptions increased by 18%.',
        type: InsightType.subscription,
        impact: InsightImpact.high,
        route: '/subscriptions',
      ),
      insight(
        id: 'b',
        title: 'Budget drift',
        description: 'Dining budget is near threshold.',
        type: InsightType.budget,
        impact: InsightImpact.medium,
        route: '/budgets',
      ),
    ];

    await pumpScreen(tester, state: AsyncValue.data(insights));

    expect(find.text('Financial Copilot'), findsNWidgets(2));
    expect(find.text('Copilot Overview'), findsOneWidget);
    expect(find.text('Recommended actions'), findsOneWidget);
    expect(find.text('Forecast'), findsOneWidget);
    expect(find.text('Recent Copilot Activity'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.byType(InsightCard), findsNothing);
  });

  testWidgets('shows loading and error states with modern feedback', (tester) async {
    await pumpScreen(tester, state: const AsyncValue.loading());
    expect(find.byType(AppLottieView), findsOneWidget);
    expect(find.text('Analyzing financial patterns…'), findsOneWidget);

    await pumpScreen(
      tester,
      state: AsyncValue.error(Exception('boom'), StackTrace.current),
    );
    expect(find.text('Analysis failed'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  testWidgets('shows empty recommendations and forecast states', (tester) async {
    final insights = [
      insight(
        id: 'c',
        title: 'Savings chance',
        description: 'Set aside more weekly.',
        type: InsightType.saving,
        impact: InsightImpact.low,
      ),
    ];

    await pumpScreen(tester, state: AsyncValue.data(insights));

    expect(find.byKey(const ValueKey<String>('copilot-empty-insights')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('copilot-empty-forecast')), findsOneWidget);
    expect(find.byType(AppLottieView), findsWidgets);
  });

  testWidgets('quick actions call navigation seam with expected routes',
      (tester) async {
    final visited = <String>[];
    await pumpScreen(
      tester,
      state: const AsyncValue.data(<Insight>[]),
      onNavigate: visited.add,
    );

    await tester.tap(find.byKey(const ValueKey<String>('quick-action-scenarios')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('quick-action-budgets')));
    await tester.pumpAndSettle();

    expect(visited.contains('/scenarios'), isTrue);
    expect(visited.contains('/budgets'), isTrue);
  });

  testWidgets('small screens stay scrollable without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final insights = List.generate(
      8,
      (index) => insight(
        id: 'id-$index',
        title: 'Insight $index',
        description: 'Description for $index',
        type: index.isEven ? InsightType.spending : InsightType.trend,
        impact: index % 3 == 0 ? InsightImpact.high : InsightImpact.medium,
        route: '/insights',
      ),
    );

    await pumpScreen(tester, state: AsyncValue.data(insights));
    await tester.fling(find.byType(Scrollable).first, const Offset(0, -900), 1800);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}