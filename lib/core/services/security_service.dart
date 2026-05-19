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
}




