import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart'; // 👈 استيراد المكتبة الحالية في مشروعك
import '../../utils/AppColors.dart';
import '../../utils/AppImages.dart';

/// ─────────────────────────────────────────────────────────────
/// SupportNotificationGroup — كبسولة (جرس الإشعارات | واتساب)
/// ─────────────────────────────────────────────────────────────
class SupportNotificationGroup extends StatelessWidget {
  final VoidCallback? onChatTap;
  final VoidCallback? onNotificationTap;
  final bool hasNotification;

  const SupportNotificationGroup({
    Key? key,
    this.onChatTap,
    this.onNotificationTap,
    this.hasNotification = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: kBrandPrimary.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── الجرس (يظهر جهة اليمين في تصميم الـ RTL) ──────────
          Semantics(
            label: 'الإشعارات',
            button: true,
            child: InkWell(
              onTap: onNotificationTap,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(50),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: kBrandPrimary,
                      size: 23, // حجم متناسق ومطابق للتصميم
                    ),
                    if (hasNotification)
                      PositionedDirectional(
                        top: -1,
                        end: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: kBrandSecondary, // النقطة الصفراء/البرتقالية للإشعارات
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── الخط الفاصل العمودي الوسطي ──────────────────────────
          Container(
            width: 1,
            height: 20,
            color: kBrandPrimary.withValues(alpha: 0.18),
          ),

          // ── أيقونة الواتساب المفرغة (تظهر جهة اليسار) ──────────
          Semantics(
            label: 'تواصل عبر واتساب',
            button: true,
            child: InkWell(
              onTap: onChatTap,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(50),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                // ✅ استخدام الأيقونة الرسمية المفرغة مباشرة من مكتبتك الحالية بدون أي خلفيات دائرية مشوهة
                child: Icon(
                  FontAwesome.whatsapp,
                  color: kBrandPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// FloatingAppBar — شريط التطبيق العلوي العائم
/// ─────────────────────────────────────────────────────────────
class FloatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onNotificationTap;
  final bool hasNotification;
  final bool showAccentLine;
  final bool isScrolled;

  const FloatingAppBar({
    Key? key,
    required this.title,
    this.onSearchTap,
    this.onChatTap,
    this.onNotificationTap,
    this.hasNotification = false,
    this.showAccentLine = true,
    this.isScrolled = false,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(110);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: kBrandPrimary.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // كبسولة الإشعارات والواتساب المحدثة
                    SupportNotificationGroup(
                      onChatTap: onChatTap,
                      onNotificationTap: onNotificationTap,
                      hasNotification: hasNotification,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: boldTextStyle(size: 22, color: kBrandPrimary),
                      ),
                    ),
                    // زر البحث الدائري على اليمين
                    Semantics(
                      label: 'بحث',
                      button: true,
                      child: GestureDetector(
                        onTap: onSearchTap,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kBrandBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: kBrandPrimary.withValues(alpha: 0.10),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: kBrandPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showAccentLine) ...[
                const SizedBox(height: 10),
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: kAccentLineGradient,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}