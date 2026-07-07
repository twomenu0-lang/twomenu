// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewards_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$RewardsStore on RewardsStoreBase, Store {
  Computed<List<Reward>>? _$availableRewardsComputed;

  @override
  List<Reward> get availableRewards => (_$availableRewardsComputed ??=
          Computed<List<Reward>>(() => super.availableRewards,
              name: 'RewardsStoreBase.availableRewards'))
      .value;
  Computed<List<Reward>>? _$expiringSoonRewardsComputed;

  @override
  List<Reward> get expiringSoonRewards => (_$expiringSoonRewardsComputed ??=
          Computed<List<Reward>>(() => super.expiringSoonRewards,
              name: 'RewardsStoreBase.expiringSoonRewards'))
      .value;
  Computed<List<Reward>>? _$usedRewardsComputed;

  @override
  List<Reward> get usedRewards =>
      (_$usedRewardsComputed ??= Computed<List<Reward>>(() => super.usedRewards,
              name: 'RewardsStoreBase.usedRewards'))
          .value;
  Computed<List<Reward>>? _$expiredRewardsComputed;

  @override
  List<Reward> get expiredRewards => (_$expiredRewardsComputed ??=
          Computed<List<Reward>>(() => super.expiredRewards,
              name: 'RewardsStoreBase.expiredRewards'))
      .value;

  late final _$rewardsAtom =
      Atom(name: 'RewardsStoreBase.rewards', context: context);

  @override
  ObservableList<Reward> get rewards {
    _$rewardsAtom.reportRead();
    return super.rewards;
  }

  @override
  set rewards(ObservableList<Reward> value) {
    _$rewardsAtom.reportWrite(value, super.rewards, () {
      super.rewards = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'RewardsStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorAtom =
      Atom(name: 'RewardsStoreBase.error', context: context);

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

  late final _$activeCodeAtom =
      Atom(name: 'RewardsStoreBase.activeCode', context: context);

  @override
  RewardCode? get activeCode {
    _$activeCodeAtom.reportRead();
    return super.activeCode;
  }

  @override
  set activeCode(RewardCode? value) {
    _$activeCodeAtom.reportWrite(value, super.activeCode, () {
      super.activeCode = value;
    });
  }

  late final _$isGeneratingCodeAtom =
      Atom(name: 'RewardsStoreBase.isGeneratingCode', context: context);

  @override
  bool get isGeneratingCode {
    _$isGeneratingCodeAtom.reportRead();
    return super.isGeneratingCode;
  }

  @override
  set isGeneratingCode(bool value) {
    _$isGeneratingCodeAtom.reportWrite(value, super.isGeneratingCode, () {
      super.isGeneratingCode = value;
    });
  }

  late final _$isRenewingAtom =
      Atom(name: 'RewardsStoreBase.isRenewing', context: context);

  @override
  bool get isRenewing {
    _$isRenewingAtom.reportRead();
    return super.isRenewing;
  }

  @override
  set isRenewing(bool value) {
    _$isRenewingAtom.reportWrite(value, super.isRenewing, () {
      super.isRenewing = value;
    });
  }

  late final _$isRedeemedAtom =
      Atom(name: 'RewardsStoreBase.isRedeemed', context: context);

  @override
  bool get isRedeemed {
    _$isRedeemedAtom.reportRead();
    return super.isRedeemed;
  }

  @override
  set isRedeemed(bool value) {
    _$isRedeemedAtom.reportWrite(value, super.isRedeemed, () {
      super.isRedeemed = value;
    });
  }

  late final _$appliedCouponAtom =
      Atom(name: 'RewardsStoreBase.appliedCoupon', context: context);

  @override
  AppliedCoupon? get appliedCoupon {
    _$appliedCouponAtom.reportRead();
    return super.appliedCoupon;
  }

  @override
  set appliedCoupon(AppliedCoupon? value) {
    _$appliedCouponAtom.reportWrite(value, super.appliedCoupon, () {
      super.appliedCoupon = value;
    });
  }

  late final _$isApplyingToCartAtom =
      Atom(name: 'RewardsStoreBase.isApplyingToCart', context: context);

  @override
  bool get isApplyingToCart {
    _$isApplyingToCartAtom.reportRead();
    return super.isApplyingToCart;
  }

  @override
  set isApplyingToCart(bool value) {
    _$isApplyingToCartAtom.reportWrite(value, super.isApplyingToCart, () {
      super.isApplyingToCart = value;
    });
  }

  late final _$fetchRewardsAsyncAction =
      AsyncAction('RewardsStoreBase.fetchRewards', context: context);

  @override
  Future<void> fetchRewards() {
    return _$fetchRewardsAsyncAction.run(() => super.fetchRewards());
  }

  late final _$generateCodeAsyncAction =
      AsyncAction('RewardsStoreBase.generateCode', context: context);

  @override
  Future<void> generateCode(int rewardId) {
    return _$generateCodeAsyncAction.run(() => super.generateCode(rewardId));
  }

  late final _$renewCodeAsyncAction =
      AsyncAction('RewardsStoreBase.renewCode', context: context);

  @override
  Future<void> renewCode(int rewardId) {
    return _$renewCodeAsyncAction.run(() => super.renewCode(rewardId));
  }

  late final _$redeemAsyncAction =
      AsyncAction('RewardsStoreBase.redeem', context: context);

  @override
  Future<bool> redeem(String code, int rewardId) {
    return _$redeemAsyncAction.run(() => super.redeem(code, rewardId));
  }

  late final _$applyToCartAsyncAction =
      AsyncAction('RewardsStoreBase.applyToCart', context: context);

  @override
  Future<bool> applyToCart(Reward reward) {
    return _$applyToCartAsyncAction.run(() => super.applyToCart(reward));
  }

  late final _$RewardsStoreBaseActionController =
      ActionController(name: 'RewardsStoreBase', context: context);

  @override
  void markRedeemed(int rewardId) {
    final _$actionInfo = _$RewardsStoreBaseActionController.startAction(
        name: 'RewardsStoreBase.markRedeemed');
    try {
      return super.markRedeemed(rewardId);
    } finally {
      _$RewardsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearRedeemedFlag() {
    final _$actionInfo = _$RewardsStoreBaseActionController.startAction(
        name: 'RewardsStoreBase.clearRedeemedFlag');
    try {
      return super.clearRedeemedFlag();
    } finally {
      _$RewardsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearActiveCode() {
    final _$actionInfo = _$RewardsStoreBaseActionController.startAction(
        name: 'RewardsStoreBase.clearActiveCode');
    try {
      return super.clearActiveCode();
    } finally {
      _$RewardsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearAppliedCoupon() {
    final _$actionInfo = _$RewardsStoreBaseActionController.startAction(
        name: 'RewardsStoreBase.clearAppliedCoupon');
    try {
      return super.clearAppliedCoupon();
    } finally {
      _$RewardsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
rewards: ${rewards},
isLoading: ${isLoading},
error: ${error},
activeCode: ${activeCode},
isGeneratingCode: ${isGeneratingCode},
isRenewing: ${isRenewing},
isRedeemed: ${isRedeemed},
appliedCoupon: ${appliedCoupon},
isApplyingToCart: ${isApplyingToCart},
availableRewards: ${availableRewards},
expiringSoonRewards: ${expiringSoonRewards},
usedRewards: ${usedRewards},
expiredRewards: ${expiredRewards}
    ''';
  }
}
