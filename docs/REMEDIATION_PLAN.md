# SmartSpend Remediation Plan — dev_end

Generated from the Engineering & Product Audit (this session). Executed autonomously via `/loop` at 40-minute
intervals on branch `dev_end`. Every item below follows the same cycle: **implement → unit test → integration/
feature test covering everything the change touches → run full relevant test suite → commit → push to dev_end
→ mark task complete.**

## Constraints locked in before autonomous execution (user-approved, cannot be revisited without asking)
- **No live server/infra changes.** Everything happens as commits on `dev_end`. The production server, Traefik
  config, and `.env` are never touched directly tonight.
- **Secret rotation (C-2): prepare only.** Generate a rotation script + runbook as a deliverable. Do NOT rotate
  the live JWT/Postgres/SMTP secrets — that logs out every user with no warning and needs a human awake for it.
- **Load testing: run for real, against production** (`api.smaartspend.com`) — user's explicit choice, accepting
  the risk. Ramp conservatively, monitor `/health/ready` and error rates throughout, abort if error rate spikes
  or latency degrades sharply. Do not sustain peak load — this is a real production system with real users.
- **Roadmap features (bank sync, net worth, shared budgets, recurring auto-detect, trend charts, guided
  first-run): spec/design only.** No code. Plaid specifically needs a third-party account this session cannot
  create. Each gets a written implementation spec, not an implementation.
- Nothing merges to `main`. `dev_end` is for review — a PR already exists for the user to open when ready:
  https://github.com/Autisync/smartbudget/pull/new/dev_end

## Test philosophy per stack
- **Backend (pytest)**: unit test = isolated function/service test (mock DB/Redis where sensible, or use the
  existing test DB fixture). Integration/feature test = a real request through `TestClient` hitting the actual
  endpoint, asserting on DB state and response — proves the fix didn't break the surrounding auth/finance flow.
- **Flutter (flutter test)**: unit test = the isolated widget/provider/service in question. Feature test = a
  widget test (or existing integration test harness) exercising the whole screen/flow the change sits inside,
  not just the changed function — catches regressions in surrounding state.
- Where an item is infrastructure/process rather than logic (e.g. CI workflow changes, dead-code deletion), the
  "test" is the most meaningful verification available (CI dry-run, `flutter analyze`/`pytest` passing clean,
  a scripted `curl` check) — noted per item.

---

## Phase 1 — Critical (fix first, regardless of what else happens tonight)

### 1.1 Fix reflected XSS on password-reset page (C-1)
- **File**: `backend/app/main.py` (`_reset_password_page_html`, ~line 73-82)
- **Fix**: stop interpolating `token` into an inline `<script>` block via `json.dumps`. Move it into an
  HTML-escaped `data-token` attribute on a DOM element and read it via `dataset.token` in the page's script,
  or at minimum escape `/` → `\/` before interpolation and add a CSP header on this response.
- **Unit test**: `backend/tests/` — new test asserting the rendered HTML for a token containing
  `</script><img src=x onerror=alert(1)>` never contains an unescaped `</script>` sequence outside the
  intended one, and that the token round-trips correctly for a normal alphanumeric token.
- **Feature test**: full request test via `TestClient.get("/r/reset-password?token=...")` for both a malicious
  and a legitimate token — asserts 200, asserts the malicious payload is neutralized, and asserts the normal
  reset flow (page loads, real token embedded, form present) still works end-to-end.

### 1.2 Prepare secret-rotation runbook (C-2) — deliverable only, no execution
- **Output**: `backend/scripts/rotate_secrets.sh` (generates new random `POSTGRES_PASSWORD`, `JWT_SECRET_KEY`,
  `SMTP_PASSWORD` — SMTP password no longer reused across services) + `backend/ROTATION_RUNBOOK.md` documenting
  exact steps, order of operations (rotate DB password → update Postgres → update `.env` → restart backend →
  rotate JWT → all sessions invalidated, expected) and rollback plan.
- **Unit test**: n/a (no executable app code change).
- **Verification**: script runs locally in dry-run mode and produces syntactically valid `.env`-format output;
  reviewed for command-injection safety (no unsanitized interpolation into shell commands).

### 1.3 Investigate and fix SQLCipher native-link crash (mobile, confirmed on today's build)
- **File**: `lib/data/datasources/local/database_cipher.dart`, `ios/Podfile`, `ios/Runner.xcodeproj`
- **Investigation**: resume the simulator build already in progress; reproduce the `StateError` on-device/
  simulator; check whether it's the SPM/CocoaPods hybrid-resolution conflict flagged in the build warning, or
  the `IPHONEOS_DEPLOYMENT_TARGET` 14.0→15.0 bump, or a `use_frameworks!` symbol-visibility issue with
  `DynamicLibrary.process()`.
- **Fix**: whatever the root cause turns out to be — likely candidates: force CocoaPods-only resolution for
  `sqlcipher_flutter_libs` (disable SPM for that plugin explicitly), or link SQLCipher statically instead of
  as a dynamic framework.
- **Unit test**: cannot unit-test native linking from `flutter test` (documented, intentional — this is exactly
  why RELEASE_BUILD.md gates it on device QA). Instead: a `flutter test` regression test confirming
  `setupSqlCipher()` + the Drift schema still open correctly against the *testing* in-memory path (proves no
  Dart-level regression).
- **Feature test**: on-device/simulator verification per `RELEASE_BUILD.md`'s existing checklist — fresh
  install, add a transaction, confirm `PRAGMA cipher_version` returns non-empty, confirm no `StateError` on
  launch. This is the real test for this item; record the result in the commit message.

### 1.4 Close Apple Sign-In email-spoofing account-takeover path (H-1)
- **File**: `backend/app/services/auth_service.py` (`_verify_apple_token` / `social_login`, ~line 141-188,
  338-381)
- **Fix**: stop trusting client-supplied `email` as a fallback identity. Resolve/store by Apple's stable `sub`
  claim (add an `apple_sub` column + migration if not already present via existing OAuth-provider fields;
  otherwise map through the existing social-identity table). If the token lacks an email claim and no prior
  `apple_sub` mapping exists, reject with a clear "re-authenticate, email required" error instead of falling
  back to the request body.
- **Unit test**: `auth_service` test asserting a token with no `email` claim and a client-supplied email
  matching an *existing different user's* email does NOT log the caller in as that user.
- **Feature test**: full `/auth/social-login` request test — (a) valid Apple token with email claim → normal
  login works unchanged; (b) valid Apple token without email claim, no prior mapping → rejected with a clear
  error, not a silent login as someone else; (c) returning user via `apple_sub` on a second login without an
  email claim → still logs in correctly. Also re-run the full existing auth test suite to confirm Google
  social-login and password login are unaffected.

---

## Phase 2 — Before public launch (security & backend)

### 2.1 Fix Argon2 timing side-channel on signup/login (H-2)
- **File**: `backend/app/services/auth_service.py` (~line 55-72, 100-103)
- **Fix**: on the "account doesn't exist" fast paths, run a dummy `verify_password()` against a static
  precomputed hash so response time is constant regardless of account existence.
- **Unit test**: assert `hash_password`/`verify_password` timing helper is invoked on both branches (mock and
  assert call count, not wall-clock — wall-clock assertions are flaky in CI).
- **Feature test**: statistical timing test — N requests each for "existing user, wrong password" vs.
  "nonexistent user", assert the mean latency difference is below a generous threshold (e.g. <20ms), run
  the full signup/login test suite to confirm no behavioral regression in either flow.

### 2.2 Fix per-account login rate-limit gap (M-1)
- **File**: `backend/app/services/rate_limiter.py`, `backend/app/api/v1/endpoints/auth.py` (~line 55-56)
- **Fix**: add a second Redis-backed bucket keyed only on `email` (IP-independent), e.g. 20-30 attempts/hour,
  alongside the existing per-`(IP, email)` bucket. Both must pass for a login attempt to proceed.
- **Unit test**: `rate_limiter` test — simulate the per-IP bucket never filling (different IP each call) while
  the per-email bucket does fill; assert the limiter still blocks after the email-only threshold.
- **Feature test**: `/auth/login` request test simulating attempts from many distinct source IPs against one
  target email, asserting the account-level limiter still engages; re-run existing rate-limit tests to confirm
  the legitimate single-IP case is unaffected.

### 2.3 Fix CORS empty-string wildcard fallback (M-2)
- **File**: `backend/app/core/config.py` (`production_secret_issues`, ~line 71-74), `backend/app/main.py`
  (~line 301-311)
- **Fix**: treat an empty/unparseable `CORS_ORIGINS` the same as `"*"` in the startup guard; fail closed
  (raise on startup) in non-development environments instead of silently defaulting to wildcard.
- **Unit test**: `config` test asserting `production_secret_issues()` flags both `CORS_ORIGINS="*"` and
  `CORS_ORIGINS=""` as issues in a simulated production environment.
- **Feature test**: app-startup test with `CORS_ORIGINS=""` and `ENVIRONMENT=production` asserting the app
  fails to start (or the guard raises) rather than serving with wildcard CORS; confirm a valid
  `CORS_ORIGINS="https://smaartspend.com"` still starts and applies the correct origin list.

### 2.4 Docker hardening — non-root user + .dockerignore (M-3)
- **File**: `backend/Dockerfile`, new `backend/.dockerignore`
- **Fix**: add a non-root `USER app` after dependency install; add `.dockerignore` excluding `.env*`, `.git`,
  `tests/`, `__pycache__/`.
- **Unit test**: n/a (infra, not app logic).
- **Verification test**: `docker build` succeeds; `docker run --rm <image> whoami` returns the non-root user,
  not `root`; confirm the built image, when inspected, contains no `.env` file layer.

### 2.5 Add security headers middleware + CSP (M-4)
- **File**: new `backend/app/middleware/security_headers.py`, wired in `backend/app/main.py`
- **Fix**: add middleware setting `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
  `Referrer-Policy: strict-origin-when-cross-origin`, and a CSP scoped to the two HTML pages in `main.py`
  (`script-src 'self'`, no `unsafe-inline` — depends on 1.1's fix landing first so this doesn't break the
  reset page).
- **Unit test**: middleware unit test asserting headers are present on a bare response.
- **Feature test**: `TestClient` requests to `/r/reset-password`, `/health`, and an API endpoint — assert all
  three carry the new headers, and re-run the 1.1 XSS regression test to confirm CSP + the escaping fix work
  together (defense in depth, not double-fixing the same bug).

### 2.6 Add pagination to budgets, savings-goals, subscriptions endpoints
- **File**: `backend/app/api/v1/endpoints/finance.py` (~line 154-179), `backend/app/schemas/finance.py`
- **Fix**: mirror the existing `transactions` pagination pattern (`limit` default 50 / max 200, `offset`,
  `total` in response) onto all three endpoints; introduce a shared `PageMeta`/`Page[T]` schema if not already
  generic.
- **Unit test**: repository-layer test asserting `limit`/`offset` are honored and `total` reflects the full
  count independent of the page returned.
- **Feature test**: endpoint test seeding >200 rows for one user across budgets/goals/subscriptions, asserting
  default and max-limit behavior, and that a second user's data never leaks into the first page (existing IDOR
  protection preserved). Re-run the full finance endpoint test suite.

### 2.7 DB pool tuning, index verification under load, multi-worker uvicorn config
- **File**: `backend/app/db/session.py` (explicit `pool_size`/`max_overflow`/`pool_timeout`), `backend/
  docker-compose.yml` (uvicorn `--workers`), new Alembic migration adding partial index
  `auth_sessions(user_id) WHERE revoked_at IS NULL`
- **Fix**: set explicit, documented pool bounds; add the partial index; document (don't necessarily change
  replica count) the chosen worker count with rationale.
- **Unit test**: migration test — apply/rollback the new index migration cleanly against a test DB.
- **Feature test**: `EXPLAIN ANALYZE` captured for the login-by-email query and the active-session-by-user
  query before/after the index, saved into `backend/PERFORMANCE_NOTES.md` as evidence (this is the closest
  thing to a "test" for a query-plan change); confirm the full test suite still passes against the new pool
  config (no connection-exhaustion regressions in the test run itself).

### 2.8 Fix duplicate hourly subscription-notification bug
- **File**: `backend/app/tasks/finance.py` (`check_subscriptions`, ~line 24-37), `backend/app/models/
  finance.py` (add `last_notified_at` to `Subscription` or a uniqueness constraint on
  `(subscription_id, due_date)` for `Notification`), new migration
- **Fix**: make the task idempotent — only notify once per due date per subscription.
- **Unit test**: task-level test — running `check_subscriptions` twice in a row for the same due subscription
  produces exactly one `Notification` row, not two.
- **Feature test**: seed a subscription due today, run the Celery task synchronously three times (simulating
  three hourly beats), assert exactly one notification exists and it reaches the existing notification-delivery
  path unchanged; re-run the subscriptions test suite.

### 2.9 Backend error monitoring + structured logging + global exception handler
- **File**: `backend/app/main.py`, `backend/app/core/config.py` (Sentry DSN setting), `backend/
  requirements.txt` (`sentry-sdk[fastapi]`)
- **Fix**: initialize Sentry (safe no-op without a DSN, matching the Flutter app's pattern), add a global
  FastAPI exception handler that logs with request context and reports to Sentry before returning a sanitized
  500, and a basic JSON log formatter.
- **Unit test**: exception-handler test asserting an unhandled exception in a route returns a sanitized body
  (no internals leaked) and that the Sentry capture hook is called (mocked).
- **Feature test**: `TestClient` request to a route forced to raise, asserting the response is safe and the
  app doesn't crash for subsequent requests in the same test session (no shared-state corruption from the
  handler itself); re-run full suite to confirm no route's existing error-response contract changed.

### 2.10 Add Postgres/Redis checks to `/health/ready`; restrict endpoint (L-3)
- **File**: `backend/app/api/v1/endpoints/health.py` (~line 54-88)
- **Fix**: add a lightweight `SELECT 1` and Redis `PING` to the readiness check; gate the endpoint behind an
  internal-network check or shared token.
- **Unit test**: readiness-check unit test with mocked DB/Redis failures asserting `status: degraded` is
  reported correctly for each failure mode independently.
- **Feature test**: `TestClient` hitting `/health/ready` with DB/Redis healthy (200, `ok`) and with a simulated
  DB outage (still 200 per the existing "never trip the container healthcheck" design, but `status: degraded`
  with the DB flagged) — confirms the existing thoughtful design is preserved, not replaced.

### 2.11 Expand audit logging to auth events; populate ip_address/metadata_json (L-2)
- **File**: `backend/app/services/auth_service.py`, `backend/app/models/finance.py` (`AuditLog` usage)
- **Fix**: log login, failed login, logout, signup, password reset, and session revocation to `AuditLog` with
  `ip_address` and `metadata_json` (device/platform/user agent) populated; do the same retroactively for the
  existing transaction create/delete call sites.
- **Unit test**: assert each auth service method writes exactly one well-formed `AuditLog` row with the
  expected `action`/`actor_user_id`.
- **Feature test**: full login → failed login → logout flow via `TestClient`, asserting the audit trail is
  complete and ordered correctly; re-run the finance audit-log tests to confirm they still pass.

### 2.12 Server-side password complexity validation (L-4)
- **File**: `backend/app/schemas/auth.py` (`SignupRequest.password`, `ResetPasswordRequest.new_password`)
- **Fix**: mirror the client-side complexity rule (upper/lower/digit, existing length bounds) in a Pydantic
  validator.
- **Unit test**: schema validation test — `"aaaaaaaa"` rejected, a compliant password accepted.
- **Feature test**: `/auth/signup` and `/auth/reset-password` request tests confirming the new validation
  error is clear and doesn't break any existing valid test-fixture passwords across the whole suite.

### 2.13 Auth-session cleanup beat task (L-5)
- **File**: `backend/app/core/celery_app.py`, `backend/app/tasks/`
- **Fix**: add a low-priority daily beat task deleting `auth_sessions` rows past `expires_at`/old `revoked_at`.
- **Unit test**: task test seeding expired/revoked/active sessions, asserting only the correct rows are
  deleted.
- **Feature test**: run the task against a seeded DB with a real active session in the mix, assert the active
  session survives and login/refresh still work immediately after cleanup runs.

### 2.14 Delete dead `async_session.py` code
- **File**: `backend/app/db/async_session.py`
- **Fix**: delete (confirmed unused anywhere in `app/` — grep verified in the original audit).
- **Test**: `pytest` full suite + `grep -rn "async_session"` across `backend/` returns nothing outside version
  control history — proves nothing depended on it.

### 2.15 Load-test auth endpoints against production (per user's explicit choice)
- **File**: new `backend/loadtest/k6_auth.js` (or Locust equivalent)
- **Execution**: run a conservative ramp (start low, short duration, define an explicit stop condition on
  error-rate/latency degradation) against `https://api.smaartspend.com`, targeting `/auth/signup`, `/auth/
  login`, `/auth/refresh`. Monitor `/health/ready` throughout; abort immediately on sustained 5xx increase.
- **Output**: `backend/LOAD_TEST_REPORT.md` with p50/p95/p99 latency, error rate, and an explicit go/no-go
  read against the RELEASE_BUILD.md target (p95 login <400ms excl. Argon2, error rate <0.5%).
- **This item itself has no unit test** — it's a measurement, not a code change. Do not run this until 2.1,
  2.2, and 2.3 have landed (don't load-test against a version with a known timing side-channel/CORS gap).

---

## Phase 3 — Mobile production readiness

### 3.1 Report Firebase/notification/account-seeding init failures to Sentry
- **File**: `lib/main.dart` (~line 65-93)
- **Fix**: replace `debugPrint`-only catches with `ErrorMonitor.captureException` calls; verify (and document,
  can't fabricate) whether `GoogleService-Info.plist`/`google-services.json` are actually present in the build
  environment.
- **Unit test**: mock `ErrorMonitor` and assert it's invoked when each of the three init steps throws.
- **Feature test**: `flutter test` widget test booting the app shell with a forced Firebase-init failure,
  asserting the app still reaches a usable state (doesn't hard-crash) AND the error was captured — proves the
  fix doesn't change the existing graceful-degradation behavior, only its observability.

### 3.2 Route remaining raw-exception display through AppErrorMapper
- **File**: `reports_screen.dart`, `subscriptions_screen.dart`, `add_subscription_screen.dart`,
  `edit_subscription_screen.dart`, `insights_screen.dart`, `settings_screen.dart`,
  `recurring_balance_sheet_screen.dart`
- **Fix**: replace every `'...: $e'`/`.toString()` user-facing string with `AppErrorMapper.from(e).message`.
- **Unit test**: `AppErrorMapper` already has tests — extend with any new exception shapes encountered in these
  screens if not already covered.
- **Feature test**: widget test per affected screen forcing the relevant provider into an error state, asserting
  the rendered text never contains raw exception markers (stack frames, `Exception:`, file paths) — reuse
  `AppErrorMapper`'s own denylist as the test oracle.

### 3.3 iOS CI build job enforcing `--obfuscate`
- **File**: `.github/workflows/dart.yml` (uncomment/build the iOS job), or point CI at `scripts/
  build_release.sh ios`
- **Fix**: add a CI job that runs the same obfuscated build path already trusted for Android; wire
  `sentry_dart_plugin` symbol upload behind a secret-gated conditional (skip gracefully if the secret isn't
  present in this environment, don't fail the build).
- **Test**: this is inherently a CI-config change — the "test" is the workflow run itself succeeding
  end-to-end on this branch; capture the run URL/log in the commit message as evidence.

### 3.4 Fix onboarding/legal-acceptance flags surviving uninstall
- **File**: `lib/core/services/onboarding_service.dart` (~line 20-23), `lib/core/providers/core_providers.dart`
  (~line 29-38)
- **Fix**: move `onboarding_complete`/`legal_accepted`/`legal_reviewed_at` from Keychain-backed secure storage
  to `SharedPreferences` (correctly wiped on uninstall), keeping only true secrets (tokens, SQLCipher key,
  biometric state) in Keychain.
- **Unit test**: `onboarding_service` test asserting the flags are read/written via the new storage backend.
- **Feature test**: widget test simulating first-launch (flags absent) → onboarding + legal screens shown →
  set flags → simulate "reinstall" (clear `SharedPreferences` but leave Keychain populated, mirroring real
  device behavior) → assert onboarding/legal screens show again; re-run the full onboarding/auth-flow test
  suite to confirm normal repeat-launch behavior (flags present, no reinstall) is unchanged.

### 3.5 Disable google_fonts runtime fetching
- **File**: `lib/core/theme/app_typography.dart` (~line 8), `lib/main.dart` (early init)
- **Fix**: set `GoogleFonts.config.allowRuntimeFetching = false` before first use, or bundle Inter as a local
  asset like Roboto already is.
- **Unit test**: assert the config flag is set at app init (or asset registration exists in `pubspec.yaml`).
- **Feature test**: widget test rendering a themed screen with network fully disabled (mock `HttpOverrides`
  throwing on any request), asserting text still renders with a font and no exception surfaces to the user.

### 3.6 Add pagination to local transaction queries
- **File**: `lib/data/datasources/local/app_database.dart` (`getTransactions`, ~line 128-149),
  `transaction_list_screen.dart`
- **Fix**: add `limit`/`offset` parameters; page from the UI on scroll (the list is already virtualized via
  `SliverList.separated`, this closes the DB-side gap).
- **Unit test**: `app_database` test seeding N transactions, asserting `getTransactions(limit: 20, offset: 20)`
  returns the correct, non-overlapping second page.
- **Feature test**: widget test on `TransactionListScreen` seeding a large dataset, scrolling, and asserting
  additional pages load correctly and filters (category/date-range) still work combined with pagination.

### 3.7 Move non-sensitive UI prefs off Keychain
- **File**: `theme_service.dart`, `locale_service.dart`, `currency_service.dart`,
  `rollover_policy_service.dart`, `notification_preferences_service.dart`
- **Fix**: switch these five services from `flutter_secure_storage` to `shared_preferences`.
- **Unit test**: each service's existing tests re-pointed at the new storage backend, same assertions.
- **Feature test**: settings-screen widget test changing theme/locale/currency/notification prefs and
  confirming persistence across a simulated app restart (re-created provider container) still works.

### 3.8 Delete stale `test/widget_test.dart` boilerplate
- **File**: `test/widget_test.dart`
- **Fix**: delete (unmodified Flutter template, tests nothing real).
- **Test**: `flutter test` full suite passes with identical pass count minus the deleted no-op test — confirms
  it wasn't silently covering something real.

---

## Phase 4 — UX/UI polish

### 4.1 Standardize error states on `AppErrorState`
- **File**: `budget_screen.dart` (~line 618-620), `savings_screen.dart` (~line 794-796),
  `accounts_screen.dart` (~line 98), `notifications_screen.dart` (~line 247-249)
- **Fix**: replace the four divergent error-state renderings with the existing `AppErrorState` widget (Lottie
  + calm copy + working Retry that invalidates the provider), matching `dashboard_screen.dart`/
  `scenario_lab_screen.dart`.
- **Unit test**: n/a beyond existing `AppErrorState` widget tests.
- **Feature test**: widget test per screen forcing an error `AsyncValue`, asserting `AppErrorState` renders
  (not raw text) and tapping Retry re-triggers the provider; re-run each screen's existing test suite.

### 4.2 Fix Budget/Savings screens to use `AppColors.statusFor`
- **File**: `budget_screen.dart` (~line 475-479), `savings_screen.dart` (~line 1235-1409)
- **Fix**: replace raw `Colors.green/red/orange/blue` with `AppColors.statusFor`/`income`/`expense` per the
  documented money-color system.
- **Unit test**: n/a (visual/token usage — verified by grep + widget golden if goldens exist in this repo).
- **Feature test**: widget test asserting the rendered status pill's color matches `AppColors.statusFor`'s
  output for each status in both light and dark `ThemeData`, across `budget_screen.dart` and
  `savings_screen.dart`.

### 4.3 Localize hardcoded strings on auth/budget/savings screens
- **File**: `signup_screen.dart`, `login_screen.dart`, `savings_screen.dart`, `budget_screen.dart`,
  `l10n/app_en.arb` (+ propagate to de/es/fr/pt via existing translation workflow, or flag untranslated with a
  clear TODO if no translation pipeline exists — do not fabricate translations)
- **Fix**: route every hardcoded literal identified in the audit through `AppLocalizations`.
- **Unit test**: n/a.
- **Feature test**: widget test pumping each affected screen under a non-English `Locale` (e.g. `de`),
  asserting no English-only literal from the audit's list appears in the rendered tree.

### 4.4 Add textScaler clamping for the hero balance number
- **File**: `lib/main.dart` (~line 221-238), `dashboard_screen.dart` (~line 636-643)
- **Fix**: clamp `MediaQuery.textScaler` in `MaterialApp.router`'s `builder`, or make the hero balance font
  size responsive to scale factor with a sane floor.
- **Unit test**: n/a.
- **Feature test**: widget test rendering `DashboardScreen` under `TextScaler.linear(2.0)` with a long balance
  value (e.g. `$1,234,567.89`), asserting the text does not overflow/clip and remains legible (no
  `RenderFlex overflowed` errors in the test log).

### 4.5 Add tooltips/Semantics to icon-only buttons
- **File**: `notifications_screen.dart` (~line 58-74) and the remaining 10 untooltipped `IconButton` sites
  identified in the audit
- **Fix**: add `tooltip:`/`Semantics(label:)` to every bare `IconButton`, prioritizing destructive/bulk actions.
- **Unit test**: n/a.
- **Feature test**: widget test using `find.bySemanticsLabel` to confirm each targeted button now exposes a
  label to the accessibility tree.

---

## Phase 5 — Roadmap feature specs (design only, no code)

Each produces a standalone spec document under `docs/specs/` on `dev_end` — architecture, data model changes,
API surface, third-party dependencies (called out explicitly, e.g. Plaid), UX flow, and a rough effort estimate.
No implementation, no tests (nothing executable is produced).

- `docs/specs/bank-account-linking.md` — Plaid Link integration, webhook ingestion, transaction reconciliation
  against existing manual-entry model, account-linking UX, and the explicit "needs a Plaid account/API keys"
  dependency called out as a blocker to starting implementation.
- `docs/specs/net-worth-tracking.md` — new account types (investment, property, loan/debt), historical
  snapshotting, net-worth trend chart, relationship to existing `balance-sheet` feature.
- `docs/specs/recurring-transaction-detection.md` — heuristic/pattern-matching approach over transaction
  history, confidence threshold, user-confirmation UX before auto-tagging a subscription.
- `docs/specs/shared-family-budgets.md` — multi-user data model implications for a currently single-device,
  SQLCipher-encrypted-locally architecture; sync/conflict-resolution strategy; invite flow; permission model.
- `docs/specs/budget-savings-trend-charts.md` — lightest-effort item on this list (fl_chart already a
  dependency, used elsewhere); spec'd here rather than built per the user's blanket "roadmap = spec only"
  decision, flagged in the doc itself as the best candidate to promote to Phase 4 status in a future pass.
- `docs/specs/guided-first-run.md` — turning the passive tour into a real CTA (deep-link into Add
  Transaction/budget creation) or a clearly-marked removable sample budget.

---

## Phase 6 — Final re-audit

Once Phases 1-4 are as complete as the night allows: re-run the exact same four-domain analysis performed
earlier this session (security infrastructure weak points; full production-readiness pass; stack/scalability
verdict; UX/UI and feature-gap review) **fresh, against the current `dev_end` state** — not a diff, a real
re-audit, so it independently confirms what actually got fixed rather than trusting this plan's own claims.
Publish as a new artifact, explicitly comparing against tonight's starting report: what moved from
open→fixed, what's still open and why (ran out of time vs. hit a blocker), and any new findings introduced
by tonight's changes.

---

## Execution notes for the loop
- Work strictly in priority order: Phase 1 in full before Phase 2, etc. — severity ordering matters more than
  finishing every item.
- One task at a time via the tracked task list; mark `in_progress` before starting, `completed` only once the
  fix, both tests, and a full relevant test-suite run are all green and pushed.
- If a task turns out to be blocked by something outside tonight's approved scope (e.g. would require a live
  server change), stop, mark it blocked with a clear note in its task description, and move to the next task —
  do not silently expand scope to unblock it.
- If context runs low, rely on the task list and this file as the source of truth to resume — don't re-derive
  the plan from scratch.
- Every commit message should name the audit finding it closes (e.g. "fix(security): escape XSS in
  reset-password page — closes C-1").
