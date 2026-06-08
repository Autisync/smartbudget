import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-GCM encryption service for local sensitive data.
///
/// ## Algorithm upgrade: CBC → GCM
/// Previous versions used AES-256-CBC (no authentication tag), which allowed
/// undetected ciphertext tampering. All **new** encryptions now use AES-256-GCM,
/// which appends a 16-byte authentication tag and raises [EncryptionException]
/// if the tag fails verification on decryption.
///
/// ## Migration (transparent, no data-loss)
/// Existing CBC-encrypted SQLite fields are detected automatically by the
/// nonce/IV byte length in [decryptData] and decrypted with the legacy CBC
/// encrypter. CBC records are never re-written; they upgrade naturally the
/// next time their row is written.
///
/// ## Wire format
/// - GCM (new):    `<12-byte nonce, 16 base64 chars>:<ciphertext + 16-byte tag, base64>`
/// - CBC (legacy): `<16-byte IV,    24 base64 chars>:<ciphertext, base64>`
///
/// The differing nonce/IV lengths make the two formats unambiguous without a
/// version prefix and require no schema changes.
class EncryptionService {
  final FlutterSecureStorage _secureStorage;
  static const _keyAlias = 'financial_master_key';

  /// AES-256-GCM — used for all **new** encryptions.
  late encrypt.Encrypter _gcmEncrypter;

  /// AES-256-CBC — **legacy decrypt only**; never used for new data.
  late encrypt.Encrypter _cbcEncrypter;

  EncryptionService(this._secureStorage);

  Future<void> initialize() async {
    var keyString = await _secureStorage.read(key: _keyAlias);

    if (keyString == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = key.base64;
      await _secureStorage.write(key: _keyAlias, value: keyString);
    }

    final key = encrypt.Key.fromBase64(keyString);

    // IMPORTANT: do NOT pass padding: null for GCM. In the `encrypt` package,
    // a null padding routes encryption/decryption through a raw processBlock
    // loop that never calls doFinal — which means the GCM authentication tag is
    // neither appended nor verified, silently disabling tamper detection.
    // Leaving padding at its default makes the Encrypter call _cipher.process()
    // (→ doFinal), so GCMBlockCipher appends the 16-byte tag on encrypt and
    // throws on tag mismatch during decrypt. GCM ignores the PKCS7 byte-padding
    // itself (it is an AEAD stream cipher), so no extra padding is applied.
    _gcmEncrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    // CBC encrypter retained exclusively for decrypting existing records.
    _cbcEncrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
  }

  /// Encrypts [plainText] with AES-256-GCM using a unique random 96-bit nonce.
  ///
  /// Output: `<nonce_base64>:<ciphertext+tag_base64>`
  /// The nonce is 12 bytes (16 base64 chars), which distinguishes this format
  /// from legacy CBC output (16-byte IV = 24 base64 chars) in [decryptData].
  String encryptData(String plainText) {
    try {
      final nonce = encrypt.IV.fromSecureRandom(12); // 96-bit nonce for GCM
      final encrypted = _gcmEncrypter.encrypt(plainText, iv: nonce);
      return '${nonce.base64}:${encrypted.base64}';
    } catch (e) {
      throw EncryptionException('Failed to encrypt data');
    }
  }

  /// Decrypts [encryptedData], auto-selecting the algorithm by nonce/IV length:
  ///
  /// - **12-byte first segment (16 base64 chars)** → AES-256-GCM; the
  ///   GCMBlockCipher verifies the authentication tag and throws if invalid,
  ///   so any ciphertext tampering is detected before plaintext is returned.
  /// - **16-byte first segment (24 base64 chars)** → AES-256-CBC legacy path;
  ///   backwards-compatible with records written before the GCM upgrade.
  String decryptData(String encryptedData) {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw const FormatException('Invalid encrypted format');
      }

      final ivOrNonce = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      switch (ivOrNonce.bytes.length) {
        case 12:
          // AES-256-GCM: authentication tag verified automatically by
          // PointyCastle's GCMBlockCipher — throws on tag mismatch.
          return _gcmEncrypter.decrypt(encrypted, iv: ivOrNonce);
        case 16:
          // AES-256-CBC legacy: no authentication tag, plaintext fallback.
          return _cbcEncrypter.decrypt(encrypted, iv: ivOrNonce);
        default:
          throw FormatException(
            'Unrecognised IV/nonce length: ${ivOrNonce.bytes.length} bytes',
          );
      }
    } catch (e) {
      throw EncryptionException('Failed to decrypt data');
    }
  }

  /// Returns a SHA-256 hex digest of [data].
  ///
  /// One-way; use only for deduplication or integrity checks where the
  /// original value is not needed (e.g. detecting duplicate transactions).
  /// **Never use this for passwords** — the backend must use a memory-hard
  /// KDF (Argon2id) before storing any credential hash. This function
  /// operates only on non-secret client-side identifiers.
  String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}




