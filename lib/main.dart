import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:smartbudget/core/boot/non_fatal_init.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_typography.dart';
import 'package:smartbudget/core/widgets/text_scale_clamp.dart';
import 'package:smartbudget/data/datasources/local/database_cipher.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/core/services/locale_service.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';
import 'package:smartbudget/core/theme/app_theme.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  // Single entry point. ErrorMonitor.init initializes Sentry and runs _boot
  // INSIDE Sentry's error-capturing zone. We must NOT nest another
  // runZonedGuarded here: the Flutter bindings get initialized in Sentry's zone,
  // so calling runApp in a different (nested) zone triggers a "Zone mismatch"
  // and breaks zone-bound async/timers — which left the app stuck on the splash.
  ErrorMonitor.init(_boot);
}

Future<void> _boot() async {
  // Wrap the critical boot path: if any of it throws, show the recovery screen
  // instead of a black/stuck splash. Non-critical steps below have their own
  // try/catch and continue. Uncaught *async* errors after launch are reported by
  // Sentry's zone and do not replace the live UI.
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // L-7 FIX: must run before the first GoogleFonts.* call (AppTheme, built
    // below via the widget tree, is the first) so no screen ever makes a
    // runtime request to Google's font CDN.
    AppTypography.disableRuntimeFetching();

    // Catch Flutter framework errors (widget build failures, etc.): show a
    // visible error widget instead of a black screen AND report to monitoring.
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

    // Route package:sqlite3 to the bundled SQLCipher native library and apply
    // the old-Android workaround BEFORE the encrypted database is first opened.
    DatabaseCipher.setupSqlCipher();
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

    // Initialize services
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await container.read(encryptionServiceProvider).initialize();

    // L-3 FIX: Firebase is optional — the app operates fully offline without
    // it — but a failure here must be reported, not left silent, and must
    // never abort boot. Same contract for notifications and account seeding
    // below; runNonFatalInit (lib/core/boot/non_fatal_init.dart) is the
    // shared implementation so all three behave identically and are unit
    // testable without booting the real app.
    await runNonFatalInit('Firebase.initializeApp', () => Firebase.initializeApp());

    await runNonFatalInit(
      'notificationServiceProvider.initialize',
      () => container.read(notificationServiceProvider).initialize(),
    );

    // Seed the default money-source accounts (Cash, Bank Transfer, Credit Card)
    // and remap any legacy 'default' transactions. Idempotent — safe every run.
    await runNonFatalInit('ensureDefaultAccounts', () {
      final appCurrency = container.read(appCurrencyControllerProvider);
      return container
          .read(accountRepositoryProvider)
          .ensureDefaultAccounts(currency: appCurrency);
    });

    // M-4 FIX: Prune auth logs older than 90 days on every startup.
    unawaited(
      container.read(securityServiceProvider).pruneAuthLogs(),
    );

    // Sentry is already initialized by ErrorMonitor.init (which wraps boot).
    // SentryWidget enables session replay / widget instrumentation.
    runApp(
      SentryWidget(
        child: UncontrolledProviderScope(
          container: container,
          child: const SmartSpendApp(),
        ),
      ),
    );
  } catch (error, stack) {
    // A critical boot step failed before the app could launch. Report it and
    // show the recovery screen instead of a black/stuck splash.
    ErrorMonitor.captureException(error, stack, context: 'boot failure');
    if (kDebugMode) {
      debugPrint('[SmartSpend] Boot failed: $error\n$stack');
    }
    try {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(SentryWidget(child: const _FatalErrorApp()));
    } catch (_) {
      // Binding not ready or runApp failed — nothing more we can do.
    }
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

class SmartSpendApp extends ConsumerStatefulWidget {
  const SmartSpendApp({super.key});

  @override
  ConsumerState<SmartSpendApp> createState() => _SmartSpendAppState();
}

class _SmartSpendAppState extends ConsumerState<SmartSpendApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns to the app (e.g. after verifying their email in the
    // browser), re-fetch the user so a now-verified account is reflected and the
    // verification banner / gate clears without a re-login.
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(sessionControllerProvider.notifier).refreshUser(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      builder: (context, child) => TextScaleClamp(child: child!),
    );
  }
}




