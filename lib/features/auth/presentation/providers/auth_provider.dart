import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/models/tables.dart' as tables;

part 'auth_provider.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<bool> build() async {
    // Check if we need to authenticate
    final bioService = ref.read(biometricAuthServiceProvider);
    final securityService = ref.read(securityServiceProvider);
    final shouldAuth = await bioService.shouldRequireAuth();

    if (!shouldAuth) return true;

    final settings = await securityService.loadSecuritySettings();
    if (!settings.biometricEnabled) return true;

    final isEnabled = await bioService.isBiometricEnabled();
    if (!isEnabled) return true;

    return false; // Need to authenticate
  }

  Future<AuthStatus> authenticate() async {
    final bioService = ref.read(biometricAuthServiceProvider);
    final securityService = ref.read(securityServiceProvider);
    final result = await bioService.authenticate(
      reason: 'Authenticate to access your financial data',
    );

    final authStatus = result == AuthStatus.authenticated
        ? tables.AuthStatus.success
        : tables.AuthStatus.failed;

    await securityService.logAuthAttempt(
      tables.AuthLogType.biometric,
      authStatus,
      deviceId: 'local_device',
      failedAttempts: result == AuthStatus.authenticated ? 0 : 1,
    );

    if (result == AuthStatus.authenticated) {
      state = const AsyncValue.data(true);
    }

    return result;
  }

  Future<void> enableBiometric(bool enable) async {
    final bioService = ref.read(biometricAuthServiceProvider);
    final securityService = ref.read(securityServiceProvider);
    await bioService.setBiometricEnabled(enable);
    await securityService.updateBiometricEnabled(enable);
  }
}
