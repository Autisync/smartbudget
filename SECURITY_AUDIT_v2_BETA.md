# SmartSpend — Security Audit Report
**Version:** v2 Public Beta Pre-Release  
**Audited:** 2026-06-07  
**Scope:** Full Flutter client codebase (lib/, android/, ios/, pubspec.yaml)  
**Severity Scale:** 🔴 Critical · 🟠 High · 🟡 Medium · 🔵 Low

---

## Executive Summary

SmartSpend has a strong security foundation — JWT tokens in OS Keychain/Keystore, biometric unlock, Drift ORM preventing raw SQL injection, proper error abstraction, and a clean auth flow. However, **4 critical issues** must be fixed before any public beta release. Two of them (static IV encryption and unencrypted database) expose user financial data at rest. A further 5 high-severity issues need resolution before shipping to a general audience.

**Total findings: 18**  
🔴 Critical: 4 · 🟠 High: 5 · 🟡 Medium: 6 · 🔵 Low: 3

---

## 🔴 CRITICAL

---

### C-1 — Static IV in AES-CBC Encryption Breaks Confidentiality
**File:** `lib/core/services/encryption_service.dart:28`

```dart
// BROKEN — IV.fromLength creates all-zeros IV, set once, reused forever
_iv = encrypt.IV.fromLength(16);
```

`IV.fromLength(16)` creates a 16-byte all-zeros IV. This same IV is used for every single call to `encryptData()`. In AES-CBC mode, reusing an IV with the same key means:
- Two identical plaintexts produce identical ciphertexts (breaks semantic security)
- Chosen-plaintext attacks become feasible
- The IV stored in the output (`${_iv.base64}:...`) is always `AAAAAAAAAAAAAAAAAAAAAA==` — meaningless

The stored format already parses a per-record IV from the ciphertext, so the decryption path supports unique IVs — only the encryption path is broken.

**Fix:** Generate a fresh random IV per encryption call:
```dart
String encryptData(String plainText) {
  final iv = encrypt.IV.fromSecureRandom(16); // unique per call
  final encrypted = _encrypter.encrypt(plainText, iv: iv);
  return '${iv.base64}:${encrypted.base64}';
}
// Remove: late encrypt.IV _iv; and _iv = encrypt.IV.fromLength(16);
```

---

### C-2 — SQLite Database Is Unencrypted at Rest
**File:** `lib/data/datasources/local/app_database.dart:_openConnection()`

```dart
return NativeDatabase(file); // no encryption
```

All financial data — transactions, budgets, savings goals, subscriptions, auth logs — is stored in plaintext at `<AppDocuments>/smartbudget_db.sqlite`. On a rooted Android device or via an iTunes backup (without device encryption enabled), this file is fully readable.

The `EncryptionService` and `FlutterSecureStorage` exist but are never wired to the database layer.

**Fix:** Use `drift_flutter` with SQLCipher or `sqlite3_flutter_libs` with encryption. The simplest approach uses `drift`'s `NativeDatabase` with a passphrase derived from the master key stored in secure storage:

```dart
static Future<QueryExecutor> _openEncryptedConnection() async {
  final storage = await _getSecureStorage();
  final passphrase = await storage.read(key: 'db_passphrase') 
      ?? await _generateAndStorePassphrase(storage);
  final docs = await getApplicationDocumentsDirectory();
  final file = File(p.join(docs.path, 'smartbudget_db.sqlite'));
  // Use drift with sqlcipher or encrypted NativeDatabase
  return NativeDatabase(file, setup: (db) {
    db.execute("PRAGMA key = '$passphrase';");
  });
}
```

Alternatively, if full SQLCipher is too heavy for v2, migrate sensitive columns to be encrypted by `EncryptionService` before write and decrypted after read (field-level encryption), prioritising `amount`, `note`, `category`, `paymentMethod`.

---

### C-3 — `hashSensitiveData()` Is Not a Hash — It's Plain Base64
**File:** `lib/core/services/encryption_service.dart:56-60`

```dart
String hashSensitiveData(String data) {
  // Simple hash for demonstration - use crypto package for production
  final bytes = utf8.encode(data);
  return base64Encode(bytes); // THIS IS TRIVIALLY REVERSIBLE
}
```

The comment acknowledges this is placeholder code, but it has shipped into the codebase. Base64 is fully reversible — it provides zero security. Any caller treating this as a "hash" is producing reversible, unprotected data while believing it is protected.

**Fix:** Remove or replace immediately. Use `package:crypto` for non-secret hashing (SHA-256) or `package:pointycastle` for Argon2 if hashing passwords client-side.
```dart
import 'package:crypto/crypto.dart';
String hashSensitiveData(String data) {
  final bytes = utf8.encode(data);
  return sha256.convert(bytes).toString();
}
```
Add `crypto: ^3.0.3` to pubspec.

---

### C-4 — TLS Certificate Validation Disabled in All Non-Release Builds
**File:** `lib/core/network/debug_tls_io.dart`

```dart
void configureDebugTlsAdapter(Dio dio, String baseUrl) {
  if (kReleaseMode || !baseUrl.startsWith('https://')) {
    return; // only skips for release OR non-https
  }
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true; // ACCEPTS ANY CERT
      return client;
    },
  );
}
```

This disables TLS certificate validation for **all profile/TestFlight/ad-hoc builds** that use an HTTPS base URL (including `https://api.smaartspend.com` which is the iOS default in debug mode per `session_provider.dart:52`). This means beta testers on TestFlight are running with MITM-vulnerable networking.

**Fix:** Scope this bypass to localhost/dev IPs only, and never accept arbitrary certificates for the production domain:
```dart
void configureDebugTlsAdapter(Dio dio, String baseUrl) {
  if (kReleaseMode) return;
  final uri = Uri.tryParse(baseUrl);
  final isLocalhost = uri != null && 
      (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '10.0.2.2');
  if (!isLocalhost) return; // never bypass cert validation for remote hosts
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      return client;
    },
  );
}
```

---

## 🟠 HIGH

---

### H-1 — Android Backup Not Disabled — Database Exposed via Cloud Backup
**File:** `android/app/src/main/AndroidManifest.xml`

The `<application>` tag does not set `android:allowBackup="false"`. By default, Android backs up app data (including the documents directory where `smartbudget_db.sqlite` lives) to Google Drive. This means a user's entire unencrypted financial database may be silently uploaded to Google Drive.

**Fix:** Add to the `<application>` tag and create backup rules:
```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="@xml/backup_rules"
    android:dataExtractionRules="@xml/data_extraction_rules"
    ...>
```
Create `res/xml/backup_rules.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="file" path="smartbudget_db.sqlite"/>
    <exclude domain="database" path="."/>
</full-backup-content>
```

---

### H-2 — Client-Side Lockout Not Enforced Despite Being Stored and Displayed
**Files:** `lib/core/services/security_service.dart`, `lib/features/auth/presentation/providers/auth_provider.dart`

`SecuritySettings` stores `maxFailedAttempts` (default: 5) and `lockoutDuration` (default: 900s), and these are editable in the Security screen. Auth attempts are logged via `logAuthAttempt()`. However, **nothing reads these logs to enforce lockout**. A bad actor with physical device access can attempt biometric authentication infinitely without triggering any app-level lockout.

The OS biometric lockout is a separate mechanism but can be bypassed if the attacker uses the password fallback path. The `failedAttempts` field in `AuthLog` is incremented to 1 per failure but never accumulated or queried for enforcement.

**Fix:** In `BiometricAuthService` or `SessionController.login()`, read recent failed auth logs and compare against `maxFailedAttempts`. If exceeded within the `lockoutDuration` window, block further attempts and show a lockout countdown.

---

### H-3 — Exchange Rate API Key Embedded in URL Path
**File:** `lib/core/services/exchange_rate_service.dart:112`

```dart
final response = await _exchangeRateApiDio.get<Map<String, dynamic>>(
  '/$_exchangeRateApiKey/pair/$base/$target', // key is in the URL path
);
```

Embedding API keys in URL paths means they appear in server access logs, Dio interceptor logs, proxy/CDN logs, and crash report stack traces. Any log aggregation tool or network proxy will capture this key in plaintext.

**Fix:** Move the key to an `Authorization` or `x-api-key` header:
```dart
final response = await _exchangeRateApiDio.get(
  '/pair/$base/$target',
  options: Options(headers: {'Authorization': 'Bearer $_exchangeRateApiKey'}),
);
```
Also ensure the key is never logged — add a Dio interceptor that redacts `Authorization` headers from any log output.

---

### H-4 — Session Timeout Setting Stored but Never Enforced
**File:** `lib/core/services/security_service.dart` / `lib/core/services/biometric_auth_service.dart`

`SecuritySettings.sessionTimeout` (default: 300s, configurable by user) is stored in the database and displayed in the Security screen. However, the actual auth timeout used by `BiometricAuthService.shouldRequireAuth()` is a hardcoded constant:

```dart
// biometric_auth_service.dart:16
static const _authTimeout = Duration(minutes: 5); // ignores SecuritySettings
```

This means changing session timeout in the security settings UI has zero effect.

**Fix:** Pass the `SecuritySettings.sessionTimeout` value into `shouldRequireAuth()`:
```dart
Future<bool> shouldRequireAuth({int timeoutSeconds = 300}) async {
  final lastAuthStr = await _secureStorage.read(key: _keyLastAuth);
  if (lastAuthStr == null) return true;
  final lastAuth = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAuthStr));
  return DateTime.now().difference(lastAuth) > Duration(seconds: timeoutSeconds);
}
```
Then in `SessionController._shouldRequireLocalUnlock()`, pass `settings.sessionTimeout`.

---

### H-5 — No Certificate Pinning for Production API
**Files:** `lib/features/auth/data/datasources/auth_remote_datasource.dart`

The Dio clients for the auth API and exchange rate services have no certificate pinning. For a financial app storing sensitive personal data, a MITM attacker with a trusted CA cert (e.g. corporate MDM, compromised CA) can intercept all API traffic including login credentials and JWT tokens.

**Fix:** Add certificate pinning using `dio_certificate_pincer` or a custom `HttpClientAdapter`. Pin the SHA-256 fingerprint of `api.smaartspend.com`'s certificate (or its CA). Include at least two backup pins for rotation safety.

```dart
// In AuthApiClient constructor
dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        final fingerprint = sha256.convert(cert.der).toString();
        return _pinnedFingerprints.contains(fingerprint);
      };
    return client;
  },
);
static const _pinnedFingerprints = {'<sha256-of-prod-cert>', '<sha256-backup>'};
```

---

## 🟡 MEDIUM

---

### M-1 — Deep Links Accept Tokens Without Origin Validation
**Files:** `lib/core/router/app_router.dart:186-192`, `android/app/src/main/AndroidManifest.xml`

Password reset and email verification tokens arrive via the custom `smartbudget://` deep link scheme:
```dart
GoRoute(
  path: '/reset-password',
  builder: (context, state) => ResetPasswordScreen(
    token: state.uri.queryParameters['token'] ?? '',
  ),
),
```
Custom URL schemes (`smartbudget://`) can be intercepted or injected by any other app installed on the device that registers the same scheme. On Android, any app can declare an intent filter for `smartbudget://`. This could be used to deliver a malicious `token` parameter.

**Fix:** Switch to **Android App Links** (HTTPS with `autoVerify="true"`) and **iOS Universal Links** for all deep links that carry security tokens. These are cryptographically bound to your domain. At minimum, validate token format (e.g., JWT signature check or UUID pattern) before passing to the API.

---

### M-2 — Server Error Messages Forwarded Verbatim to UI
**File:** `lib/core/errors/app_error_mapper.dart:_extractDetail()`

```dart
static String? _extractDetail(dynamic data) {
  final detail = data['detail'];
  if (detail is String && detail.trim().isNotEmpty) {
    return detail.trim(); // forwarded directly to user
  }
  ...
}
```

If the backend returns internal error details, stack traces, or database error messages in the `detail` or `message` field, these are displayed verbatim to the user. This is an information disclosure risk and can also expose internal API structure to an attacker intercepting responses.

**Fix:** Only forward server messages that are explicitly marked as user-facing (e.g. a `user_message` field separate from `detail`). Apply an allowlist of safe server messages or always use the client-defined fallback strings.

---

### M-3 — Auth Form State Persists in Memory After Logout
**File:** `lib/features/auth/presentation/providers/login_form_provider.dart`

`loginFormProvider` and `signupFormProvider` are `StateNotifierProvider` without `autoDispose`. Email and password strings persist in the Riverpod container until the app is killed. After logout and re-login, the previous email field may re-populate from state.

**Fix:** Add `autoDispose` modifier:
```dart
final loginFormProvider = StateNotifierProvider.autoDispose<...>((ref) => ...);
```

---

### M-4 — Auth Logs Accumulate Without Cleanup / TTL
**File:** `lib/data/datasources/local/app_database.dart`

`AuthLogs` has no deletion or expiry mechanism. `getAuthLogs(limit: 20)` is the only read query — writes are unbounded. Over months of use, this table will grow indefinitely and could store years of authentication metadata.

**Fix:** Add a cleanup job that deletes logs older than 90 days (or whatever your data retention policy states):
```dart
Future<void> pruneAuthLogs({int retentionDays = 90}) async {
  final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
  await (delete(authLogs)..where((a) => a.timestamp.isSmallerThanValue(cutoff))).go();
}
```
Call this during app startup or on a background schedule.

---

### M-5 — No Android Network Security Config (Cleartext Permitted by Default)
**Files:** `android/app/src/main/AndroidManifest.xml`

There is no `android:networkSecurityConfig` attribute and no `network_security_config.xml`. On Android API < 28 (Android 8), cleartext HTTP traffic is permitted by default. Debug builds use `http://10.0.2.2:8000` which is HTTP. Without an explicit config, there is no protection preventing accidental HTTP requests.

**Fix:** Create `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">127.0.0.1</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
```
Reference it in `AndroidManifest.xml`: `android:networkSecurityConfig="@xml/network_security_config"`.

---

### M-6 — Release Builds Not Configured for Obfuscation
**Files:** `pubspec.yaml`, build configs

No `--obfuscate --split-debug-info` flags are documented or enforced in the build pipeline. Without obfuscation, a decompiled APK/IPA reveals all class names, method names, API endpoint strings, and provider structure — making reverse engineering and targeted attacks significantly easier.

**Fix:** Add to your release build command:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols/android/
flutter build ipa --release --obfuscate --split-debug-info=build/debug-symbols/ios/
```
Store the debug symbol files securely (needed for crash symbolication) but never ship them.

---

## 🔵 LOW

---

### L-1 — Biometric Setting Inconsistency Between DB and Secure Storage
**Files:** `lib/data/models/tables.dart:SecuritySettings`, `lib/core/services/biometric_auth_service.dart`

`SecuritySettings` defaults `biometricEnabled` to `true` in the database (`const Value(true)`), but `BiometricAuthService.isBiometricEnabled()` reads from `FlutterSecureStorage` independently. A new install will have `DB.biometricEnabled = true` but `secureStorage.biometric_enabled = null` (false). The `SecurityScreen` reads from DB; `BiometricAuthService` reads from secure storage. They can diverge silently.

**Fix:** Make one source of truth. Either remove `biometricEnabled` from `SecuritySettings` and only use `FlutterSecureStorage`, or have `BiometricAuthService.setBiometricEnabled()` also update the database.

---

### L-2 — Exported Financial Reports Have No Sharing Warning
**File:** `lib/features/reports/presentation/screens/reports_screen.dart`

PDF and CSV exports use `share_plus` to invoke the system share sheet. There is no user warning that the exported file will contain their full financial history in plaintext. A user could accidentally share this to an unintended recipient (email, cloud storage, messaging app).

**Fix:** Show a one-time confirmation dialog before export: *"This file contains your personal financial data. Only share it with trusted recipients."* Consider adding a user-name watermark to exported PDFs.

---

### L-3 — Firebase Initialization Silently Fails
**File:** `lib/main.dart:27-29`

```dart
try {
  await Firebase.initializeApp();
} catch (_) {
  // Firebase is optional in local/dev environments.
}
```

A misconfigured `google-services.json` or `GoogleService-Info.plist` will cause Firebase to silently fail on production. Push notifications (including security alerts and budget threshold warnings) will stop working with no log, crash, or diagnostic output.

**Fix:** Log the error at minimum, and in release builds, consider reporting it to a non-Firebase crash reporter:
```dart
} catch (e, st) {
  if (kDebugMode) debugPrint('Firebase init failed: $e\n$st');
  // In release: report to fallback monitoring
}
```

---

## Remediation Priority for v2 Beta

| # | Issue | Priority | Effort |
|---|-------|----------|--------|
| C-1 | Fix static IV in AES-CBC | **Ship-blocker** | 30 min |
| C-3 | Replace fake hash with real SHA-256 | **Ship-blocker** | 15 min |
| C-4 | Scope TLS bypass to localhost only | **Ship-blocker** | 20 min |
| H-1 | Disable Android backup + create rules | **Ship-blocker** | 1 hour |
| H-4 | Wire session timeout to enforcement | High | 2 hours |
| M-5 | Add network security config | High | 1 hour |
| H-3 | Move API key out of URL path | High | 30 min |
| H-2 | Enforce client-side lockout counter | High | 3 hours |
| C-2 | Encrypt SQLite database | High (v2.1) | 1–2 days |
| H-5 | Certificate pinning | High (v2.1) | 4 hours |
| M-1 | Universal Links / App Links | Medium (v2.1) | 1 day |
| M-2 | Sanitize server error messages | Medium | 1 hour |
| M-3 | autoDispose on form providers | Low | 15 min |
| M-4 | Auth log TTL cleanup | Low | 1 hour |
| M-6 | Build obfuscation flags | Low | 30 min |
| L-1 | Unify biometric setting source of truth | Low | 1 hour |
| L-2 | Export sharing warning | Low | 30 min |
| L-3 | Firebase error logging | Low | 15 min |

---

## What's Already Done Well

- **JWT tokens in OS Keychain/Keystore** via `flutter_secure_storage` with Android EncryptedSharedPreferences and AES-GCM — correct.
- **Biometric auth flow** is solid: timeout, graceful fallback, proper OS API usage, auth logging.
- **Drift ORM** fully prevents SQL injection — no raw query strings in the codebase.
- **Refresh token rotation** with retry-once-then-force-logout pattern is well implemented.
- **Password strength enforcement** on signup (uppercase + lowercase + digit + 8 chars).
- **Error messages** are user-friendly generic strings — internal errors don't leak raw exceptions to UI (except the server `detail` pass-through noted in M-2).
- **Secure storage options** are correctly configured per-platform (iOS Keychain accessibility, Android AES-GCM).
- **HTTPS enforced** for iOS production; Android debug HTTP scoped to emulator loopback.
- **Session invalidation on refresh failure** correctly clears tokens and forces re-login.
- **Input validation** via `FormValidation` is thorough and consistent across all forms.

---

*Generated by SmartSpend Engineering Copilot — 2026-06-07*
