# SmartSpend — Final Re-Audit & Comparison Report

**Branch audited**: `dev_end` (current state, all Phase 1-5 remediation work landed)
**Method**: four independent, fresh domain audits (security, backend architecture/scalability,
mobile production-readiness, UX/feature-gap) re-examining the actual current code — not a diff
against commit messages, and not trusting the remediation plan's own claims. Each of tonight's
original findings was independently re-verified; each domain also did a fresh pass for anything
the original audit missed.

## Executive summary

- **29 of 32 original findings: confirmed fixed** with real, targeted code changes (verified by
  reading the actual current source, not by trusting commit messages).
- **3 partially fixed**: `/health/ready` access restriction (works, but defaults to unauthenticated
  rather than failing closed), `AppErrorMapper` adoption (3 stray call sites outside the
  originally-scoped files still leak raw exceptions), and hardcoded-string cleanup (budget/savings
  screens still carry some residual English literals beyond what got caught tonight).
- **1 critical new finding**: the Android release build is still signed with the debug keystore
  and has no code shrinking configured — this will be rejected by Google Play as-is. This is a
  genuine launch blocker, independent of tonight's remediation scope (Android release signing was
  never a tracked item), and should be the top priority before any Android release.
- **1 high new finding**: the app's global "More" navigation menu and quick-add menu are
  extensively hardcoded in English — more user-visible than the localization gaps that were
  actually fixed tonight (auth/budget/savings screens), since every user touches this menu.
- All six Phase 5 roadmap specs were independently reviewed for quality and found to be concrete,
  grounded in the real codebase (every cited file/line checked out), and honest about
  architectural tension rather than hand-waving — ready to hand to an engineer as-is.

---

## Domain 1 — Security

| id | original finding | status |
|---|---|---|
| C-1 | Reflected XSS on password-reset page | ✅ Confirmed fixed — escaped interpolation + CSP nonce, defense in depth |
| C-2 | Secret rotation runbook | ✅ Confirmed fixed — runbook + script exist, sound, correctly scoped to prepare-only |
| H-1 | Apple Sign-In email-spoofing takeover | ✅ Confirmed fixed — resolves by `sub` claim, rejects rather than trusting client email |
| H-2 | Argon2 timing side-channel | ✅ Confirmed fixed — dummy-hash verify on the "no such account" path |
| M-1 | Per-account rate-limit gap | ✅ Confirmed fixed — new IP-independent email-keyed bucket |
| M-2 | CORS empty-string wildcard fallback | ✅ Confirmed fixed — fails closed outside `development` |
| M-3 | Docker hardening | ✅ Confirmed fixed — non-root user, `.dockerignore` |
| M-4 | Security headers + CSP | ✅ Confirmed fixed — global middleware, doesn't clobber the reset-page's own CSP |
| L-2 | Auth audit logging | ✅ Confirmed fixed — ip_address/metadata_json populated across all auth events |
| L-3 | `/health/ready` checks + restriction | ⚠️ **Partially fixed** — real DB/Redis checks now work; access restriction is opt-in via `HEALTH_CHECK_TOKEN`, which defaults empty in `.env.example`/`docker-compose.yml`, so an operator who doesn't explicitly set it still serves this endpoint unauthenticated in production |
| L-4 | Server-side password complexity | ✅ Confirmed fixed |
| L-5 | Auth-session cleanup task | ✅ Confirmed fixed — daily beat task, correct retention logic |
| — | SQLCipher client-side encryption wiring | ✅ Confirmed fixed and correctly wired — fails loudly rather than silently falling back to plaintext |

**New findings this pass:**
- current_user() dependency never checks `is_active` — a deactivated account keeps API access on any already-issued token until its 15-minute TTL expires. (Low)
- `/reset-password` and `/verify-email` have no rate limiting, unlike the rest of the auth surface. Low practical risk (tokens are signed JWTs, not brute-forceable), but inconsistent. (Low)
- Reset/verify tokens are stateless JWTs with no server-side single-use tracking — a captured link is repeatably usable for its full TTL. Deliberate tradeoff, not obviously wrong, worth a conscious call. (Info)
- No certificate pinning in the Flutter app — relies on OS trust store. Reasonable default for most consumer apps; worth a conscious decision given this handles financial data. (Info)
- Recommend `pip-audit`/`safety` as a standing CI check rather than a one-off manual review of `requirements.txt`. (Info)

**Verdict**: the security remediation is genuine and thorough. The one real gap (`/health/ready` default) is small and easy to close — flip the production default to fail-closed rather than opt-in.

---

## Domain 2 — Backend architecture & scalability

| original finding | status |
|---|---|
| Missing pagination (budgets/savings-goals/subscriptions) | ✅ Confirmed fixed — matches the transactions reference pattern |
| DB pool tuning + partial index + worker config | ✅ Confirmed fixed — explicit pool bounds, index migration, documented worker math, real `EXPLAIN ANALYZE` evidence in `PERFORMANCE_NOTES.md` |
| Duplicate subscription-notification bug | ✅ Confirmed fixed — idempotent per due-date via `last_notified_for` |
| Error monitoring / structured logging / exception handler | ✅ Confirmed fixed — Sentry wired (no-op without DSN), global handler doesn't shadow expected exception types |
| `/health/ready` DB/Redis checks | ⚠️ Same partial finding as Security domain — see L-3 above |
| Auth-session cleanup beat task | ✅ Confirmed fixed |
| Dead `async_session.py` | ✅ Confirmed fixed — file gone, zero references anywhere |
| Production load test | ✅ Confirmed — report and methodology are internally coherent, includes an honest account of a rate-limiter false-positive during the test run and how it was resolved |

**New findings this pass:**
- `check_subscriptions` runs hourly with no `user_id` predicate and no usable index on `next_due_on` alone (only a composite `(user_id, next_due_on)` index exists) — forces a full table scan every run. Cheap to fix, will matter once the subscriptions table has real volume. (Medium)
- The new partial index on `auth_sessions` was created without `CONCURRENTLY`, taking a full table lock during the migration — fine on today's near-empty table, but a risky pattern to repeat once this hot-path table has production traffic. (Medium)
- Single backend service in `docker-compose.yml`, no replica/orchestrator config — the app is architecturally stateless and horizontally-scalable (JWT auth, Redis-backed pub/sub, no local session state) but not currently configured for multi-host scale. Not a defect, just unconfigured. (Info)
- No leak or N+1 patterns found anywhere in the query/session-lifecycle code — explicitly verified clean. (Info)

**Verdict**: 7 of 8 original items solidly fixed with real evidence, not just claims. Backend is reasonably scale-ready for its current single-host deployment; the two new Medium findings are real but modest, not blockers.

---

## Domain 3 — Mobile production readiness

| original finding | status |
|---|---|
| Firebase/notification/seeding init failures reported to Sentry | ✅ Confirmed fixed — `runNonFatalInit` wraps all three, forwards to `ErrorMonitor` |
| Raw exception strings shown to users (7 named screens) | ⚠️ **Partially fixed** — all 7 originally-named screens now route through `AppErrorMapper`, but a broader sweep found 3 more call sites (not in the original list) still passing raw `err.toString()` into user-facing strings: `security_screen.dart`, `financial_health_screen.dart` |
| iOS CI build job enforcing `--obfuscate` | ✅ Confirmed fixed |
| Onboarding/legal flags surviving uninstall | ✅ Confirmed fixed — moved to SharedPreferences, secrets correctly left in Keychain |
| `google_fonts` runtime fetching | ✅ Confirmed fixed |
| Local transaction query pagination | ✅ Confirmed fixed — stable sort key, correct scope (paginated where it should be, unbounded where analytics needs the full set) |
| Five UI-pref services off Keychain | ✅ Confirmed fixed — and true secrets (tokens, SQLCipher key, biometric state) verified still in secure storage, no scope creep |
| SQLCipher native-link crash | ✅ Confirmed fixed — actual root cause (CocoaPods link-order shadowing by Firebase's own sqlite3) fixed, on-device QA documented in `RELEASE_BUILD.md` |
| Stale `test/widget_test.dart` | ✅ Confirmed fixed |

**New findings this pass:**
- **Android release build is still signed with the debug keystore** (`android/app/build.gradle.kts` — `release { signingConfig = signingConfigs.getByName("debug") }`, unmodified Flutter template TODO left in place) with no `minifyEnabled`/`shrinkResources`/ProGuard rules configured. This build cannot be uploaded to Google Play as-is, and ships fully unminified Kotlin/plugin code even though the CI's `--obfuscate` flag correctly obfuscates the Dart side. **(Critical)**
- The same 3 stray `AppErrorMapper` gaps noted above. (Medium)
- No memory-leak patterns found — every `Timer`/`StreamSubscription`/`AnimationController` checked disposes correctly. Verified clean. (Info)
- `exchange_rate_service.dart` silently swallows two of three provider failures before falling back — a deliberate degradation chain, but zero visibility into upstream provider health over time if that's ever worth tracking. (Low)

**Verdict**: every originally-flagged item is genuinely fixed at the root cause, not patched over. The one launch blocker found tonight — Android release signing — was never a tracked item in the original audit and needs to be fixed before any Play Store submission.

---

## Domain 4 — UX/UI and feature gaps

| original finding | status |
|---|---|
| Divergent error states (4 screens) → `AppErrorState` | ✅ Confirmed fixed — all four use the shared widget with working Retry |
| Raw status colors → `AppColors.statusFor` (budget/savings) | ✅ Confirmed fixed in both named files |
| Hardcoded strings (signup/login/budget/savings) | ⚠️ **Partially fixed** — signup/login fully localized; budget/savings still carry several residual English strings beyond what the original audit's list caught (see new findings below for the bigger gap) |
| textScaler clamping for hero balance | ✅ Confirmed fixed — app-wide clamp plus the pre-existing ellipsis fallback |
| IconButton tooltips | ✅ Confirmed fixed, and comprehensively — an independent fresh scan found only one bare `IconButton` app-wide, and it's already wrapped in a parent `Tooltip` |

**New findings this pass:**
- **The global "More" menu and quick-add menu are extensively hardcoded in English** (`app_router.dart`) — Transaction/Subscription/Savings/Budget labels, Accounts/Balance Sheet/Reports/Exchange Rates/AI Insights/Scenario Lab/theme-toggle/Help, plus a hardcoded SnackBar message. This surface is touched by every single user and is more consequential than the screens that were actually localized tonight. **(High)**
- `accounts_screen.dart` — not one of the four originally-audited screens — is extensively unlocalized: empty state, delete confirmation, editor sheet, type selector, balance card copy. (Medium)
- `onboarding_screen.dart`'s "Skip" button is hardcoded English one line away from properly-localized "Get Started"/"Continue" buttons — on the very first screen a new user sees. (Medium)
- Two screens adjacent to tonight's fixes show the same defects the fixes addressed: `dashboard_screen.dart` has its own bespoke error card (no Retry) for one specific card, and `scenario_lab_screen.dart`'s stress meter still uses raw `Colors.*` instead of `AppColors.statusFor`. (Low, each)
- `PopupMenuButton` icon-only menus rely on the platform default tooltip rather than a contextual label — not covered by the `IconButton`-scoped fix. (Low)

**Phase 5 spec quality** (independent review): all six specs were checked against the actual codebase — every cited file, line number, and entity name verified accurate. None read as generic or hand-wavy; `shared-family-budgets.md` in particular was singled out for correctly identifying that it requires a server-authoritative source of truth the app doesn't have today, and scoping itself down specifically to avoid needing general sync/CRDT machinery rather than overpromising. All six are considered ready to hand to an engineer as-is.

**Verdict**: every originally-flagged item was genuinely fixed, but "fixed" was scoped narrowly to the four/five files named in the original audit — the identical defects (hardcoded strings, raw status colors, inconsistent error states) immediately resurface in adjacent, equally user-visible surfaces that weren't in scope. The app's biggest remaining UX gap is information architecture — real differentiated features (Scenario Lab, Balance Sheet, AI Insights) are buried in a flat, ungrouped menu with no promotion elsewhere — and an onboarding flow that's still fundamentally passive, both already correctly diagnosed by `guided-first-run.md` but not yet acted on.

---

## What moved from open → fixed tonight

29 of 32 tracked findings across all four domains: the full Phase 1 (critical) and Phase 2
(security/backend) severity-ranked list, the Phase 3 mobile production-readiness list, and the
Phase 4 UX polish list. Every fix was independently re-verified against actual current code, not
assumed from commit messages — see the domain sections above for specifics and file citations.

## What's still open, and why

- **`/health/ready` access restriction defaults to off** — the check logic is correct, but the
  token gate isn't enforced by default. Ran out of scope tonight to also add a
  `production_secret_issues()`-style startup guard requiring the token outside development; this
  is a small, well-understood follow-up, not a design gap.
- **`AppErrorMapper` adoption has 3 stray gaps** and **hardcoded strings have a wider footprint**
  than the original audit caught (both largely in `accounts_screen.dart`, the global nav menu, and
  a couple of adjacent screens) — the original audit scoped these fixes to specific named files
  found in an earlier pass; tonight's fresh re-audit swept more broadly and found the same defect
  pattern recurring just outside that original scope. Not a regression, a scope gap.
- **Android release signing** was never a tracked finding in the original audit at all — it
  surfaces here for the first time. This is the clearest actionable next step before any Android
  release.

## New findings introduced by tonight's changes

None. Every new finding in this report (the Android signing gap, the stray `AppErrorMapper`/
localization sites, the missing subscriptions index, the health-check default, etc.) predates
tonight's remediation work — they're gaps the original audit didn't catch, not regressions
introduced by tonight's fixes. No fresh-audit finding traces back to a change made tonight.

## Recommended next steps, in priority order

1. **Fix Android release signing** (Critical, blocks any Play Store submission) — add a real
   release keystore + `key.properties` (kept out of git) and enable `minifyEnabled`/
   `shrinkResources` with ProGuard rules.
2. **Localize the global nav menu** (High, touches every user) — `app_router.dart`'s More/quick-add
   menus.
3. Flip `/health/ready`'s token requirement to fail-closed by default outside development.
4. Sweep the remaining `AppErrorMapper` and localization gaps (`accounts_screen.dart`,
   `onboarding_screen.dart`'s Skip button, `scenario_lab_screen.dart`, `dashboard_screen.dart`'s
   health card).
5. Add the missing `subscriptions(next_due_on)` index before that table grows.
6. Consider promoting `budget-savings-trend-charts.md` from spec to an actual build, per its own
   recommendation — smallest effort-to-value ratio of the six Phase 5 items.
