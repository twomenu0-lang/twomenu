// lib/screen/tier_details_screen.dart
// شاشة تفاصيل المستويات — تُفتح بالضغط على شريط التقدم
// محدّثة بالكامل: تبني خريطة مستويات حقيقية بدمج المستويات المقفولة، التالية، الحالية، والمُنجزة

import 'package:flutter/material.dart';
import '../models/SpendingMilestonesResponse.dart';
import '../main.dart';
import '../component/TierProgressCard.dart'; // ✅ جديد: استخدام الكارت المشترك الموحد

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
  static const Color _surface = Color(0xFFF7F9FB);
  static const Color _onSurface = Color(0xFF191C1E);
  static const Color _onSurfaceVariant = Color(0xFF464650);
  static const Color _statusNeutral = Color(0xFF64748B);

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
        child: CircularProgressIndicator(color: Color(0xFF4b41e1)),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4b41e1)),
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
      color: const Color(0xFF4b41e1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. بطاقة المستوى المشتركة والموحدة ────────────
            TierProgressCard(
              wallet: wallet,
              barProgress: spendingStore.barProgress,
              barAnimation: _barAnimation,
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
            // الترتيب: مقفولة (الأعلى رتبة فوق) ← التالي ← الحالي ← المُنجزة (الأقرب للحالي فالأقدم)
            Builder(builder: (_) {
              final allForMap = <_MapTierItem>[
                // أولاً: المستويات المقفولة (ترتيب عكسي — الأعلى فوق)
                ...wallet.lockedTiers.reversed.map((t) => _MapTierItem(
                  key: t.key,
                  name: t.name,
                  minAmount: t.minAmount,
                  maxAmount: null,
                  colorHex: t.colorHex,
                  status: _TierStatus.locked,
                  rewardTitle: t.rewardTitle,
                )),
                // ثانياً: المستوى التالي إن وُجد
                if (wallet.nextTier != null) _MapTierItem(
                  key: wallet.nextTier!.tierId,
                  name: wallet.nextTier!.tierName,
                  minAmount: wallet.nextTier!.minSpend,
                  maxAmount: wallet.nextTier!.maxSpend,
                  colorHex: wallet.nextTier!.colorHex,
                  status: _TierStatus.locked,
                  rewardTitle: wallet.nextTier!.motivationalText,
                ),
                // ثالثاً: المستوى الحالي
                _MapTierItem(
                  key: wallet.currentTier.tierId,
                  name: wallet.currentTier.tierName,
                  minAmount: wallet.currentTier.minSpend,
                  maxAmount: wallet.currentTier.maxSpend,
                  colorHex: wallet.currentTier.colorHex,
                  status: _TierStatus.current,
                  rewardTitle: wallet.unlockedReward?.rewardTitle ?? wallet.currentTier.motivationalText,
                ),
                // رابعاً: المستويات المُنجزة فعلاً (الأقرب للحالي أولاً، ثم الأقدم في الأسفل)
                ...wallet.completedTiers.reversed.map((t) => _MapTierItem(
                  key: t.key,
                  name: t.name,
                  minAmount: t.minAmount,
                  maxAmount: null,
                  colorHex: t.colorHex,
                  status: _TierStatus.completed,
                  rewardTitle: t.rewardTitle,
                )),
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
                    status: t.status,
                    rewardTitle: t.rewardTitle,
                    formatAmount: formatTierAmount, // ✅ استخدام الدالة العامة والموحدة لتنسيق المبالغ
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

// حالة المستوى في الخريطة — مقفول / حالي / مُنجز
enum _TierStatus { locked, current, completed }

// ── بطاقة مستوى محدثة — تدعم 3 حالات: مقفول / حالي / مُنجز ──
class _TierRoadmapCard extends StatelessWidget {
  final String tierKey;
  final String tierName;
  final double minAmount;
  final double? maxAmount;
  final String? colorHex;
  final _TierStatus status;
  final String rewardTitle;
  final String Function(double) formatAmount;

  const _TierRoadmapCard({
    super.key,
    required this.tierKey,
    required this.tierName,
    required this.minAmount,
    this.maxAmount,
    this.colorHex,
    required this.status,
    required this.rewardTitle,
    required this.formatAmount,
  });

  bool get _isLocked => status == _TierStatus.locked;
  bool get _isCurrent => status == _TierStatus.current;
  bool get _isCompleted => status == _TierStatus.completed;

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
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          // المُنجز يفضل واضح تمامًا (مش باهت زي المقفول) بس بهدوء لوني في التفاصيل
          opacity: _isLocked ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // المستوى المُنجز ياخد خلفية رمادي فاتح هادي بدل الأبيض النشط
              color: _isCompleted ? const Color(0xFFF5F5F7) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isCurrent
                    ? const Color(0xFF4b41e1)
                    : const Color(0xFFC7C5D2).withValues(alpha: 0.30),
                width: _isCurrent ? 1.5 : 1,
              ),
              boxShadow: _isCurrent
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
                              fontWeight: _isCurrent ? FontWeight.w700 : FontWeight.w400,
                              // المُنجز بلون نص أهدى شوية عن الحالي
                              color: _isCompleted
                                  ? const Color(0xFF464650)
                                  : const Color(0xFF191C1E),
                            ),
                          ),
                          if (_isCurrent) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFF59E0B),
                              size: 16,
                            ),
                          ],
                          // علامة "تم الإنجاز" الخضراء للمستويات المُنجزة فعلاً
                          if (_isCompleted) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF22C55E),
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

                // للمُنجز: بادچ "تم الإنجاز" هادي بدل عرض المكافأة كـ CTA
                if (_isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'تم الإنجاز',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: 11,
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                // عرض الهدية أو النص التحفيزي المتاح بشكل أنيق (للحالي/المقفول)
                else if (rewardTitle.isNotEmpty)
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

        // طبقة الحجب الذكية فوق المستويات التي لم يتم فتحها بعد (Locked Tiers فقط)
        if (_isLocked)
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

// ── الكلاس المساعد لتجميع وهيكلة بيانات الخريطة بيسر ──
class _MapTierItem {
  final String key;
  final String name;
  final String rewardTitle;
  final double minAmount;
  final double? maxAmount;
  final String? colorHex;
  final _TierStatus status;

  const _MapTierItem({
    required this.key,
    required this.name,
    required this.minAmount,
    this.maxAmount,
    this.colorHex,
    required this.status,
    required this.rewardTitle,
  });
}