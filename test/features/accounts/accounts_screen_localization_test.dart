// Feature-level cover for a re-audit finding: accounts_screen.dart —
// not one of P4.3's originally-audited files — was extensively unlocalized
// (empty state, delete-confirmation dialog, editor sheet, type selector,
// total-balance card). Pumping under a non-English locale proves the l10n
// machinery is genuinely active for every newly-added key: no exception
// resolving any l10n.accounts* reference this fix added, and the one key
// with a real German translation (accountsEmptyTitle) renders translated.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

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
  testWidgets(
      'AccountsScreen empty state renders in German with no missing-key exceptions',
      (tester) async {
    final prefs = await _freshPrefs();
    await tester.pumpWidget(_germanApp(const AccountsScreen(), [
      sharedPreferencesProvider.overrideWithValue(prefs),
      accountsProvider.overrideWith((ref) => Stream.value(<Account>[])),
    ]));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Noch keine Konten'), findsOneWidget);
  });
}
