import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
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
    final settings = await _securityService.loadSecuritySettings();
    if (!settings.biometricEnabled) return false;
    return _biometricAuthService.shouldRequireAuth();
  }

  Future<void> initialize() async {
    state = state.copyWith(initializing: true, errorMessage: null);
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
      final user = await _repository.me();
      final requiresLocalUnlock = await _shouldRequireLocalUnlock();
      state = SessionState(
        initializing: false,
        authenticated: true,
        localUnlockRequired: requiresLocalUnlock,
        user: user,
      );
    } catch (_) {
      try {
        await _repository.refreshToken();
        final user = await _repository.me();
        final requiresLocalUnlock = await _shouldRequireLocalUnlock();
        state = SessionState(
          initializing: false,
          authenticated: true,
          localUnlockRequired: requiresLocalUnlock,
          user: user,
        );
      } catch (_) {
        await _repository.clearTokens();
        state = const SessionState(
          initializing: false,
          authenticated: false,
          localUnlockRequired: false,
        );
      }
    }
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

  Future<void> logout() async {
    await _repository.logout();
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

  controller.initialize();
  return controller;
});




