import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../AppLocalizations.dart';
import '/../main.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../component/BottomNav/FloatingBottomNavigation.dart';

class DashBoardScreen extends StatefulWidget {
  static String tag = '/DashBoardScreen1';

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen>
    with WidgetsBindingObserver {
  // ─────────────────────────────────────────────────────────────
  // ✅ قراءة IS_LOGGED_IN مرة واحدة بس — مش في كل rebuild
  // ─────────────────────────────────────────────────────────────
  final bool mIsLoggedIn = getBoolAsync(IS_LOGGED_IN);
  final bool mIsGuest    = getBoolAsync(IS_GUEST_USER);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    afterBuildCreated(init);
  }

  void init() {
    setStatusBarColor(Colors.transparent, statusBarIconBrightness: Brightness.dark);
    setValue(CARTCOUNT, appStore.count);

    // ✅ OneSignal notification listener
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data.containsKey('ID')) {
        final notId = (data['ID'] as String?)?.trim() ?? '';
        if (notId.isNotEmpty) {
          // TODO: navigate to product/order if needed
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ WidgetsBindingObserver بدل window.onPlatformBrightnessChanged
  // ─────────────────────────────────────────────────────────────
  @override
  void didChangePlatformBrightness() {
    if (!mounted) return;
    if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) {
      final isDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      appStore.setDarkMode(aIsDarkMode: isDark);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ─────────────────────────────────────────────────────────────
  // Exit confirmation dialog — نفس هوية تصميم التطبيق
  // ─────────────────────────────────────────────────────────────
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── الجزء العلوي بالأيقونة ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: primaryColor!.withValues(alpha: 0.12), // ✅ تم الإصلاح بإضافة color والفاصلة
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primaryColor!.withValues(alpha: 0.18), // ✅ تم الإصلاح بإضافة color والفاصلة
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.exit_to_app_rounded,
                    size: 36,
                    color: primaryColor,
                  ),
                ),
              ),
            ),

            // ── النص والأزرار ────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'هل أنت متأكد أنك تريد الخروج؟',
                    style: boldTextStyle(size: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // ── زر نعم ──────────────────────────────
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check,
                              color: Colors.white),
                          label: Text(
                            'نعم',
                            style: boldTextStyle(color: Colors.white),
                          ),
                          onPressed: () =>
                              Navigator.of(ctx).pop(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ── زر إلغاء ────────────────────────────
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(Icons.close,
                              color: Colors.grey.shade600),
                          label: Text(
                            'إلغاء',
                            style:
                            boldTextStyle(color: Colors.grey.shade600),
                          ),
                          onPressed: () =>
                              Navigator.of(ctx).pop(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ✅ منع الـ default back behavior تماماً
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // الحالة ١: المستخدم مش في Home tab → ارجعه للـ Home
        if (appStore.index != 0) {
          appStore.setBottomNavigationIndex(0);
          return;
        }

        // الحالة ٢: المستخدم في Home tab → اعرض dialog التأكيد
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop(); // ✅ إغلاق التطبيق بشكل نظيف
        }
      },
      child: Observer(
        builder: (context) => Scaffold(
          backgroundColor: context.scaffoldBackgroundColor,
          // ✅ يسمح لمحتوى الشاشة بالامتداد خلف شريط التنقل العائم
          extendBody: true,
          body: appStore.dashboardScreeList[appStore.index],
          // ✅ شريط تنقل عائم شفاف الخلفية (FloatingBottomNavigation)
          bottomNavigationBar: Material(
            color: Colors.transparent,
            child: FloatingBottomNavigation(
              currentIndex: appStore.index,
              onTap: appStore.setBottomNavigationIndex,
              // ✅ نفس منطق ظهور البادچ القديم: بس لو المستخدم Logged in أو Guest
              cartCount: (mIsLoggedIn || mIsGuest) ? (appStore.count ?? 0) : 0,
              categoriesLabel:
              AppLocalizations.of(context)!.translate("lbl_category") ?? '', // ✅ حماية ضد الـ Null
              cartLabel:
              AppLocalizations.of(context)!.translate("lbl_basket") ?? '',   // ✅ حماية ضد الـ Null
              favouritesLabel:
              AppLocalizations.of(context)!.translate("lbl_favourite") ?? '',// ✅ حماية ضد الـ Null
              accountLabel:
              AppLocalizations.of(context)!.translate("lbl_account") ?? '',  // ✅ حماية ضد الـ Null
            ),
          ),
        ),
      ),
    );
  }
}
