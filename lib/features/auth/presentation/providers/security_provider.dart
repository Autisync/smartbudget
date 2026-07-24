import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart';

part 'security_provider.g.dart';

@riverpod
Future<SecuritySetting> securitySetting(Ref ref) async {
  return ref.watch(securityServiceProvider).loadSecuritySettings();
}

@riverpod
Future<List<AuthLog>> authLogs(Ref ref) async {
  return ref.watch(securityServiceProvider).fetchRecentAuthLogs(limit: 25);
}
