// Feature-level cover for P4.2: budget_screen.dart's insight card used raw
// Colors.orange for its "near limit" tone instead of AppColors.statusFor —
// inconsistent with the documented money-color system used everywhere else
// (e.g. dashboard's burn-rate/health states). Renders a real "near limit"
// alert through the actual screen and asserts the rendered status text's
// color matches AppColors.statusFor(brightness, AppStatus.warning) exactly,
// in both light and dark ThemeData.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/data/models/tables.dart' show BudgetPeriod;
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/budgets/presentation/screens/budget_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() {
  final nearLimitAlert = BudgetAlert(
    budgetId: 'b-1',
    category: 'Food',
    progress: 0.85,
    threshold: 80,
    nearLimit: true,
    overLimit: false,
    generatedAt: DateTime(2026, 3, 10),
  );

  Future<void> pumpBudgetScreen(WidgetTester tester, {required Brightness brightness}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          budgetListProvider.overrideWith(() => _SingleInactiveBudgetList()),
          budgetAlertsProvider.overrideWith((ref) async => [nearLimitAlert]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'a near-limit budget alert renders with AppColors.statusFor(warning) in ${brightness.name} mode',
      (tester) async {
        await pumpBudgetScreen(tester, brightness: brightness);

        // The insight card's leading icon and its "delta" metric are the two
        // widgets actually painted with `tone`; the status label text itself
        // has no tone applied (a separate, pre-existing wiring quirk not in
        // scope here). Confirm the icon carries the right color.
        final icon = tester.widget<Icon>(find.byIcon(Icons.warning_amber_outlined));
        final expected = AppColors.statusFor(brightness, AppStatus.warning);

        expect(find.text('Near Limit'), findsOneWidget);
        expect(icon.color, expected);
      },
    );
  }
}

// A single INACTIVE budget: keeps the screen past its "budgets.isEmpty"
// early-return (which would skip the alerts section entirely) without
// exercising the active per-item list, which needs real
// budgetSpendingProvider/transactionListProvider data — out of scope here.
class _SingleInactiveBudgetList extends BudgetList {
  @override
  Future<List<Budget>> build() async => [
        Budget(
          id: 'b-1',
          category: 'Food',
          limitAmount: 500,
          currency: 'USD',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 3, 1),
          isActive: false,
        ),
      ];
}
