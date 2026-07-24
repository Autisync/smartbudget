// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$securitySettingHash() => r'8d9783fe5842ee10cebde5b1c2a6051a46175657';

/// See also [securitySetting].
@ProviderFor(securitySetting)
final securitySettingProvider =
    AutoDisposeFutureProvider<SecuritySetting>.internal(
  securitySetting,
  name: r'securitySettingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$securitySettingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecuritySettingRef = AutoDisposeFutureProviderRef<SecuritySetting>;
String _$authLogsHash() => r'fc9078d2116bfdc8a3d46cbe050d574122573a29';

/// See also [authLogs].
@ProviderFor(authLogs)
final authLogsProvider = AutoDisposeFutureProvider<List<AuthLog>>.internal(
  authLogs,
  name: r'authLogsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthLogsRef = AutoDisposeFutureProviderRef<List<AuthLog>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
