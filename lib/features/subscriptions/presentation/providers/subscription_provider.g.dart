// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dueSubscriptionsHash() => r'b3a7c8a43bea54531c450c94d0f803733a26e635';

/// See also [dueSubscriptions].
@ProviderFor(dueSubscriptions)
final dueSubscriptionsProvider =
    AutoDisposeFutureProvider<List<Subscription>>.internal(
  dueSubscriptions,
  name: r'dueSubscriptionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dueSubscriptionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DueSubscriptionsRef = AutoDisposeFutureProviderRef<List<Subscription>>;
String _$subscriptionHash() => r'53e9d2998e461c9fefcd32d605621acb546d873e';

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

/// See also [subscription].
@ProviderFor(subscription)
const subscriptionProvider = SubscriptionFamily();

/// See also [subscription].
class SubscriptionFamily extends Family<AsyncValue<Subscription?>> {
  /// See also [subscription].
  const SubscriptionFamily();

  /// See also [subscription].
  SubscriptionProvider call(
    String id,
  ) {
    return SubscriptionProvider(
      id,
    );
  }

  @override
  SubscriptionProvider getProviderOverride(
    covariant SubscriptionProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'subscriptionProvider';
}

/// See also [subscription].
class SubscriptionProvider extends AutoDisposeFutureProvider<Subscription?> {
  /// See also [subscription].
  SubscriptionProvider(
    String id,
  ) : this._internal(
          (ref) => subscription(
            ref as SubscriptionRef,
            id,
          ),
          from: subscriptionProvider,
          name: r'subscriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionHash,
          dependencies: SubscriptionFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionFamily._allTransitiveDependencies,
          id: id,
        );

  SubscriptionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Subscription?> Function(SubscriptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionProvider._internal(
        (ref) => create(ref as SubscriptionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Subscription?> createElement() {
    return _SubscriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubscriptionRef on AutoDisposeFutureProviderRef<Subscription?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _SubscriptionProviderElement
    extends AutoDisposeFutureProviderElement<Subscription?>
    with SubscriptionRef {
  _SubscriptionProviderElement(super.provider);

  @override
  String get id => (origin as SubscriptionProvider).id;
}

String _$subscriptionListHash() => r'89402b13bdec14778e37c8af2ad69488005f2584';

/// See also [SubscriptionList].
@ProviderFor(SubscriptionList)
final subscriptionListProvider = AutoDisposeAsyncNotifierProvider<
    SubscriptionList, List<Subscription>>.internal(
  SubscriptionList.new,
  name: r'subscriptionListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionList = AutoDisposeAsyncNotifier<List<Subscription>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package




