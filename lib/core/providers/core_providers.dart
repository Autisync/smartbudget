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
import 'package:smartbudget/core/services/encryption_service.dart';
import 'package:smartbudget/core/services/theme_service.dart';
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

@Riverpod(keepAlive: true)
SubscriptionRepositoryImpl subscriptionRepository(
    SubscriptionRepositoryRef ref) {
  final database = ref.watch(databaseProvider);
  return SubscriptionRepositoryImpl(database);
}
