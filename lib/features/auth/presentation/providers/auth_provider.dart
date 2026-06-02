import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/models/tables.dart' as tables;

part 'auth_provider.g.dart';

typedef BiometricAuthenticateAction = Future<AuthStatus> Function();

final biometricAuthenticateActionProvider =
    Provider<BiometricAuthenticateAction>((ref) {
  return () => ref.read(authControllerProvider.notifier).authenticate();
});

enum BiometricUiPhase {
  idle,
  openingPrompt,
  authenticating,
  success,
  failed,
  cancelled,
  fallback,
}

class BiometricAuthUiState {
  const BiometricAuthUiState({
    this.phase = BiometricUiPhase.idle,
    this.message,
    this.lastResult,
  });

  final BiometricUiPhase phase;
  final String? message;
  final AuthStatus? lastResult;

  bool get isBusy =>
      phase == BiometricUiPhase.openingPrompt ||
      phase == BiometricUiPhase.authenticating;

  BiometricAuthUiState copyWith({
    BiometricUiPhase? phase,
    String? message,
    AuthStatus? lastResult,
  }) {
    return BiometricAuthUiState(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

final biometricAuthUiProvider =
    StateNotifierProvider<BiometricAuthUiController, BiometricAuthUiState>(
        (ref) {
  return BiometricAuthUiController(ref);
});

class BiometricAuthUiController extends StateNotifier<BiometricAuthUiState> {
  BiometricAuthUiController(this._ref) : super(const BiometricAuthUiState());

  final Ref _ref;
  bool _inFlight = false;

  Future<AuthStatus> authenticateForUnlock() async {
    if (_inFlight) {
      return state.lastResult ?? AuthStatus.denied;
    }

    _inFlight = true;
    state = const BiometricAuthUiState(
      phase: BiometricUiPhase.openingPrompt,
      message: 'Opening biometric prompt...',
    );

    await Future<void>.delayed(const Duration(milliseconds: 120));
    state = const BiometricAuthUiState(
      phase: BiometricUiPhase.authenticating,
      message: 'Waiting for biometric verification...',
    );

    try {
      final result = await _ref
          .read(biometricAuthenticateActionProvider)()
          .timeout(const Duration(seconds: 14), onTimeout: () {
        return AuthStatus.error;
      });
      _applyResult(result);
      return result;
    } finally {
      _inFlight = false;
    }
  }

  void switchToPasswordFallback() {
    state = const BiometricAuthUiState(
      phase: BiometricUiPhase.fallback,
      message: 'Use your password to continue.',
    );
  }

  void reset() {
    state = const BiometricAuthUiState();
  }

  void _applyResult(AuthStatus result) {
    switch (result) {
      case AuthStatus.authenticated:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.success,
          message: 'Verified. Unlocking your session...',
          lastResult: AuthStatus.authenticated,
        );
        return;
      case AuthStatus.denied:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.cancelled,
          message: 'Biometric verification was cancelled or denied.',
          lastResult: AuthStatus.denied,
        );
        return;
      case AuthStatus.notAvailable:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.fallback,
          message: 'Biometrics are not available on this device.',
          lastResult: AuthStatus.notAvailable,
        );
        return;
      case AuthStatus.noBiometricsEnrolled:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.fallback,
          message: 'No biometrics are enrolled. Use password instead.',
          lastResult: AuthStatus.noBiometricsEnrolled,
        );
        return;
      case AuthStatus.lockedOut:
      case AuthStatus.permanentlyLockedOut:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.fallback,
          message: 'Biometrics are locked. Unlock your device and try again.',
          lastResult: AuthStatus.lockedOut,
        );
        return;
      case AuthStatus.error:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.failed,
          message: 'Unable to verify biometrics right now. Try again.',
          lastResult: AuthStatus.error,
        );
        return;
    }
  }
}

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




