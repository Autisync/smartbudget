import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Encryption-at-rest for the SmartSpend SQLite database using SQLCipher.
///
/// ## How it works
/// - [setupSqlCipher] routes `package:sqlite3` to the bundled SQLCipher native
///   library. It MUST be called once at app startup, before the database is
///   opened, and is a no-op in unit tests (which use an in-memory plain DB via
///   `AppDatabase.forTesting`).
/// - [openEncryptedDatabase] opens (or creates) the on-disk DB with a 256-bit
///   key held in the OS keychain/keystore, applying `PRAGMA key` and verifying
///   that a real SQLCipher build is active.
/// - Existing **plaintext** databases from before encryption are migrated once,
///   in place, via `sqlcipher_export` into a new encrypted file that atomically
///   replaces the original.
///
/// ## Device QA required
/// SQLCipher links a native library that is only present in a real Flutter
/// build, so the encryption and the plaintext→encrypted migration CANNOT be
/// exercised by host `flutter test`. Verify on a device/emulator before
/// release (see RELEASE_BUILD.md → "Database encryption verification").
class DatabaseCipher {
  DatabaseCipher._();

  static const _dbFileName = 'smartbudget_db.sqlite';
  static const _cipherKeyAlias = 'db_cipher_key_v1';

  /// Point `package:sqlite3` at the SQLCipher native library. App-only: unit
  /// tests never call this, so they keep using the default plaintext sqlite3.
  static void setupSqlCipher() {
    open
      ..overrideFor(OperatingSystem.android, openCipherOnAndroid)
      // On iOS/macOS the SQLCipher symbols are statically linked into the
      // process by sqlcipher_flutter_libs.
      ..overrideFor(OperatingSystem.iOS, DynamicLibrary.process)
      ..overrideFor(OperatingSystem.macOS, DynamicLibrary.process);
  }

  /// Returns a [LazyDatabase] that opens the encrypted on-disk database,
  /// performing a one-time plaintext→encrypted migration when needed.
  static LazyDatabase openEncryptedDatabase({FlutterSecureStorage? storage}) {
    final secureStorage = storage ?? _defaultStorage();
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, _dbFileName);
      final key = await _loadOrCreateKey(secureStorage);

      // Defensive: remove any plaintext backup left behind by a previously
      // interrupted migration so an unencrypted copy can never linger on disk.
      final staleBackup = File('$dbPath.plaintext.bak');
      if (staleBackup.existsSync()) {
        try {
          staleBackup.deleteSync();
        } catch (_) {/* ignore */}
      }

      await _migratePlaintextIfNeeded(dbPath, key);

      return NativeDatabase(
        File(dbPath),
        setup: (raw) {
          // Raw key (no KDF salt derivation) — supply 32 bytes as hex.
          raw.execute("PRAGMA key = \"x'$key'\";");
          _assertCipherActive(raw);
        },
      );
    });
  }

  static FlutterSecureStorage _defaultStorage() => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  /// Loads the hex-encoded 256-bit key, generating and persisting one on first
  /// run. Stored in the OS keychain/keystore — never in the database itself.
  static Future<String> _loadOrCreateKey(FlutterSecureStorage storage) async {
    final existing = await storage.read(key: _cipherKeyAlias);
    if (existing != null && existing.length == 64) return existing;

    final keyBytes = encrypt.Key.fromSecureRandom(32).bytes;
    final hex = keyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await storage.write(key: _cipherKeyAlias, value: hex);
    return hex;
  }

  /// Fails loudly if the active sqlite build is not SQLCipher, so a
  /// misconfiguration can never silently store the database in plaintext.
  static void _assertCipherActive(Database raw) {
    final result = raw.select('PRAGMA cipher_version;');
    if (result.isEmpty || (result.first.values.first?.toString() ?? '').isEmpty) {
      throw StateError(
        'SQLCipher is not active — refusing to open the database unencrypted. '
        'Ensure setupSqlCipher() ran and sqlcipher_flutter_libs is linked.',
      );
    }
  }

  /// One-time, in-place migration of a legacy plaintext DB into an encrypted
  /// one. No-op if the file is missing (fresh install) or already encrypted.
  static Future<void> _migratePlaintextIfNeeded(
    String dbPath,
    String keyHex,
  ) async {
    final file = File(dbPath);
    if (!file.existsSync()) return; // fresh install → created encrypted

    // Detect a plaintext DB: a SQLCipher-keyed open of a plaintext file throws.
    Database? probe;
    var isPlaintext = false;
    try {
      probe = sqlite3.open(dbPath);
      // A plaintext file reads its header fine without a key.
      probe.select('SELECT count(*) FROM sqlite_master;');
      isPlaintext = true;
    } catch (_) {
      isPlaintext = false; // already encrypted (or unreadable) → leave as-is
    } finally {
      probe?.dispose();
    }
    if (!isPlaintext) return;

    if (kDebugMode) {
      debugPrint('[SmartSpend] Migrating plaintext database to SQLCipher…');
    }

    final encryptedPath = '$dbPath.enc';
    File(encryptedPath).existsSync()
        ? File(encryptedPath).deleteSync()
        : null;

    final plain = sqlite3.open(dbPath);
    try {
      // Attach a new encrypted database and copy everything across.
      plain.execute("ATTACH DATABASE '$encryptedPath' AS enc KEY \"x'$keyHex'\";");
      plain.execute("SELECT sqlcipher_export('enc');");
      plain.execute('DETACH DATABASE enc;');
    } finally {
      plain.dispose();
    }

    // Atomically replace the plaintext file with the encrypted copy.
    final backupPath = '$dbPath.plaintext.bak';
    File(dbPath).renameSync(backupPath);
    File(encryptedPath).renameSync(dbPath);
    // Best-effort cleanup of the plaintext backup once the swap succeeded.
    try {
      File(backupPath).deleteSync();
    } catch (_) {/* leave the backup if deletion fails */}
  }
}
