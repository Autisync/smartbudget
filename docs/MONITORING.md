# Error Monitoring & Reporting

SmartSpend uses **Sentry** for crash/error monitoring, fronted by a small
facade — `ErrorMonitor` (`lib/core/monitoring/error_monitor.dart`) — so the rest
of the app never imports Sentry directly.

## Enabling it

Monitoring is **off by default** and turns on only when a DSN is provided at
build time (so debug runs and tests need no setup):

```sh
flutter run \
  --dart-define=SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project> \
  --dart-define=SENTRY_ENV=production \
  --dart-define=SENTRY_RELEASE=1.0.0+1
```

Get the DSN from **Sentry → Project Settings → Client Keys (DSN)**. For
TestFlight/App Store builds, pass the same `--dart-define`s to
`flutter build ipa` (and `flutter build appbundle` for Android). iOS also needs
`pod install` after the first `pub get` (CI/Xcode does this automatically).

## What it captures

- **Flutter framework errors** (`FlutterError.onError`) — build/layout failures.
- **Uncaught async errors** (the `runZonedGuarded` handler in `main.dart`).
- **Manual reports** anywhere: `ErrorMonitor.captureException(e, stack)`.
- **Breadcrumbs** for context: `ErrorMonitor.addBreadcrumb('opened reports')`.
- **User association**: the signed-in user's id is attached on login and cleared
  on logout (no email/PII unless explicitly enabled).
- **Performance traces**: 20% sampled in production, 100% in dev.

## On-device diagnostics report

Independent of Sentry, the last ~120 events are kept in memory and can be turned
into a shareable report (e.g. from a hidden Settings action or a support flow):

```dart
final report = ErrorMonitor.compileDiagnosticsReport();
// show in a dialog / Share.share(report)
```

This works fully offline and is handy for beta testers who can't access the
Sentry dashboard.

## Privacy

`sendDefaultPii = false` — IP addresses and request bodies are not sent. Only an
opaque user id is attached. Review `error_monitor.dart` before enabling more.
