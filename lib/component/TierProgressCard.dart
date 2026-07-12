import 'package:flutter/material.dart';
import '../models/SpendingMilestonesResponse.dart';

// ✅ دوال مشتركة للتدرجات اللونية ولون النص وتنسيق المبالغ الخاصة
// بنظام المستويات — تُستخدم في TierDetailsScreen و ProfileScreen معاً
// لضمان عدم وجود أي اختلاف بين الشاشتين.

LinearGradient gradientForTier(String tierId) {
  switch (tierId.toLowerCase()) {
    case 'diamond':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0FFFF), Color(0xFF00CED1)],
      );
    case 'gold':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
      );
    case 'silver':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC0C0C0), Color(0xFF71706E)],
      );
    default:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCD7F32), Color(0xFFA0522D)],
      );
  }
}

Color textColorForTier(String tierId) {
  switch (tierId.toLowerCase()) {
    case 'diamond':
      return const Color(0xFF003333);
    default:
      return Colors.white;
  }
}

String formatTierAmount(double amount) {
  final int val = amount.toInt();
  final String formatted = val.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );
  return '$formatted ج.م';
}

/// ✅ بطاقة المستوى الموحّدة (Hero Card).
/// نفس الشكل بالحرف الواحد في شاشة تفاصيل المستويات وشاشة الحساب الشخصي.
class TierProgressCard extends StatelessWidget {
  final SpendingMilestonesResponse wallet;
  final double barProgress;
  final Animation<double> barAnimation;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const TierProgressCard({
    super.key,
    required this.wallet,
    required this.barProgress,
    required this.barAnimation,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = wallet.currentTier;
    final isMax = wallet.nextTier == null;
    final gradient = gradientForTier(current.tierId);
    final textColor = textColorForTier(current.tierId);

    final card = Container(
      margin: margin,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإنفاق السنوي: ${formatTierAmount(wallet.customerWallet.totalSpent)}',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (!isMax && wallet.customerWallet.amountToNextTier != null)
                    Text(
                      'باقي ${formatTierAmount(wallet.customerWallet.amountToNextTier!)} للـ${wallet.nextTier?.tierName ?? ""}',
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

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}