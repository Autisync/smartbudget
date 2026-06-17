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

/// Localizable status messages for the biometric unlock flow. The provider has
/// no BuildContext, so it sets a key here and the UI resolves it to a string.
enum BiometricUiMessage {
  none,
  openingPrompt,
  waiting,
  usePassword,
  verified,
  cancelled,
  notAvailable,
  noneEnrolled,
  locked,
  error,
}

class BiometricAuthUiState {
  const BiometricAuthUiState({
    this.phase = BiometricUiPhase.idle,
    this.message = BiometricUiMessage.none,
    this.lastResult,
  });

  final BiometricUiPhase phase;
  final BiometricUiMessage message;
  final AuthStatus? lastResult;

  bool get isBusy =>
      phase == BiometricUiPhase.openingPrompt ||
      phase == BiometricUiPhase.authenticating;

  BiometricAuthUiState copyWith({
    BiometricUiPhase? phase,
    BiometricUiMessage? message,
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
      message: BiometricUiMessage.openingPrompt,
    );

    await Future<void>.delayed(const Duration(milliseconds: 120));
    state = const BiometricAuthUiState(
      phase: BiometricUiPhase.authenticating,
      message: BiometricUiMessage.waiting,
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
      message: BiometricUiMessage.usePassword,
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
          message: BiometricUiMessage.verified,
          lastResult: AuthStatus.authenticated,
        );
        return;
      case AuthStatus.denied:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.cancelled,
          message: BiometricUiMessage.cancelled,
          lastResult: AuthStatus.denied,
        );
        return;
      case AuthStatus.notAvailable:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.fallback,
          message: BiometricUiMessage.notAvailable,
          lastResult: AuthStatus.notAvailable,
        );
        return;
      case AuthStatus.noBiometricsEnrolled:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.fallback,
          message: BiometricUiMessage.noneEnrolled,
          lastResult: AuthStatus.noBiometricsEnrolled,
        );
        return;
      case AuthStatus.lockedOut:
      case AuthStatus.permanentlyLockedOut:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.fallback,
          message: BiometricUiMessage.locked,
          lastResult: AuthStatus.lockedOut,
        );
        return;
      case AuthStatus.error:
        state = const BiometricAuthUiState(
          phase: BiometricUiPhase.failed,
          message: BiometricUiMessage.error,
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

    // H-2 FIX: Enforce client-side lockout before attempting biometric.
    // Prevents brute-force by checking recent failure count against the
    // user-configured maxFailedAttempts / lockoutDuration from SecuritySettings.
    final locked = await securityService.isLockedOut();
    if (locked) {
      await securityService.logAuthAttempt(
        tables.AuthLogType.biometric,
        tables.AuthStatus.failed,
        deviceId: 'local_device',
        failedAttempts: 0, // counted by isLockedOut, not incremented here
      );
      return AuthStatus.lockedOut;
    }

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
