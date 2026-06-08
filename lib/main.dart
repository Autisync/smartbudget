import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/core/services/locale_service.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final container = ProviderContainer();
  await container.read(encryptionServiceProvider).initialize();

  // L-3 FIX: Log Firebase init failures so they don't silently disappear.
  // In debug mode we print the error; in release mode we swallow it gracefully
  // (Firebase is optional for local-first operation) but this guard ensures
  // we at least see failures during development and CI.
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[SmartSpend] Firebase init failed: $e\n$st');
    }
    // In release mode: continue without Firebase. Core app is local-first.
  }

  await container.read(notificationServiceProvider).initialize();

  // Seed the default money-source accounts (Cash, Bank Transfer, Credit Card)
  // and remap any legacy 'default' transactions. Idempotent — safe every run.
  final appCurrency = container.read(appCurrencyControllerProvider);
  await container
      .read(accountRepositoryProvider)
      .ensureDefaultAccounts(currency: appCurrency);

  // M-4 FIX: Prune auth logs older than 90 days on every startup to prevent
  // unbounded growth of the local auth log table.
  unawaited(
    container.read(securityServiceProvider).pruneAuthLogs(),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SmartSpendApp(),
    ),
  );
}

class SmartSpendApp extends ConsumerWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final appLocale = ref.watch(appLocaleControllerProvider);

    return MaterialApp.router(
      title: 'SmartSpend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleService.supportedLanguageCodes
          .map((code) => Locale(code))
          .toList(),
      locale: appLocale,
    );
  }
}




