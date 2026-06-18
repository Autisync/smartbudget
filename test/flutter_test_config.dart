import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs once before every test in the suite (Flutter auto-discovers this file).
///
/// Without a platform, `flutter_secure_storage` reads never complete in tests,
/// which would hang session/onboarding bootstrap (and trip the boot-timeout
/// timers we rely on in production). Seed an in-memory store so every read
/// resolves promptly. Individual tests can still override the storage provider
/// for their own fixtures.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Seed an in-memory store. `app_tour_seen` is set so the first-run coach tour
  // doesn't overlay screens under test (tests that exercise the tour can clear
  // it). Onboarding/legal flags are intentionally left unset so onboarding-flow
  // tests still see a fresh user.
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    'app_tour_seen': 'true',
  });
  await testMain();
}
