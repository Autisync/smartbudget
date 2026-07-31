// Regression cover for P3.7: the rollover policy isn't a secret and
// previously lived in Keychain-backed secure storage — moved to
// SharedPreferences.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbudget/core/services/rollover_policy_service.dart';

void main() {
  Future<RolloverPolicyService> freshService() async {
    SharedPreferences.setMockInitialValues({});
    return RolloverPolicyService(await SharedPreferences.getInstance());
  }

  test('defaults to auto-rollover enabled on day 1 when nothing is stored', () async {
    final service = await freshService();
    final policy = await service.loadPolicy();
    expect(policy.autoRolloverEnabled, isTrue);
    expect(policy.rolloverDay, 1);
  });

  test('round-trips a saved policy through SharedPreferences', () async {
    final service = await freshService();
    await service.savePolicy(const RolloverPolicy(
      autoRolloverEnabled: false,
      rolloverDay: 15,
    ));

    final policy = await service.loadPolicy();
    expect(policy.autoRolloverEnabled, isFalse);
    expect(policy.rolloverDay, 15);
  });

  test('corrupted stored JSON falls back to defaults instead of throwing', () async {
    SharedPreferences.setMockInitialValues({'budget_rollover_policy': 'not json'});
    final service = RolloverPolicyService(await SharedPreferences.getInstance());
    final policy = await service.loadPolicy();
    expect(policy.autoRolloverEnabled, RolloverPolicy.defaults.autoRolloverEnabled);
    expect(policy.rolloverDay, RolloverPolicy.defaults.rolloverDay);
  });
}
