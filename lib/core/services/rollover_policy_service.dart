import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RolloverPolicy {
  const RolloverPolicy({
    required this.autoRolloverEnabled,
    required this.rolloverDay,
  });

  final bool autoRolloverEnabled;
  final int rolloverDay;

  static const defaults = RolloverPolicy(
    autoRolloverEnabled: true,
    rolloverDay: 1,
  );

  RolloverPolicy copyWith({
    bool? autoRolloverEnabled,
    int? rolloverDay,
  }) {
    return RolloverPolicy(
      autoRolloverEnabled: autoRolloverEnabled ?? this.autoRolloverEnabled,
      rolloverDay: rolloverDay ?? this.rolloverDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoRolloverEnabled': autoRolloverEnabled,
      'rolloverDay': rolloverDay,
    };
  }

  factory RolloverPolicy.fromJson(Map<String, dynamic> json) {
    return RolloverPolicy(
      autoRolloverEnabled: json['autoRolloverEnabled'] as bool? ?? true,
      rolloverDay: (json['rolloverDay'] as num?)?.toInt().clamp(1, 31) ?? 1,
    );
  }
}

/// P3.7: the rollover policy isn't a secret — moved off Keychain-backed
/// secure storage onto SharedPreferences.
class RolloverPolicyService {
  const RolloverPolicyService(this._prefs);

  static const _key = 'budget_rollover_policy';

  final SharedPreferences _prefs;

  Future<RolloverPolicy> loadPolicy() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return RolloverPolicy.defaults;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RolloverPolicy.fromJson(json);
    } catch (_) {
      return RolloverPolicy.defaults;
    }
  }

  Future<void> savePolicy(RolloverPolicy policy) async {
    await _prefs.setString(_key, jsonEncode(policy.toJson()));
  }
}

class RolloverPolicyController extends StateNotifier<RolloverPolicy> {
  RolloverPolicyController(this._service) : super(RolloverPolicy.defaults) {
    _load();
  }

  final RolloverPolicyService _service;

  Future<void> _load() async {
    state = await _service.loadPolicy();
  }

  Future<RolloverPolicy> load() async {
    state = await _service.loadPolicy();
    return state;
  }

  Future<void> setAutoRollover(bool enabled) async {
    state = state.copyWith(autoRolloverEnabled: enabled);
    await _service.savePolicy(state);
  }

  Future<void> setRolloverDay(int day) async {
    final clamped = day.clamp(1, 31);
    state = state.copyWith(rolloverDay: clamped);
    await _service.savePolicy(state);
  }
}




