// ═══════════════════════════════════════════════════════════════
// SpendingMilestonesResponse.dart  — v1.7.0 (محدث لدعم الـ Locked Tiers)
// ═══════════════════════════════════════════════════════════════

class SpendingMilestonesResponse {
  final CustomerWallet customerWallet;
  final TierInfo currentTier;
  final TierInfo? nextTier;
  final List<TierInfo> allTiers;
  final TierReward? unlockedReward;
  final AnnualCycle annualCycle;
  final bool tierUpgraded;
  final String? upgradedToTierName;
  final bool isVipMax;
  // ✅ الحقل الجديد لاستقبال المستويات المقفولة من السيرفر
  final List<LockedTier> lockedTiers;

  const SpendingMilestonesResponse({
    required this.customerWallet,
    required this.currentTier,
    this.nextTier,
    required this.allTiers,
    this.unlockedReward,
    required this.annualCycle,
    required this.tierUpgraded,
    this.upgradedToTierName,
    required this.isVipMax,
    required this.lockedTiers, // ✅ مطلوب في الـ Constructor
  });

  factory SpendingMilestonesResponse.fromJson(Map<String, dynamic> json) {
    // ── Annual Cycle ─────────────────────────────────────────────
    final int year = (json['year'] as num?)?.toInt() ?? DateTime.now().year;
    final annualCycle = AnnualCycle(
      cycleStartDate: DateTime.tryParse(json['cycle_start'] as String? ?? '') ??
          DateTime(year, 1, 1),
      cycleEndDate: DateTime.tryParse(json['cycle_end'] as String? ?? '') ??
          DateTime(year, 12, 31),
      daysRemaining: DateTime(year, 12, 31).difference(DateTime.now()).inDays.clamp(0, 365),
      cycleYear: year,
    );

    // ── Customer Wallet ──────────────────────────────────────────
    final customerWallet = CustomerWallet(
      totalSpent: _toDouble(json['total_spent_this_year']),
      progressWithinTier: (_toDouble(json['progress_percent']) / 100).clamp(0.0, 1.0),
      amountToNextTier: json['amount_to_next_tier'] != null
          ? _toDouble(json['amount_to_next_tier'])
          : null,
    );

    // ── Current Tier ─────────────────────────────────────────────
    final currentTierJson = json['current_tier'] as Map<String, dynamic>? ?? {};
    final currentTier = TierInfo.fromJson(currentTierJson, isCurrentTier: true);

    // ── Next Tier ────────────────────────────────────────────────
    final TierInfo? nextTier = json['next_tier'] != null
        ? TierInfo.fromJson(json['next_tier'] as Map<String, dynamic>)
        : null;

    // ── Current Tier Reward ──────────────────────────────────────
    final TierReward? unlockedReward = json['current_tier_reward'] != null
        ? TierReward.fromJson(json['current_tier_reward'] as Map<String, dynamic>)
        : null;

    return SpendingMilestonesResponse(
      customerWallet: customerWallet,
      currentTier: currentTier,
      nextTier: nextTier,
      allTiers: const [],
      unlockedReward: unlockedReward,
      annualCycle: annualCycle,
      tierUpgraded: json['tier_upgraded'] as bool? ?? false,
      upgradedToTierName: null,
      isVipMax: json['is_vip_max'] as bool? ?? false,
      // ✅ قراءة وتوليد قائمة الـ Locked Tiers بأمان
      lockedTiers: (json['locked_tiers'] as List<dynamic>? ?? [])
          .map((e) => LockedTier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'year': annualCycle.cycleYear,
    'cycle_start': annualCycle.cycleStartDate.toIso8601String(),
    'cycle_end': annualCycle.cycleEndDate.toIso8601String(),
    'total_spent_this_year': customerWallet.totalSpent,
    'progress_percent': customerWallet.progressWithinTier,
    'amount_to_next_tier': customerWallet.amountToNextTier,
    'current_tier': currentTier.toJson(),
    'next_tier': nextTier?.toJson(),
    'current_tier_reward': unlockedReward?.toJson(),
    'tier_upgraded': tierUpgraded,
    'is_vip_max': isVipMax,
    'locked_tiers': lockedTiers.map((t) => t.toJson()).toList(), // ✅ تحويل إلى JSON
  };
}

// ── ✅ الكلاس الجديد الخاص بالمستويات المقفولة والمحمي من أخطاء الـ Type Cast ──
class LockedTier {
  final String key;
  final String name;
  final double minAmount;
  final String rewardTitle;
  final String? colorHex;

  const LockedTier({
    required this.key,
    required this.name,
    required this.minAmount,
    required this.rewardTitle,
    this.colorHex,
  });

  factory LockedTier.fromJson(Map<String, dynamic> json) => LockedTier(
    key: json['key'] as String? ?? '',
    name: json['name'] as String? ?? '',
    minAmount: _toDouble(json['min_amount']), // حماية تامة للرقم
    rewardTitle: json['reward_title'] as String? ?? '',
    colorHex: json['color_hex'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'min_amount': minAmount,
    'reward_title': rewardTitle,
    'color_hex': colorHex,
  };
}

// ───────────────────────────────────────────────
class CustomerWallet {
  final double totalSpent;
  final double progressWithinTier;
  final double? amountToNextTier;

  const CustomerWallet({
    required this.totalSpent,
    required this.progressWithinTier,
    this.amountToNextTier,
  });

  Map<String, dynamic> toJson() => {
    'total_spent': totalSpent,
    'progress_within_tier': progressWithinTier,
    'amount_to_next_tier': amountToNextTier,
  };
}

// ───────────────────────────────────────────────
class TierInfo {
  final String tierId;
  final String tierName;
  final int tierOrder;
  final double minSpend;
  final double? maxSpend;
  final String motivationalText;
  final bool isCurrentTier;
  final bool isCompleted;
  final String? colorHex;

  const TierInfo({
    required this.tierId,
    required this.tierName,
    required this.tierOrder,
    required this.minSpend,
    this.maxSpend,
    required this.motivationalText,
    required this.isCurrentTier,
    required this.isCompleted,
    this.colorHex,
  });

  bool get isMaxTier => maxSpend == null || maxSpend == 0;
  bool get isLocked => !isCurrentTier && !isCompleted;

  factory TierInfo.fromJson(
      Map<String, dynamic> json, {
        bool isCurrentTier = false,
        bool isCompleted = false,
        int tierOrder = 0,
      }) {
    return TierInfo(
      tierId: json['key'] as String? ?? json['tier_id'] as String? ?? '',
      tierName: json['name'] as String? ?? json['tier_name'] as String? ?? '',
      tierOrder: (json['tier_order'] as num?)?.toInt() ?? tierOrder,
      minSpend: _toDouble(json['min_amount']),
      maxSpend: json['max_amount'] != null ? _toDouble(json['max_amount']) : null,
      motivationalText: json['motivational_text'] as String? ?? '',
      isCurrentTier: json['is_current_tier'] as bool? ?? isCurrentTier,
      isCompleted: json['is_completed'] as bool? ?? isCompleted,
      colorHex: json['color_hex'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': tierId,
    'name': tierName,
    'min_amount': minSpend,
    'max_amount': maxSpend,
    'color_hex': colorHex,
  };
}

// ───────────────────────────────────────────────
class TierReward {
  final int rewardId;
  final String rewardTitle;
  final String rewardDescription;
  final String rewardType;
  final double rewardValue;
  final bool isUsed;

  const TierReward({
    required this.rewardId,
    required this.rewardTitle,
    required this.rewardDescription,
    required this.rewardType,
    required this.rewardValue,
    required this.isUsed,
  });

  factory TierReward.fromJson(Map<String, dynamic> json) {
    return TierReward(
      rewardId: (json['reward_id'] as num?)?.toInt() ?? 0,
      rewardTitle: json['reward_title'] as String? ?? '',
      rewardDescription: json['reward_description'] as String? ?? '',
      rewardType: json['reward_type'] as String? ?? '',
      rewardValue: _toDouble(json['reward_value']),
      isUsed: json['is_used'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'reward_id': rewardId,
    'reward_title': rewardTitle,
    'reward_description': rewardDescription,
    'reward_type': rewardType,
    'reward_value': rewardValue,
    'is_used': isUsed,
  };
}

// ───────────────────────────────────────────────
class AnnualCycle {
  final DateTime cycleStartDate;
  final DateTime cycleEndDate;
  final int daysRemaining;
  final int cycleYear;

  const AnnualCycle({
    required this.cycleStartDate,
    required this.cycleEndDate,
    required this.daysRemaining,
    required this.cycleYear,
  });

  String get displayRange => '1 يناير – 31 ديسمبر $cycleYear';

  Map<String, dynamic> toJson() => {
    'cycle_start_date': cycleStartDate.toIso8601String(),
    'cycle_end_date': cycleEndDate.toIso8601String(),
    'days_remaining': daysRemaining,
    'cycle_year': cycleYear,
  };
}

// ───────────────────────────────────────────────
class SpendingHistoryItem {
  final int orderId;
  final double amount;
  final DateTime completedAt;

  const SpendingHistoryItem({
    required this.orderId,
    required this.amount,
    required this.completedAt,
  });

  factory SpendingHistoryItem.fromJson(Map<String, dynamic> json) {
    return SpendingHistoryItem(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      amount: _toDouble(json['amount']),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'amount': amount,
    'completed_at': completedAt.toIso8601String(),
  };
}

// ── الدالة المساعدة لحماية فك الـ JSON من تقلبات السيرفر ──
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}