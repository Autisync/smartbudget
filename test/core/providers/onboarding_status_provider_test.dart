// Feature-level cover for L-6: proves the actual seam app_router.dart's
// redirect logic reads (onboardingStatusProvider, built on
// onboardingServiceProvider) — not just the underlying OnboardingService in
// isolation — correctly reports "not onboarded" again after a simulated
// reinstall wipes SharedPreferences.
//
// Testing the router's full redirect (onboarding shown vs. main app) would
// also require mocking session/auth state, a much larger harness unrelated
// to this fix; this test covers the exact value the router branches on.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/providers/core_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first launch: onboardingStatusProvider resolves to not-ready', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final status = await container.read(onboardingStatusProvider.future);

    expect(status.isReady, isFalse);
  });

  test(
    'reinstall simulation: completing onboarding then rebuilding the '
    'provider graph against a freshly-wiped SharedPreferences reports '
    'not-ready again, exactly like a real uninstall/reinstall',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstInstallPrefs = await SharedPreferences.getInstance();
      final firstInstallContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(firstInstallPrefs)],
      );
      addTearDown(firstInstallContainer.dispose);

      await firstInstallContainer
          .read(onboardingServiceProvider)
          .completeOnboarding(acceptedLegal: true);
      firstInstallContainer.invalidate(onboardingStatusProvider);
      final beforeReinstall =
          await firstInstallContainer.read(onboardingStatusProvider.future);
      expect(beforeReinstall.isReady, isTrue);

      // The OS wipes SharedPreferences on uninstall; a real reinstall boots
      // main.dart's _boot() again, which builds a brand new ProviderContainer
      // wired to whatever SharedPreferences.getInstance() returns now.
      SharedPreferences.setMockInitialValues({});
      final reinstallPrefs = await SharedPreferences.getInstance();
      final reinstallContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(reinstallPrefs)],
      );
      addTearDown(reinstallContainer.dispose);

      final afterReinstall =
          await reinstallContainer.read(onboardingStatusProvider.future);

      expect(afterReinstall.isReady, isFalse);
      expect(afterReinstall.onboardingComplete, isFalse);
      expect(afterReinstall.legalAccepted, isFalse);
    },
  );

  test(
    'normal repeat launch (no reinstall): re-reading the same container '
    'after completing onboarding still reports ready',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(onboardingServiceProvider)
          .completeOnboarding(acceptedLegal: true);
      container.invalidate(onboardingStatusProvider);

      final status = await container.read(onboardingStatusProvider.future);
      expect(status.isReady, isTrue);

      // A second read (e.g. a later cold start reusing the same, un-reinstalled
      // SharedPreferences-backed disk state) must keep reporting ready.
      container.invalidate(onboardingStatusProvider);
      final statusAgain = await container.read(onboardingStatusProvider.future);
      expect(statusAgain.isReady, isTrue);
    },
  );
}
