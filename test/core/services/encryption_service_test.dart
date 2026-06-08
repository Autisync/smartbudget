import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/core/services/encryption_service.dart';

/// In-memory stand-in for the flutter_secure_storage platform channel so the
/// EncryptionService can be exercised without a device keystore.
class _InMemorySecureStorage {
  final Map<String, String> _store = {};

  void install() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          _store[key!] = args['value'] as String;
          return null;
        case 'read':
          return _store[key];
        case 'delete':
          _store.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(_store);
        case 'deleteAll':
          _store.clear();
          return null;
        case 'containsKey':
          return _store.containsKey(key);
        default:
          return null;
      }
    });
  }
}

void main() {
  late EncryptionService service;

  setUp(() async {
    _InMemorySecureStorage().install();
    service = EncryptionService(const FlutterSecureStorage());
    await service.initialize();
  });

  group('AES-256-GCM round trip', () {
    test('encrypt then decrypt returns the original plaintext', () {
      const plaintext = 'Coffee with friends — €4.50';
      final encrypted = service.encryptData(plaintext);
      expect(service.decryptData(encrypted), plaintext);
    });

    test('new ciphertext uses the 12-byte GCM nonce format', () {
      final encrypted = service.encryptData('hello');
      final nonceSegment = encrypted.split(':').first;
      expect(base64Decode(nonceSegment).length, 12);
    });

    test('identical plaintext yields different ciphertext (random nonce)', () {
      final a = service.encryptData('same');
      final b = service.encryptData('same');
      expect(a, isNot(equals(b)));
      expect(service.decryptData(a), 'same');
      expect(service.decryptData(b), 'same');
    });

    test('tampered ciphertext fails the GCM auth tag and throws', () {
      final encrypted = service.encryptData('sensitive');
      final parts = encrypted.split(':');
      final body = base64Decode(parts[1]);
      body[0] ^= 0xFF; // flip a bit in the ciphertext+tag
      final tampered = '${parts[0]}:${base64Encode(body)}';
      expect(
        () => service.decryptData(tampered),
        throwsA(isA<EncryptionException>()),
      );
    });
  });

  group('legacy AES-256-CBC backward compatibility', () {
    test('decrypts data written in the old 16-byte IV CBC format', () async {
      // Reconstruct the master key the service generated so we can hand-craft
      // a legacy CBC record exactly as the previous implementation would have.
      const storage = FlutterSecureStorage();
      final keyB64 = await storage.read(key: 'financial_master_key');
      final key = encrypt.Key.fromBase64(keyB64!);
      final cbc = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );
      final iv = encrypt.IV.fromSecureRandom(16);
      final legacy = '${iv.base64}:${cbc.encrypt('legacy note', iv: iv).base64}';

      // The 16-byte IV must route to the CBC path and decrypt cleanly.
      expect(base64Decode(legacy.split(':').first).length, 16);
      expect(service.decryptData(legacy), 'legacy note');
    });
  });

  group('input validation', () {
    test('malformed payload throws EncryptionException', () {
      expect(
        () => service.decryptData('not-a-valid-format'),
        throwsA(isA<EncryptionException>()),
      );
    });
  });

  group('hashSensitiveData', () {
    test('is deterministic and not reversible base64', () {
      final h1 = service.hashSensitiveData('abc');
      final h2 = service.hashSensitiveData('abc');
      expect(h1, h2);
      expect(h1.length, 64); // SHA-256 hex
      expect(h1, isNot(equals(base64Encode(utf8.encode('abc')))));
    });
  });
}
