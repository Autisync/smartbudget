import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/legal_center_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

Future<void> _pumpLegalCenter(
	WidgetTester tester, {
	required Size size,
}) async {
	tester.view.physicalSize = size;
	tester.view.devicePixelRatio = 1.0;
	addTearDown(tester.view.resetPhysicalSize);
	addTearDown(tester.view.resetDevicePixelRatio);

	await tester.pumpWidget(
		const MaterialApp(
			localizationsDelegates: [
				AppLocalizations.delegate,
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
				GlobalCupertinoLocalizations.delegate,
			],
			supportedLocales: AppLocalizations.supportedLocales,
			home: LegalCenterScreen(),
		),
	);

	await tester.pumpAndSettle();
}

void main() {
	testWidgets('Legal center renders on compact viewport', (
		WidgetTester tester,
	) async {
		await _pumpLegalCenter(tester, size: const Size(390, 844));

		expect(find.byType(LegalCenterScreen), findsOneWidget);
		expect(find.byType(ListTile), findsAtLeastNWidgets(1));
	});

	testWidgets('Legal center renders on wide viewport', (
		WidgetTester tester,
	) async {
		await _pumpLegalCenter(tester, size: const Size(1366, 768));

		expect(find.byType(LegalCenterScreen), findsOneWidget);
		expect(find.byType(ListTile), findsAtLeastNWidgets(1));
	});
}
