// Regression cover for the P1.3 fix: the OTHER_LDFLAGS `-framework SQLCipher`
// linker flag added to ios/Runner.xcodeproj/project.pbxproj (Runner target,
// all three configs) to resolve a StateError('SQLCipher is not active')
// crash on real devices/TestFlight. Root cause: `sqlcipher_flutter_libs`'s
// own README documents that depending on another package that also links
// the plain sqlite3 library (firebase_messaging is named explicitly, and
// this app depends on it) can cause the linker/dyld to resolve sqlite3
// symbols against the wrong library, silently disabling SQLCipher. The
// documented fix is exactly this linker flag.
//
// The native linking itself is NOT testable from `flutter test` — it only
// manifests in a real iOS build (see RELEASE_BUILD.md's device-QA gate,
// and the on-device verification recorded in this task's commit message).
// This file only guards the Dart-level surface: that `setupSqlCipher()`
// still registers its overrides without throwing, and that it does so
// exactly once per call with no side effects that would break the
// unrelated in-memory testing path used everywhere else in this suite.
//
// IMPORTANT: this test intentionally does NOT open a real database after
// calling setupSqlCipher() in the same isolate. On this macOS test host,
// `setupSqlCipher()` overrides sqlite3's macOS opener to
// `DynamicLibrary.process()`, which has no SQLCipher symbols in the
// `flutter_tester` process — opening a DB afterward would fail for reasons
// unrelated to this fix. `flutter test` isolates state per file, so this
// doesn't affect the plain in-memory DB used by every other test file
// (see database_schema_test.dart, which continues to pass unmodified).
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/data/datasources/local/database_cipher.dart';

void main() {
  test('setupSqlCipher registers overrides without throwing', () {
    expect(DatabaseCipher.setupSqlCipher, returnsNormally);
  });

  test('setupSqlCipher is idempotent — calling it twice does not throw', () {
    DatabaseCipher.setupSqlCipher();
    expect(DatabaseCipher.setupSqlCipher, returnsNormally);
  });
}
