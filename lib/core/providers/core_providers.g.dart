// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'dfb355b75031c13f4b9aacb208490f1d92f17762';

/// See also [database].
@ProviderFor(database)
final databaseProvider = Provider<AppDatabase>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DatabaseRef = ProviderRef<AppDatabase>;
String _$secureStorageHash() => r'ed88dce95a08c3d0173da54e8f23d477851f8d59';

/// See also [secureStorage].
@ProviderFor(secureStorage)
final secureStorageProvider = Provider<FlutterSecureStorage>.internal(
  secureStorage,
  name: r'secureStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$secureStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SecureStorageRef = ProviderRef<FlutterSecureStorage>;
String _$localAuthHash() => r'558740d844521301fb1fcae6c4964a039532dc12';

/// See also [localAuth].
@ProviderFor(localAuth)
final localAuthProvider = Provider<LocalAuthentication>.internal(
  localAuth,
  name: r'localAuthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$localAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LocalAuthRef = ProviderRef<LocalAuthentication>;
String _$encryptionServiceHash() => r'8698a024ded3e2f6d40c2dce6ddcf482980d70d7';

/// See also [encryptionService].
@ProviderFor(encryptionService)
final encryptionServiceProvider = Provider<EncryptionService>.internal(
  encryptionService,
  name: r'encryptionServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$encryptionServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EncryptionServiceRef = ProviderRef<EncryptionService>;
String _$biometricAuthServiceHash() =>
    r'eb4075adfc8308feec3dae56b9f55218a2b6a35f';

/// See also [biometricAuthService].
@ProviderFor(biometricAuthService)
final biometricAuthServiceProvider = Provider<BiometricAuthService>.internal(
  biometricAuthService,
  name: r'biometricAuthServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricAuthServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BiometricAuthServiceRef = ProviderRef<BiometricAuthService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
