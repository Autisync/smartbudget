import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:smartbudget/core/providers/core_providers.dart';

part 'scheduler_provider.g.dart';

@riverpod
Future<void> recurringSync(RecurringSyncRef ref) async {
  final scheduler = ref.watch(recurringSchedulerServiceProvider);
  await scheduler.syncRecurringTransactions();
}




