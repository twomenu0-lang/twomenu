import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ تم إضافة استيراد خدمات النظام للاهتزاز
import 'package:nb_utils/nb_utils.dart';

import '../../utils/AppColors.dart';

/// ─────────────────────────────────────────────────────────────
/// FloatingHomeButton
/// ─────────────────────────────────────────────────────────────
/// زر الرئيسية العائم في منتصف شريط التنقل، يبرز فوق الشريط بحركة
/// scale عند التفعيل.
class FloatingHomeButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const FloatingHomeButton({
    Key? key,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'الصفحة الرئيسية',
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact(); // ✅ تم إضافة الـ Haptic Feedback هنا
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: kAnimDuration,
          curve: Curves.easeOutBack,
          scale: isActive ? 1.0 : 0.94,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kBrandPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: kBrandPrimary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: kAnimDuration,
              child: Icon(
                isActive ? Icons.home_rounded : Icons.home_outlined,
                key: ValueKey(isActive),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// FloatingBottomNavItem (data model)
/// ─────────────────────────────────────────────────────────────
class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// ─────────────────────────────────────────────────────────────
/// FloatingBottomNavigation
/// ─────────────────────────────────────────────────────────────
/// شريط تنقل عائم بحواف دائرية (radius 30) مع زر Home عائم بالمنتصف
/// أعلى الشريط. مبني ليتوافق مع appStore.index (0..4) حيث 0 = Home.
///
/// الترتيب من اليمين لليسار (مناسب لـ RTL): الفئات، السلة، [Home]، المفضلة، حساب
class FloatingBottomNavigation extends StatelessWidget {
  /// ✅ الارتفاع الكلي للشريط العائم (64 لارتفاع الشريط نفسه + 16 من الـ
  /// padding السفلي المضاف حول الـ SizedBox). يُستخدم في الشاشات الأخرى
  /// (مثل MyCartScreen) لحساب المسافة اللازمة فوق هذا الشريط حتى لا يتم
  /// تغطية أي عناصر (مثل زر "متابعة") خلفه.
  static const double totalHeight = 76.0 + 16.0; // = 92.0

  /// المؤشر الحالي (0 = Home, 1 = Categories, 2 = Cart, 3 = Favourites, 4 = Account)
  final int currentIndex;

  /// يستقبل المؤشر الجديد عند الضغط
  final ValueChanged<int> onTap;

  /// عدد عناصر السلة (لعرض الـ badge)
  final int cartCount;

  /// تسميات العناصر — افتراضياً بالعربي حسب التصميم
  final String categoriesLabel;
  final String cartLabel;
  final String favouritesLabel;
  final String accountLabel;

  const FloatingBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
    this.categoriesLabel = 'الفئات',
    this.cartLabel = 'السلة',
    this.favouritesLabel = 'المفضلة',
    this.accountLabel = 'حساب',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // ── الشريط العائم ─────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kBottomNavRadius),
                  boxShadow: kFloatingShadow(opacity: 0.10, blur: 24, offset: const Offset(0, 10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      item: FloatingNavItem(
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view_rounded,
                        label: categoriesLabel,
                      ),
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    // ✅ تم استبدال الأيقونة هنا لتصبح عربة تسوق بدلاً من الحقيبة
                    _NavItem(
                      item: FloatingNavItem(
                        icon: Icons.shopping_cart_outlined,
                        activeIcon: Icons.shopping_cart,
                        label: cartLabel,
                      ),
                      isActive: currentIndex == 2,
                      onTap: () => onTap(2),
                      badgeCount: cartCount,
                    ),
                    // مساحة فاضية لزر الـ Home العائم
                    const SizedBox(width: 64),
                    _NavItem(
                      item: FloatingNavItem(
                        icon: Icons.favorite_outline_rounded,
                        activeIcon: Icons.favorite_rounded,
                        label: favouritesLabel,
                      ),
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                    _NavItem(
                      item: FloatingNavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: accountLabel,
                      ),
                      isActive: currentIndex == 4,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ),
            ),

            // ── زر الـ Home العائم فوق منتصف الشريط ────────────
            Positioned(
              top: 0,
              child: FloatingHomeButton(
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// _NavItem — عنصر فردي داخل الشريط مع حركة scale + slide + opacity
/// ─────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? kBrandPrimary : kTextMuted;

    return Expanded(
      child: Semantics(
        label: item.label,
        button: true,
        selected: isActive,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact(); // ✅ تم إضافة الـ Haptic Feedback هنا أيضاً لجميع الأزرار الأخرى
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // ── حركة Slide + Scale للأيقونة عند التفعيل ──
                  AnimatedSlide(
                    duration: kAnimDuration,
                    curve: Curves.easeOut,
                    offset: isActive ? const Offset(0, -0.08) : Offset.zero,
                    child: AnimatedScale(
                      duration: kAnimDuration,
                      curve: Curves.easeOutBack,
                      scale: isActive ? 1.15 : 1.0,
                      child: AnimatedSwitcher(
                        duration: kAnimDuration,
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          key: ValueKey(isActive),
                          color: color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: const BoxDecoration(
                          color: kBrandSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          textAlign: TextAlign.center,
                          style: boldTextStyle(size: 9, color: kBrandPrimary),
                        ),
                      ),
                    ),
                ],
              ),
              4.height,
              // ── حركة Opacity + تغيير وزن الخط عند التفعيل ────
              AnimatedDefaultTextStyle(
                duration: kAnimDuration,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                child: AnimatedOpacity(
                  duration: kAnimDuration,
                  opacity: isActive ? 1.0 : 0.75,
                  child: Text(item.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}