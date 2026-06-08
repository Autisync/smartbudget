import 'package:drift/drift.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';
import 'package:smartbudget/data/models/tables.dart' as tables;

class SecurityService {
  final AppDatabase _database;

  SecurityService(this._database);

  Future<SecuritySetting> loadSecuritySettings() async {
    final current = await _database.getSecuritySettings();
    if (current != null) return current;

    final companion = SecuritySettingsCompanion.insert(
      sessionTimeout: const Value(300),
      biometricEnabled: const Value(false),
      pinEnabled: const Value(false),
      maxFailedAttempts: const Value(5),
      lockoutDuration: const Value(900),
      lastSecurityUpdate: Value(DateTime.now()),
    );

    await _database.upsertSecuritySettings(companion);
    final created = await _database.getSecuritySettings();
    return created!;
  }

  Future<void> updateBiometricEnabled(bool enabled) async {
    final settings = await loadSecuritySettings();
    final companion = SecuritySettingsCompanion(
      id: Value(settings.id),
      sessionTimeout: Value(settings.sessionTimeout),
      biometricEnabled: Value(enabled),
      pinEnabled: Value(settings.pinEnabled),
      maxFailedAttempts: Value(settings.maxFailedAttempts),
      lockoutDuration: Value(settings.lockoutDuration),
      lastSecurityUpdate: Value(DateTime.now()),
    );
    await _database.upsertSecuritySettings(companion);
  }

  Future<void> updateSessionTimeout(int seconds) async {
    final settings = await loadSecuritySettings();
    final companion = SecuritySettingsCompanion(
      id: Value(settings.id),
      sessionTimeout: Value(seconds),
      biometricEnabled: Value(settings.biometricEnabled),
      pinEnabled: Value(settings.pinEnabled),
      maxFailedAttempts: Value(settings.maxFailedAttempts),
      lockoutDuration: Value(settings.lockoutDuration),
      lastSecurityUpdate: Value(DateTime.now()),
    );
    await _database.upsertSecuritySettings(companion);
  }

  Future<void> updateMaxFailedAttempts(int attempts) async {
    final settings = await loadSecuritySettings();
    final companion = SecuritySettingsCompanion(
      id: Value(settings.id),
      sessionTimeout: Value(settings.sessionTimeout),
      biometricEnabled: Value(settings.biometricEnabled),
      pinEnabled: Value(settings.pinEnabled),
      maxFailedAttempts: Value(attempts),
      lockoutDuration: Value(settings.lockoutDuration),
      lastSecurityUpdate: Value(DateTime.now()),
    );
    await _database.upsertSecuritySettings(companion);
  }

  Future<List<AuthLog>> fetchRecentAuthLogs({int limit = 20}) async {
    return _database.getAuthLogs(limit: limit);
  }

  Future<void> logAuthAttempt(
    tables.AuthLogType authType,
    tables.AuthStatus status, {
    String deviceId = 'local_device',
    String? ipAddress,
    String? userAgent,
    int failedAttempts = 0,
  }) async {
    await _database.insertAuthLog(
      AuthLogsCompanion.insert(
        deviceId: deviceId,
        authType: authType,
        status: status,
        ipAddress: Value(ipAddress),
        userAgent: Value(userAgent),
        failedAttempts: Value(failedAttempts),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  /// H-2 FIX: Returns true if the device has exceeded [maxFailedAttempts]
  /// within the [lockoutDuration] window — enforcing client-side lockout.
  Future<bool> isLockedOut({String deviceId = 'local_device'}) async {
    final settings = await loadSecuritySettings();
    final recentFailures = await _database.countRecentAuthFailures(
      window: Duration(seconds: settings.lockoutDuration),
      deviceId: deviceId,
    );
    return recentFailures >= settings.maxFailedAttempts;
  }

  /// H-2: Returns when the current lockout window expires, or null if not locked.
  Future<DateTime?> lockoutExpiresAt({String deviceId = 'local_device'}) async {
    final settings = await loadSecuritySettings();
    final logs = await _database.getAuthLogs(limit: settings.maxFailedAttempts + 1);
    final failures = logs
        .where((l) => l.status == tables.AuthStatus.failed && l.deviceId == deviceId)
        .toList();
    if (failures.length < settings.maxFailedAttempts) return null;
    // Lockout expires lockoutDuration seconds after the oldest relevant failure.
    final oldest = failures.last.timestamp;
    return oldest.add(Duration(seconds: settings.lockoutDuration));
  }

  /// M-4 FIX: Deletes auth logs older than [retentionDays]. Call on app startup.
  Future<void> pruneAuthLogs({int retentionDays = 90}) async {
    await _database.pruneAuthLogs(retentionDays: retentionDays);
  }
}




