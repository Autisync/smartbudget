import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum NotificationFrequency { immediate, daily, weekly }

enum NotificationDispatchBlockReason {
  notificationsDisabled,
  categoryDisabled,
  quietHours,
  frequencyCooldown,
}

class NotificationDispatchStatus {
  const NotificationDispatchStatus({
    required this.nextEligibleAt,
    this.blockReason,
  });

  final DateTime? nextEligibleAt;
  final NotificationDispatchBlockReason? blockReason;
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.enabled,
    required this.frequency,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.categories,
  });

  final bool enabled;
  final NotificationFrequency frequency;
  final int quietHoursStart;
  final int quietHoursEnd;
  final Map<String, bool> categories;

  static const defaultCategories = <String, bool>{
    'budgetAlerts': true,
    'savingsNudges': true,
    'healthInsights': true,
  };

  static const defaults = NotificationPreferences(
    enabled: true,
    frequency: NotificationFrequency.immediate,
    quietHoursStart: 22,
    quietHoursEnd: 7,
    categories: defaultCategories,
  );

  NotificationPreferences copyWith({
    bool? enabled,
    NotificationFrequency? frequency,
    int? quietHoursStart,
    int? quietHoursEnd,
    Map<String, bool>? categories,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'frequency': frequency.name,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'categories': categories,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value as bool)) ??
        defaultCategories;

    return NotificationPreferences(
      enabled: json['enabled'] as bool? ?? true,
      frequency: _frequencyFromString(json['frequency'] as String?),
      quietHoursStart:
          ((json['quietHoursStart'] as num?)?.toInt() ?? 22).clamp(0, 23),
      quietHoursEnd:
          ((json['quietHoursEnd'] as num?)?.toInt() ?? 7).clamp(0, 23),
      categories: {
        ...defaultCategories,
        ...rawCategories,
      },
    );
  }

  static NotificationFrequency _frequencyFromString(String? value) {
    switch (value) {
      case 'daily':
        return NotificationFrequency.daily;
      case 'weekly':
        return NotificationFrequency.weekly;
      case 'immediate':
      default:
        return NotificationFrequency.immediate;
    }
  }
}

class NotificationPreferencesService {
  const NotificationPreferencesService(this._storage);

  static const _keyPrefs = 'notification_preferences';
  static const _lastSentPrefix = 'notification_last_sent_';

  final FlutterSecureStorage _storage;

  Future<NotificationPreferences> loadPreferences() async {
    final raw = await _storage.read(key: _keyPrefs);
    if (raw == null || raw.isEmpty) {
      return NotificationPreferences.defaults;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPreferences.fromJson(json);
    } catch (_) {
      return NotificationPreferences.defaults;
    }
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    await _storage.write(key: _keyPrefs, value: jsonEncode(preferences.toJson()));
  }

  Future<bool> shouldDispatch(String categoryKey, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final prefs = await loadPreferences();

    if (!prefs.enabled) return false;
    if (!(prefs.categories[categoryKey] ?? false)) return false;
    if (_isInQuietHours(currentTime, prefs.quietHoursStart, prefs.quietHoursEnd)) {
      return false;
    }

    final lastSentRaw =
        await _storage.read(key: '$_lastSentPrefix$categoryKey');
    if (lastSentRaw == null || lastSentRaw.isEmpty) {
      await _markSent(categoryKey, currentTime);
      return true;
    }

    final lastSent = DateTime.tryParse(lastSentRaw);
    if (lastSent == null) {
      await _markSent(categoryKey, currentTime);
      return true;
    }

    final elapsed = currentTime.difference(lastSent);
    final allowed = switch (prefs.frequency) {
      NotificationFrequency.immediate => true,
      NotificationFrequency.daily => elapsed >= const Duration(days: 1),
      NotificationFrequency.weekly => elapsed >= const Duration(days: 7),
    };

    if (!allowed) return false;

    await _markSent(categoryKey, currentTime);
    return true;
  }

  Future<NotificationDispatchStatus> dispatchStatus(
    String categoryKey, {
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final prefs = await loadPreferences();

    if (!prefs.enabled) {
      return const NotificationDispatchStatus(
        nextEligibleAt: null,
        blockReason: NotificationDispatchBlockReason.notificationsDisabled,
      );
    }

    if (!(prefs.categories[categoryKey] ?? false)) {
      return const NotificationDispatchStatus(
        nextEligibleAt: null,
        blockReason: NotificationDispatchBlockReason.categoryDisabled,
      );
    }

    final quietReadyAt = _isInQuietHours(
      currentTime,
      prefs.quietHoursStart,
      prefs.quietHoursEnd,
    )
        ? _nextOutsideQuietHours(
            currentTime,
            prefs.quietHoursStart,
            prefs.quietHoursEnd,
          )
        : currentTime;

    final lastSentRaw = await _storage.read(key: '$_lastSentPrefix$categoryKey');
    final lastSent = lastSentRaw == null ? null : DateTime.tryParse(lastSentRaw);
    final frequencyReadyAt = switch (prefs.frequency) {
      NotificationFrequency.immediate => currentTime,
      NotificationFrequency.daily =>
        lastSent == null ? currentTime : lastSent.add(const Duration(days: 1)),
      NotificationFrequency.weekly =>
        lastSent == null ? currentTime : lastSent.add(const Duration(days: 7)),
    };

    var candidate = currentTime;
    if (quietReadyAt.isAfter(candidate)) {
      candidate = quietReadyAt;
    }
    if (frequencyReadyAt.isAfter(candidate)) {
      candidate = frequencyReadyAt;
    }

    if (_isInQuietHours(candidate, prefs.quietHoursStart, prefs.quietHoursEnd)) {
      candidate = _nextOutsideQuietHours(
        candidate,
        prefs.quietHoursStart,
        prefs.quietHoursEnd,
      );
    }

    if (!candidate.isAfter(currentTime)) {
      return NotificationDispatchStatus(nextEligibleAt: currentTime);
    }

    final blockedByFrequency = frequencyReadyAt.isAfter(currentTime) &&
        (frequencyReadyAt.isAfter(quietReadyAt) || !quietReadyAt.isAfter(currentTime));

    return NotificationDispatchStatus(
      nextEligibleAt: candidate,
      blockReason: blockedByFrequency
          ? NotificationDispatchBlockReason.frequencyCooldown
          : NotificationDispatchBlockReason.quietHours,
    );
  }

  Future<DateTime?> nextEligibleDispatch(String categoryKey, {DateTime? now}) async {
    final status = await dispatchStatus(categoryKey, now: now);
    return status.nextEligibleAt;
  }

  Future<void> _markSent(String categoryKey, DateTime when) async {
    await _storage.write(
      key: '$_lastSentPrefix$categoryKey',
      value: when.toIso8601String(),
    );
  }

  bool _isInQuietHours(DateTime now, int startHour, int endHour) {
    final hour = now.hour;
    if (startHour == endHour) return false;

    if (startHour < endHour) {
      return hour >= startHour && hour < endHour;
    }

    return hour >= startHour || hour < endHour;
  }

  DateTime _nextOutsideQuietHours(DateTime now, int startHour, int endHour) {
    if (!_isInQuietHours(now, startHour, endHour)) {
      return now;
    }

    final dayStart = DateTime(now.year, now.month, now.day);
    if (startHour < endHour) {
      return DateTime(now.year, now.month, now.day, endHour);
    }

    if (now.hour >= startHour) {
      final nextDay = dayStart.add(const Duration(days: 1));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, endHour);
    }

    return DateTime(now.year, now.month, now.day, endHour);
  }
}

class NotificationPreferencesController
    extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesController(this._service)
      : super(NotificationPreferences.defaults) {
    _load();
  }

  final NotificationPreferencesService _service;

  Future<void> _load() async {
    state = await _service.loadPreferences();
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _service.savePreferences(state);
  }

  Future<void> setFrequency(NotificationFrequency frequency) async {
    state = state.copyWith(frequency: frequency);
    await _service.savePreferences(state);
  }

  Future<void> setQuietHours({required int start, required int end}) async {
    state = state.copyWith(
      quietHoursStart: start.clamp(0, 23),
      quietHoursEnd: end.clamp(0, 23),
    );
    await _service.savePreferences(state);
  }

  Future<void> setCategoryEnabled(String categoryKey, bool enabled) async {
    state = state.copyWith(
      categories: {
        ...state.categories,
        categoryKey: enabled,
      },
    );
    await _service.savePreferences(state);
  }
}
