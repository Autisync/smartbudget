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
String _$savingsGoalListHash() => r'3752efd5564510d34ab3e2578ba472d8d1208748';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
