// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$budgetRepositoryHash() => r'722621f1902af26c697c5d67149a2725555543dc';

/// See also [budgetRepository].
@ProviderFor(budgetRepository)
final budgetRepositoryProvider = Provider<BudgetRepository>.internal(
  budgetRepository,
  name: r'budgetRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$budgetRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BudgetRepositoryRef = ProviderRef<BudgetRepository>;
String _$budgetSpendingHash() => r'fb47708ba44873b386e352010f0977ea54ad0d19';

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

/// See also [budgetSpending].
@ProviderFor(budgetSpending)
const budgetSpendingProvider = BudgetSpendingFamily();

/// See also [budgetSpending].
class BudgetSpendingFamily extends Family<AsyncValue<double>> {
  /// See also [budgetSpending].
  const BudgetSpendingFamily();

  /// See also [budgetSpending].
  BudgetSpendingProvider call({
    required String category,
    required DateTime start,
    required DateTime end,
  }) {
    return BudgetSpendingProvider(
      category: category,
      start: start,
      end: end,
    );
  }

  @override
  BudgetSpendingProvider getProviderOverride(
    covariant BudgetSpendingProvider provider,
  ) {
    return call(
      category: provider.category,
      start: provider.start,
      end: provider.end,
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
  String? get name => r'budgetSpendingProvider';
}

/// See also [budgetSpending].
class BudgetSpendingProvider extends AutoDisposeFutureProvider<double> {
  /// See also [budgetSpending].
  BudgetSpendingProvider({
    required String category,
    required DateTime start,
    required DateTime end,
  }) : this._internal(
          (ref) => budgetSpending(
            ref as BudgetSpendingRef,
            category: category,
            start: start,
            end: end,
          ),
          from: budgetSpendingProvider,
          name: r'budgetSpendingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$budgetSpendingHash,
          dependencies: BudgetSpendingFamily._dependencies,
          allTransitiveDependencies:
              BudgetSpendingFamily._allTransitiveDependencies,
          category: category,
          start: start,
          end: end,
        );

  BudgetSpendingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
    required this.start,
    required this.end,
  }) : super.internal();

  final String category;
  final DateTime start;
  final DateTime end;

  @override
  Override overrideWith(
    FutureOr<double> Function(BudgetSpendingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BudgetSpendingProvider._internal(
        (ref) => create(ref as BudgetSpendingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
        start: start,
        end: end,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<double> createElement() {
    return _BudgetSpendingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetSpendingProvider &&
        other.category == category &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);
    hash = _SystemHash.combine(hash, start.hashCode);
    hash = _SystemHash.combine(hash, end.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BudgetSpendingRef on AutoDisposeFutureProviderRef<double> {
  /// The parameter `category` of this provider.
  String get category;

  /// The parameter `start` of this provider.
  DateTime get start;

  /// The parameter `end` of this provider.
  DateTime get end;
}

class _BudgetSpendingProviderElement
    extends AutoDisposeFutureProviderElement<double> with BudgetSpendingRef {
  _BudgetSpendingProviderElement(super.provider);

  @override
  String get category => (origin as BudgetSpendingProvider).category;
  @override
  DateTime get start => (origin as BudgetSpendingProvider).start;
  @override
  DateTime get end => (origin as BudgetSpendingProvider).end;
}

String _$budgetListHash() => r'b731ba27896d9b24f6cf2885e4e559e7830d7d15';

/// See also [BudgetList].
@ProviderFor(BudgetList)
final budgetListProvider =
    AutoDisposeAsyncNotifierProvider<BudgetList, List<Budget>>.internal(
  BudgetList.new,
  name: r'budgetListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$budgetListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BudgetList = AutoDisposeAsyncNotifier<List<Budget>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package




