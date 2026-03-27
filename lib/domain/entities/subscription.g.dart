// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionImpl _$$SubscriptionImplFromJson(Map<String, dynamic> json) =>
    _$SubscriptionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      billingCycle: $enumDecode(_$BillingCycleEnumMap, json['billingCycle']),
      startDate: DateTime.parse(json['startDate'] as String),
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      category: json['category'] as String,
      isActive: json['isActive'] as bool? ?? true,
      paymentMethod: json['paymentMethod'] as String?,
      website: json['website'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SubscriptionImplToJson(_$SubscriptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'amount': instance.amount,
      'currency': instance.currency,
      'billingCycle': _$BillingCycleEnumMap[instance.billingCycle]!,
      'startDate': instance.startDate.toIso8601String(),
      'nextBillingDate': instance.nextBillingDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'category': instance.category,
      'isActive': instance.isActive,
      'paymentMethod': instance.paymentMethod,
      'website': instance.website,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$BillingCycleEnumMap = {
  BillingCycle.weekly: 'weekly',
  BillingCycle.monthly: 'monthly',
  BillingCycle.quarterly: 'quarterly',
  BillingCycle.yearly: 'yearly',
};
