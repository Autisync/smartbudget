import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/core/providers/core_providers.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<bool> build() async {
    // Check if we need to authenticate
    final bioService = ref.read(biometricAuthServiceProvider);
    final shouldAuth = await bioService.shouldRequireAuth();

    if (!shouldAuth) return true;

    // If biometrics not enabled, allow access (or implement PIN)
    final isEnabled = await bioService.isBiometricEnabled();
    if (!isEnabled) return true;

    return false; // Need to authenticate
  }

  Future<AuthStatus> authenticate() async {
    final bioService = ref.read(biometricAuthServiceProvider);
    final result = await bioService.authenticate(
      reason: 'Authenticate to access your financial data',
    );

    if (result == AuthStatus.authenticated) {
      state = const AsyncValue.data(true);
    }

    return result;
  }

  Future<void> enableBiometric(bool enable) async {
    final bioService = ref.read(biometricAuthServiceProvider);
    await bioService.setBiometricEnabled(enable);
  }
}
