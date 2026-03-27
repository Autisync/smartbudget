// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Budget {
  String get id => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  double get limitAmount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  BudgetPeriod get period => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  int get alertThreshold => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BudgetCopyWith<Budget> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetCopyWith<$Res> {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) then) =
      _$BudgetCopyWithImpl<$Res, Budget>;
  @useResult
  $Res call(
      {String id,
      String category,
      double limitAmount,
      String currency,
      BudgetPeriod period,
      DateTime startDate,
      DateTime? endDate,
      int alertThreshold,
      bool isActive});
}

/// @nodoc
class _$BudgetCopyWithImpl<$Res, $Val extends Budget>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? limitAmount = null,
    Object? currency = null,
    Object? period = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? alertThreshold = null,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      limitAmount: null == limitAmount
          ? _value.limitAmount
          : limitAmount // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as BudgetPeriod,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      alertThreshold: null == alertThreshold
          ? _value.alertThreshold
          : alertThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BudgetImplCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$$BudgetImplCopyWith(
          _$BudgetImpl value, $Res Function(_$BudgetImpl) then) =
      __$$BudgetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String category,
      double limitAmount,
      String currency,
      BudgetPeriod period,
      DateTime startDate,
      DateTime? endDate,
      int alertThreshold,
      bool isActive});
}

/// @nodoc
class __$$BudgetImplCopyWithImpl<$Res>
    extends _$BudgetCopyWithImpl<$Res, _$BudgetImpl>
    implements _$$BudgetImplCopyWith<$Res> {
  __$$BudgetImplCopyWithImpl(
      _$BudgetImpl _value, $Res Function(_$BudgetImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? limitAmount = null,
    Object? currency = null,
    Object? period = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? alertThreshold = null,
    Object? isActive = null,
  }) {
    return _then(_$BudgetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      limitAmount: null == limitAmount
          ? _value.limitAmount
          : limitAmount // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as BudgetPeriod,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      alertThreshold: null == alertThreshold
          ? _value.alertThreshold
          : alertThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$BudgetImpl implements _Budget {
  const _$BudgetImpl(
      {required this.id,
      required this.category,
      required this.limitAmount,
      required this.currency,
      required this.period,
      required this.startDate,
      this.endDate,
      this.alertThreshold = 80,
      this.isActive = true});

  @override
  final String id;
  @override
  final String category;
  @override
  final double limitAmount;
  @override
  final String currency;
  @override
  final BudgetPeriod period;
  @override
  final DateTime startDate;
  @override
  final DateTime? endDate;
  @override
  @JsonKey()
  final int alertThreshold;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'Budget(id: $id, category: $category, limitAmount: $limitAmount, currency: $currency, period: $period, startDate: $startDate, endDate: $endDate, alertThreshold: $alertThreshold, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.limitAmount, limitAmount) ||
                other.limitAmount == limitAmount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.alertThreshold, alertThreshold) ||
                other.alertThreshold == alertThreshold) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, category, limitAmount,
      currency, period, startDate, endDate, alertThreshold, isActive);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      __$$BudgetImplCopyWithImpl<_$BudgetImpl>(this, _$identity);
}

abstract class _Budget implements Budget {
  const factory _Budget(
      {required final String id,
      required final String category,
      required final double limitAmount,
      required final String currency,
      required final BudgetPeriod period,
      required final DateTime startDate,
      final DateTime? endDate,
      final int alertThreshold,
      final bool isActive}) = _$BudgetImpl;

  @override
  String get id;
  @override
  String get category;
  @override
  double get limitAmount;
  @override
  String get currency;
  @override
  BudgetPeriod get period;
  @override
  DateTime get startDate;
  @override
  DateTime? get endDate;
  @override
  int get alertThreshold;
  @override
  bool get isActive;
  @override
  @JsonKey(ignore: true)
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BudgetProgress {
  Budget get budget => throw _privateConstructorUsedError;
  double get spent => throw _privateConstructorUsedError;
  double get remaining => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;
  bool get isOverBudget => throw _privateConstructorUsedError;
  bool get isNearLimit => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BudgetProgressCopyWith<BudgetProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetProgressCopyWith<$Res> {
  factory $BudgetProgressCopyWith(
          BudgetProgress value, $Res Function(BudgetProgress) then) =
      _$BudgetProgressCopyWithImpl<$Res, BudgetProgress>;
  @useResult
  $Res call(
      {Budget budget,
      double spent,
      double remaining,
      double percentage,
      bool isOverBudget,
      bool isNearLimit});

  $BudgetCopyWith<$Res> get budget;
}

/// @nodoc
class _$BudgetProgressCopyWithImpl<$Res, $Val extends BudgetProgress>
    implements $BudgetProgressCopyWith<$Res> {
  _$BudgetProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budget = null,
    Object? spent = null,
    Object? remaining = null,
    Object? percentage = null,
    Object? isOverBudget = null,
    Object? isNearLimit = null,
  }) {
    return _then(_value.copyWith(
      budget: null == budget
          ? _value.budget
          : budget // ignore: cast_nullable_to_non_nullable
              as Budget,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      remaining: null == remaining
          ? _value.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      isOverBudget: null == isOverBudget
          ? _value.isOverBudget
          : isOverBudget // ignore: cast_nullable_to_non_nullable
              as bool,
      isNearLimit: null == isNearLimit
          ? _value.isNearLimit
          : isNearLimit // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BudgetCopyWith<$Res> get budget {
    return $BudgetCopyWith<$Res>(_value.budget, (value) {
      return _then(_value.copyWith(budget: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BudgetProgressImplCopyWith<$Res>
    implements $BudgetProgressCopyWith<$Res> {
  factory _$$BudgetProgressImplCopyWith(_$BudgetProgressImpl value,
          $Res Function(_$BudgetProgressImpl) then) =
      __$$BudgetProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Budget budget,
      double spent,
      double remaining,
      double percentage,
      bool isOverBudget,
      bool isNearLimit});

  @override
  $BudgetCopyWith<$Res> get budget;
}

/// @nodoc
class __$$BudgetProgressImplCopyWithImpl<$Res>
    extends _$BudgetProgressCopyWithImpl<$Res, _$BudgetProgressImpl>
    implements _$$BudgetProgressImplCopyWith<$Res> {
  __$$BudgetProgressImplCopyWithImpl(
      _$BudgetProgressImpl _value, $Res Function(_$BudgetProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budget = null,
    Object? spent = null,
    Object? remaining = null,
    Object? percentage = null,
    Object? isOverBudget = null,
    Object? isNearLimit = null,
  }) {
    return _then(_$BudgetProgressImpl(
      budget: null == budget
          ? _value.budget
          : budget // ignore: cast_nullable_to_non_nullable
              as Budget,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      remaining: null == remaining
          ? _value.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      isOverBudget: null == isOverBudget
          ? _value.isOverBudget
          : isOverBudget // ignore: cast_nullable_to_non_nullable
              as bool,
      isNearLimit: null == isNearLimit
          ? _value.isNearLimit
          : isNearLimit // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$BudgetProgressImpl implements _BudgetProgress {
  const _$BudgetProgressImpl(
      {required this.budget,
      required this.spent,
      required this.remaining,
      required this.percentage,
      required this.isOverBudget,
      required this.isNearLimit});

  @override
  final Budget budget;
  @override
  final double spent;
  @override
  final double remaining;
  @override
  final double percentage;
  @override
  final bool isOverBudget;
  @override
  final bool isNearLimit;

  @override
  String toString() {
    return 'BudgetProgress(budget: $budget, spent: $spent, remaining: $remaining, percentage: $percentage, isOverBudget: $isOverBudget, isNearLimit: $isNearLimit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetProgressImpl &&
            (identical(other.budget, budget) || other.budget == budget) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.isOverBudget, isOverBudget) ||
                other.isOverBudget == isOverBudget) &&
            (identical(other.isNearLimit, isNearLimit) ||
                other.isNearLimit == isNearLimit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, budget, spent, remaining,
      percentage, isOverBudget, isNearLimit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetProgressImplCopyWith<_$BudgetProgressImpl> get copyWith =>
      __$$BudgetProgressImplCopyWithImpl<_$BudgetProgressImpl>(
          this, _$identity);
}

abstract class _BudgetProgress implements BudgetProgress {
  const factory _BudgetProgress(
      {required final Budget budget,
      required final double spent,
      required final double remaining,
      required final double percentage,
      required final bool isOverBudget,
      required final bool isNearLimit}) = _$BudgetProgressImpl;

  @override
  Budget get budget;
  @override
  double get spent;
  @override
  double get remaining;
  @override
  double get percentage;
  @override
  bool get isOverBudget;
  @override
  bool get isNearLimit;
  @override
  @JsonKey(ignore: true)
  _$$BudgetProgressImplCopyWith<_$BudgetProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
