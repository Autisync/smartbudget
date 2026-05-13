import 'package:smartbudget/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smartbudget/features/auth/data/models/auth_models.dart';
import 'package:smartbudget/features/auth/domain/entities/auth_tokens.dart';
import 'package:smartbudget/features/auth/domain/entities/auth_user.dart';
import 'package:smartbudget/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
      {required AuthApiClient remoteClient, required AuthTokenStorage storage})
      : _remoteClient = remoteClient,
        _storage = storage;

  final AuthApiClient _remoteClient;
  final AuthTokenStorage _storage;

  @override
  Future<(AuthUser, AuthTokens)> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _remoteClient.signup(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      deviceName: deviceName,
      platform: platform,
    );
    await _storage.saveTokens(response.tokens);
    return (response.user, response.tokens);
  }

  @override
  Future<(AuthUser, AuthTokens)> login({
    required String email,
    required String password,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _remoteClient.login(
      email: email,
      password: password,
      deviceName: deviceName,
      platform: platform,
    );
    await _storage.saveTokens(response.tokens);
    return (response.user, response.tokens);
  }

  @override
  Future<(AuthUser, AuthTokens)> socialLogin({
    required String provider,
    required String idToken,
    String? email,
    String? firstName,
    String? lastName,
    String? deviceName,
    String? platform,
  }) async {
    final response = await _remoteClient.socialLogin(
      provider: provider,
      idToken: idToken,
      email: email,
      firstName: firstName,
      lastName: lastName,
      deviceName: deviceName,
      platform: platform,
    );
    await _storage.saveTokens(response.tokens);
    return (response.user, response.tokens);
  }

  @override
  Future<void> logout() async {
    final tokens = await _storage.readTokens();
    if (tokens != null) {
      try {
        await _remoteClient.logout(refreshToken: tokens.refreshToken);
      } catch (_) {
        // Always clear local tokens even if network logout fails.
      }
    }
    await _storage.clearTokens();
  }

  @override
  Future<void> forgotPassword(String email) {
    return _remoteClient.forgotPassword(email);
  }

  @override
  Future<void> resetPassword(
      {required String token, required String newPassword}) {
    return _remoteClient.resetPassword(token: token, newPassword: newPassword);
  }

  @override
  Future<void> verifyEmail(String token) {
    return _remoteClient.verifyEmail(token);
  }

  @override
  Future<AuthUser> me() {
    return _remoteClient.me();
  }

  @override
  Future<AuthTokens> refreshToken() async {
    final existing = await _storage.readTokens();
    if (existing == null) {
      throw Exception('No refresh token available');
    }
    final refreshed =
        await _remoteClient.refresh(refreshToken: existing.refreshToken);
    await _storage.saveTokens(refreshed);
    return refreshed;
  }

  @override
  Future<AuthTokens?> readStoredTokens() {
    return _storage.readTokens();
  }

  @override
  Future<void> clearTokens() {
    return _storage.clearTokens();
  }

  @override
  Future<void> storeTokens(AuthTokens tokens) {
    return _storage.saveTokens(
      AuthTokensModel(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessTokenExpiresAt: tokens.accessTokenExpiresAt,
      ),
    );
  }
}
