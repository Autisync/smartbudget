import 'package:smartbudget/features/auth/domain/entities/auth_tokens.dart';
import 'package:smartbudget/features/auth/domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.isActive,
    required super.isVerified,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  /// Snapshot persisted locally so the session can be restored offline
  /// (see [AuthTokenStorage.saveUser]).
  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'is_active': isActive,
        'is_verified': isVerified,
      };

  factory AuthUserModel.fromStorageJson(Map<String, dynamic> json) =>
      AuthUserModel.fromJson(json);

  factory AuthUserModel.fromEntity(AuthUser user) => AuthUserModel(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        isActive: user.isActive,
        isVerified: user.isVerified,
      );
}

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
    required super.accessTokenExpiresAt,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    final expiresInSeconds = (json['access_token_expires_in'] as num?)?.toInt() ?? 900;
    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_token_expires_at': accessTokenExpiresAt.toIso8601String(),
    };
  }

  factory AuthTokensModel.fromStorageJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.parse(json['access_token_expires_at'] as String),
    );
  }
}

class AuthResponseModel {
  const AuthResponseModel({required this.user, required this.tokens});

  final AuthUserModel user;
  final AuthTokensModel tokens;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokensModel.fromJson(json),
    );
  }
}




