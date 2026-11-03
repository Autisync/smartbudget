import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Central error-monitoring facade for the app.
///
/// Wraps Sentry so the rest of the codebase never imports it directly — call
/// sites depend only on [ErrorMonitor]. It is also a safe no-op until a DSN is
/// supplied at build time, so debug runs and tests need no configuration:
///
/// ```sh
/// flutter run --dart-define=SENTRY_DSN=https://...ingest.sentry.io/...
/// ```
///
/// Regardless of whether Sentry is enabled, a rolling in-memory buffer of recent
/// events is kept so [compileDiagnosticsReport] can produce a shareable report
/// on-device (useful for support, and works fully offline).
class ErrorMonitor {
  ErrorMonitor._();

  /// Project DSN. A DSN is not a secret (it ships inside the client app), so it
  /// is safe to embed as the default. A `--dart-define=SENTRY_DSN=…` build flag
  /// overrides it (e.g. to point staging vs prod at different projects). Set the
  /// default to empty to disable monitoring entirely.
  static const String _dsnOverride = String.fromEnvironment('SENTRY_DSN');
  static const String _defaultDsn =
      'https://afd92e179fe1efbf47208adcf428a14e@o4511355600437248.ingest.de.sentry.io/4511588586422352';
  static String get _dsn =>
      _dsnOverride.isNotEmpty ? _dsnOverride : _defaultDsn;

  static const String _environment = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );

  static const String _release = String.fromEnvironment('SENTRY_RELEASE');

  /// Optional `--dart-define=SENTRY_SAMPLE_RATE=0.5` override for traces/profiles
  /// sampling. Falls back to 0.2 in release / 1.0 in debug. (Dart has no
  /// double.fromEnvironment, so it's read as a string and parsed.)
  static const String _sampleRateOverride =
      String.fromEnvironment('SENTRY_SAMPLE_RATE');

  static double get _sampleRate =>
      double.tryParse(_sampleRateOverride) ?? (kReleaseMode ? 0.2 : 1.0);

  static bool _initialized = false;

  /// True when a DSN was provided and Sentry was initialized successfully.
  static bool get isEnabled => _initialized;

  static final Queue<_Event> _events = Queue<_Event>();
  static const int _maxEvents = 120;

  /// Initializes monitoring and runs [appRunner] inside Sentry's error-capturing
  /// zone. When no DSN is configured this simply runs [appRunner] directly, so
  /// the app behaves identically minus the reporting.
  static Future<void> init(FutureOr<void> Function() appRunner) async {
    if (_dsn.isEmpty) {
      await appRunner();
      return;
    }
    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = _environment;
        if (_release.isNotEmpty) options.release = _release;
        options.attachStacktrace = true;
        options.enableAutoSessionTracking = true;
        // Privacy: this is a finance app, so do NOT attach PII (user IP,
        // request headers). Only an opaque user id is set elsewhere.
        options.sendDefaultPii = false;
        // Crash and error reports only. The privacy policy, the Play Store
        // Data safety form and the App Store privacy label say "crash logs and
        // diagnostics", nothing more: no session replay (it records the
        // screen of a finance app), no profiling, and performance traces only
        // when explicitly turned on for a test build with
        // --dart-define=SENTRY_SAMPLE_RATE=<0..1>.
        options.tracesSampleRate =
            _sampleRateOverride.isNotEmpty ? _sampleRate : 0.0;
        options.enableLogs = false;
        options.replay.sessionSampleRate = 0.0;
        options.replay.onErrorSampleRate = 0.0;
        options.debug = false;
      },
      appRunner: () async {
        _initialized = true;
        await appRunner();
      },
    );
  }

  /// Reports an exception (e.g. from a catch block or a zone handler).
  static Future<void> captureException(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) async {
    _record('error', context == null ? '$error' : '$error — $context');
    if (!_initialized) return;
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Reports a Flutter framework error (wire into `FlutterError.onError`).
  static void captureFlutterError(FlutterErrorDetails details) {
    _record('flutter', details.exceptionAsString());
    if (!_initialized) return;
    unawaited(
      Sentry.captureException(details.exception, stackTrace: details.stack),
    );
  }

  /// Adds a breadcrumb — a lightweight trail of what the user/app was doing
  /// before an error, attached to the next report.
  static void addBreadcrumb(String message, {String category = 'app'}) {
    _record(category, message);
    if (!_initialized) return;
    Sentry.addBreadcrumb(Breadcrumb(message: message, category: category));
  }

  /// Emits a non-fatal warning/info message to monitoring and the local
  /// diagnostics buffer.
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.warning,
    String category = 'app',
  }) async {
    _record(category, message);
    if (!_initialized) return;
    await Sentry.captureMessage(message, level: level);
  }

  /// Associates subsequent events with the signed-in user (id only by default).
  static void setUser({required String id, String? email}) {
    if (!_initialized) return;
    Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: id, email: email)),
    );
  }

  /// Clears the user association (call on logout).
  static void clearUser() {
    if (!_initialized) return;
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// A copy/shareable diagnostics report built from recent in-memory events.
  /// Works whether or not Sentry is enabled.
  static String compileDiagnosticsReport() {
    final buffer = StringBuffer()
      ..writeln('SmartSpend — diagnostics report')
      ..writeln('monitoring: ${isEnabled ? 'enabled' : 'disabled'}')
      ..writeln('environment: $_environment')
      ..writeln('release: ${_release.isEmpty ? 'n/a' : _release}')
      ..writeln('events captured: ${_events.length}')
      ..writeln('---');
    for (final e in _events) {
      buffer.writeln('[${e.category}] ${e.message}');
    }
    return buffer.toString();
  }

  static void _record(String category, String message) {
    _events.add(_Event(category, message));
    while (_events.length > _maxEvents) {
      _events.removeFirst();
    }
    if (kDebugMode) {
      debugPrint('[ErrorMonitor:$category] $message');
    }
  }
}

class _Event {
  _Event(this.category, this.message);
  final String category;
  final String message;
}
