// lib/store/SpendingStore/spending_store.dart

import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart'; // ✅ بدل print
import '../../models/SpendingMilestonesResponse.dart';
import '../../network/rest_apis.dart';

part 'spending_store.g.dart';

class SpendingStore = SpendingStoreBase with _$SpendingStore;

abstract class SpendingStoreBase with Store {

  @observable
  SpendingMilestonesResponse? wallet;

  @observable
  bool isLoadingWallet = false;

  @observable
  String? error;

  @computed
  double get barProgress =>
      wallet?.customerWallet.progressWithinTier ?? 0.0;

  @computed
  bool get isMaxTier => wallet?.nextTier == null;

  @computed
  double get amountToNextTier => wallet?.customerWallet.amountToNextTier ?? 0.0;

  @computed
  bool get hasPendingUpgrade => wallet?.tierUpgraded ?? false;

  @action
  Future<void> fetchWallet() async {
    isLoadingWallet = true;
    error = null;
    Map<String, dynamic>? data;

    try {
      data = await getSpendingWallet() as Map<String, dynamic>;
      wallet = SpendingMilestonesResponse.fromJson(data);
      log('✅ wallet: tier=${wallet?.currentTier.tierName} | progress=${wallet?.customerWallet.progressWithinTier} | spent=${wallet?.customerWallet.totalSpent}');
    } catch (e) {
      log('❌ wallet error: $e');
      log('❌ data was: $data');
      error = e.toString();
    } finally {
      isLoadingWallet = false;
    }
  }

  @action
  Future<void> clearUpgradeFlag() async {
    if (wallet == null) return;

    // ✅ tierId هو الاسم الصح في TierInfo
    final tierKey = wallet!.currentTier.tierId;

    // Optimistic update — تحديث محلي فوري للـ UI
    wallet = SpendingMilestonesResponse(
      customerWallet: wallet!.customerWallet,
      currentTier: wallet!.currentTier,
      nextTier: wallet!.nextTier,
      allTiers: wallet!.allTiers,
      unlockedReward: wallet!.unlockedReward,
      annualCycle: wallet!.annualCycle,
      tierUpgraded: false,
      upgradedToTierName: wallet!.upgradedToTierName,
      isVipMax: wallet!.isVipMax,
      lockedTiers: wallet!.lockedTiers,
    );

    try {
      await ackTierUpgrade(tierKey);
      log('✅ ackTierUpgrade: تم تأكيد رؤية الترقية للمستوى: $tierKey');
    } catch (e) {
      log('⚠️ ackTierUpgrade فشل: $e — الـ popup قد يظهر مجدداً في الجلسة القادمة');
    }
  }
}