// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      recurrence: $enumDecodeNullable(
              _$TransactionRecurrenceEnumMap, json['recurrence']) ??
          TransactionRecurrence.none,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountId': instance.accountId,
      'amount': instance.amount,
      'currency': instance.currency,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'category': instance.category,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
      'recurrence': _$TransactionRecurrenceEnumMap[instance.recurrence]!,
      'isSynced': instance.isSynced,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.transfer: 'transfer',
};

const _$TransactionRecurrenceEnumMap = {
  TransactionRecurrence.none: 'none',
  TransactionRecurrence.daily: 'daily',
  TransactionRecurrence.weekly: 'weekly',
  TransactionRecurrence.monthly: 'monthly',
  TransactionRecurrence.yearly: 'yearly',
};
