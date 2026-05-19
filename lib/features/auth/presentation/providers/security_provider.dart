import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';

part 'security_provider.g.dart';

@riverpod
Future<SecuritySetting> securitySetting(SecuritySettingRef ref) async {
  return ref.watch(securityServiceProvider).loadSecuritySettings();
}

@riverpod
Future<List<AuthLog>> authLogs(AuthLogsRef ref) async {
  return ref.watch(securityServiceProvider).fetchRecentAuthLogs(limit: 25);
}




