// Regression cover for P3.1: Firebase/notification/account-seeding init
// failures during boot were only ever `debugPrint`-ed, never reported to
// monitoring — a real production failure in any of these would be
// permanently invisible. runNonFatalInit (lib/core/boot/non_fatal_init.dart)
// is the shared implementation main.dart uses for all three boot steps.
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/boot/non_fatal_init.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runNonFatalInit', () {
    test('a successful step completes without reporting anything', () async {
      var ran = false;
      await runNonFatalInit('unit-test-success', () async {
        ran = true;
      });
      expect(ran, isTrue);
    });

    test('a throwing step is swallowed, not rethrown', () async {
      await expectLater(
        runNonFatalInit('unit-test-throws', () async {
          throw Exception('boom');
        }),
        completes,
      );
    });

    // Mirrors the three real boot call sites in main.dart — each must be
    // independently reported under its own context string.
    for (final context in [
      'Firebase.initializeApp',
      'notificationServiceProvider.initialize',
      'ensureDefaultAccounts',
    ]) {
      test('a failure in "$context" is captured by ErrorMonitor', () async {
        await runNonFatalInit(context, () async {
          throw StateError('$context failed for test');
        });

        final report = ErrorMonitor.compileDiagnosticsReport();
        expect(report, contains('error'));
        expect(report, contains(context));
      });
    }
  });
}
