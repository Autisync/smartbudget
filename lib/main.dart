import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
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




