// Regression cover for P3.7: notification preferences (and the per-category
// "last sent" timestamps) aren't secrets and previously lived in
// Keychain-backed secure storage — moved to SharedPreferences. Business
// logic (quiet hours, frequency throttling) is unchanged by this migration
// and isn't re-tested here.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/services/notification_preferences_service.dart';

void main() {
  Future<NotificationPreferencesService> freshService() async {
    SharedPreferences.setMockInitialValues({});
    return NotificationPreferencesService(await SharedPreferences.getInstance());
  }

  test('defaults when nothing is stored', () async {
    final service = await freshService();
    final prefs = await service.loadPreferences();
    expect(prefs.enabled, NotificationPreferences.defaults.enabled);
    expect(prefs.frequency, NotificationPreferences.defaults.frequency);
  });

  test('round-trips saved preferences through SharedPreferences', () async {
    final service = await freshService();
    await service.savePreferences(NotificationPreferences.defaults.copyWith(
      enabled: false,
      frequency: NotificationFrequency.weekly,
      quietHoursStart: 23,
      quietHoursEnd: 6,
    ));

    final loaded = await service.loadPreferences();
    expect(loaded.enabled, isFalse);
    expect(loaded.frequency, NotificationFrequency.weekly);
    expect(loaded.quietHoursStart, 23);
    expect(loaded.quietHoursEnd, 6);
  });

  test('corrupted stored JSON falls back to defaults instead of throwing', () async {
    SharedPreferences.setMockInitialValues({'notification_preferences': 'not json'});
    final service = NotificationPreferencesService(await SharedPreferences.getInstance());
    final prefs = await service.loadPreferences();
    expect(prefs.enabled, NotificationPreferences.defaults.enabled);
  });

  test('shouldDispatch persists the per-category last-sent timestamp across calls', () async {
    final service = await freshService();
    final now = DateTime(2026, 3, 10, 12);

    // Immediate frequency: first call marks sent and allows; a second call
    // moments later must still see that persisted timestamp (unchanged
    // behavior, now backed by SharedPreferences instead of Keychain).
    expect(await service.shouldDispatch('budgetAlerts', now: now), isTrue);
    final status = await service.dispatchStatus('budgetAlerts', now: now);
    expect(status.nextEligibleAt, isNotNull);
  });
}
