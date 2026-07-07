// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spending_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SpendingStore on SpendingStoreBase, Store {
  Computed<double>? _$barProgressComputed;

  @override
  double get barProgress =>
      (_$barProgressComputed ??= Computed<double>(() => super.barProgress,
              name: 'SpendingStoreBase.barProgress'))
          .value;
  Computed<bool>? _$isMaxTierComputed;

  @override
  bool get isMaxTier =>
      (_$isMaxTierComputed ??= Computed<bool>(() => super.isMaxTier,
              name: 'SpendingStoreBase.isMaxTier'))
          .value;
  Computed<double>? _$amountToNextTierComputed;

  @override
  double get amountToNextTier => (_$amountToNextTierComputed ??=
          Computed<double>(() => super.amountToNextTier,
              name: 'SpendingStoreBase.amountToNextTier'))
      .value;
  Computed<bool>? _$hasPendingUpgradeComputed;

  @override
  bool get hasPendingUpgrade => (_$hasPendingUpgradeComputed ??= Computed<bool>(
          () => super.hasPendingUpgrade,
          name: 'SpendingStoreBase.hasPendingUpgrade'))
      .value;

  late final _$walletAtom =
      Atom(name: 'SpendingStoreBase.wallet', context: context);

  @override
  SpendingMilestonesResponse? get wallet {
    _$walletAtom.reportRead();
    return super.wallet;
  }

  @override
  set wallet(SpendingMilestonesResponse? value) {
    _$walletAtom.reportWrite(value, super.wallet, () {
      super.wallet = value;
    });
  }

  late final _$isLoadingWalletAtom =
      Atom(name: 'SpendingStoreBase.isLoadingWallet', context: context);

  @override
  bool get isLoadingWallet {
    _$isLoadingWalletAtom.reportRead();
    return super.isLoadingWallet;
  }

  @override
  set isLoadingWallet(bool value) {
    _$isLoadingWalletAtom.reportWrite(value, super.isLoadingWallet, () {
      super.isLoadingWallet = value;
    });
  }

  late final _$errorAtom =
      Atom(name: 'SpendingStoreBase.error', context: context);

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$fetchWalletAsyncAction =
      AsyncAction('SpendingStoreBase.fetchWallet', context: context);

  @override
  Future<void> fetchWallet() {
    return _$fetchWalletAsyncAction.run(() => super.fetchWallet());
  }

  late final _$clearUpgradeFlagAsyncAction =
      AsyncAction('SpendingStoreBase.clearUpgradeFlag', context: context);

  @override
  Future<void> clearUpgradeFlag() {
    return _$clearUpgradeFlagAsyncAction.run(() => super.clearUpgradeFlag());
  }

  @override
  String toString() {
    return '''
wallet: ${wallet},
isLoadingWallet: ${isLoadingWallet},
error: ${error},
barProgress: ${barProgress},
isMaxTier: ${isMaxTier},
amountToNextTier: ${amountToNextTier},
hasPendingUpgrade: ${hasPendingUpgrade}
    ''';
  }
}
