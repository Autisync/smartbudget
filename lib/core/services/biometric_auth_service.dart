import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricAuthService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyLastAuth = 'last_authentication_time';
  static const _authTimeout = Duration(minutes: 5);

  BiometricAuthService(this._localAuth, this._secureStorage);

  Future<bool> isDeviceSupported() async {
    return await _localAuth.isDeviceSupported();
  }

  Future<bool> canCheckBiometrics() async {
    return await _localAuth.canCheckBiometrics;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  Future<AuthStatus> authenticate({required String reason}) async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!isAvailable || !canCheck) {
        return AuthStatus.notAvailable;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return AuthStatus.noBiometricsEnrolled;
      }

      // Keep the authenticate call simple to stay compatible across
      // local_auth versions. Avoid platform-specific message classes which
      // may not be available in all versions of the package.
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        await _updateLastAuthTime();
        return AuthStatus.authenticated;
      }

      return AuthStatus.denied;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) return AuthStatus.notAvailable;
      if (e.code == auth_error.notEnrolled) {
        return AuthStatus.noBiometricsEnrolled;
      }
      if (e.code == auth_error.lockedOut) return AuthStatus.lockedOut;
      if (e.code == auth_error.permanentlyLockedOut) {
        return AuthStatus.permanentlyLockedOut;
      }
      return AuthStatus.error;
    }
  }

  Future<void> _updateLastAuthTime() async {
    await _secureStorage.write(
      key: _keyLastAuth,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<bool> shouldRequireAuth() async {
    final lastAuthStr = await _secureStorage.read(key: _keyLastAuth);
    if (lastAuthStr == null) return true;

    final lastAuth = DateTime.fromMillisecondsSinceEpoch(
      int.parse(lastAuthStr),
    );
    return DateTime.now().difference(lastAuth) > _authTimeout;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }
}

enum AuthStatus {
  authenticated,
  denied,
  notAvailable,
  noBiometricsEnrolled,
  lockedOut,
  permanentlyLockedOut,
  error,
}
