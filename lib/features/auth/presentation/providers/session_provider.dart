import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/core/services/security_service.dart';
import 'package:smartbudget/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smartbudget/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smartbudget/features/auth/domain/entities/auth_user.dart';
import 'package:smartbudget/features/auth/domain/repositories/auth_repository.dart';

class SessionState {
  const SessionState({
    required this.initializing,
    required this.authenticated,
    required this.localUnlockRequired,
    this.user,
    this.errorMessage,
  });

  final bool initializing;
  final bool authenticated;
  final bool localUnlockRequired;
  final AuthUser? user;
  final String? errorMessage;

  SessionState copyWith({
    bool? initializing,
    bool? authenticated,
    bool? localUnlockRequired,
    AuthUser? user,
    String? errorMessage,
  }) {
    return SessionState(
      initializing: initializing ?? this.initializing,
      authenticated: authenticated ?? this.authenticated,
      localUnlockRequired: localUnlockRequired ?? this.localUnlockRequired,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  static const initial = SessionState(
    initializing: true,
    authenticated: false,
    localUnlockRequired: false,
  );
}

final authBaseUrlProvider = Provider<String>((ref) {
  const configured =
      String.fromEnvironment('AUTH_API_BASE_URL', defaultValue: '');
  if (configured.isNotEmpty) {
    return configured;
  }

  // Release builds use production API; debug defaults vary by platform.
  if (kReleaseMode) {
    return 'https://api.smaartspend.com';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'http://10.0.2.2:8000',
    TargetPlatform.iOS => 'https://api.smaartspend.com',
    _ => 'http://127.0.0.1:8000',
  };
});

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthTokenStorage(secureStorage);
});

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final storage = ref.watch(authTokenStorageProvider);
  final baseUrl = ref.watch(authBaseUrlProvider);
  return AuthApiClient(storage: storage, baseUrl: baseUrl);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(authApiClientProvider);
  final storage = ref.watch(authTokenStorageProvider);
  return AuthRepositoryImpl(remoteClient: client, storage: storage);
});

class SessionController extends StateNotifier<SessionState> {
  SessionController({
    required AuthRepository repository,
    required BiometricAuthService biometricAuthService,
    required SecurityService securityService,
  })  : _repository = repository,
        _biometricAuthService = biometricAuthService,
        _securityService = securityService,
        super(SessionState.initial);

  final AuthRepository _repository;
  final BiometricAuthService _biometricAuthService;
  final SecurityService _securityService;

  Future<bool> _shouldRequireLocalUnlock() async {
    // L-1 FIX: Use BiometricAuthService (Keychain/secure storage) as the
    // authoritative source for whether biometric is enabled, not the DB row
    // which could be stale after an uninstall/reinstall cycle.
    final biometricEnabled = await _biometricAuthService.isBiometricEnabled();
    if (!biometricEnabled) return false;

    // H-4 FIX: Pass the user-configured session timeout from SecuritySettings
    // instead of using a hardcoded 5-minute constant.
    final settings = await _securityService.loadSecuritySettings();
    return _biometricAuthService.shouldRequireAuth(
      timeoutSeconds: settings.sessionTimeout,
    );
  }

  /// Hard ceiling on each network/storage call during cold-start. Without this,
  /// a stalled connection (captive wifi, flaky signal) leaves [initializing]
  /// true forever and the app is stuck on the splash screen. On timeout the call
  /// throws and we fall through to the graceful offline/login fallback below.
  static const Duration _bootCallTimeout = Duration(seconds: 8);

  /// Absolute backstop for the whole boot sequence. Even if a secure-storage
  /// (Keychain) read hangs — or any unforeseen error escapes — the splash must
  /// be released within this window. This is what guarantees the app can never
  /// get permanently stuck on "Getting things ready…".
  static const Duration _bootOverallTimeout = Duration(seconds: 12);

  Future<void> initialize() async {
    state = state.copyWith(initializing: true, errorMessage: null);
    try {
      await _initializeInternal().timeout(_bootOverallTimeout);
    } catch (_) {
      // A hung Keychain read, overall timeout, or any unexpected failure must
      // never strand the user on the splash. Drop to a clean unauthenticated
      // state so the router can show the login screen.
      state = const SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
      );
    } finally {
      // Defence in depth: whatever path ran above, the boot gate is now open.
      if (state.initializing) {
        state = state.copyWith(initializing: false);
      }
    }
  }

  Future<void> _initializeInternal() async {
    // Local secure-storage read — bounded by the overall boot timeout above.
    final tokens = await _repository.readStoredTokens();
    if (tokens == null) {
      state = const SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
      );
      return;
    }

    try {
      final user = await _repository.me().timeout(_bootCallTimeout);
      await _applyAuthenticated(user);
    } catch (e) {
      // Offline-first: a connectivity failure (no network, timeout, captive
      // wifi) must NOT log the user out. If we have a cached user, restore the
      // session offline; the next successful request refreshes it.
      if (_isConnectivityError(e) && await _restoreOffline()) {
        return;
      }
      // Otherwise the access token is likely expired — try one refresh.
      try {
        await _repository.refreshToken().timeout(_bootCallTimeout);
        final user = await _repository.me().timeout(_bootCallTimeout);
        await _applyAuthenticated(user);
      } catch (e2) {
        if (_isConnectivityError(e2) && await _restoreOffline()) {
          return;
        }
        // Genuine auth failure (refresh token invalid/revoked): clear and exit.
        await _repository.clearTokens();
        state = const SessionState(
          initializing: false,
          authenticated: false,
          localUnlockRequired: false,
        );
      }
    }
  }

  Future<void> _applyAuthenticated(AuthUser user) async {
    final requiresLocalUnlock = await _shouldRequireLocalUnlock();
    ErrorMonitor.setUser(id: user.id);
    state = SessionState(
      initializing: false,
      authenticated: true,
      localUnlockRequired: requiresLocalUnlock,
      user: user,
    );
  }

  /// Restores an authenticated session from the locally cached user when the
  /// server is unreachable. Returns false if nothing is cached (caller then
  /// falls back to the login screen).
  Future<bool> _restoreOffline() async {
    final cached = await _repository.readCachedUser();
    if (cached == null) return false;
    final requiresLocalUnlock = await _shouldRequireLocalUnlock();
    ErrorMonitor.setUser(id: cached.id);
    state = SessionState(
      initializing: false,
      authenticated: true,
      localUnlockRequired: requiresLocalUnlock,
      user: cached,
    );
    return true;
  }

  /// True when [error] indicates the device couldn't reach the server (vs. an
  /// auth/validation error), so the session should be preserved offline.
  bool _isConnectivityError(Object error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.unknown:
          return error.error is SocketException;
        default:
          return false;
      }
    }
    return false;
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(initializing: true, errorMessage: null);
    try {
      final result = await _repository.login(
        email: email,
        password: password,
        deviceName: Platform.operatingSystem,
        platform: Platform.operatingSystem,
      );
      state = SessionState(
        initializing: false,
        authenticated: true,
        localUnlockRequired: false,
        user: result.$1,
      );
      return true;
    } on DioException catch (e) {
      state = SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to sign in right now.',
          unauthorizedMessage: 'Email or password is incorrect.',
        ),
      );
      return false;
    } catch (e) {
      state = SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to sign in right now.',
        ),
      );
      return false;
    }
  }

  Future<bool> socialLogin({
    required String provider,
    required String idToken,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    state = state.copyWith(initializing: true, errorMessage: null);
    try {
      final result = await _repository.socialLogin(
        provider: provider,
        idToken: idToken,
        email: email,
        firstName: firstName,
        lastName: lastName,
        deviceName: Platform.operatingSystem,
        platform: Platform.operatingSystem,
      );
      state = SessionState(
        initializing: false,
        authenticated: true,
        localUnlockRequired: false,
        user: result.$1,
      );
      return true;
    } on DioException catch (e) {
      state = SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to complete social sign in right now.',
          unauthorizedMessage:
              'Social authentication failed. Please try again.',
        ),
      );
      return false;
    } catch (e) {
      state = SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to complete social sign in right now.',
        ),
      );
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(initializing: true, errorMessage: null);
    try {
      final result = await _repository.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        deviceName: Platform.operatingSystem,
        platform: Platform.operatingSystem,
      );
      state = SessionState(
        initializing: false,
        authenticated: true,
        localUnlockRequired: false,
        user: result.$1,
      );
      return true;
    } on DioException catch (e) {
      state = SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to create account right now.',
        ),
      );
      return false;
    } catch (e) {
      state = SessionState(
        initializing: false,
        authenticated: false,
        localUnlockRequired: false,
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to create account right now.',
        ),
      );
      return false;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(initializing: true, errorMessage: null);
    try {
      await _repository.forgotPassword(email);
      state = state.copyWith(initializing: false, errorMessage: null);
    } on DioException catch (e) {
      state = state.copyWith(
        initializing: false,
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to process request.',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        initializing: false,
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to process request.',
        ),
      );
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(initializing: true, errorMessage: null);
    try {
      await _repository.resetPassword(token: token, newPassword: newPassword);
      state = state.copyWith(initializing: false, errorMessage: null);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        initializing: false,
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to reset password right now.',
        ),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        initializing: false,
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to reset password right now.',
        ),
      );
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(initializing: true, errorMessage: null);
    try {
      await _repository.verifyEmail(token);
      state = state.copyWith(initializing: false, errorMessage: null);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        initializing: false,
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to verify email right now.',
        ),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        initializing: false,
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to verify email right now.',
        ),
      );
      return false;
    }
  }

  /// Requests a fresh verification email for the signed-in account. Requires an
  /// authenticated session (the backend resolves the recipient from the token).
  Future<bool> resendVerificationEmail() async {
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.resendVerificationEmail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to send a verification email right now.',
        ),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to send a verification email right now.',
        ),
      );
      return false;
    }
  }

  /// Updates the signed-in user's personal details (name) and refreshes the
  /// in-memory session with the server's canonical response.
  Future<bool> updateProfile({String? firstName, String? lastName}) async {
    state = state.copyWith(errorMessage: null);
    try {
      final updated = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );
      state = state.copyWith(user: updated, errorMessage: null);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        errorMessage: _errorMessageFromDio(
          e,
          fallback: 'Unable to update your profile right now.',
        ),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: AppErrorMapper.from(
          e,
          fallback: 'Unable to update your profile right now.',
        ),
      );
      return false;
    }
  }

  /// Re-fetches the current user from the server and updates the session — used
  /// after the user verifies their email on the web (server-side), so the app
  /// reflects the new `isVerified` without requiring a re-login. No-op when not
  /// authenticated; silent on transient/offline failure so it can be called
  /// freely (e.g. on app resume). Returns the refreshed verified state.
  Future<bool> refreshUser() async {
    if (!state.authenticated) return false;
    try {
      final user = await _repository.me().timeout(_bootCallTimeout);
      state = state.copyWith(user: user);
      return user.isVerified;
    } catch (_) {
      return state.user?.isVerified ?? false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    ErrorMonitor.clearUser();
    state = const SessionState(
      initializing: false,
      authenticated: false,
      localUnlockRequired: false,
    );
  }

  void markUnlockedLocally() {
    if (!state.authenticated) return;
    state = state.copyWith(localUnlockRequired: false, errorMessage: null);
  }

  void requireLocalUnlock() {
    if (!state.authenticated) return;
    state = state.copyWith(localUnlockRequired: true, errorMessage: null);
  }

  Future<void> forceLogoutFromRefreshFailure() async {
    await _repository.clearTokens();
    ErrorMonitor.clearUser();
    state = const SessionState(
      initializing: false,
      authenticated: false,
      localUnlockRequired: false,
    );
  }

  String _errorMessageFromDio(
    DioException e, {
    String fallback = 'Something went wrong. Please try again.',
    String unauthorizedMessage = 'Authentication failed. Please sign in again.',
  }) {
    return AppErrorMapper.fromDio(
      e,
      fallback: fallback,
      unauthorizedMessage: unauthorizedMessage,
    );
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final biometricService = ref.watch(biometricAuthServiceProvider);
  final securityService = ref.watch(securityServiceProvider);
  final controller = SessionController(
    repository: repository,
    biometricAuthService: biometricService,
    securityService: securityService,
  );

  final apiClient = ref.watch(authApiClientProvider);
  apiClient.onRefreshFailed = controller.forceLogoutFromRefreshFailure;

  // initialize() handles its own errors and always releases the boot gate, but
  // guard the fire-and-forget future too so nothing can surface as unhandled.
  controller.initialize().catchError((_) {});
  return controller;
});




