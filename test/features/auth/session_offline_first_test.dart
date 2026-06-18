import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/core/services/security_service.dart';
import 'package:smartbudget/features/auth/domain/entities/auth_tokens.dart';
import 'package:smartbudget/features/auth/domain/entities/auth_user.dart';
import 'package:smartbudget/features/auth/domain/repositories/auth_repository.dart';
import 'package:smartbudget/features/auth/presentation/providers/session_provider.dart';

/// Repository fake: only the boot-path methods are implemented; everything else
/// routes to noSuchMethod (and would throw if unexpectedly called).
class _FakeRepo implements AuthRepository {
  _FakeRepo({
    required this.tokens,
    required this.meBehaviour,
    required this.refreshBehaviour,
    this.cachedUser,
  });

  final AuthTokens? tokens;
  final Object? Function() meBehaviour; // returns AuthUser or throws
  final Object? Function() refreshBehaviour;
  final AuthUser? cachedUser;
  bool clearTokensCalled = false;

  static const _user = AuthUser(
    id: 'u1',
    email: 'a@b.com',
    firstName: 'A',
    lastName: 'B',
    isActive: true,
    isVerified: true,
  );

  @override
  Future<AuthTokens?> readStoredTokens() async => tokens;

  @override
  Future<AuthUser> me() async {
    final r = meBehaviour();
    if (r is AuthUser) return r;
    throw r!;
  }

  @override
  Future<AuthTokens> refreshToken() async {
    final r = refreshBehaviour();
    if (r is AuthTokens) return r;
    throw r!;
  }

  @override
  Future<AuthUser?> readCachedUser() async => cachedUser;

  @override
  Future<void> clearTokens() async => clearTokensCalled = true;

  static AuthUser get sampleUser => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}

class _FakeBiometric implements BiometricAuthService {
  @override
  Future<bool> isBiometricEnabled() async => false; // skips local-unlock path

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}

class _FakeSecurity implements SecurityService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}

SessionController _controller(_FakeRepo repo) => SessionController(
      repository: repo,
      biometricAuthService: _FakeBiometric(),
      securityService: _FakeSecurity(),
    );

final _tokens = AuthTokens(
  accessToken: 'a',
  refreshToken: 'r',
  accessTokenExpiresAt: DateTime(2030),
);

void main() {
  test('online: me() succeeds -> authenticated', () async {
    final repo = _FakeRepo(
      tokens: _tokens,
      meBehaviour: () => _FakeRepo.sampleUser,
      refreshBehaviour: () => _tokens,
    );
    final c = _controller(repo);
    await c.initialize();
    expect(c.state.initializing, false);
    expect(c.state.authenticated, true);
    expect(repo.clearTokensCalled, false);
  });

  test('offline: me() connectivity error + cached user -> stays signed in',
      () async {
    final repo = _FakeRepo(
      tokens: _tokens,
      meBehaviour: () => const SocketException('offline'),
      refreshBehaviour: () => const SocketException('offline'),
      cachedUser: _FakeRepo.sampleUser,
    );
    final c = _controller(repo);
    await c.initialize();
    expect(c.state.authenticated, true,
        reason: 'connectivity failure must restore from cache, not log out');
    expect(repo.clearTokensCalled, false,
        reason: 'tokens must be preserved when offline');
  });

  test('offline timeout via DioException is treated as connectivity', () async {
    final repo = _FakeRepo(
      tokens: _tokens,
      meBehaviour: () => DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: RequestOptions(path: '/me'),
      ),
      refreshBehaviour: () => DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: RequestOptions(path: '/refresh'),
      ),
      cachedUser: _FakeRepo.sampleUser,
    );
    final c = _controller(repo);
    await c.initialize();
    expect(c.state.authenticated, true);
  });

  test('auth failure (non-connectivity) + refresh fails -> logged out & cleared',
      () async {
    final repo = _FakeRepo(
      tokens: _tokens,
      meBehaviour: () => Exception('401 unauthorized'),
      refreshBehaviour: () => Exception('401 unauthorized'),
      cachedUser: _FakeRepo.sampleUser, // present, but must NOT be used
    );
    final c = _controller(repo);
    await c.initialize();
    expect(c.state.authenticated, false,
        reason: 'a genuine auth failure must not fall back to the cache');
    expect(repo.clearTokensCalled, true);
  });

  test('no stored tokens -> unauthenticated, boot gate released', () async {
    final repo = _FakeRepo(
      tokens: null,
      meBehaviour: () => _FakeRepo.sampleUser,
      refreshBehaviour: () => _tokens,
    );
    final c = _controller(repo);
    await c.initialize();
    expect(c.state.initializing, false);
    expect(c.state.authenticated, false);
  });
}
