// Feature-level cover for P4.3: signup_screen.dart, login_screen.dart,
// budget_screen.dart, and savings_screen.dart had dozens of hardcoded
// English string literals instead of routing through AppLocalizations.
// Confirmed via grep that no hardcoded literals remain in any of the four
// files (aside from two `category: 'Savings'` data identifiers in
// savings_screen.dart, and a kDebugMode-gated developer-only Sentry test
// button in login_screen.dart — neither is user-facing production copy).
//
// This test proves the l10n machinery is genuinely active for these
// screens: pumping each one under a non-English locale (de) renders an
// already-translated string in German, and no exception is thrown
// resolving any of the newly-added l10n.* references this session added.
// German doesn't yet have real translations for the *new* keys added here
// (they fall back to English per Flutter's standard untranslated-message
// behavior, same as P4.1), so this anchors on a pre-existing key that
// already has a real German translation rather than asserting the new
// keys' text differs from English.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/models/tables.dart' show BudgetPeriod;
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/features/auth/presentation/screens/login_screen.dart';
import 'package:smartbudget/features/auth/presentation/screens/signup_screen.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/budgets/presentation/screens/budget_screen.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/features/savings/presentation/screens/savings_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

// A single INACTIVE budget: reaches the "no active budgets" branch
// (l10n.budgetsNoActive, which has a real German translation) rather than
// the earlier "no budgets at all" early-return (l10n.budgetEmptyTitle,
// which doesn't — not useful for proving the locale is genuinely active).
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

class _EmptyGoalList extends SavingsGoalList {
  @override
  Future<List<SavingsGoal>> build() async => [];
}

Future<SharedPreferences> _freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Widget _germanApp(Widget home, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  testWidgets('SignupScreen renders in German with no missing-key exceptions',
      (tester) async {
    await tester.pumpWidget(_germanApp(const SignupScreen(), []));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Bauen Sie gesündere Finanzgewohnheiten auf.'), findsOneWidget);
  });

  testWidgets('LoginScreen renders in German with no missing-key exceptions',
      (tester) async {
    await tester.pumpWidget(_germanApp(const LoginScreen(), []));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Verwalten Sie Ihre Finanzen mit Zuversicht.'), findsOneWidget);
  });

  testWidgets('BudgetScreen renders in German with no missing-key exceptions',
      (tester) async {
    final prefs = await _freshPrefs();
    await tester.pumpWidget(_germanApp(const BudgetScreen(), [
      sharedPreferencesProvider.overrideWithValue(prefs),
      budgetListProvider.overrideWith(_SingleInactiveBudgetList.new),
    ]));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Keine aktiven Budgets'), findsOneWidget);
  });

  testWidgets('SavingsScreen renders in German with no missing-key exceptions',
      (tester) async {
    // Unlike budget_screen.dart's "no active budgets" branch, savings_screen
    // reaches its "no active goals, but some paused/archived exist" branch
    // (l10n.savingsNoActiveGoals — has a real German translation) only via
    // local widget state (_pausedGoalIds/_archivedGoalIds) that a fresh
    // ProviderScope can't seed. With a genuinely empty list it renders the
    // "no goals at all" branch instead (l10n.savingsEmptyTitle), which
    // doesn't yet have a German translation and falls back to English —
    // still valid proof no l10n.* reference throws under this locale.
    final prefs = await _freshPrefs();
    await tester.pumpWidget(_germanApp(const SavingsScreen(), [
      sharedPreferencesProvider.overrideWithValue(prefs),
      savingsGoalListProvider.overrideWith(_EmptyGoalList.new),
    ]));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Create your first savings goal'), findsOneWidget);
  });
}
