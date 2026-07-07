// lib/screen/tier_details_screen.dart
// شاشة تفاصيل المستويات — تُفتح بالضغط على شريط التقدم
// محدّثة بالكامل: تبني خريطة مستويات حقيقية بدمج المستويات المقفولة، التالية، والحالية

import 'package:flutter/material.dart';
import '../models/SpendingMilestonesResponse.dart';
import '../main.dart';

class TierDetailsScreen extends StatefulWidget {
  const TierDetailsScreen({super.key});

  @override
  State<TierDetailsScreen> createState() => _TierDetailsScreenState();
}

class _TierDetailsScreenState extends State<TierDetailsScreen>
    with SingleTickerProviderStateMixin {
  // أنيميشن شريط التقدم
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  // ── Colors (من DESIGN.md) ────────────────────────
  static const Color _primary = Color(0xFF030048);
  static const Color _secondary = Color(0xFF4b41e1);
  static const Color _surface = Color(0xFFF7F9FB);
  static const Color _onSurface = Color(0xFF191C1E);
  static const Color _onSurfaceVariant = Color(0xFF464650);
  static const Color _statusNeutral = Color(0xFF64748B);

  // Tier Gradients الرئيسي للبطاقة العلوية
  static const LinearGradient _bronzeGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCD7F32), Color(0xFFA0522D)],
  );
  static const LinearGradient _silverGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC0C0C0), Color(0xFF71706E)],
  );
  static const LinearGradient _goldGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
  );
  static const LinearGradient _diamondGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0FFFF), Color(0xFF00CED1)],
  );

  // ── Init ────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnimation = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeInOut,
    );

    _fetchData();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  void _startBarAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barController.forward(from: 0);
    });
  }

  // ── جلب البيانات من spendingStore ────────────────
  Future<void> _fetchData() async {
    await spendingStore.fetchWallet();
    if (mounted) {
      _startBarAnimation();
      setState(() {});
    }
  }

  // ── Helper: Gradient بحسب tierId للبطاقة الـ Hero ──
  LinearGradient _gradientForTier(String tierId) {
    switch (tierId.toLowerCase()) {
      case 'diamond':
        return _diamondGrad;
      case 'gold':
        return _goldGrad;
      case 'silver':
        return _silverGrad;
      default:
        return _bronzeGrad;
    }
  }

  // ── Helper: لون النص فوق بطاقة المستوى ──────────
  Color _textColorForTier(String tierId) {
    switch (tierId.toLowerCase()) {
      case 'diamond':
        return const Color(0xFF003333);
      default:
        return Colors.white;
    }
  }

  // ── تنسيق المبالغ: 12,500 ج.م ───────────────────
  String _formatAmount(double amount) {
    final int val = amount.toInt();
    final String formatted = val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$formatted ج.م';
  }

  // ── Build ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'تفاصيل المستويات',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                color: _onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (spendingStore.isLoadingWallet) {
      return const Center(
        child: CircularProgressIndicator(color: _secondary),
      );
    }

    if (spendingStore.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: _statusNeutral),
            const SizedBox(height: 16),
            Text(spendingStore.error!,
                style: const TextStyle(color: _onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: _secondary),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (spendingStore.wallet == null) return const SizedBox.shrink();
    final wallet = spendingStore.wallet!;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: _secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. بطاقة المستوى الرئيسية ────────────
            _HeroTierCard(
              wallet: wallet,
              barProgress: spendingStore.barProgress,
              barAnimation: _barAnimation,
              gradient: _gradientForTier(wallet.currentTier.tierId),
              textColor: _textColorForTier(wallet.currentTier.tierId),
              formatAmount: _formatAmount,
            ),

            const SizedBox(height: 24),

            // ── 2. خريطة المستويات المحدثة ──────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'خريطة المستويات',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ بناء خريطة مدمجة وشاملة من الأعلى للأسفل ديناميكياً
            Builder(builder: (_) {
              final allForMap = <_MapTierItem>[
                // أولاً: المستويات المقفولة (ترتيب عكسي — الأعلى فوق)
                ...wallet.lockedTiers.reversed.map((t) => _MapTierItem(
                  key: t.key,
                  name: t.name,
                  minAmount: t.minAmount,
                  maxAmount: null,
                  colorHex: t.colorHex,
                  isCurrentTier: false,
                  isLocked: true,
                  rewardTitle: t.rewardTitle,
                )),
                // ثانياً: المستوى التالي إن وُجد
                if (wallet.nextTier != null) _MapTierItem(
                  key: wallet.nextTier!.tierId,
                  name: wallet.nextTier!.tierName,
                  minAmount: wallet.nextTier!.minSpend,
                  maxAmount: wallet.nextTier!.maxSpend,
                  colorHex: wallet.nextTier!.colorHex,
                  isCurrentTier: false,
                  isLocked: false,
                  rewardTitle: wallet.nextTier!.motivationalText,
                ),
                // ثالثاً: المستوى الحالي في الأسفل
                _MapTierItem(
                  key: wallet.currentTier.tierId,
                  name: wallet.currentTier.tierName,
                  minAmount: wallet.currentTier.minSpend,
                  maxAmount: wallet.currentTier.maxSpend,
                  colorHex: wallet.currentTier.colorHex,
                  isCurrentTier: true,
                  isLocked: false,
                  rewardTitle: wallet.unlockedReward?.rewardTitle ?? wallet.currentTier.motivationalText,
                ),
              ];

              return Column(
                children: allForMap.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _TierRoadmapCard(
                    key: ValueKey(t.key),
                    tierKey: t.key,
                    tierName: t.name,
                    minAmount: t.minAmount,
                    maxAmount: t.maxAmount,
                    colorHex: t.colorHex,
                    isCurrentTier: t.isCurrentTier,
                    isLocked: t.isLocked,
                    rewardTitle: t.rewardTitle,
                    formatAmount: _formatAmount,
                  ),
                )).toList(),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-Widgets
// ═══════════════════════════════════════════════════════════════

// ── بطاقة المستوى Hero ──────────────────────────────────────────
class _HeroTierCard extends StatelessWidget {
  final SpendingMilestonesResponse wallet;
  final double barProgress;
  final Animation<double> barAnimation;
  final LinearGradient gradient;
  final Color textColor;
  final String Function(double) formatAmount;

  const _HeroTierCard({
    required this.wallet,
    required this.barProgress,
    required this.barAnimation,
    required this.gradient,
    required this.textColor,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final current = wallet.currentTier;
    final isMax = wallet.nextTier == null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -24,
            left: -24,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: اسم المستوى ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    current.tierName,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (isMax || wallet.isVipMax)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        'VIP',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // ── شريط التقدم والمعلومات المالية المعدلة ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإنفاق السنوي: ${formatAmount(wallet.customerWallet.totalSpent)}',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (!isMax && wallet.customerWallet.amountToNextTier != null)
                    Text(
                      'باقي ${formatAmount(wallet.customerWallet.amountToNextTier!)} للـ${wallet.nextTier?.tierName ?? ""}',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // الشريط المتحرك للتقدم الحالي
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: AnimatedBuilder(
                  animation: barAnimation,
                  builder: (_, __) {
                    final target = isMax ? 1.0 : barProgress;
                    return LinearProgressIndicator(
                      value: barAnimation.value * target,
                      minHeight: 8,
                      backgroundColor: Colors.black.withValues(alpha: 0.20),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ✅ بطاقة مستوى محدثة لتعمل مع الـ Fields الجديدة بحرية وتكامل ──
class _TierRoadmapCard extends StatelessWidget {
  final String tierKey;
  final String tierName;
  final double minAmount;
  final double? maxAmount;
  final String? colorHex;
  final bool isCurrentTier;
  final bool isLocked;
  final String rewardTitle;
  final String Function(double) formatAmount;

  const _TierRoadmapCard({
    super.key,
    required this.tierKey,
    required this.tierName,
    required this.minAmount,
    this.maxAmount,
    this.colorHex,
    required this.isCurrentTier,
    required this.isLocked,
    required this.rewardTitle,
    required this.formatAmount,
  });

  // تحديد الـ Gradient الجانبي بناءً على الـ key الفريد للمستوى
  LinearGradient _gradientForKey(String key) {
    switch (key.toLowerCase()) {
      case 'diamond':
        return const LinearGradient(colors: [Color(0xFFE0FFFF), Color(0xFF00CED1)]);
      case 'gold':
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]);
      case 'silver':
        return const LinearGradient(colors: [Color(0xFFC0C0C0), Color(0xFF71706E)]);
      default:
        return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFA0522D)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = isCurrentTier;

    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isLocked ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF4b41e1)
                    : const Color(0xFFC7C5D2).withValues(alpha: 0.30),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
                  : [],
            ),
            child: Row(
              children: [
                // الشريط الملوّن الجانبي المعبر عن رتبة المستوى ديناميكياً
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _gradientForKey(tierKey),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // اسم المستوى + نطاق الإنفاق المالي الخاص به
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'المستوى $tierName',
                            style: TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                              color: const Color(0xFF191C1E),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFF59E0B),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (maxAmount == null || maxAmount == 0)
                            ? '${formatAmount(minAmount)} وأكثر'
                            : '${formatAmount(minAmount)} ← ${formatAmount(maxAmount!)}',
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: 12,
                          color: Color(0xFF464650),
                        ),
                      ),
                    ],
                  ),
                ),

                // عرض الهدية أو النص التحفيزي المتاح بشكل أنيق
                if (rewardTitle.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4b41e1).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rewardTitle,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: 11,
                        color: Color(0xFF4b41e1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // طبقة الحجب الذكية فوق المستويات التي لم يتم فتحها بعد (Locked Tiers)
        if (isLocked)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: Colors.white.withValues(alpha: 0.55),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'مغلق',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── ✅ الكلاس المساعد لتجميع وهيكلة بيانات الخريطة بيسر ──
class _MapTierItem {
  final String key;
  final String name;
  final String rewardTitle;
  final double minAmount;
  final double? maxAmount;
  final String? colorHex;
  final bool isCurrentTier;
  final bool isLocked;

  const _MapTierItem({
    required this.key,
    required this.name,
    required this.minAmount,
    this.maxAmount,
    this.colorHex,
    required this.isCurrentTier,
    required this.isLocked,
    required this.rewardTitle,
  });
}