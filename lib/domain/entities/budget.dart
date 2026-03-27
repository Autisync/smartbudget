import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smartbudget/data/models/tables.dart';

part 'budget.freezed.dart';

@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String category,
    required double limitAmount,
    required String currency,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
    @Default(80) int alertThreshold,
    @Default(true) bool isActive,
  }) = _Budget;
}

@freezed
class BudgetProgress with _$BudgetProgress {
  const factory BudgetProgress({
    required Budget budget,
    required double spent,
    required double remaining,
    required double percentage,
    required bool isOverBudget,
    required bool isNearLimit,
  }) = _BudgetProgress;
}
