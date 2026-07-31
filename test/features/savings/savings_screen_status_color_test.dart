// Feature-level cover for P4.2: savings_screen.dart's "goal achieved" badge
// used raw Colors.green instead of AppColors.statusFor — inconsistent with
// the documented money-color system used everywhere else. Renders a real
// completed savings goal through the actual screen and asserts the
// rendered badge icon's color matches
// AppColors.statusFor(brightness, AppStatus.success) exactly, in both light
// and dark ThemeData.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/data/models/tables.dart' show GoalPriority;
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/features/savings/presentation/screens/savings_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class _AchievedGoalList extends SavingsGoalList {
  @override
  Future<List<SavingsGoal>> build() async => [
        SavingsGoal(
          id: 'g-1',
          title: 'Emergency Fund',
          targetAmount: 1000,
          savedAmount: 1000,
          priority: GoalPriority.high,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
}

void main() {
  Future<void> pumpSavingsScreen(WidgetTester tester, {required Brightness brightness}) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          savingsGoalListProvider.overrideWith(_AchievedGoalList.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SavingsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'a completed savings goal renders its achieved badge with AppColors.statusFor(success) in ${brightness.name} mode',
      (tester) async {
        await pumpSavingsScreen(tester, brightness: brightness);

        final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
        final expected = AppColors.statusFor(brightness, AppStatus.success);

        expect(icon.color, expected);
      },
    );
  }
}
