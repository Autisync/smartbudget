import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/services/biometric_auth_service.dart';
import 'package:smartbudget/features/auth/presentation/providers/auth_provider.dart';

void main() {
  test('prevents duplicate biometric prompts while one is in flight', () async {
    var callCount = 0;
    final completer = Completer<AuthStatus>();

    final container = ProviderContainer(
      overrides: [
        biometricAuthenticateActionProvider.overrideWithValue(() {
          callCount += 1;
          return completer.future;
        }),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(biometricAuthUiProvider.notifier);

    final first = controller.authenticateForUnlock();
    final second = controller.authenticateForUnlock();

    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(callCount, 1);
    completer.complete(AuthStatus.authenticated);

    final results = await Future.wait([first, second]);
    expect(results.first, AuthStatus.authenticated);
    expect(results.last, AuthStatus.denied);
    expect(
      container.read(biometricAuthUiProvider).phase,
      BiometricUiPhase.success,
    );
  });

  test('moves to fallback phase when biometrics are unavailable', () async {
    final container = ProviderContainer(
      overrides: [
        biometricAuthenticateActionProvider.overrideWithValue(
          () async => AuthStatus.notAvailable,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(biometricAuthUiProvider.notifier)
        .authenticateForUnlock();

    final state = container.read(biometricAuthUiProvider);
    expect(state.phase, BiometricUiPhase.fallback);
    expect(state.lastResult, AuthStatus.notAvailable);
  });
}
