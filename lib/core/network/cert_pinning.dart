import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';

const bool _pinningEnabled =
    bool.fromEnvironment('ENABLE_CERT_PINNING', defaultValue: false);

// Emergency-only escape hatch for production incidents where the API serves
// an invalid/untrusted certificate chain and users are blocked from auth.
// Keep disabled by default and enable only via explicit --dart-define.
const bool _allowInsecureApiTls =
    bool.fromEnvironment('ALLOW_INSECURE_API_TLS', defaultValue: false);

bool _insecureTlsWarningSent = false;

/// SPKI pins: base64(SHA-256(SubjectPublicKeyInfo DER)).
///
/// Generate the leaf pin after Let's Encrypt issues the first cert:
///
/// ```sh
/// openssl s_client -connect api.smaartspend.com:443 -servername api.smaartspend.com \
///   </dev/null 2>/dev/null \
///   | openssl x509 -pubkey -noout \
///   | openssl pkey -pubin -outform DER \
///   | openssl dgst -sha256 -binary \
///   | base64
/// ```
///
/// Generate the intermediate CA backup pin (Let's Encrypt E5/R10):
///
/// ```sh
/// openssl s_client -connect api.smaartspend.com:443 -servername api.smaartspend.com \
///   -showcerts </dev/null 2>/dev/null \
///   | awk '/-----BEGIN CERTIFICATE-----/{c++} c==2{print} /-----END CERTIFICATE-----/ && c==2{exit}' \
///   | openssl x509 -pubkey -noout \
///   | openssl pkey -pubin -outform DER \
///   | openssl dgst -sha256 -binary \
///   | base64
/// ```
///
/// Leaf pin: changes every ~90 days on Let's Encrypt renewal.
/// Intermediate pin: stable for years (same LE key across renewals).
/// Add the NEW leaf pin before renewal so old clients keep working
/// until all users have updated. Remove the previous leaf pin after
/// the old cert has expired.
const Set<String> _productionPins = {
  // Leaf SPKI pin — CN=TRAEFIK DEFAULT CERT (self-signed, expires 2027-05-28).
  // Obtained: 2026-06-07 via `openssl s_client … | openssl x509 -pubkey -noout | …`
  // TODO: Replace with Let's Encrypt leaf pin once LE is configured on the server.
  'NILeAobXrKJyjBkhewvvHgvQMwj3LdCAw2ayUrHku7E=',
  // TODO: Add Let's Encrypt E5 (ECDSA) or R10 (RSA) intermediate CA backup pin
  // once the server is switched to a CA-signed cert. Intermediate pins are stable
  // across 90-day renewals and serve as the rotation safety net.
  // 'REPLACE_WITH_LE_INTERMEDIATE_SPKI_PIN==',
};

/// Applies SPKI certificate pinning to [dio] for the production API host.
///
/// Uses SecurityContext(withTrustedRoots: false) so that badCertificateCallback
/// fires for every certificate — including CA-signed ones — giving us a
/// consistent hook to verify the SPKI pin regardless of cert type.
/// All trust decisions are made solely via the pinned public key hashes.
///
/// In debug/profile mode, pinning is skipped for local hosts.
/// If pins contain placeholder strings, pinning is disabled with a warning.
void applyCertificatePinning(Dio dio, String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null) return;

  // Emergency override takes precedence over pinning mode so a production TLS
  // incident can be unblocked with a single --dart-define.
  if (_allowInsecureApiTls &&
      uri.scheme == 'https' &&
      !_isLocalHost(uri.host)) {
    if (kReleaseMode && !_insecureTlsWarningSent) {
      _insecureTlsWarningSent = true;
      ErrorMonitor.captureMessage(
        'SECURITY WARNING: ALLOW_INSECURE_API_TLS=true is active for ${uri.host}.',
        category: 'security',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[SmartSpend Security] ⚠️  Insecure API TLS override enabled for ${uri.host}.',
      );
    }

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          // Allow ONLY the configured API host while override is enabled.
          return host == uri.host;
        };
        return client;
      },
    );
    return;
  }

  // Pinning is opt-in via --dart-define=ENABLE_CERT_PINNING=true.
  // Defaulting off keeps environments functional when cert chains rotate.
  if (!_pinningEnabled) {
    if (kDebugMode) {
      debugPrint('[SmartSpend Security] Certificate pinning disabled.');
    }
    return;
  }

  if (uri.scheme != 'https') return;
  if (_isLocalHost(uri.host)) return;

  if (_productionPins.any((p) => p.startsWith('REPLACE_WITH'))) {
    if (kDebugMode) {
      debugPrint(
        '[SmartSpend Security] ⚠️  Certificate pinning is NOT active — '
        'replace placeholder pins in cert_pinning.dart before release.',
      );
    }
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      // withTrustedRoots: false means no system CAs are trusted, so
      // badCertificateCallback fires for every cert (including CA-signed).
      // We perform our own trust decision by verifying the SPKI pin.
      final context = SecurityContext(withTrustedRoots: false);
      final client = HttpClient(context: context);
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        if (host != uri.host) return false;

        final spkiPin = _computeSpkiPin(Uint8List.fromList(cert.der));
        if (spkiPin == null) {
          if (kDebugMode) {
            debugPrint(
                '[SmartSpend Security] Failed to parse SPKI from cert for $host');
          }
          return false;
        }

        final matched = _productionPins.contains(spkiPin);
        if (!matched && kDebugMode) {
          debugPrint(
            '[SmartSpend Security] Pin mismatch for $host — '
            'computed SPKI: $spkiPin',
          );
        }
        return matched;
      };
      return client;
    },
  );
}

/// Thin wrapper for use in unit tests — calls [_computeSpkiPin] directly.
@visibleForTesting
String? computeSpkiPinForTest(List<int> certDer) =>
    _computeSpkiPin(Uint8List.fromList(certDer));

/// Returns base64(SHA-256(SubjectPublicKeyInfo DER)) from a DER-encoded X.509 cert,
/// or null if the cert cannot be parsed.
String? _computeSpkiPin(Uint8List certDer) {
  final range = _findSpkiRange(certDer);
  if (range == null) return null;
  final spkiBytes = certDer.sublist(range.$1, range.$2);
  return base64Encode(sha256.convert(spkiBytes).bytes);
}

/// Returns the [start, end) byte range of SubjectPublicKeyInfo within a
/// DER-encoded X.509 certificate, or null if parsing fails.
///
/// X.509 TBSCertificate element order (RFC 5280):
///   [0] version (OPTIONAL, always present in v3)
///   serialNumber  INTEGER
///   signature     AlgorithmIdentifier SEQUENCE
///   issuer        Name SEQUENCE
///   validity      Validity SEQUENCE
///   subject       Name SEQUENCE
///   subjectPublicKeyInfo  SEQUENCE  <-- target
(int, int)? _findSpkiRange(Uint8List d) {
  try {
    // Enter Certificate SEQUENCE
    if (d[0] != 0x30) return null;
    var pos = _contentStart(d, 0);

    // Enter TBSCertificate SEQUENCE
    if (d[pos] != 0x30) return null;
    pos = _contentStart(d, pos);

    // Skip optional [0] EXPLICIT version (tag 0xa0, always present in v3)
    if (d[pos] == 0xa0) pos = _elementEnd(d, pos);

    // Skip serialNumber INTEGER
    if (d[pos] != 0x02) return null;
    pos = _elementEnd(d, pos);

    // Skip signature AlgorithmIdentifier
    if (d[pos] != 0x30) return null;
    pos = _elementEnd(d, pos);

    // Skip issuer Name
    if (d[pos] != 0x30) return null;
    pos = _elementEnd(d, pos);

    // Skip validity
    if (d[pos] != 0x30) return null;
    pos = _elementEnd(d, pos);

    // Skip subject Name
    if (d[pos] != 0x30) return null;
    pos = _elementEnd(d, pos);

    // SubjectPublicKeyInfo SEQUENCE
    if (d[pos] != 0x30) return null;
    return (pos, _elementEnd(d, pos));
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Minimal DER/BER length helpers (single-byte tags only; sufficient for X.509)
// ---------------------------------------------------------------------------

/// Offset of an element's content (past tag + length bytes).
int _contentStart(Uint8List d, int pos) {
  pos++; // skip tag
  return pos + _lenFieldWidth(d, pos);
}

/// Offset just past the end of the DER element starting at [pos].
int _elementEnd(Uint8List d, int pos) {
  pos++; // skip tag
  final w = _lenFieldWidth(d, pos);
  return pos + w + _decodeLen(d, pos);
}

/// Number of bytes occupied by the length field at [pos].
int _lenFieldWidth(Uint8List d, int pos) {
  return d[pos] < 0x80 ? 1 : 1 + (d[pos] & 0x7f);
}

/// Decoded length value at [pos].
int _decodeLen(Uint8List d, int pos) {
  if (d[pos] < 0x80) return d[pos];
  final n = d[pos] & 0x7f;
  var len = 0;
  for (var i = 1; i <= n; i++) {
    len = (len << 8) | d[pos + i];
  }
  return len;
}

bool _isLocalHost(String host) =>
    host == 'localhost' ||
    host == '127.0.0.1' ||
    host == '10.0.2.2' ||
    host == '::1';
