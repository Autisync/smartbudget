import 'package:freezed_annotation/freezed_annotation.dart';
part 'budget_alert.freezed.dart';

@freezed
class BudgetAlert with _$BudgetAlert {
  const factory BudgetAlert({
    required String budgetId,
    required String category,
    required double progress,
    required int threshold,
    required bool nearLimit,
    required bool overLimit,
    required DateTime generatedAt,
  }) = _BudgetAlert;
}
