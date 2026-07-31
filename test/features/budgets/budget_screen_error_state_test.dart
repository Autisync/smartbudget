// Feature-level cover for P4.1: budget_screen.dart previously rendered
// 'Error: {error}' with the raw exception interpolated straight in — no
// retry, no visual consistency, and a raw-exception leak (the same class
// of bug fixed elsewhere in P3.2, closed here as a side effect of moving to
// AppErrorState, which never displays the raw error at all). Forces
// budgetListProvider into an error state and asserts the shared
// AppErrorState widget renders with a working Retry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/budgets/presentation/screens/budget_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

int _buildCount = 0;

class _ThrowingBudgetList extends BudgetList {
  @override
  Future<List<Budget>> build() async {
    _buildCount++;
    throw StateError('duplicate key value violates unique constraint "budgets_pkey"');
  }
}

void main() {
  testWidgets(
    'shows AppErrorState (not the raw exception) when budgets fail to load, and Retry re-triggers the provider',
    (tester) async {
      _buildCount = 0;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            budgetListProvider.overrideWith(_ThrowingBudgetList.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BudgetScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(_buildCount, 1);
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Unable to load budgets'), findsOneWidget);
      expect(find.textContaining('budgets_pkey'), findsNothing);
      expect(find.textContaining('unique constraint'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(seconds: 1));

      expect(_buildCount, 2);
    },
  );
}
