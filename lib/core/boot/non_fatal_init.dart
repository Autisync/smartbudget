import 'package:flutter/foundation.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';

/// Runs a non-critical startup step (Firebase, notifications, account
/// seeding) and reports failures to monitoring instead of letting them
/// silently disappear or abort the rest of boot. `context` identifies which
/// step failed in the captured event.
Future<void> runNonFatalInit(String context, Future<void> Function() step) async {
  try {
    await step();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[SmartSpend] $context failed: $e\n$st');
    }
    await ErrorMonitor.captureException(e, st, context: context);
  }
}
