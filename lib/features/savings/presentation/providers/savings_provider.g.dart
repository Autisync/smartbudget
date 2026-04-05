// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$savingsGoalRepositoryHash() =>
    r'a9f6a9b6928d673587a9d3b3d8ca1bcd0f10ce2e';

/// See also [savingsGoalRepository].
@ProviderFor(savingsGoalRepository)
final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>.internal(
  savingsGoalRepository,
  name: r'savingsGoalRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$savingsGoalRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SavingsGoalRepositoryRef = ProviderRef<SavingsGoalRepository>;
String _$savingsGoalListHash() => r'12acc3d7af2987f16a799a85f375110cc7a0b46c';

/// See also [SavingsGoalList].
@ProviderFor(SavingsGoalList)
final savingsGoalListProvider = AutoDisposeAsyncNotifierProvider<
    SavingsGoalList, List<SavingsGoal>>.internal(
  SavingsGoalList.new,
  name: r'savingsGoalListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$savingsGoalListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SavingsGoalList = AutoDisposeAsyncNotifier<List<SavingsGoal>>;
String _$savingsNudgesHash() => r'0fa6ae9e701e746ce460da241c3a2c5254af5a42';

/// See also [SavingsNudges].
@ProviderFor(SavingsNudges)
final savingsNudgesProvider =
    AsyncNotifierProvider<SavingsNudges, List<SavingsNudge>>.internal(
  SavingsNudges.new,
  name: r'savingsNudgesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$savingsNudgesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SavingsNudges = AsyncNotifier<List<SavingsNudge>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
