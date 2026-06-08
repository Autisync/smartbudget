import 'package:smartbudget/data/models/tables.dart' show AccountType;

export 'package:smartbudget/data/models/tables.dart' show AccountType;

/// Stable identifiers for the three default money-source accounts that every
/// install is seeded with. Kept as constants so transactions and migrations can
/// reference them without magic strings.
class DefaultAccountIds {
  const DefaultAccountIds._();
  static const cash = 'acct_cash';
  static const bankTransfer = 'acct_bank';
  static const creditCard = 'acct_credit';

  /// The placeholder id used by transactions written before accounts existed.
  static const legacyDefault = 'default';
}

/// A money source (Cash, Bank Transfer, Credit Card, …) with its derived
/// current balance.
///
/// [openingBalance] is the user-set starting balance stored on the row.
/// [currentBalance] is always derived (opening + income − expense); it is never
/// persisted, so it cannot drift away from the underlying ledger.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final String currency;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;

  bool get isDefault =>
      id == DefaultAccountIds.cash ||
      id == DefaultAccountIds.bankTransfer ||
      id == DefaultAccountIds.creditCard;

  Account copyWith({
    String? name,
    AccountType? type,
    String? currency,
    double? openingBalance,
    double? currentBalance,
    bool? isActive,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Human-friendly label for an [AccountType].
extension AccountTypeLabel on AccountType {
  String get label => switch (this) {
        AccountType.cash => 'Cash',
        AccountType.bank => 'Bank Transfer',
        AccountType.mobileMoney => 'Mobile Money',
        AccountType.creditCard => 'Credit Card',
        AccountType.investment => 'Investment',
      };
}
