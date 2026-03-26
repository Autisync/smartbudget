// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spending_analyzer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SpendingProfile {
  double get monthlyBurnRate => throw _privateConstructorUsedError;
  double get averageDailySpend => throw _privateConstructorUsedError;
  Map<String, double> get categoryDistribution =>
      throw _privateConstructorUsedError;
  List<SpendingAnomaly> get anomalies => throw _privateConstructorUsedError;
  TrendDirection get trend => throw _privateConstructorUsedError;
  double get topCategoryPercentage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SpendingProfileCopyWith<SpendingProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpendingProfileCopyWith<$Res> {
  factory $SpendingProfileCopyWith(
          SpendingProfile value, $Res Function(SpendingProfile) then) =
      _$SpendingProfileCopyWithImpl<$Res, SpendingProfile>;
  @useResult
  $Res call(
      {double monthlyBurnRate,
      double averageDailySpend,
      Map<String, double> categoryDistribution,
      List<SpendingAnomaly> anomalies,
      TrendDirection trend,
      double topCategoryPercentage});
}

/// @nodoc
class _$SpendingProfileCopyWithImpl<$Res, $Val extends SpendingProfile>
    implements $SpendingProfileCopyWith<$Res> {
  _$SpendingProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monthlyBurnRate = null,
    Object? averageDailySpend = null,
    Object? categoryDistribution = null,
    Object? anomalies = null,
    Object? trend = null,
    Object? topCategoryPercentage = null,
  }) {
    return _then(_value.copyWith(
      monthlyBurnRate: null == monthlyBurnRate
          ? _value.monthlyBurnRate
          : monthlyBurnRate // ignore: cast_nullable_to_non_nullable
              as double,
      averageDailySpend: null == averageDailySpend
          ? _value.averageDailySpend
          : averageDailySpend // ignore: cast_nullable_to_non_nullable
              as double,
      categoryDistribution: null == categoryDistribution
          ? _value.categoryDistribution
          : categoryDistribution // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      anomalies: null == anomalies
          ? _value.anomalies
          : anomalies // ignore: cast_nullable_to_non_nullable
              as List<SpendingAnomaly>,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as TrendDirection,
      topCategoryPercentage: null == topCategoryPercentage
          ? _value.topCategoryPercentage
          : topCategoryPercentage // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpendingProfileImplCopyWith<$Res>
    implements $SpendingProfileCopyWith<$Res> {
  factory _$$SpendingProfileImplCopyWith(_$SpendingProfileImpl value,
          $Res Function(_$SpendingProfileImpl) then) =
      __$$SpendingProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double monthlyBurnRate,
      double averageDailySpend,
      Map<String, double> categoryDistribution,
      List<SpendingAnomaly> anomalies,
      TrendDirection trend,
      double topCategoryPercentage});
}

/// @nodoc
class __$$SpendingProfileImplCopyWithImpl<$Res>
    extends _$SpendingProfileCopyWithImpl<$Res, _$SpendingProfileImpl>
    implements _$$SpendingProfileImplCopyWith<$Res> {
  __$$SpendingProfileImplCopyWithImpl(
      _$SpendingProfileImpl _value, $Res Function(_$SpendingProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monthlyBurnRate = null,
    Object? averageDailySpend = null,
    Object? categoryDistribution = null,
    Object? anomalies = null,
    Object? trend = null,
    Object? topCategoryPercentage = null,
  }) {
    return _then(_$SpendingProfileImpl(
      monthlyBurnRate: null == monthlyBurnRate
          ? _value.monthlyBurnRate
          : monthlyBurnRate // ignore: cast_nullable_to_non_nullable
              as double,
      averageDailySpend: null == averageDailySpend
          ? _value.averageDailySpend
          : averageDailySpend // ignore: cast_nullable_to_non_nullable
              as double,
      categoryDistribution: null == categoryDistribution
          ? _value._categoryDistribution
          : categoryDistribution // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      anomalies: null == anomalies
          ? _value._anomalies
          : anomalies // ignore: cast_nullable_to_non_nullable
              as List<SpendingAnomaly>,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as TrendDirection,
      topCategoryPercentage: null == topCategoryPercentage
          ? _value.topCategoryPercentage
          : topCategoryPercentage // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$SpendingProfileImpl implements _SpendingProfile {
  const _$SpendingProfileImpl(
      {required this.monthlyBurnRate,
      required this.averageDailySpend,
      required final Map<String, double> categoryDistribution,
      required final List<SpendingAnomaly> anomalies,
      required this.trend,
      required this.topCategoryPercentage})
      : _categoryDistribution = categoryDistribution,
        _anomalies = anomalies;

  @override
  final double monthlyBurnRate;
  @override
  final double averageDailySpend;
  final Map<String, double> _categoryDistribution;
  @override
  Map<String, double> get categoryDistribution {
    if (_categoryDistribution is EqualUnmodifiableMapView)
      return _categoryDistribution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categoryDistribution);
  }

  final List<SpendingAnomaly> _anomalies;
  @override
  List<SpendingAnomaly> get anomalies {
    if (_anomalies is EqualUnmodifiableListView) return _anomalies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_anomalies);
  }

  @override
  final TrendDirection trend;
  @override
  final double topCategoryPercentage;

  @override
  String toString() {
    return 'SpendingProfile(monthlyBurnRate: $monthlyBurnRate, averageDailySpend: $averageDailySpend, categoryDistribution: $categoryDistribution, anomalies: $anomalies, trend: $trend, topCategoryPercentage: $topCategoryPercentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpendingProfileImpl &&
            (identical(other.monthlyBurnRate, monthlyBurnRate) ||
                other.monthlyBurnRate == monthlyBurnRate) &&
            (identical(other.averageDailySpend, averageDailySpend) ||
                other.averageDailySpend == averageDailySpend) &&
            const DeepCollectionEquality()
                .equals(other._categoryDistribution, _categoryDistribution) &&
            const DeepCollectionEquality()
                .equals(other._anomalies, _anomalies) &&
            (identical(other.trend, trend) || other.trend == trend) &&
            (identical(other.topCategoryPercentage, topCategoryPercentage) ||
                other.topCategoryPercentage == topCategoryPercentage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      monthlyBurnRate,
      averageDailySpend,
      const DeepCollectionEquality().hash(_categoryDistribution),
      const DeepCollectionEquality().hash(_anomalies),
      trend,
      topCategoryPercentage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SpendingProfileImplCopyWith<_$SpendingProfileImpl> get copyWith =>
      __$$SpendingProfileImplCopyWithImpl<_$SpendingProfileImpl>(
          this, _$identity);
}

abstract class _SpendingProfile implements SpendingProfile {
  const factory _SpendingProfile(
      {required final double monthlyBurnRate,
      required final double averageDailySpend,
      required final Map<String, double> categoryDistribution,
      required final List<SpendingAnomaly> anomalies,
      required final TrendDirection trend,
      required final double topCategoryPercentage}) = _$SpendingProfileImpl;

  @override
  double get monthlyBurnRate;
  @override
  double get averageDailySpend;
  @override
  Map<String, double> get categoryDistribution;
  @override
  List<SpendingAnomaly> get anomalies;
  @override
  TrendDirection get trend;
  @override
  double get topCategoryPercentage;
  @override
  @JsonKey(ignore: true)
  _$$SpendingProfileImplCopyWith<_$SpendingProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SpendingAnomaly {
  Transaction get transaction => throw _privateConstructorUsedError;
  AnomalySeverity get severity => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  double get deviationPercentage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SpendingAnomalyCopyWith<SpendingAnomaly> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpendingAnomalyCopyWith<$Res> {
  factory $SpendingAnomalyCopyWith(
          SpendingAnomaly value, $Res Function(SpendingAnomaly) then) =
      _$SpendingAnomalyCopyWithImpl<$Res, SpendingAnomaly>;
  @useResult
  $Res call(
      {Transaction transaction,
      AnomalySeverity severity,
      String reason,
      double deviationPercentage});

  $TransactionCopyWith<$Res> get transaction;
}

/// @nodoc
class _$SpendingAnomalyCopyWithImpl<$Res, $Val extends SpendingAnomaly>
    implements $SpendingAnomalyCopyWith<$Res> {
  _$SpendingAnomalyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transaction = null,
    Object? severity = null,
    Object? reason = null,
    Object? deviationPercentage = null,
  }) {
    return _then(_value.copyWith(
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as Transaction,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as AnomalySeverity,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      deviationPercentage: null == deviationPercentage
          ? _value.deviationPercentage
          : deviationPercentage // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TransactionCopyWith<$Res> get transaction {
    return $TransactionCopyWith<$Res>(_value.transaction, (value) {
      return _then(_value.copyWith(transaction: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SpendingAnomalyImplCopyWith<$Res>
    implements $SpendingAnomalyCopyWith<$Res> {
  factory _$$SpendingAnomalyImplCopyWith(_$SpendingAnomalyImpl value,
          $Res Function(_$SpendingAnomalyImpl) then) =
      __$$SpendingAnomalyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Transaction transaction,
      AnomalySeverity severity,
      String reason,
      double deviationPercentage});

  @override
  $TransactionCopyWith<$Res> get transaction;
}

/// @nodoc
class __$$SpendingAnomalyImplCopyWithImpl<$Res>
    extends _$SpendingAnomalyCopyWithImpl<$Res, _$SpendingAnomalyImpl>
    implements _$$SpendingAnomalyImplCopyWith<$Res> {
  __$$SpendingAnomalyImplCopyWithImpl(
      _$SpendingAnomalyImpl _value, $Res Function(_$SpendingAnomalyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transaction = null,
    Object? severity = null,
    Object? reason = null,
    Object? deviationPercentage = null,
  }) {
    return _then(_$SpendingAnomalyImpl(
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as Transaction,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as AnomalySeverity,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      deviationPercentage: null == deviationPercentage
          ? _value.deviationPercentage
          : deviationPercentage // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$SpendingAnomalyImpl implements _SpendingAnomaly {
  const _$SpendingAnomalyImpl(
      {required this.transaction,
      required this.severity,
      required this.reason,
      required this.deviationPercentage});

  @override
  final Transaction transaction;
  @override
  final AnomalySeverity severity;
  @override
  final String reason;
  @override
  final double deviationPercentage;

  @override
  String toString() {
    return 'SpendingAnomaly(transaction: $transaction, severity: $severity, reason: $reason, deviationPercentage: $deviationPercentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpendingAnomalyImpl &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.deviationPercentage, deviationPercentage) ||
                other.deviationPercentage == deviationPercentage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, transaction, severity, reason, deviationPercentage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SpendingAnomalyImplCopyWith<_$SpendingAnomalyImpl> get copyWith =>
      __$$SpendingAnomalyImplCopyWithImpl<_$SpendingAnomalyImpl>(
          this, _$identity);
}

abstract class _SpendingAnomaly implements SpendingAnomaly {
  const factory _SpendingAnomaly(
      {required final Transaction transaction,
      required final AnomalySeverity severity,
      required final String reason,
      required final double deviationPercentage}) = _$SpendingAnomalyImpl;

  @override
  Transaction get transaction;
  @override
  AnomalySeverity get severity;
  @override
  String get reason;
  @override
  double get deviationPercentage;
  @override
  @JsonKey(ignore: true)
  _$$SpendingAnomalyImplCopyWith<_$SpendingAnomalyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
