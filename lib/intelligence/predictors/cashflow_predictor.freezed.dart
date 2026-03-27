// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cashflow_predictor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CashflowPrediction {
  double get projectedMonthlySpend => throw _privateConstructorUsedError;
  double get projectedEndBalance => throw _privateConstructorUsedError;
  double get confidenceInterval => throw _privateConstructorUsedError;
  RiskLevel get riskLevel => throw _privateConstructorUsedError;
  String get recommendation => throw _privateConstructorUsedError;
  DateTime get predictionDate => throw _privateConstructorUsedError;

  /// Create a copy of CashflowPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CashflowPredictionCopyWith<CashflowPrediction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CashflowPredictionCopyWith<$Res> {
  factory $CashflowPredictionCopyWith(
          CashflowPrediction value, $Res Function(CashflowPrediction) then) =
      _$CashflowPredictionCopyWithImpl<$Res, CashflowPrediction>;
  @useResult
  $Res call(
      {double projectedMonthlySpend,
      double projectedEndBalance,
      double confidenceInterval,
      RiskLevel riskLevel,
      String recommendation,
      DateTime predictionDate});
}

/// @nodoc
class _$CashflowPredictionCopyWithImpl<$Res, $Val extends CashflowPrediction>
    implements $CashflowPredictionCopyWith<$Res> {
  _$CashflowPredictionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CashflowPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectedMonthlySpend = null,
    Object? projectedEndBalance = null,
    Object? confidenceInterval = null,
    Object? riskLevel = null,
    Object? recommendation = null,
    Object? predictionDate = null,
  }) {
    return _then(_value.copyWith(
      projectedMonthlySpend: null == projectedMonthlySpend
          ? _value.projectedMonthlySpend
          : projectedMonthlySpend // ignore: cast_nullable_to_non_nullable
              as double,
      projectedEndBalance: null == projectedEndBalance
          ? _value.projectedEndBalance
          : projectedEndBalance // ignore: cast_nullable_to_non_nullable
              as double,
      confidenceInterval: null == confidenceInterval
          ? _value.confidenceInterval
          : confidenceInterval // ignore: cast_nullable_to_non_nullable
              as double,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as RiskLevel,
      recommendation: null == recommendation
          ? _value.recommendation
          : recommendation // ignore: cast_nullable_to_non_nullable
              as String,
      predictionDate: null == predictionDate
          ? _value.predictionDate
          : predictionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CashflowPredictionImplCopyWith<$Res>
    implements $CashflowPredictionCopyWith<$Res> {
  factory _$$CashflowPredictionImplCopyWith(_$CashflowPredictionImpl value,
          $Res Function(_$CashflowPredictionImpl) then) =
      __$$CashflowPredictionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double projectedMonthlySpend,
      double projectedEndBalance,
      double confidenceInterval,
      RiskLevel riskLevel,
      String recommendation,
      DateTime predictionDate});
}

/// @nodoc
class __$$CashflowPredictionImplCopyWithImpl<$Res>
    extends _$CashflowPredictionCopyWithImpl<$Res, _$CashflowPredictionImpl>
    implements _$$CashflowPredictionImplCopyWith<$Res> {
  __$$CashflowPredictionImplCopyWithImpl(_$CashflowPredictionImpl _value,
      $Res Function(_$CashflowPredictionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CashflowPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectedMonthlySpend = null,
    Object? projectedEndBalance = null,
    Object? confidenceInterval = null,
    Object? riskLevel = null,
    Object? recommendation = null,
    Object? predictionDate = null,
  }) {
    return _then(_$CashflowPredictionImpl(
      projectedMonthlySpend: null == projectedMonthlySpend
          ? _value.projectedMonthlySpend
          : projectedMonthlySpend // ignore: cast_nullable_to_non_nullable
              as double,
      projectedEndBalance: null == projectedEndBalance
          ? _value.projectedEndBalance
          : projectedEndBalance // ignore: cast_nullable_to_non_nullable
              as double,
      confidenceInterval: null == confidenceInterval
          ? _value.confidenceInterval
          : confidenceInterval // ignore: cast_nullable_to_non_nullable
              as double,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as RiskLevel,
      recommendation: null == recommendation
          ? _value.recommendation
          : recommendation // ignore: cast_nullable_to_non_nullable
              as String,
      predictionDate: null == predictionDate
          ? _value.predictionDate
          : predictionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$CashflowPredictionImpl implements _CashflowPrediction {
  const _$CashflowPredictionImpl(
      {required this.projectedMonthlySpend,
      required this.projectedEndBalance,
      required this.confidenceInterval,
      required this.riskLevel,
      required this.recommendation,
      required this.predictionDate});

  @override
  final double projectedMonthlySpend;
  @override
  final double projectedEndBalance;
  @override
  final double confidenceInterval;
  @override
  final RiskLevel riskLevel;
  @override
  final String recommendation;
  @override
  final DateTime predictionDate;

  @override
  String toString() {
    return 'CashflowPrediction(projectedMonthlySpend: $projectedMonthlySpend, projectedEndBalance: $projectedEndBalance, confidenceInterval: $confidenceInterval, riskLevel: $riskLevel, recommendation: $recommendation, predictionDate: $predictionDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CashflowPredictionImpl &&
            (identical(other.projectedMonthlySpend, projectedMonthlySpend) ||
                other.projectedMonthlySpend == projectedMonthlySpend) &&
            (identical(other.projectedEndBalance, projectedEndBalance) ||
                other.projectedEndBalance == projectedEndBalance) &&
            (identical(other.confidenceInterval, confidenceInterval) ||
                other.confidenceInterval == confidenceInterval) &&
            (identical(other.riskLevel, riskLevel) ||
                other.riskLevel == riskLevel) &&
            (identical(other.recommendation, recommendation) ||
                other.recommendation == recommendation) &&
            (identical(other.predictionDate, predictionDate) ||
                other.predictionDate == predictionDate));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      projectedMonthlySpend,
      projectedEndBalance,
      confidenceInterval,
      riskLevel,
      recommendation,
      predictionDate);

  /// Create a copy of CashflowPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CashflowPredictionImplCopyWith<_$CashflowPredictionImpl> get copyWith =>
      __$$CashflowPredictionImplCopyWithImpl<_$CashflowPredictionImpl>(
          this, _$identity);
}

abstract class _CashflowPrediction implements CashflowPrediction {
  const factory _CashflowPrediction(
      {required final double projectedMonthlySpend,
      required final double projectedEndBalance,
      required final double confidenceInterval,
      required final RiskLevel riskLevel,
      required final String recommendation,
      required final DateTime predictionDate}) = _$CashflowPredictionImpl;

  @override
  double get projectedMonthlySpend;
  @override
  double get projectedEndBalance;
  @override
  double get confidenceInterval;
  @override
  RiskLevel get riskLevel;
  @override
  String get recommendation;
  @override
  DateTime get predictionDate;

  /// Create a copy of CashflowPrediction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CashflowPredictionImplCopyWith<_$CashflowPredictionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
