// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionRepositoryHash() =>
    r'f5626bbbbae28adf6e9cbeae85d97dc082d42250';

/// See also [transactionRepository].
@ProviderFor(transactionRepository)
final transactionRepositoryProvider = Provider<TransactionRepository>.internal(
  transactionRepository,
  name: r'transactionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionRepositoryRef = ProviderRef<TransactionRepository>;
String _$recentTransactionsHash() =>
    r'51375331e007bb47be5c6aca5900922006c25527';

/// See also [recentTransactions].
@ProviderFor(recentTransactions)
final recentTransactionsProvider =
    AutoDisposeFutureProvider<List<Transaction>>.internal(
  recentTransactions,
  name: r'recentTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentTransactionsRef = AutoDisposeFutureProviderRef<List<Transaction>>;
String _$spendingProfileHash() => r'102fb9416b5d6e1a9c761aa152ce5d6c902a060c';

/// See also [spendingProfile].
@ProviderFor(spendingProfile)
final spendingProfileProvider =
    AutoDisposeFutureProvider<SpendingProfile>.internal(
  spendingProfile,
  name: r'spendingProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spendingProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SpendingProfileRef = AutoDisposeFutureProviderRef<SpendingProfile>;
String _$burnRateInsightHash() => r'7ed95f89e915fa2bc5da02d0dc481994513e712f';

/// See also [burnRateInsight].
@ProviderFor(burnRateInsight)
final burnRateInsightProvider =
    AutoDisposeFutureProvider<BurnRateInsight>.internal(
  burnRateInsight,
  name: r'burnRateInsightProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$burnRateInsightHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BurnRateInsightRef = AutoDisposeFutureProviderRef<BurnRateInsight>;
String _$transactionDecisionSnapshotHash() =>
    r'075e9cd7d0268ddb49c9dd2421710a3944f1bfc7';

/// See also [transactionDecisionSnapshot].
@ProviderFor(transactionDecisionSnapshot)
final transactionDecisionSnapshotProvider =
    AutoDisposeFutureProvider<TransactionDecisionSnapshotData>.internal(
  transactionDecisionSnapshot,
  name: r'transactionDecisionSnapshotProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionDecisionSnapshotHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionDecisionSnapshotRef
    = AutoDisposeFutureProviderRef<TransactionDecisionSnapshotData>;
String _$cashflowPredictionHash() =>
    r'a05b1af74d7c3f347456101954f2e1c0e82d41f8';

/// See also [cashflowPrediction].
@ProviderFor(cashflowPrediction)
final cashflowPredictionProvider =
    AutoDisposeFutureProvider<CashflowPrediction>.internal(
  cashflowPrediction,
  name: r'cashflowPredictionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cashflowPredictionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CashflowPredictionRef
    = AutoDisposeFutureProviderRef<CashflowPrediction>;
String _$recurringTransactionsHash() =>
    r'21c3732074a6632a63c656d78ebf27563ae2ad1e';

/// See also [recurringTransactions].
@ProviderFor(recurringTransactions)
final recurringTransactionsProvider = AutoDisposeFutureProvider<void>.internal(
  recurringTransactions,
  name: r'recurringTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recurringTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecurringTransactionsRef = AutoDisposeFutureProviderRef<void>;
String _$transactionListHash() => r'ae453c29c758f083dca028e16c68edc62a9918f6';

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

abstract class _$TransactionList
    extends BuildlessAutoDisposeAsyncNotifier<List<Transaction>> {
  late final DateTime? startDate;
  late final DateTime? endDate;
  late final String? category;

  FutureOr<List<Transaction>> build({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  });
}

/// See also [TransactionList].
@ProviderFor(TransactionList)
const transactionListProvider = TransactionListFamily();

/// See also [TransactionList].
class TransactionListFamily extends Family<AsyncValue<List<Transaction>>> {
  /// See also [TransactionList].
  const TransactionListFamily();

  /// See also [TransactionList].
  TransactionListProvider call({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) {
    return TransactionListProvider(
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  @override
  TransactionListProvider getProviderOverride(
    covariant TransactionListProvider provider,
  ) {
    return call(
      startDate: provider.startDate,
      endDate: provider.endDate,
      category: provider.category,
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
  String? get name => r'transactionListProvider';
}

/// See also [TransactionList].
class TransactionListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    TransactionList, List<Transaction>> {
  /// See also [TransactionList].
  TransactionListProvider({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) : this._internal(
          () => TransactionList()
            ..startDate = startDate
            ..endDate = endDate
            ..category = category,
          from: transactionListProvider,
          name: r'transactionListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$transactionListHash,
          dependencies: TransactionListFamily._dependencies,
          allTransitiveDependencies:
              TransactionListFamily._allTransitiveDependencies,
          startDate: startDate,
          endDate: endDate,
          category: category,
        );

  TransactionListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
    required this.category,
  }) : super.internal();

  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;

  @override
  FutureOr<List<Transaction>> runNotifierBuild(
    covariant TransactionList notifier,
  ) {
    return notifier.build(
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  @override
  Override overrideWith(TransactionList Function() create) {
    return ProviderOverride(
      origin: this,
      override: TransactionListProvider._internal(
        () => create()
          ..startDate = startDate
          ..endDate = endDate
          ..category = category,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TransactionList, List<Transaction>>
      createElement() {
    return _TransactionListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionListProvider &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TransactionListRef
    on AutoDisposeAsyncNotifierProviderRef<List<Transaction>> {
  /// The parameter `startDate` of this provider.
  DateTime? get startDate;

  /// The parameter `endDate` of this provider.
  DateTime? get endDate;

  /// The parameter `category` of this provider.
  String? get category;
}

class _TransactionListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TransactionList,
        List<Transaction>> with TransactionListRef {
  _TransactionListProviderElement(super.provider);

  @override
  DateTime? get startDate => (origin as TransactionListProvider).startDate;
  @override
  DateTime? get endDate => (origin as TransactionListProvider).endDate;
  @override
  String? get category => (origin as TransactionListProvider).category;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
