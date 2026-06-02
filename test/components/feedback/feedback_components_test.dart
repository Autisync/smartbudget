import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:smartbudget/components/feedback/app_feedback_service.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';

void main() {
  test('AppFeedbackToast suppresses duplicates inside dedupe window', () {
    final message = 'duplicate-check-${DateTime.now().microsecondsSinceEpoch}';

    final first = AppFeedbackToast.shouldSuppressDuplicate(
      message,
      window: const Duration(seconds: 5),
    );
    final second = AppFeedbackToast.shouldSuppressDuplicate(
      message,
      window: const Duration(seconds: 5),
    );

    expect(first, isFalse);
    expect(second, isTrue);
  });

  testWidgets('AppLottieView disables animation when reduced motion is on',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AppLottieView(
              assetPath: 'assets/animations/loading.json',
              animate: true,
            ),
          ),
        ),
      ),
    );

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(lottie.animate, isFalse);
  });

  testWidgets('AppLottieView falls back to icon when asset fails to load',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLottieView(
            assetPath: 'assets/animations/does_not_exist.json',
            fallbackIcon: Icons.warning_rounded,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
  });

  testWidgets('AppFeedbackService shows and dismisses loading overlay',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    final context = tester.element(find.byType(Scaffold));

    AppFeedbackService.showLoading(context, 'Saving preferences...');
    await tester.pump();
    expect(find.text('Saving preferences...'), findsOneWidget);

    AppFeedbackService.dismissLoading();
    await tester.pump();
    expect(find.text('Saving preferences...'), findsNothing);
  });

  testWidgets('AppEmptyState uses Lottie when lottieAsset is provided',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No data',
            message: 'Add your first record.',
            lottieAsset: 'assets/animations/empty_reports.json',
          ),
        ),
      ),
    );

    expect(find.byType(AppLottieView), findsOneWidget);
  });
}
