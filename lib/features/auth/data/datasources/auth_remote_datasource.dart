import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartbudget/core/network/debug_tls_noop.dart'
    if (dart.library.io) 'package:smartbudget/core/network/debug_tls_io.dart';
import 'package:smartbudget/features/auth/data/models/auth_models.dart';

class AuthTokenStorage {
  AuthTokenStorage(this._secureStorage);

  static const _tokensKey = 'auth_tokens';
  final FlutterSecureStorage _secureStorage;

  Future<void> saveTokens(AuthTokensModel tokens) async {
    await _secureStorage.write(
      key: _tokensKey,
      value: jsonEncode(tokens.toStorageJson()),
    );
  }

  Future<AuthTokensModel?> readTokens() async {
    final raw = await _secureStorage.read(key: _tokensKey);
    if (raw == null || raw.isEmpty) return null;
    return AuthTokensModel.fromStorageJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _tokensKey);
  }
}

class AuthApiClient {
  AuthApiClient({required this.storage, required String baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: const {'Content-Type': 'application/json'},
          ),
        ),
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    configureDebugTlsAdapter(_dio, baseUrl);
    configureDebugTlsAdapter(_refreshDio, baseUrl);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] != false;
          if (!requiresAuth) {
            handler.next(options);
            return;
          }

          final tokens = await storage.readTokens();
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode != 401) {
            handler.next(err);
            return;
          }

          final requestPath = err.requestOptions.path;
          if (requestPath.endsWith('/auth/login') ||
              requestPath.endsWith('/auth/signup') ||
              requestPath.endsWith('/auth/refresh')) {
            handler.next(err);
            return;
          }

          final alreadyRetried = err.requestOptions.extra['retried'] == true;
          if (alreadyRetried) {
            await storage.clearTokens();
            if (onRefreshFailed != null) await onRefreshFailed!.call();
            handler.next(err);
            return;
          }

          final refreshed = await _refreshTokens();
          if (!refreshed) {
            await storage.clearTokens();
            if (onRefreshFailed != null) await onRefreshFailed!.call();
            handler.next(err);
            return;
          }

          final latestTokens = await storage.readTokens();
          final retryOptions = err.requestOptions;
          retryOptions.extra['retried'] = true;
          retryOptions.headers['Authorization'] =
              'Bearer ${latestTokens!.accessToken}';

          try {
            final response = await _dio.fetch<dynamic>(retryOptions);
            handler.resolve(response);
          } catch (_) {
            handler.next(err);
          }
        },
      ),
    );
  }

  final Dio _dio;
  final Dio _refreshDio;
  final AuthTokenStorage storage;
  Future<void> Function()? onRefreshFailed;

  Future<bool> _refreshTokens() async {
    final existing = await storage.readTokens();
    if (existing == null) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': existing.refreshToken},
      );
      final tokens = AuthTokensModel.fromJson(response.data!);
      await storage.saveTokens(tokens);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResponseModel> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/signup',
      options: Options(extra: {'requiresAuth': false}),
      data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'device_name': deviceName,
        'platform': platform,
      },
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      options: Options(extra: {'requiresAuth': false}),
      data: {
        'email': email,
        'password': password,
        'device_name': deviceName,
        'platform': platform,
      },
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<AuthResponseModel> socialLogin({
    required String provider,
    required String idToken,
    String? email,
    String? firstName,
    String? lastName,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/social-login',
      options: Options(extra: {'requiresAuth': false}),
      data: {
        'provider': provider,
        'id_token': idToken,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'device_name': deviceName,
        'platform': platform,
      },
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<AuthTokensModel> refresh({required String refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      options: Options(extra: {'requiresAuth': false}),
      data: {'refresh_token': refreshToken},
    );
    return AuthTokensModel.fromJson(response.data!);
  }

  Future<void> logout({required String refreshToken}) async {
    await _dio.post<void>(
      '/api/v1/auth/logout',
      options: Options(extra: {'requiresAuth': false}),
      data: {'refresh_token': refreshToken},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      '/api/v1/auth/forgot-password',
      options: Options(extra: {'requiresAuth': false}),
      data: {'email': email},
    );
  }

  Future<void> resetPassword(
      {required String token, required String newPassword}) async {
    await _dio.post<void>(
      '/api/v1/auth/reset-password',
      options: Options(extra: {'requiresAuth': false}),
      data: {'token': token, 'new_password': newPassword},
    );
  }

  Future<void> verifyEmail(String token) async {
    await _dio.post<void>(
      '/api/v1/auth/verify-email',
      options: Options(extra: {'requiresAuth': false}),
      data: {'token': token},
    );
  }

  Future<AuthUserModel> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/auth/me');
    return AuthUserModel.fromJson(response.data!);
  }
}
