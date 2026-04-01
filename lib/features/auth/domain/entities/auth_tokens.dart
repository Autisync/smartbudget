class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
}
