import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingStatus {
  final bool onboardingComplete;
  final bool legalAccepted;
  final DateTime? legalReviewedAt;

  const OnboardingStatus({
    required this.onboardingComplete,
    required this.legalAccepted,
    this.legalReviewedAt,
  });

  bool get isReady => onboardingComplete && legalAccepted;
}

class OnboardingService {
  final FlutterSecureStorage _secureStorage;

  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyLegalAccepted = 'legal_accepted';
  static const _keyLegalReviewedAt = 'legal_reviewed_at';

  const OnboardingService(this._secureStorage);

  Future<OnboardingStatus> readStatus() async {
    final onboardingComplete =
        await _secureStorage.read(key: _keyOnboardingComplete) == 'true';
    final legalAccepted =
        await _secureStorage.read(key: _keyLegalAccepted) == 'true';
    final legalReviewedAtRaw =
        await _secureStorage.read(key: _keyLegalReviewedAt);
    final legalReviewedAt =
        legalReviewedAtRaw == null || legalReviewedAtRaw.isEmpty
            ? null
            : DateTime.tryParse(legalReviewedAtRaw);

    return OnboardingStatus(
      onboardingComplete: onboardingComplete,
      legalAccepted: legalAccepted,
      legalReviewedAt: legalReviewedAt,
    );
  }

  Future<void> completeOnboarding({
    required bool acceptedLegal,
    DateTime? reviewedAt,
  }) async {
    await _secureStorage.write(
      key: _keyOnboardingComplete,
      value: 'true',
    );
    await _secureStorage.write(
      key: _keyLegalAccepted,
      value: acceptedLegal.toString(),
    );
    if (acceptedLegal) {
      await _secureStorage.write(
        key: _keyLegalReviewedAt,
        value: (reviewedAt ?? DateTime.now().toUtc()).toIso8601String(),
      );
    } else {
      await _secureStorage.delete(key: _keyLegalReviewedAt);
    }
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
    await _secureStorage.delete(key: _keyLegalReviewedAt);
  }
}




