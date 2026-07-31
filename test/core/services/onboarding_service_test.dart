// Regression cover for L-6: onboarding/legal-acceptance flags previously
// lived in Keychain-backed secure storage, which survives an app uninstall
// on both iOS and Android — a reinstalling user was dropped straight past
// onboarding/legal acceptance as if they'd already completed it on this
// device. Moved to SharedPreferences, which IS correctly wiped on uninstall.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/services/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingService> freshService() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return OnboardingService(prefs);
  }

  test('a fresh install reports onboarding and legal as not complete', () async {
    final service = await freshService();
    final status = await service.readStatus();

    expect(status.onboardingComplete, isFalse);
    expect(status.legalAccepted, isFalse);
    expect(status.legalReviewedAt, isNull);
    expect(status.isReady, isFalse);
  });

  test('completeOnboarding persists onboarding + legal acceptance + timestamp', () async {
    final service = await freshService();
    final reviewedAt = DateTime.utc(2026, 1, 15, 10, 30);

    await service.completeOnboarding(acceptedLegal: true, reviewedAt: reviewedAt);
    final status = await service.readStatus();

    expect(status.onboardingComplete, isTrue);
    expect(status.legalAccepted, isTrue);
    expect(status.legalReviewedAt, reviewedAt);
    expect(status.isReady, isTrue);
  });

  test('completeOnboarding without accepting legal does not record a review timestamp', () async {
    final service = await freshService();

    await service.completeOnboarding(acceptedLegal: false);
    final status = await service.readStatus();

    expect(status.onboardingComplete, isTrue);
    expect(status.legalAccepted, isFalse);
    expect(status.legalReviewedAt, isNull);
    expect(status.isReady, isFalse);
  });

  test('resetOnboarding clears completion, acceptance, and the review timestamp', () async {
    final service = await freshService();
    await service.completeOnboarding(acceptedLegal: true);

    await service.resetOnboarding();
    final status = await service.readStatus();

    expect(status.onboardingComplete, isFalse);
    expect(status.legalAccepted, isFalse);
    expect(status.legalReviewedAt, isNull);
  });

  test('the app tour flag defaults to unseen and can be marked seen', () async {
    final service = await freshService();
    expect(await service.isAppTourSeen(), isFalse);

    await service.markAppTourSeen();
    expect(await service.isAppTourSeen(), isTrue);
  });

  test(
    'reinstall simulation: a fresh SharedPreferences instance (uninstall wiped it) '
    'reports not-onboarded again, even for a service that previously completed onboarding',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstInstallPrefs = await SharedPreferences.getInstance();
      final firstInstall = OnboardingService(firstInstallPrefs);
      await firstInstall.completeOnboarding(acceptedLegal: true);
      await firstInstall.markAppTourSeen();
      expect((await firstInstall.readStatus()).isReady, isTrue);

      // Simulates the OS wiping this app's SharedPreferences on uninstall —
      // a fresh backing store, as a real reinstall would produce.
      SharedPreferences.setMockInitialValues({});
      final reinstallPrefs = await SharedPreferences.getInstance();
      final afterReinstall = OnboardingService(reinstallPrefs);

      final status = await afterReinstall.readStatus();
      expect(status.onboardingComplete, isFalse);
      expect(status.legalAccepted, isFalse);
      expect(status.isReady, isFalse);
      expect(await afterReinstall.isAppTourSeen(), isFalse);
    },
  );
}
