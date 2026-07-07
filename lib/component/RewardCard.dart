// lib/component/RewardCard.dart
// كارت المكافأة الفردي — يعرض تفاصيل العرض ويفتح شاشة التفاصيل مباشرة بدون تكرار نوافذ التأكيد

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/Reward.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onUse;

  const RewardCard({
    super.key,
    required this.reward,
    required this.onUse,
  });

  // ── نص الـ Badge (نسبة أو قيمة) ──
  String get _badgeText {
    if (reward.rewardType == 'percentage') {
      return '${reward.rewardValue.toInt()}%';
    } else if (reward.rewardType == 'fixed_amount') {
      return '${reward.rewardValue.toInt()} ج.م';
    } else if (reward.rewardType == 'free_drink' ||
        reward.rewardType == 'free_product') {
      return 'مجاني';
    }
    return reward.rewardTitle;
  }

  // ── نص تاريخ الانتهاء ──
  String get _expiryText {
    if (reward.isExpiringSoon) {
      final hours = reward.expiryDate.difference(DateTime.now()).inHours;
      if (hours < 1) {
        final mins = reward.expiryDate.difference(DateTime.now()).inMinutes;
        return 'تنتهي خلال $mins دقيقة';
      }
      return 'تنتهي خلال $hours ساعة';
    }
    return 'تنتهي في: ${DateFormat('dd/MM/yyyy').format(reward.expiryDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpiring = reward.isExpiringSoon;
    final theme           = Theme.of(context);
    final primaryColor    = theme.primaryColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── الكارت الرئيسي ──────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isExpiring
                ? Border.all(color: const Color(0xFFE53E3E), width: 1.5)
                : Border.all(
                color: const Color(0xFFE6E8EA).withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── صف: اللوجو + المعلومات ──────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // لوجو الشريك
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF2F4F6),
                        image: reward.logoUrl.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(reward.logoUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: reward.logoUrl.isEmpty
                          ? const Icon(Icons.store,
                          size: 26, color: Color(0xFF64748B))
                          : null,
                    ),
                    const SizedBox(width: 14),

                    // المعلومات
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم الشريك
                          Text(
                            reward.partnerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // عنوان المكافأة
                          Text(
                            reward.rewardTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF464650),
                            ),
                          ),
                          const SizedBox(height: 7),

                          // تاريخ الانتهاء
                          Row(
                            children: [
                              Icon(
                                isExpiring
                                    ? Icons.alarm_rounded
                                    : Icons.calendar_today_rounded,
                                size: 13,
                                color: isExpiring
                                    ? const Color(0xFFE53E3E)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _expiryText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpiring
                                      ? const Color(0xFFE53E3E)
                                      : const Color(0xFF64748B),
                                  fontWeight: isExpiring
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),

                          // نص مرة واحدة فقط
                          if (reward.maxUsesPerUser == 1) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'صالحة للاستخدام مرة واحدة فقط',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),

                const SizedBox(height: 14),

                // ── زر استخدم المكافأة ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // ✅ تم التعديل لينطلق مباشرة إلى شاشة تفاصيل المكافأة ويمنع الـ Dialog المكرر
                    onPressed: onUse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'استخدم المكافأة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Badge الخصم — في الكورنر الأيسر العلوي (RTL) ──
        Positioned(
          top: 4,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}