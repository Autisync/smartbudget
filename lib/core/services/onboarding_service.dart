import 'package:shared_preferences/shared_preferences.dart';

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

/// L-6 fix: these flags previously lived in Keychain-backed secure storage,
/// which iOS/Android both preserve across an app uninstall/reinstall — a
/// user who deletes and reinstalls the app got dropped straight past
/// onboarding and legal acceptance, as if they'd already gone through it on
/// this device. None of these values are secrets (they're plain booleans/a
/// timestamp), so SharedPreferences — which IS correctly wiped on
/// uninstall — is the right backend. True secrets (auth tokens, the
/// SQLCipher key, biometric state) stay in Keychain via FlutterSecureStorage
/// elsewhere; this service never touches that.
class OnboardingService {
  final SharedPreferences _prefs;

  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyLegalAccepted = 'legal_accepted';
  static const _keyLegalReviewedAt = 'legal_reviewed_at';
  static const _keyAppTourSeen = 'app_tour_seen';

  const OnboardingService(this._prefs);

  Future<OnboardingStatus> readStatus() async {
    final onboardingComplete =
        _prefs.getBool(_keyOnboardingComplete) ?? false;
    final legalAccepted = _prefs.getBool(_keyLegalAccepted) ?? false;
    final legalReviewedAtRaw = _prefs.getString(_keyLegalReviewedAt);
    final legalReviewedAt = legalReviewedAtRaw == null || legalReviewedAtRaw.isEmpty
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
    await _prefs.setBool(_keyOnboardingComplete, true);
    await _prefs.setBool(_keyLegalAccepted, acceptedLegal);
    if (acceptedLegal) {
      await _prefs.setString(
        _keyLegalReviewedAt,
        (reviewedAt ?? DateTime.now().toUtc()).toIso8601String(),
      );
    } else {
      await _prefs.remove(_keyLegalReviewedAt);
    }
  }

  Future<bool> isAppTourSeen() async {
    return _prefs.getBool(_keyAppTourSeen) ?? false;
  }

  Future<void> markAppTourSeen() async {
    await _prefs.setBool(_keyAppTourSeen, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.setBool(_keyOnboardingComplete, false);
    await _prefs.setBool(_keyLegalAccepted, false);
    await _prefs.remove(_keyLegalReviewedAt);
  }
}




