import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smartbudget/data/models/tables.dart';

part 'savings_goal.freezed.dart';

@freezed
class SavingsGoal with _$SavingsGoal {
  const factory SavingsGoal({
    required String id,
    required String title,
    required double targetAmount,
    required double savedAmount,
    DateTime? deadline,
    required GoalPriority priority,
    String? color,
    @Default(false) bool autoAllocate,
    DateTime? createdAt,
  }) = _SavingsGoal;
}




