# SmartSpend — v2 Beta Release Notes
**Build:** 1.0.0+1 · Public Beta  
**Platform:** iOS (TestFlight) · Android (Internal Testing)  
**Prepared:** 2026-06-10

---

## What's New

### Security — Complete Hardening Pass
This beta represents a full security audit and remediation cycle across the entire app and backend. Every critical and high-severity finding from the audit has been resolved.

- **Data encrypted at rest.** The on-device database is now encrypted with SQLCipher using a 256-bit key stored in the iOS Keychain / Android Keystore. Financial data (transactions, budgets, savings goals, subscriptions) can no longer be read from the raw database file, even on rooted devices or unencrypted backups.
- **Sensitive notes encrypted per-field.** Transaction notes are individually encrypted using AES-256-GCM with a unique random nonce per record before being written to the database. Prior builds used a static IV — that has been corrected.
- **Brute-force lockout enforced.** Five failed login attempts within 15 minutes locks the account. The lockout is enforced both on the device and on the server independently. A session timeout logs users out after 30 minutes of inactivity.
- **Login alerts.** A security notification email is sent on every new sign-in, with device, location, and time. The link in the email goes to `https://smaartspend.com/app/security` — not a custom URI scheme that could be intercepted.
- **Signup no longer reveals registered emails.** Previously, attempting to register with an existing email returned "Account already exists" — a classic enumeration vector. The response is now generic. The legitimate account holder receives a private security notification email instead.
- **Network security hardened.** Android `android:usesCleartextTraffic` is disabled. Certificate pinning is active against the production API. The app ID has been updated from `com.example` to `com.smaartspend.app`.
- **Auth log pruning.** The device-side authentication audit log automatically purges entries older than 90 days to prevent unbounded growth.
- **Production JWT secret guard.** The backend refuses to start if it detects the default development JWT secret in a production environment.

---

### Multi-Currency — Accurate Money Storage
- **Per-currency decimal precision.** Amount input fields now respect ISO 4217 decimal rules: zero-decimal currencies (JPY, KRW, VND, etc.) accept whole numbers only; 3-decimal Gulf currencies (KWD, BHD, OMR, etc.) allow the correct precision. Previously all currencies were treated as 2-decimal.
- **Original amount preserved on currency change.** When you change your app currency, transaction history is converted for display only. The original currency and amount at time of entry are stored permanently and never overwritten — meaning your historical records remain accurate regardless of future currency changes.
- **Integer minor-unit storage.** Amounts are now stored internally as integer minor units (e.g. 1250 for $12.50) to eliminate floating-point rounding errors in calculations and reports.

---

### Email Verification Gating
- **Verification banner.** A dismissible banner now appears at the top of the app for users who haven't confirmed their email address. It includes a one-tap Resend button.
- **Write operations soft-blocked.** Adding transactions, budgets, and savings goals requires a verified email. Tapping any of these actions while unverified shows a prompt explaining why and offering a Resend link. Existing data is never affected — only new entries are gated.

---

### Legal & Compliance
- All legal documents (Privacy Policy, Terms of Service, Data Processing Agreement, Cookie Policy, and supporting records) have been updated with the live support, privacy, and DPA contact addresses for smaartspend.com.

---

## Bug Fixes

- Fixed: crash on startup caused by `LogoLoadingIndicator` referencing a removed Lottie asset — replaced with `AppShimmerSkeleton` across all loading states.
- Fixed: `const` constructor warnings across shimmer skeleton and onboarding screen widgets — all hot-path rebuild widgets are now correctly const.
- Fixed: transaction and budget forms using hardcoded 2-decimal precision for all currencies — now reads `MoneyUtils.decimalDigits(currency)` dynamically.
- Fixed: accounts screen currency input ignoring the account's own stored currency on edit — now uses the account's currency, falling back to the app-level default only for new accounts.
- Fixed: fresh-install database missing `original_currency` and `original_amount_minor_units` columns — `onCreate` now creates them alongside the Drift-managed schema.
- Fixed: verification gate leaving the quick-add panel visible behind the "verify email" bottom sheet — panel now closes before the gate is evaluated.
- Fixed: potential data inconsistency if the app was force-quit between writing a new transaction and writing its immutable originals — both operations are now wrapped in a single atomic database transaction.

---

## Known Limitations (Pre-Launch, Not Beta Blockers)

| Item | Status |
|------|--------|
| TLS certificate on `api.smaartspend.com` | Requires Let's Encrypt provisioning — see `RELEASE_BUILD.md` |
| `assetlinks.json` / `apple-app-site-association` | Must be hosted before Android App Links and iOS Universal Links verify |
| Production SMTP provider | Emails send via dev SMTP in this build — configure a transactional provider (SendGrid / Postmark) for public beta |
| Android release signing keystore | A production keystore is required before publishing to the Play Store |
| Pagination on budgets, savings, subscriptions endpoints | List endpoints are currently unbounded — tracked for launch |
| Sentry / Crashlytics integration | No crash reporting wired yet — recommended before broad distribution |

---

## What to Test (TestFlight Focus Areas)

1. **Fresh install + first transaction** — confirm no crash, database encrypted, original currency fields populated.
2. **Currency switch** — change app currency in Settings → confirm historical transaction amounts convert for display but original values are unchanged.
3. **Signup with existing email** — confirm generic error message (no "already exists") and that the registered account receives the security notification email.
4. **Login from a new device/location** — confirm login alert email arrives.
5. **Unverified account flow** — create account, skip verification, attempt to add a transaction → confirm the verification gate appears with a working Resend button.
6. **Lockout** — enter wrong PIN/password 5× and confirm the account locks for 15 minutes.
7. **Japanese Yen / Kuwaiti Dinar input** — verify the amount field accepts only whole numbers for JPY and exactly 3 decimals for KWD.
8. **Database encryption check** — see `RELEASE_BUILD.md` for the `adb` verification steps.

---

*For internal infrastructure setup steps (cert pinning, SMTP, App Links), refer to `RELEASE_BUILD.md`.*
