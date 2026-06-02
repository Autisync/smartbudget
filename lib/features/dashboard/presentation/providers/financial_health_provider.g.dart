// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$financialHealthHash() => r'f5b3155b9d87cdff4f24ee9f5bd687a0b28e4b08';

/// See also [financialHealth].
@ProviderFor(financialHealth)
final financialHealthProvider =
    AutoDisposeFutureProvider<FinancialHealthSnapshot>.internal(
  financialHealth,
  name: r'financialHealthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$financialHealthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FinancialHealthRef
    = AutoDisposeFutureProviderRef<FinancialHealthSnapshot>;
String _$financialHealthHistoryHash() =>
    r'b4b03c2a5ee601a118b2ed2d6e66366e4c83394b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [financialHealthHistory].
@ProviderFor(financialHealthHistory)
const financialHealthHistoryProvider = FinancialHealthHistoryFamily();

/// See also [financialHealthHistory].
class FinancialHealthHistoryFamily
    extends Family<AsyncValue<FinancialHealthTrendSnapshot>> {
  /// See also [financialHealthHistory].
  const FinancialHealthHistoryFamily();

  /// See also [financialHealthHistory].
  FinancialHealthHistoryProvider call({
    int weeks = 8,
  }) {
    return FinancialHealthHistoryProvider(
      weeks: weeks,
    );
  }

  @override
  FinancialHealthHistoryProvider getProviderOverride(
    covariant FinancialHealthHistoryProvider provider,
  ) {
    return call(
      weeks: provider.weeks,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'financialHealthHistoryProvider';
}

/// See also [financialHealthHistory].
class FinancialHealthHistoryProvider
    extends AutoDisposeFutureProvider<FinancialHealthTrendSnapshot> {
  /// See also [financialHealthHistory].
  FinancialHealthHistoryProvider({
    int weeks = 8,
  }) : this._internal(
          (ref) => financialHealthHistory(
            ref as FinancialHealthHistoryRef,
            weeks: weeks,
          ),
          from: financialHealthHistoryProvider,
          name: r'financialHealthHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$financialHealthHistoryHash,
          dependencies: FinancialHealthHistoryFamily._dependencies,
          allTransitiveDependencies:
              FinancialHealthHistoryFamily._allTransitiveDependencies,
          weeks: weeks,
        );

  FinancialHealthHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.weeks,
  }) : super.internal();

  final int weeks;

  @override
  Override overrideWith(
    FutureOr<FinancialHealthTrendSnapshot> Function(
            FinancialHealthHistoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FinancialHealthHistoryProvider._internal(
        (ref) => create(ref as FinancialHealthHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        weeks: weeks,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FinancialHealthTrendSnapshot>
      createElement() {
    return _FinancialHealthHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FinancialHealthHistoryProvider && other.weeks == weeks;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, weeks.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FinancialHealthHistoryRef
    on AutoDisposeFutureProviderRef<FinancialHealthTrendSnapshot> {
  /// The parameter `weeks` of this provider.
  int get weeks;
}

class _FinancialHealthHistoryProviderElement
    extends AutoDisposeFutureProviderElement<FinancialHealthTrendSnapshot>
    with FinancialHealthHistoryRef {
  _FinancialHealthHistoryProviderElement(super.provider);

  @override
  int get weeks => (origin as FinancialHealthHistoryProvider).weeks;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
