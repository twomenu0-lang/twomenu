import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import '../../models/Reward.dart';
import '../../models/RewardCode.dart';
import '../../models/AppliedCoupon.dart';
import '../../network/rest_apis.dart';

part 'rewards_store.g.dart';

class RewardsStore = RewardsStoreBase with _$RewardsStore;

abstract class RewardsStoreBase with Store {

  @observable
  ObservableList<Reward> rewards = ObservableList<Reward>();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  RewardCode? activeCode;

  @observable
  bool isGeneratingCode = false;

  @observable
  bool isRenewing = false;

  // ✅ v1.7.4 — FCM redeem flag
  // بيتعمله true لما يوصل إشعار reward_redeemed من الكاشير
  // RedemptionScreen بيستمع عليه عبر reaction ويروح SuccessScreen تلقائياً
  @observable
  bool isRedeemed = false;

  @observable
  AppliedCoupon? appliedCoupon;

  @observable
  bool isApplyingToCart = false;

  // ─── COMPUTED ───────────────────────────────────────────────
  @computed
  List<Reward> get availableRewards =>
      rewards.where((r) => !r.isUsed && !r.isExpired).toList();

  @computed
  List<Reward> get expiringSoonRewards =>
      rewards.where((r) => r.isExpiringSoon && !r.isUsed).toList();

  @computed
  List<Reward> get usedRewards =>
      rewards.where((r) => r.isUsed).toList();

  @computed
  List<Reward> get expiredRewards =>
      rewards.where((r) => r.isExpired).toList();

  // ─── ACTIONS ────────────────────────────────────────────────
  @action
  Future<void> fetchRewards() async {
    isLoading = true;
    error = null;
    try {
      final response = await getRewards() as Map<String, dynamic>;
      final allRewards = <Reward>[];
      for (final key in ['available', 'expiring_soon', 'redeemed', 'expired']) {
        final list = response[key];
        if (list is List) {
          allRewards.addAll(
            list.map((e) => Reward.fromJson(e as Map<String, dynamic>)),
          );
        }
      }
      rewards
        ..clear()
        ..addAll(allRewards);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> generateCode(int rewardId) async {
    isGeneratingCode = true;
    error = null;
    try {
      final data = await generateRewardCode(rewardId) as Map<String, dynamic>;

      if (data['expires_at'] != null) {
        debugPrint('--- [GENERATE CODE DIAGNOSIS] ---');
        debugPrint('🕐 expires_at raw: ${data['expires_at']}');
        debugPrint('🕐 parsed local: ${DateTime.parse(data['expires_at'].toString()).toLocal()}');
        debugPrint('🕐 now: ${DateTime.now()}');
        debugPrint('---------------------------------');
      }

      activeCode = RewardCode.fromJson({
        ...data,
        'reward_id': rewardId,
        'renew_count': 0,
      });
    } catch (e) {
      error = e.toString();
    } finally {
      isGeneratingCode = false;
    }
  }

  @action
  Future<void> renewCode(int rewardId) async {
    isRenewing = true;
    error = null;
    try {
      final data = await renewRewardCode(rewardId) as Map<String, dynamic>;

      if (data['expires_at'] != null) {
        debugPrint('--- [RENEW CODE DIAGNOSIS] ---');
        debugPrint('🕐 expires_at raw: ${data['expires_at']}');
        debugPrint('🕐 parsed local: ${DateTime.parse(data['expires_at'].toString()).toLocal()}');
        debugPrint('🕐 now: ${DateTime.now()}');
        debugPrint('-------------------------------');
      }

      activeCode = RewardCode.fromJson({
        ...data,
        'reward_id': rewardId,
        'renew_count': (activeCode?.renewCount ?? 0) + 1,
      });
    } catch (e) {
      error = e.toString();
    } finally {
      isRenewing = false;
    }
  }

  @action
  Future<bool> redeem(String code, int rewardId) async {
    error = null;
    try {
      await redeemReward(code, rewardId);
      final index = rewards.indexWhere((r) => r.rewardId == rewardId);
      if (index != -1) {
        rewards[index] = rewards[index].copyWith(status: 'used');
      }
      activeCode = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  // ✅ v1.7.4 — بيتستدعى من main.dart لما يوصل إشعار reward_redeemed
  // بيحدّث status المكافأة في الـ list + بيرفع الـ flag عشان RedemptionScreen يستجيب
  @action
  void markRedeemed(int rewardId) {
    final index = rewards.indexWhere((r) => r.rewardId == rewardId);
    if (index != -1) {
      rewards[index] = rewards[index].copyWith(status: 'used');
    }
    activeCode = null;
    isRedeemed = true;
  }

  // ✅ بيتستدعى من RedemptionScreen بعد ما ينتقل لـ SuccessScreen لإعادة الضبط
  @action
  void clearRedeemedFlag() => isRedeemed = false;

  @action
  Future<bool> applyToCart(Reward reward) async {
    isApplyingToCart = true;
    error = null;
    appliedCoupon = null;
    try {
      final data = await applyRewardToCart(reward.rewardId) as Map<String, dynamic>;
      if (data['success'] != true) {
        error = data['message']?.toString() ?? 'تعذّر تطبيق الخصم';
        return false;
      }
      appliedCoupon = AppliedCoupon.fromJson(data);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isApplyingToCart = false;
    }
  }

  @action
  void clearActiveCode() => activeCode = null;

  @action
  void clearAppliedCoupon() => appliedCoupon = null;
}