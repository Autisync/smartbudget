import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smartbudget/data/models/tables.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String name,
    String? description,
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime startDate,
    required DateTime nextBillingDate,
    DateTime? endDate,
    required String category,
    @Default(true) bool isActive,
    String? paymentMethod,
    String? website,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}
