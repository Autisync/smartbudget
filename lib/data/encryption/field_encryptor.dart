import 'package:smartbudget/core/services/encryption_service.dart';

/// C-2 FIX: Field-level encryption for sensitive text stored in SQLite.
///
/// SQLite (Drift) is not encrypted at rest, so we encrypt individual sensitive
/// fields before writing and decrypt after reading. This protects free-text
/// financial data (notes, payment methods, descriptions) without breaking
/// indexed or queryable columns (amounts, dates, IDs, categories).
///
/// Columns encrypted: transactions.note, subscriptions.description,
/// subscriptions.paymentMethod, subscriptions.website.
///
/// Detection: encrypted values are prefixed `enc:` followed by `<iv_b64>:<ct_b64>`.
/// Plaintext values (legacy / unencrypted) are passed through transparently so
/// existing installs continue to work during a rolling migration.
class FieldEncryptor {
  FieldEncryptor(this._encryption);

  final EncryptionService _encryption;

  static const _prefix = 'enc:';

  /// Encrypts [value] and returns a prefixed ciphertext string.
  String encrypt(String value) {
    final ct = _encryption.encryptData(value);
    return '$_prefix$ct';
  }

  /// Decrypts an encrypted [value]. If [value] is plaintext (no prefix),
  /// returns it as-is for backwards compatibility with existing records.
  String decrypt(String value) {
    if (!value.startsWith(_prefix)) return value; // legacy plaintext fallback
    return _encryption.decryptData(value.substring(_prefix.length));
  }

  /// Null-safe encryption — returns null if [value] is null.
  String? encryptNullable(String? value) {
    if (value == null || value.isEmpty) return value;
    return encrypt(value);
  }

  /// Null-safe decryption with plaintext fallback.
  String? decryptNullable(String? value) {
    if (value == null || value.isEmpty) return value;
    return decrypt(value);
  }
}
