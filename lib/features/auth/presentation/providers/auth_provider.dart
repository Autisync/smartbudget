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

  Future<AuthStatus> enableBiometric(bool enable) async {
    final bioService = ref.read(biometricAuthServiceProvider);
    final securityService = ref.read(securityServiceProvider);

    if (!enable) {
      await bioService.setBiometricEnabled(false);
      await securityService.updateBiometricEnabled(false);
      return AuthStatus.authenticated;
    }

    final isSupported = await bioService.isDeviceSupported();
    if (!isSupported) {
      return AuthStatus.notAvailable;
    }

    final canCheck = await bioService.canCheckBiometrics();
    if (!canCheck) {
      return AuthStatus.noBiometricsEnrolled;
    }

    final available = await bioService.getAvailableBiometrics();
    if (available.isEmpty) {
      return AuthStatus.noBiometricsEnrolled;
    }

    final result = await bioService.authenticate(
      reason: 'Confirm biometric setup',
    );
    if (result != AuthStatus.authenticated) {
      return result;
    }

    await bioService.setBiometricEnabled(true);
    await securityService.updateBiometricEnabled(true);
    return AuthStatus.authenticated;
  }
}




