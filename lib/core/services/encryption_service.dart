import 'dart:convert';
// ...existing imports...
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final FlutterSecureStorage _secureStorage;
  static const _keyAlias = 'financial_master_key';

  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;

  EncryptionService(this._secureStorage);

  Future<void> initialize() async {
    var keyString = await _secureStorage.read(key: _keyAlias);

    if (keyString == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = key.base64;
      await _secureStorage.write(key: _keyAlias, value: keyString);
    }

    final key = encrypt.Key.fromBase64(keyString);
    _encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    _iv = encrypt.IV.fromLength(16);
  }

  String encryptData(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return '${_iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw EncryptionException('Failed to encrypt data');
    }
  }

  String decryptData(String encryptedData) {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw const FormatException('Invalid encrypted format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data');
    }
  }

  String hashSensitiveData(String data) {
    // Simple hash for demonstration - use crypto package for production
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
