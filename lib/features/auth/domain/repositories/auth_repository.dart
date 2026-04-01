import 'package:smartbudget/features/auth/domain/entities/auth_tokens.dart';
import 'package:smartbudget/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<(AuthUser, AuthTokens)> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? deviceName,
    String? platform,
  });

  Future<(AuthUser, AuthTokens)> login({
    required String email,
    required String password,
    String? deviceName,
    String? platform,
  });

  Future<AuthTokens> refreshToken();
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({required String token, required String newPassword});
  Future<void> verifyEmail(String token);
  Future<AuthUser> me();
  Future<AuthTokens?> readStoredTokens();
  Future<void> storeTokens(AuthTokens tokens);
  Future<void> clearTokens();
}
