// lib/screen/rewards_wallet_screen.dart
// محفظة المكافآت — يعرض المكافآت والتقدم الحالي للمستويات
// محدّث: تم نقل منطق الاختيار والتطبيق بالكامل هنا وإلغاء شاشة التفاصيل القديمة تماماً

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import '../models/Reward.dart';
import '../component/RewardCard.dart';
import '../../main.dart';
import '../models/SpendingMilestonesResponse.dart';
import 'RedemptionScreen.dart'; // شاشة العداد والكود للفرع
import 'MyCartScreen.dart';       // ✅ تم إضافة شاشة السلة للاستخدام داخل التطبيق
import 'TierDetailsScreen.dart';

class RewardsWalletScreen extends StatefulWidget {
  const RewardsWalletScreen({super.key});

  @override
  State<RewardsWalletScreen> createState() => _RewardsWalletScreenState();
}

class _RewardsWalletScreenState extends State<RewardsWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // ✅ الحل الجذري للـ Race Condition: ننتظر السيرفر حتى تكتمل البيانات تماماً
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      rewardsStore.fetchRewards();

      await spendingStore.fetchWallet(); // إجبار الكود على انتظار البيانات هنا

      // نتحقق الآن بأمان تام وفي الوقت المناسب
      if (mounted && spendingStore.hasPendingUpgrade) {
        _showLevelUpDialog();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLevelUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: Lottie.asset(
                'assets/animations/level_up.json',
                repeat: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '🎉 تهانينا المتميزة!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF030048),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لقد تمت ترقيتك بنجاح إلى مستوى\n[ ${spendingStore.wallet!.currentTier.tierName} ]',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تنتظرك الآن مكافآت ومميزات حصرية جديدة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // بيتنادى هنا لتحديث الـ UI فجائياً وإبلاغ السيرفر في الخلفية
              spendingStore.clearUpgradeFlag();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4b41e1),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99)),
            ),
            child: const Text(
              'استكشاف المميزات 🚀',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── ✅ 1. المايسترو الموجه للمسارات بناءً على مكان الصرف المتاح ────────────
  // 🆕 دايماً بيفتح الـ Bottom Sheet ويسيب الاختيار الظاهر يوضح المتاح من الغير متاح،
  // إلا لو قناة واحدة بس متاحة، وقتها نختصر الخطوة ونروح عليها على طول.
  void _handleUse(Reward reward) {
    final canBranch = reward.supportsBranchRedemption;
    final canApp = reward.supportsInAppRedemption;

    if (canBranch && canApp) {
      _showRedemptionChoiceSheet(reward);
    } else if (canApp) {
      _confirmInApp(reward);
    } else if (canBranch) {
      _confirmRedeem(reward);
    } else {
      // حالة استثنائية: مفيش قناة صرف مفعّلة خالص لهذه المكافأة
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذه المكافأة غير متاحة للاستخدام حالياً'),
          backgroundColor: Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── ✅ 2. الـ Bottom Sheet لاختيار مكان الاستخدام (فرع أم تطبيق) ──────────
  // 🆕 بيظهر الخيارين دايمًا؛ أي خيار غير متاح لهذه المكافأة بالذات يظهر باهت
  // ومعطّل بدل ما يختفي، عشان يبقى واضح للعميل إنه مش اختياره الشخصي.
  void _showRedemptionChoiceSheet(Reward reward) {
    final canBranch = reward.supportsBranchRedemption;
    final canApp = reward.supportsInAppRedemption;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                'فين عاوز تستخدم المكافأة؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF030048),
                ),
              ),
              const SizedBox(height: 20),
              _ChoiceTile(
                icon: Icons.storefront_outlined,
                title: 'استخدام في الفرع',
                subtitle: canBranch
                    ? 'هيتولد لك كود تعرضه للكاشير'
                    : 'غير متاح لهذه المكافأة',
                enabled: canBranch,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmRedeem(reward);
                },
              ),
              const SizedBox(height: 12),
              _ChoiceTile(
                icon: Icons.shopping_bag_outlined,
                title: 'استخدام في طلب التطبيق',
                subtitle: canApp
                    ? 'هيتطبق الخصم تلقائياً على طلبك الحالي'
                    : 'غير متاح لهذه المكافأة',
                enabled: canApp,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmInApp(reward);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ✅ 3. دايلوج تأكيد الكاشير (المسار الفعلي في الفرع) ───────────────────
  void _confirmRedeem(Reward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFC107),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'هل أنت أمام الكاشير الآن؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF030048),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لا يمكن التراجع بعد إنشاء الكود',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _generateAndOpenCode(reward);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF030048),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'تأكيد',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ✅ 4. توليد الكود والانتقال لشاشة العداد (RedemptionScreen) ──────────
  Future<void> _generateAndOpenCode(Reward reward) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4b41e1)),
      ),
    );

    try {
      await rewardsStore.generateCode(reward.rewardId);
    } finally {
      if (mounted) Navigator.pop(context);
    }

    if (!mounted) return;

    if (rewardsStore.activeCode != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RedemptionScreen(
            reward: reward,
            rewardCode: rewardsStore.activeCode!,
          ),
        ),
      );
      if (mounted) rewardsStore.fetchRewards();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rewardsStore.error ?? 'تعذّر إنشاء الكود'),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── ✅ 5. دايلوج تأكيد تطبيق الخصم مباشرة داخل السلة بالتطبيق ──────────────
  void _confirmInApp(Reward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'استخدام في طلب التطبيق',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هيتم تطبيق الخصم تلقائياً على طلبك الحالي في السلة.\n'
              'تقدر تكمّل التسوق وتستخدمه وقت ما تحب.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _applyInApp(reward);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تطبيق الخصم'),
          ),
        ],
      ),
    );
  }

  // ── ✅ 6. استدعاء السيرفر لحقن الكوبون والتوجه لشاشة السلة MyCartScreen ──────
  Future<void> _applyInApp(Reward reward) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4b41e1)),
      ),
    );

    bool success = false;
    try {
      success = await rewardsStore.applyToCart(reward);
    } catch (_) {
      success = false;
    } finally {
      if (mounted) Navigator.pop(context); // إغلاق اللودينج دائماً
    }

    if (!mounted) return;

    if (success && rewardsStore.appliedCoupon != null) {
      final coupon = rewardsStore.appliedCoupon!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 تم تطبيق ${coupon.discountLabel} من ${coupon.partnerName} على السلة',
          ),
          backgroundColor: const Color(0xFF38A169),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MyCartScreen(isShowBack: true)),
      );
      if (mounted) rewardsStore.fetchRewards();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rewardsStore.error ?? 'تعذّر تطبيق الخصم'),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        appBar: AppBar(
          title: const Text(
            'محفظة المكافآت',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            // ── Tier Hero Card ────────────────────────────────────────
            Observer(
              builder: (_) {
                if (spendingStore.isLoadingWallet &&
                    spendingStore.wallet == null) {
                  return const _TierBarSkeleton();
                }
                if (spendingStore.wallet != null) {
                  return _TierProgressBar(
                    wallet: spendingStore.wallet!,
                    progress: spendingStore.barProgress,
                  );
                }
                return _TierBarPlaceholder(
                  onRetry: spendingStore.fetchWallet,
                );
              },
            ),

            // ── Tabs ──────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                  labelPadding: EdgeInsets.zero,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: 'متاحة'),
                    Tab(text: 'تنتهي قريباً'),
                    Tab(text: 'مستخدمة'),
                    Tab(text: 'منتهية'),
                  ],
                ),
              ),
            ),

            // ── Rewards List ─────────────────────────────────────────
            Expanded(
              child: Observer(
                builder: (_) {
                  if (rewardsStore.isLoading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF4b41e1)));
                  }

                  if (rewardsStore.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_rounded,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              rewardsStore.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: rewardsStore.fetchRewards,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // ✅ تم التعديل لتوجيه الضغط للمايسترو الذكي _handleUse
                      _RewardsList(
                        rewards: rewardsStore.availableRewards,
                        emptyMessage: 'لا توجد مكافآت متاحة حالياً',
                        emptyIcon: Icons.card_giftcard_outlined,
                        onUse: (r) => _handleUse(r),   // ⬅️ بدون context
                      ),
                      _RewardsList(
                        rewards: rewardsStore.expiringSoonRewards,
                        emptyMessage: 'لا توجد مكافآت تنتهي قريباً',
                        emptyIcon: Icons.alarm_off_outlined,
                        onUse: (r) => _handleUse(r),   // ⬅️ بدون context
                      ),
                      _RedeemedExpiredList(
                        rewards: rewardsStore.usedRewards,
                        emptyMessage: 'لم تقم باستخدام أي مكافأة بعد',
                        emptyIcon: Icons.check_circle_outline,
                        isRedeemed: true,
                      ),
                      _RedeemedExpiredList(
                        rewards: rewardsStore.expiredRewards,
                        emptyMessage: 'لا توجد مكافآت منتهية الصلاحية',
                        emptyIcon: Icons.hourglass_empty,
                        isRedeemed: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Tier Hero Card
// ══════════════════════════════════════════════════════════════════════
class _TierProgressBar extends StatefulWidget {
  final SpendingMilestonesResponse wallet;
  final double progress;

  const _TierProgressBar({required this.wallet, required this.progress});

  @override
  State<_TierProgressBar> createState() => _TierProgressBarState();
}

class _TierProgressBarState extends State<_TierProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  static const _tierGradients = {
    'برونزي': [Color(0xFFCD7F32), Color(0xFFA0522D)],
    'فضي':   [Color(0xFFB8BEC7), Color(0xFF71706E)],
    'ذهبي':  [Color(0xFFFFD700), Color(0xFFB8860B)],
    'ماسي':  [Color(0xFF00CED1), Color(0xFF005F73)],
    'Bronze':  [Color(0xFFCD7F32), Color(0xFFA0522D)],
    'Silver':  [Color(0xFFB8BEC7), Color(0xFF71706E)],
    'Gold':    [Color(0xFFFFD700), Color(0xFFB8860B)],
    'Diamond': [Color(0xFF00CED1), Color(0xFF005F73)],
  };

  static const _tierIcons = {
    'برونزي': Icons.workspace_premium,
    'فضي':   Icons.workspace_premium,
    'ذهبي':  Icons.workspace_premium,
    'ماسي':  Icons.diamond_outlined,
    'Bronze':  Icons.workspace_premium,
    'Silver':  Icons.workspace_premium,
    'Gold':    Icons.workspace_premium,
    'Diamond': Icons.diamond_outlined,
  };

  List<Color> get _colors {
    final name = widget.wallet.currentTier.tierName;
    for (final key in _tierGradients.keys) {
      if (name.contains(key)) return _tierGradients[key]!;
    }
    return [const Color(0xFFFFD700), const Color(0xFFB8860B)];
  }

  IconData get _icon {
    final name = widget.wallet.currentTier.tierName;
    for (final key in _tierIcons.keys) {
      if (name.contains(key)) return _tierIcons[key]!;
    }
    return Icons.workspace_premium;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _TierProgressBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: old.progress, end: widget.progress)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors     = _colors;
    final icon       = _icon;
    final tierName   = widget.wallet.currentTier.tierName;
    final nextTier   = widget.wallet.nextTier;
    final isMaxTier  = nextTier == null;
    final totalSpent = widget.wallet.customerWallet.totalSpent;
    final amountLeft = widget.wallet.customerWallet.amountToNextTier;
    final cycle      = widget.wallet.annualCycle;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TierDetailsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors[0], colors[1]],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: -10,
              left: -10,
              child: Icon(
                icon,
                size: 110,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المستوى الحالي',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tierName,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'دورتك الحالية: ${cycle.displayRange}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإنفاق السنوي: ${totalSpent.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isMaxTier && amountLeft != null)
                        Text(
                          'باقي ${amountLeft.toStringAsFixed(0)} ج.م للـ${nextTier.tierName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (isMaxTier)
                        Text(
                          '✦ أعلى مستوى',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) {
                      final clamped = _anim.value.clamp(0.0, 1.0);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          height: 8,
                          color: Colors.black.withValues(alpha: 0.20),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: clamped,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── السكيليتون والبليدر ──
class _TierBarSkeleton extends StatefulWidget {
  const _TierBarSkeleton();

  @override
  State<_TierBarSkeleton> createState() => _TierBarSkeletonState();
}

class _TierBarSkeletonState extends State<_TierBarSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 60,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  )),
              const SizedBox(height: 6),
              Container(
                  width: 100,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  )),
              const Spacer(),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierBarPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  const _TierBarPlaceholder({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EA)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Text(
              'تعذّر تحميل بيانات المستوى — اضغط للمحاولة',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsList extends StatelessWidget {
  final List<Reward> rewards;
  final String emptyMessage;
  final IconData emptyIcon;
  final void Function(Reward) onUse;

  const _RewardsList({
    required this.rewards,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return _EmptyState(message: emptyMessage, icon: emptyIcon);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rewards.length,
      itemBuilder: (_, i) => RewardCard(
        reward: rewards[i],
        onUse: () => onUse(rewards[i]),
      ),
    );
  }
}

class _RedeemedExpiredList extends StatelessWidget {
  final List<Reward> rewards;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isRedeemed;

  const _RedeemedExpiredList({
    required this.rewards,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.isRedeemed,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return _EmptyState(message: emptyMessage, icon: emptyIcon);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rewards.length,
      itemBuilder: (_, i) => _SimpleRewardCard(
        reward: rewards[i],
        isRedeemed: isRedeemed,
      ),
    );
  }
}

class _SimpleRewardCard extends StatelessWidget {
  final Reward reward;
  final bool isRedeemed;

  const _SimpleRewardCard({required this.reward, required this.isRedeemed});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Opacity(
        opacity: 0.7,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF7F9FB),
                backgroundImage: NetworkImage(reward.logoUrl),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.partnerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF191C1E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward.rewardTitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF464650)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isRedeemed
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isRedeemed ? 'مستخدمة' : 'منتهية',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isRedeemed
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF5F6368),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── ✅ 7. الوجت المخصص لخيارات الـ Bottom Sheet ───────────────────────
// 🆕 بيدعم حالة enabled: لو false بيظهر باهت ومعطّل (بدون أي onTap فعلي)
class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final iconColor = enabled ? primaryColor : Colors.grey.shade400;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E8EA)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: enabled
                            ? const Color(0xFF191C1E)
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF64748B))
              else
                Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}