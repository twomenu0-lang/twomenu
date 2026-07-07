import 'package:flutter/material.dart';

import '../models/Reward.dart';

/// دايلوج ترحيبي موحّد يظهر مرة واحدة بعد إنشاء الحساب مباشرة (من أي مسار:
/// فورم / هاتف / سوشيال) لو فيه مكافأة تسجيل متاحة.
///
/// ✅ تم نقله من SignUpScreen.dart كما هو بالظبط (نفس الستايل: خلفية بيضا،
/// radius 24، عنوان كحلي #030048، زرار بنفسجي #4b41e1) عشان يبقى مصدر واحد
/// نستخدمه من أي مسار تسجيل/دخول من غير تكرار كود.
///
/// الاستخدام:
/// ```dart
/// await RewardWelcomeDialog.show(context, reward);
/// ```
class RewardWelcomeDialog extends StatelessWidget {
  final Reward reward;

  const RewardWelcomeDialog({super.key, required this.reward});

  /// يفتح الدايلوج. بيرجع Future بتخلص لما المستخدم يدوس "يلا نبدأ".
  static Future<void> show(BuildContext context, Reward reward) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RewardWelcomeDialog(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFEDFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFF4b41e1),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎉 هدية ترحيب بانضمامك إلينا!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF030048),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              reward.rewardTitle.isNotEmpty
                  ? reward.rewardTitle
                  : 'حصلت على مكافأة جديدة في محفظتك',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'تقدر تستخدمها في أي وقت من محفظة المكافآت.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4b41e1),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                child: const Text(
                  'يلا نبدأ 🚀',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}