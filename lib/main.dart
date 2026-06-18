import 'dart:async' show unawaited, runZonedGuarded;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/datasources/local/database_cipher.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/core/services/locale_service.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

/// True once the real app has been handed to runApp. After this point an
/// uncaught async error must NOT replace the running UI with the fatal screen —
/// it's almost always a recoverable background error (network, plugin, a
/// provider future), and nuking the whole app over it is what caused the
/// persistent "Something went wrong" screen in release/TestFlight.
bool _appLaunched = false;

void main() {
  // Run boot inside the error monitor (Sentry when a DSN is configured, a no-op
  // otherwise). It installs its own error-capturing zone, and we still guard
  // boot with runZonedGuarded so the fatal-screen recovery path is preserved.
  ErrorMonitor.init(() => runZonedGuarded(_boot, _handleUncaughtError));
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (widget build failures, etc.): show a visible
  // error widget instead of a black screen AND report them to monitoring.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorMonitor.captureFlutterError(details);
    if (kDebugMode) {
      debugPrint('[SmartSpend] Flutter error: ${details.exceptionAsString()}');
    }
  };

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Route package:sqlite3 to the bundled SQLCipher native library and apply the
  // old-Android workaround BEFORE the encrypted database is first opened.
  DatabaseCipher.setupSqlCipher();
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

  // Initialize services
  final container = ProviderContainer();
  await container.read(encryptionServiceProvider).initialize();

  // L-3 FIX: Log Firebase init failures so they don't silently disappear.
  // Firebase is optional — the app operates fully offline without it.
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[SmartSpend] Firebase init failed: $e\n$st');
    }
  }

  // Non-critical startup work: a failure here (e.g. notifications, account
  // seeding) must never abort boot and drop the user onto the fatal screen.
  try {
    await container.read(notificationServiceProvider).initialize();
  } catch (e, st) {
    if (kDebugMode) debugPrint('[SmartSpend] Notification init failed: $e\n$st');
  }

  // Seed the default money-source accounts (Cash, Bank Transfer, Credit Card)
  // and remap any legacy 'default' transactions. Idempotent — safe every run.
  try {
    final appCurrency = container.read(appCurrencyControllerProvider);
    await container
        .read(accountRepositoryProvider)
        .ensureDefaultAccounts(currency: appCurrency);
  } catch (e, st) {
    if (kDebugMode) debugPrint('[SmartSpend] Account seeding failed: $e\n$st');
  }

  // M-4 FIX: Prune auth logs older than 90 days on every startup.
  unawaited(
    container.read(securityServiceProvider).pruneAuthLogs(),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SmartSpendApp(),
    ),
  );
  // From here on, uncaught async errors are recoverable — don't replace the UI.
  _appLaunched = true;
}

/// Top-level handler for unhandled async errors (e.g. network failures,
/// database errors) that escape all try/catch blocks. Without this, these
/// produce a silent black screen. We log in debug and show a recovery UI in
/// release so the user is never left staring at a blank screen.
void _handleUncaughtError(Object error, StackTrace stack) {
  // Report every uncaught async error to monitoring, whether or not the app is
  // already running.
  ErrorMonitor.captureException(error, stack, context: 'uncaught zone error');
  if (kDebugMode) {
    debugPrint('[SmartSpend] Uncaught error: $error\n$stack');
  }
  // If the app is already running, this is a recoverable background error —
  // already reported above, but DO NOT replace the live UI. Replacing it here is
  // what turned transient async errors into a permanent "Something went wrong"
  // screen in release.
  if (_appLaunched) {
    return;
  }
  // Boot failure (before the real app exists): show the recovery screen so the
  // user isn't left on a black screen.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const _FatalErrorApp());
  } catch (_) {
    // Binding not ready or runApp failed — nothing more we can do.
  }
}

/// Minimal recovery app shown when an unrecoverable error prevents the main
/// app from launching. Instructs the user to restart rather than leaving
/// a black screen with no feedback.
class _FatalErrorApp extends StatelessWidget {
  const _FatalErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Color(0xFFEF5350),
                ),
                SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'SmartSpend encountered an unexpected error. '
                  'Please close and reopen the app. '
                  'If the problem persists, reinstalling will reset the app to a clean state.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFB0B0C8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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




