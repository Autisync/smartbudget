# SmartSpend — Release Build Guide

## Database encryption verification (Required device QA before release)

The on-disk SQLite database is encrypted at rest with **SQLCipher**
(`lib/data/datasources/local/database_cipher.dart`). The 256-bit key lives in
the OS keychain/keystore; legacy plaintext databases are migrated in place on
first launch via `sqlcipher_export`.

SQLCipher links a **native library that only exists in a real Flutter build**,
so this path is *not* exercised by `flutter test` (host unit tests use a plain
in-memory database). It MUST be verified on a device/emulator before any release:

1. **Fresh install** — install the release build, add a transaction, force-quit.
   Pull the DB file and confirm it is encrypted (no readable strings):
   ```bash
   # Android
   adb exec-out run-as com.smaartspend.app cat \
     files/smartbudget_db.sqlite > /tmp/db.sqlite
   strings /tmp/db.sqlite | grep -i "Food\|Salary" && echo "LEAK" || echo "OK (encrypted)"
   # Expect: OK (encrypted)
   ```
2. **Cipher active** — confirm the app does not throw the
   `SQLCipher is not active` StateError on launch (that guard fails the open
   rather than silently writing plaintext).
3. **Upgrade migration** — install the *previous* (plaintext) build, create data,
   then install the new build over it. Verify: (a) all prior data is still
   present, (b) the file is now encrypted, (c) no `smartbudget_db.sqlite.plaintext.bak`
   remains in the documents directory.

If any check fails, do **not** ship — investigate the SQLCipher linkage
(`DatabaseCipher.setupSqlCipher`) and the migration first.

---

## M-6: Code Obfuscation (Required for Production)

All production releases **must** be built with `--obfuscate` and `--split-debug-info`.
Without obfuscation, the compiled binary exposes class names, method names, and string
literals — including error messages and internal module paths — to anyone who reverse-
engineers the APK or IPA.

---

### Android

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android

flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android
```

### iOS

```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/debug-info/ios
```

---

## Debug Symbols

The `--split-debug-info` flag writes deobfuscation symbols to the specified path.
**Store these securely and never commit them to the repository.**

They are required to deobfuscate crash stack traces from Firebase Crashlytics or Sentry:

```bash
# Deobfuscate a stack trace (Android example)
dart run flutter_tools:symbol_resolver \
  --debug-info=build/debug-info/android \
  --input=crash_stack.txt
```

Keep one archive of debug symbols per release build, tagged by version (`v2.0.0`,
`v2.1.0`, etc.), stored in a private location accessible to the on-call engineer.

---

## Certificate Pinning (Pre-flight Checklist)

Certificate pinning uses **SPKI SHA-256** hashes (`base64(SHA-256(SubjectPublicKeyInfo DER))`).
The implementation in `lib/core/network/cert_pinning.dart` uses
`SecurityContext(withTrustedRoots: false)` so that `badCertificateCallback` fires for **every**
certificate — including CA-signed ones — giving consistent SPKI verification regardless of cert type.

### Current state

| Pin | Value | Notes |
|-----|-------|-------|
| Leaf (self-signed Traefik default) | `NILeAobXrKJyjBkhewvvHgvQMwj3LdCAw2ayUrHku7E=` | Active, expires 2027-05-28 |
| Intermediate backup | — | Add after switching to Let's Encrypt |

### Migrating to Let's Encrypt

1. Deploy Traefik with ACME config (`backend/traefik.yml` + `backend/docker-compose.traefik.yml`).
   Traefik auto-issues and renews the cert for `api.smaartspend.com`.

2. Compute the new leaf SPKI pin:
   ```bash
   openssl s_client -connect api.smaartspend.com:443 -servername api.smaartspend.com \
     </dev/null 2>/dev/null \
     | openssl x509 -pubkey -noout \
     | openssl pkey -pubin -outform DER \
     | openssl dgst -sha256 -binary \
     | base64
   ```

3. Compute the intermediate CA backup pin (Let's Encrypt E5/R10):
   ```bash
   openssl s_client -connect api.smaartspend.com:443 -servername api.smaartspend.com \
     -showcerts </dev/null 2>/dev/null \
     | awk '/-----BEGIN CERTIFICATE-----/{c++} c==2{print} /-----END CERTIFICATE-----/ && c==2{exit}' \
     | openssl x509 -pubkey -noout \
     | openssl pkey -pubin -outform DER \
     | openssl dgst -sha256 -binary \
     | base64
   ```

4. In `_productionPins` in `cert_pinning.dart`:
   - **Add** the new LE leaf pin and the intermediate backup pin.
   - **Keep** the old self-signed pin until all users have updated past the new release.
   - Ship the app update.
   - After the old self-signed cert expires (2027-05-28), remove that pin.

### Ongoing renewal (every ~90 days)

Traefik auto-renews the LE cert. The leaf SPKI pin changes on every renewal.
The weekly `pin-drift` CI job (`.github/workflows/pin-drift.yml`) will fail when the pin drifts,
giving advance notice. On drift: run steps 2–4 above, ship an update before the old cert expires.

---

## Android App Links (assetlinks.json)

The `android:autoVerify="true"` intent filter in `AndroidManifest.xml` requires a
Digital Asset Links file hosted at:

```
https://smaartspend.com/.well-known/assetlinks.json
```

Generate and deploy this file before the v2 beta release. Use the
[Asset Links Tool](https://developers.google.com/digital-asset-links/tools/generator)
or construct it manually:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.smaartspend.app",
    "sha256_cert_fingerprints": ["<YOUR_SIGNING_CERT_SHA256>"]
  }
}]
```

Verify with:
```bash
adb shell pm get-app-links com.smaartspend.app
```

Expected output: `ID: com.smaartspend.app  State: verified`.

---

## iOS Universal Links (apple-app-site-association)

For iOS App Clips / Universal Links, host the following at:
```
https://smaartspend.com/.well-known/apple-app-site-association
```

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "<TEAM_ID>.com.smaartspend.app",
      "paths": ["/app/*"]
    }]
  }
}
```

The file must be served with `Content-Type: application/json` and no redirect.
