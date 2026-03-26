import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String accountId,
    required double amount,
    required String currency,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? note,
    @Default(TransactionRecurrence.none) TransactionRecurrence recurrence,
    @Default(false) bool isSynced,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

extension TransactionExtension on Transaction {
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isRecurring => recurrence != TransactionRecurrence.none;

  Transaction copyWithSync(bool synced) => copyWith(isSynced: synced);
}
