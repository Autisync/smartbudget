// Feature-level cover for P3.1's actual guarantee: a failure in one boot
// step (e.g. Firebase) must not prevent the later steps (notifications,
// account seeding) from running, and boot as a whole must not throw — the
// app has to reach a usable state even when an optional integration is
// broken. A true widget-tree boot of main.dart isn't exercisable under
// `flutter test` (Firebase.initializeApp and the notification service both
// call real platform channels with no test harness), so this drives the
// same three-step sequence main.dart's _boot() uses, in the same order,
// with a step wired to fail — proving the sequencing/capture contract that
// _boot() relies on.
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/boot/non_fatal_init.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a failed step during boot does not stop the remaining steps from running',
    () async {
      final completed = <String>[];

      Future<void> bootSequence() async {
        await runNonFatalInit('Firebase.initializeApp', () async {
          throw Exception('Firebase unreachable in this environment');
        });
        await runNonFatalInit('notificationServiceProvider.initialize', () async {
          completed.add('notifications');
        });
        await runNonFatalInit('ensureDefaultAccounts', () async {
          completed.add('accounts');
        });
      }

      await expectLater(bootSequence(), completes);

      expect(
        completed,
        containsAll(['notifications', 'accounts']),
        reason: 'a Firebase init failure must not prevent later boot steps from running',
      );

      final report = ErrorMonitor.compileDiagnosticsReport();
      expect(
        report,
        contains('Firebase.initializeApp'),
        reason: 'the Firebase failure must have been reported to monitoring, not just swallowed',
      );
    },
  );
}
