import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
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
import 'package:smartbudget/data/repositories/subscription_repository_impl.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  return AppDatabase();
}

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'smartbudget_secure',
    ),
  );
}

@Riverpod(keepAlive: true)
LocalAuthentication localAuth(LocalAuthRef ref) {
  return LocalAuthentication();
}

@Riverpod(keepAlive: true)
EncryptionService encryptionService(EncryptionServiceRef ref) {
  final storage = ref.watch(secureStorageProvider);
  return EncryptionService(storage);
}

@Riverpod(keepAlive: true)
BiometricAuthService biometricAuthService(BiometricAuthServiceRef ref) {
  final localAuth = ref.watch(localAuthProvider);
  final storage = ref.watch(secureStorageProvider);
  return BiometricAuthService(localAuth, storage);
}

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return OnboardingService(storage);
});

final onboardingStatusProvider = FutureProvider<OnboardingStatus>((ref) async {
  final onboardingService = ref.watch(onboardingServiceProvider);
  return onboardingService.readStatus();
});

final themeServiceProvider = Provider<ThemeService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeService(storage);
});

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeModeController(themeService);
});

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return CurrencyService(storage);
});

final localeServiceProvider = Provider<LocaleService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocaleService(storage);
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
  final storage = ref.watch(secureStorageProvider);
  return RolloverPolicyService(storage);
});

final rolloverPolicyControllerProvider =
    StateNotifierProvider<RolloverPolicyController, RolloverPolicy>((ref) {
  final service = ref.watch(rolloverPolicyServiceProvider);
  return RolloverPolicyController(service);
});

final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return NotificationPreferencesService(storage);
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
SecurityService securityService(SecurityServiceRef ref) {
  final database = ref.watch(databaseProvider);
  return SecurityService(database);
}

@Riverpod(keepAlive: true)
RecurringSchedulerService recurringSchedulerService(
    RecurringSchedulerServiceRef ref) {
  final database = ref.watch(databaseProvider);
  return RecurringSchedulerService(database);
}

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
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

@Riverpod(keepAlive: true)
SubscriptionRepositoryImpl subscriptionRepository(
    SubscriptionRepositoryRef ref) {
  final database = ref.watch(databaseProvider);
  return SubscriptionRepositoryImpl(database);
}
