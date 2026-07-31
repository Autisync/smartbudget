// Feature-level cover for P4.1: savings_screen.dart previously rendered
// 'Error: {error}' with the raw exception interpolated straight in — no
// retry, no visual consistency, and a raw-exception leak closed here as a
// side effect of moving to AppErrorState. Forces savingsGoalListProvider
// into an error state and asserts the shared AppErrorState widget renders
// with a working Retry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/features/savings/presentation/screens/savings_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

int _buildCount = 0;

class _ThrowingSavingsGoalList extends SavingsGoalList {
  @override
  Future<List<SavingsGoal>> build() async {
    _buildCount++;
    throw StateError('connection refused to db.internal:5432');
  }
}

void main() {
  testWidgets(
    'shows AppErrorState (not the raw exception) when savings goals fail to load, and Retry re-triggers the provider',
    (tester) async {
      _buildCount = 0;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            savingsGoalListProvider.overrideWith(_ThrowingSavingsGoalList.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SavingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(_buildCount, 1);
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Unable to load savings goals'), findsOneWidget);
      expect(find.textContaining('db.internal'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(seconds: 1));

      expect(_buildCount, 2);
    },
  );
}
