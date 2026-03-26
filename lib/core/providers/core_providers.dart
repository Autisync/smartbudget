import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/core/services/encryption_service.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';

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
