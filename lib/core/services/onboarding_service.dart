import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingStatus {
  final bool onboardingComplete;
  final bool legalAccepted;

  const OnboardingStatus({
    required this.onboardingComplete,
    required this.legalAccepted,
  });

  bool get isReady => onboardingComplete && legalAccepted;
}

class OnboardingService {
  final FlutterSecureStorage _secureStorage;

  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyLegalAccepted = 'legal_accepted';

  const OnboardingService(this._secureStorage);

  Future<OnboardingStatus> readStatus() async {
    final onboardingComplete =
        await _secureStorage.read(key: _keyOnboardingComplete) == 'true';
    final legalAccepted =
        await _secureStorage.read(key: _keyLegalAccepted) == 'true';

    return OnboardingStatus(
      onboardingComplete: onboardingComplete,
      legalAccepted: legalAccepted,
    );
  }

  Future<void> completeOnboarding({required bool acceptedLegal}) async {
    await _secureStorage.write(
      key: _keyOnboardingComplete,
      value: 'true',
    );
    await _secureStorage.write(
      key: _keyLegalAccepted,
      value: acceptedLegal.toString(),
    );
  }

  Future<void> resetOnboarding() async {
    await _secureStorage.write(
      key: _keyOnboardingComplete,
      value: 'false',
    );
    await _secureStorage.write(
      key: _keyLegalAccepted,
      value: 'false',
    );
  }
}
