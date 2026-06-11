import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '/../AppLocalizations.dart';
import '/../main.dart';
import '/../utils/Colors.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

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

  // ─────────────────────────────────────────────────────────────
  // ✅ colors محسوبة مرة واحدة بدل ما تتحسب في كل frame
  // ─────────────────────────────────────────────────────────────
  late final Color _selectedColor;
  late final Color _unselectedColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedColor   = isHalloween ? white : primaryColor!;
    _unselectedColor = isHalloween ? white.withOpacity(0.6) : Colors.grey;

    afterBuildCreated(init);
  }

  void init() {
    setStatusBarColor(primaryColor!);
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
  // (الطريقة القديمة deprecated في Flutter الجديد)
  // ─────────────────────────────────────────────────────────────
  @override
  void didChangePlatformBrightness() {
    if (!mounted) return;
    if (getIntAsync(THEME_MODE_INDEX) == ThemeModeSystem) {
      final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
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
  // CART BADGE — extracted widget لتجنب rebuild الـ BottomNavBar كله
  // ─────────────────────────────────────────────────────────────
  Widget _cartIcon({required bool isActive}) {
    final bool showBadge = mIsLoggedIn || mIsGuest;
    final iconColor      = isActive ? _selectedColor : _unselectedColor;

    return Observer(
      builder: (_) {
        final count = appStore.count ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isActive ? MaterialIcons.shopping_bag : Icons.shopping_bag_outlined,
              color: iconColor,
            ),
            if (showBadge && count > 0)
              Positioned(
                top: -2,
                right: -6,
                child: CircleAvatar(
                  maxRadius: 7,
                  backgroundColor: isHalloween ? mChristmasColor : primaryColor,
                  child: FittedBox(
                    child: Text(
                      '$count',
                      style: secondaryTextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;

    return Observer(
      builder: (context) => Scaffold(
        body: appStore.dashboardScreeList[appStore.index],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: isHalloween ? mChristmasColor : context.cardColor,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          showSelectedLabels: true,
          elevation: 1,
          currentIndex: appStore.index,
          unselectedItemColor: _unselectedColor,
          unselectedLabelStyle: TextStyle(color: _unselectedColor),
          selectedItemColor: _selectedColor,
          onTap: appStore.setBottomNavigationIndex,
          items: [
            // ── Home ──────────────────────────────────────────
            BottomNavigationBarItem(
              icon:       Icon(Ionicons.ios_home_outline, color: _unselectedColor),
              activeIcon: Icon(Ionicons.ios_home,         color: _selectedColor),
              label: appLocalization.translate("lbl_home"),
            ),
            // ── Category ──────────────────────────────────────
            BottomNavigationBarItem(
              icon:       Icon(Ionicons.ios_grid_outline, color: _unselectedColor),
              activeIcon: Icon(Ionicons.ios_grid,         color: _selectedColor),
              label: appLocalization.translate("lbl_category"),
            ),
            // ── Cart (مع badge) ────────────────────────────────
            BottomNavigationBarItem(
              icon:       _cartIcon(isActive: false),
              activeIcon: _cartIcon(isActive: true),
              label: appLocalization.translate("lbl_basket"),
            ),
            // ── Favourites ────────────────────────────────────
            BottomNavigationBarItem(
              icon:       Icon(Icons.favorite_outline_sharp, color: _unselectedColor),
              activeIcon: Icon(MaterialIcons.favorite,       color: _selectedColor),
              label: appLocalization.translate("lbl_favourite"),
            ),
            // ── Account ───────────────────────────────────────
            BottomNavigationBarItem(
              icon:       Icon(Ionicons.person_outline, color: _unselectedColor),
              activeIcon: Icon(Ionicons.person,         color: _selectedColor),
              label: appLocalization.translate("lbl_account"),
            ),
          ],
        ),
      ),
    );
  }
}