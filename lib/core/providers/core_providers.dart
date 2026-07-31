import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/core/services/onboarding_service.dart';
import 'package:smartbudget/core/services/security_service.dart';
import 'package:smartbudget/core/services/recurring_scheduler_service.dart';
import 'package:smartbudget/core/services/notification_service.dart';
import 'package:smartbudget/core/services/exchange_rate_service.dart';
import 'package:smartbudget/core/services/currency_migration_service.dart';
import 'package:smartbudget/core/services/notification_preferences_service.dart';
import 'package:smartbudget/core/services/rollover_policy_service.dart';
import 'package:smartbudget/core/services/encryption_service.dart';
import 'package:smartbudget/core/services/theme_service.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/core/services/locale_service.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';
import 'package:smartbudget/data/encryption/field_encryptor.dart';
import 'package:smartbudget/data/repositories/subscription_repository_impl.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  return AppDatabase();
}

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'smartbudget_secure',
    ),
  );
}

@Riverpod(keepAlive: true)
LocalAuthentication localAuth(Ref ref) {
  return LocalAuthentication();
}

@Riverpod(keepAlive: true)
EncryptionService encryptionService(Ref ref) {
  final storage = ref.watch(secureStorageProvider);
  return EncryptionService(storage);
}

// C-2: Field-level encryption provider — injected into repositories that store
// sensitive free-text in SQLite (notes, payment methods, descriptions).
final fieldEncryptorProvider = Provider<FieldEncryptor>((ref) {
  final encryption = ref.watch(encryptionServiceProvider);
  return FieldEncryptor(encryption);
});

@Riverpod(keepAlive: true)
BiometricAuthService biometricAuthService(Ref ref) {
  final localAuth = ref.watch(localAuthProvider);
  final storage = ref.watch(secureStorageProvider);
  return BiometricAuthService(localAuth, storage);
}

// L-6: overridden at app startup (see main.dart) with the real, already-
// resolved SharedPreferences.getInstance() — that call is async, and this
// provider's dependents (onboardingServiceProvider and everything built on
// it) need to stay synchronous, same as secureStorageProvider above.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a resolved '
    'SharedPreferences instance before use (see main.dart _boot()).',
  );
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingService(prefs);
});

final onboardingStatusProvider = FutureProvider<OnboardingStatus>((ref) async {
  final onboardingService = ref.watch(onboardingServiceProvider);
  try {
    // The router parks on the splash until this resolves, so a stalled
    // secure-storage (Keychain) read could otherwise hang boot. Bound it and
    // fall back to a safe default that keeps the user moving.
    return await onboardingService
        .readStatus()
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    return const OnboardingStatus(
      onboardingComplete: false,
      legalAccepted: false,
    );
  }
});

/// `true` once the user has completed the in-app feature tour.
final appTourSeenProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(onboardingServiceProvider);
  return svc.isAppTourSeen();
});

final themeServiceProvider = Provider<ThemeService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeService(prefs);
});

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeModeController(themeService);
});

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyService(prefs);
});

final localeServiceProvider = Provider<LocaleService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleService(prefs);
});

final appCurrencyControllerProvider =
    StateNotifierProvider<AppCurrencyController, String>((ref) {
  final service = ref.watch(currencyServiceProvider);
  return AppCurrencyController(service);
});

final appLocaleControllerProvider =
    StateNotifierProvider<AppLocaleController, Locale>((ref) {
  final service = ref.watch(localeServiceProvider);
  return AppLocaleController(service);
});

final rolloverPolicyServiceProvider = Provider<RolloverPolicyService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RolloverPolicyService(prefs);
});

final rolloverPolicyControllerProvider =
    StateNotifierProvider<RolloverPolicyController, RolloverPolicy>((ref) {
  final service = ref.watch(rolloverPolicyServiceProvider);
  return RolloverPolicyController(service);
});

final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationPreferencesService(prefs);
});

final notificationPreferencesControllerProvider = StateNotifierProvider<
    NotificationPreferencesController, NotificationPreferences>((ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return NotificationPreferencesController(service);
});

final notificationNextEligibleProvider =
    FutureProvider.family<DateTime?, String>((ref, categoryKey) async {
  ref.watch(notificationPreferencesControllerProvider);
  final service = ref.watch(notificationPreferencesServiceProvider);
  return service.nextEligibleDispatch(categoryKey);
});

final notificationDispatchStatusProvider =
    FutureProvider.family<NotificationDispatchStatus, String>(
        (ref, categoryKey) async {
  ref.watch(notificationPreferencesControllerProvider);
  final service = ref.watch(notificationPreferencesServiceProvider);
  return service.dispatchStatus(categoryKey);
});

@Riverpod(keepAlive: true)
SecurityService securityService(Ref ref) {
  final database = ref.watch(databaseProvider);
  return SecurityService(database);
}

@Riverpod(keepAlive: true)
RecurringSchedulerService recurringSchedulerService(Ref ref) {
  final database = ref.watch(databaseProvider);
  return RecurringSchedulerService(database);
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService();
}

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

final currencyMigrationServiceProvider =
    Provider<CurrencyMigrationService>((ref) {
  final database = ref.watch(databaseProvider);
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);
  final currencyService = ref.watch(currencyServiceProvider);
  return CurrencyMigrationService(
      database, exchangeRateService, currencyService);
});

final notificationInboxProvider =
    StreamProvider<List<AppNotificationEntry>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.watchInbox();
});

final pushPermissionStateProvider =
    FutureProvider<PushPermissionState>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getPushPermissionState();
});

@Riverpod(keepAlive: true)
SubscriptionRepositoryImpl subscriptionRepository(Ref ref) {
  final database = ref.watch(databaseProvider);
  final encryptor = ref.watch(fieldEncryptorProvider);
  // C-2: inject FieldEncryptor so description/paymentMethod/website are encrypted.
  return SubscriptionRepositoryImpl(database, encryptor: encryptor);
}
