# Error Monitoring & Reporting

SmartSpend uses **Sentry** for crash/error monitoring, fronted by a small
facade — `ErrorMonitor` (`lib/core/monitoring/error_monitor.dart`) — so the rest
of the app never imports Sentry directly.

## Enabling it

Monitoring is **on by default** — the project DSN is embedded in `ErrorMonitor`
(a DSN is not a secret; it ships inside the client app). To point a build at a
different Sentry project, or to set the environment/release, pass dart-defines:

```sh
flutter build ipa \
  --dart-define=SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project> \
  --dart-define=SENTRY_ENV=production \
  --dart-define=SENTRY_RELEASE=1.0.0+1
```

To **disable** monitoring entirely, set `_defaultDsn` to an empty string in
`error_monitor.dart`. iOS needs `pod install` after the first `pub get`
(CI/Xcode does this automatically). Tests/debug never initialize Sentry unless
`main()` runs, so they need no setup.

## Verifying the setup

The login screen has a temporary **"Verify Sentry Setup"** button that throws a
`StateError`. Tap it, then confirm the event appears in the Sentry dashboard.
**Remove that button** (in `login_screen.dart`, marked `TEMPORARY`) once
confirmed.

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

`sendDefaultPii = false` — IP addresses and request headers are NOT sent; only
an opaque user id is attached. Session Replay is on (10% of sessions, 100% of
error sessions) but Sentry masks all text and images by default
(`maskAllText`/`maskAllImages`), so on-screen balances/transactions are redacted.
Review these settings in `error_monitor.dart` before public launch.
