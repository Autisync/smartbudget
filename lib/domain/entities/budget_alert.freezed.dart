// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BudgetAlert {
  String get budgetId => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  int get threshold => throw _privateConstructorUsedError;
  bool get nearLimit => throw _privateConstructorUsedError;
  bool get overLimit => throw _privateConstructorUsedError;
  DateTime get generatedAt => throw _privateConstructorUsedError;

  /// Create a copy of BudgetAlert
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetAlertCopyWith<BudgetAlert> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetAlertCopyWith<$Res> {
  factory $BudgetAlertCopyWith(
          BudgetAlert value, $Res Function(BudgetAlert) then) =
      _$BudgetAlertCopyWithImpl<$Res, BudgetAlert>;
  @useResult
  $Res call(
      {String budgetId,
      String category,
      double progress,
      int threshold,
      bool nearLimit,
      bool overLimit,
      DateTime generatedAt});
}

/// @nodoc
class _$BudgetAlertCopyWithImpl<$Res, $Val extends BudgetAlert>
    implements $BudgetAlertCopyWith<$Res> {
  _$BudgetAlertCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetAlert
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budgetId = null,
    Object? category = null,
    Object? progress = null,
    Object? threshold = null,
    Object? nearLimit = null,
    Object? overLimit = null,
    Object? generatedAt = null,
  }) {
    return _then(_value.copyWith(
      budgetId: null == budgetId
          ? _value.budgetId
          : budgetId // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      nearLimit: null == nearLimit
          ? _value.nearLimit
          : nearLimit // ignore: cast_nullable_to_non_nullable
              as bool,
      overLimit: null == overLimit
          ? _value.overLimit
          : overLimit // ignore: cast_nullable_to_non_nullable
              as bool,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BudgetAlertImplCopyWith<$Res>
    implements $BudgetAlertCopyWith<$Res> {
  factory _$$BudgetAlertImplCopyWith(
          _$BudgetAlertImpl value, $Res Function(_$BudgetAlertImpl) then) =
      __$$BudgetAlertImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String budgetId,
      String category,
      double progress,
      int threshold,
      bool nearLimit,
      bool overLimit,
      DateTime generatedAt});
}

/// @nodoc
class __$$BudgetAlertImplCopyWithImpl<$Res>
    extends _$BudgetAlertCopyWithImpl<$Res, _$BudgetAlertImpl>
    implements _$$BudgetAlertImplCopyWith<$Res> {
  __$$BudgetAlertImplCopyWithImpl(
      _$BudgetAlertImpl _value, $Res Function(_$BudgetAlertImpl) _then)
      : super(_value, _then);

  /// Create a copy of BudgetAlert
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? budgetId = null,
    Object? category = null,
    Object? progress = null,
    Object? threshold = null,
    Object? nearLimit = null,
    Object? overLimit = null,
    Object? generatedAt = null,
  }) {
    return _then(_$BudgetAlertImpl(
      budgetId: null == budgetId
          ? _value.budgetId
          : budgetId // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      nearLimit: null == nearLimit
          ? _value.nearLimit
          : nearLimit // ignore: cast_nullable_to_non_nullable
              as bool,
      overLimit: null == overLimit
          ? _value.overLimit
          : overLimit // ignore: cast_nullable_to_non_nullable
              as bool,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$BudgetAlertImpl implements _BudgetAlert {
  const _$BudgetAlertImpl(
      {required this.budgetId,
      required this.category,
      required this.progress,
      required this.threshold,
      required this.nearLimit,
      required this.overLimit,
      required this.generatedAt});

  @override
  final String budgetId;
  @override
  final String category;
  @override
  final double progress;
  @override
  final int threshold;
  @override
  final bool nearLimit;
  @override
  final bool overLimit;
  @override
  final DateTime generatedAt;

  @override
  String toString() {
    return 'BudgetAlert(budgetId: $budgetId, category: $category, progress: $progress, threshold: $threshold, nearLimit: $nearLimit, overLimit: $overLimit, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetAlertImpl &&
            (identical(other.budgetId, budgetId) ||
                other.budgetId == budgetId) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.threshold, threshold) ||
                other.threshold == threshold) &&
            (identical(other.nearLimit, nearLimit) ||
                other.nearLimit == nearLimit) &&
            (identical(other.overLimit, overLimit) ||
                other.overLimit == overLimit) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, budgetId, category, progress,
      threshold, nearLimit, overLimit, generatedAt);

  /// Create a copy of BudgetAlert
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetAlertImplCopyWith<_$BudgetAlertImpl> get copyWith =>
      __$$BudgetAlertImplCopyWithImpl<_$BudgetAlertImpl>(this, _$identity);
}

abstract class _BudgetAlert implements BudgetAlert {
  const factory _BudgetAlert(
      {required final String budgetId,
      required final String category,
      required final double progress,
      required final int threshold,
      required final bool nearLimit,
      required final bool overLimit,
      required final DateTime generatedAt}) = _$BudgetAlertImpl;

  @override
  String get budgetId;
  @override
  String get category;
  @override
  double get progress;
  @override
  int get threshold;
  @override
  bool get nearLimit;
  @override
  bool get overLimit;
  @override
  DateTime get generatedAt;

  /// Create a copy of BudgetAlert
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetAlertImplCopyWith<_$BudgetAlertImpl> get copyWith =>
      throw _privateConstructorUsedError;
}




