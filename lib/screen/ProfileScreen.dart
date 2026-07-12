import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_picker/image_picker.dart';
import '/../AppLocalizations.dart';
import '/../component/ThemeSelectionDialog.dart';
import '/../component/TierProgressCard.dart'; // ✅ الكارت الموحّد
import '/../main.dart';
import '/../models/LanguageModel.dart';
import '/../network/rest_apis.dart'; // ✅ لرفع الصورة
import '/../screen/AboutUsScreen.dart';
import '/../screen/ProfileImageViewScreen.dart'; // ✅ عرض الصورة بالزوم
import '/../screen/TeraWalletScreen.dart';
import '/../screen/TierDetailsScreen.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/AppColors.dart';
import '/../screen/BlogListScreen.dart';
import '/../screen/ChangePasswordScreen.dart';
import '/../screen/ChooseDashboardPageVariant.dart';
import '/../screen/ChooseDemo.dart';
import '/../screen/DashBoardScreen.dart';
import '/../screen/EditProfileScreen.dart';
import '/../screen/NotificationScreen.dart';
import '/../screen/OrderListScreen.dart';
import '/../screen/SignInScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../screen/rewards_wallet_screen.dart';
import 'package:in_app_review/in_app_review.dart';
import 'ChooseProductDetailVariant.dart';

class ProfileScreen extends StatefulWidget {
  static String tag = '/ProfileScreen';

  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  String mProfileImage = '';
  String userName = '';
  String userEmail = '';

  bool isChange = false;
  bool mIsLoggedIn = false;
  bool mIsGuest = false;

  // ✅ أنيميشن شريط التقدم — نفس المتحكم المستخدم في TierDetailsScreen بالظبط
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  // ظل ناعم وخفيف يُستخدم بدل الإطارات (Border) في كروت الشاشة
  final List<BoxShadow> _softCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

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
    afterBuildCreated(() {
      init();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  init() async {
    mIsLoggedIn = getBoolAsync(IS_LOGGED_IN);
    mIsGuest = getBoolAsync(IS_GUEST_USER);
    userName = mIsLoggedIn ? '${getStringAsync(FIRST_NAME)} ${getStringAsync(LAST_NAME)}' : '';
    userEmail = mIsLoggedIn ? getStringAsync(USER_EMAIL) : '';
    mProfileImage = getStringAsync(PROFILE_IMAGE);
    setState(() {});
    if (mIsLoggedIn && !mIsGuest) {
      await spendingStore.fetchWallet();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _barController.forward(from: 0);
        });
        setState(() {});
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String _tierEmoji(String tierId) {
    switch (tierId.toLowerCase()) {
      case 'diamond':
        return '💎';
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      default:
        return '🥉';
    }
  }

  Color _tierColor(String tierId) {
    switch (tierId.toLowerCase()) {
      case 'diamond':
        return const Color(0xFF00CED1);
      case 'gold':
        return const Color(0xFFB8860B);
      case 'silver':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  // ═══════════════════════════════════════════════
  // ✅ منطق الصورة الشخصية: عرض / تغيير / إضافة
  // ═══════════════════════════════════════════════
  void _openImageViewer() {
    if (mProfileImage.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileImageViewScreen(imageUrl: mProfileImage)));
  }

  void _showPhotoOptionsSheet(AppLocalizations appLocalization) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bc) {
        return SafeArea(
          child: Wrap(
            children: [
              if (mProfileImage.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.remove_red_eye_outlined, color: kBrandPrimary),
                  title: Text(appLocalization.translate('lbl_view_photo') ?? 'عرض الصورة'),
                  onTap: () {
                    Navigator.pop(bc);
                    _openImageViewer();
                  },
                ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: kBrandPrimary),
                title: Text(appLocalization.translate('lbl_camera') ?? 'التقاط صورة'),
                onTap: () {
                  Navigator.pop(bc);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: kBrandPrimary),
                title: Text(
                  mProfileImage.isEmpty
                      ? (appLocalization.translate('lbl_add_photo') ?? 'إضافة صورة')
                      : (appLocalization.translate('lbl_change_photo') ?? 'تغيير الصورة'),
                ),
                onTap: () {
                  Navigator.pop(bc);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (picked == null) return;
    final File pickedFile = File(picked.path);

    if (mIsGuest) {
      toast(AppLocalizations.of(context)!.translate('toast_txt_profile_saved') ?? 'تم الحفظ');
      return;
    }

    appStore.setLoading(true);
    try {
      await updateProfile(
        file: pickedFile,
        toastMessage: AppLocalizations.of(context)!.translate('toast_txt_profile_saved') ?? 'تم تحديث الصورة بنجاح',
        errorMessage: AppLocalizations.of(context)!.translate('error_something_went_wrong') ?? 'حدث خطأ ما، حاول مرة أخرى',
      );
      mProfileImage = getStringAsync(PROFILE_IMAGE);
    } catch (e) {
      toast(AppLocalizations.of(context)!.translate('error_something_went_wrong') ?? 'حدث خطأ ما، حاول مرة أخرى');
    } finally {
      appStore.setLoading(false);
      setState(() {});
    }
  }

  String _formatAmount(double amount) {
    final int val = amount.toInt();
    final String formatted = val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$formatted ج.م';
  }

  Future<void> _openEditProfile() async {
    bool? isLoad = await const EditProfileScreen().launch(context);
    if (isLoad != null) {
      setState(() {
        mProfileImage = getStringAsync(PROFILE_IMAGE);
        userName = mIsLoggedIn ? '${getStringAsync(FIRST_NAME)} ${getStringAsync(LAST_NAME)}' : '';
        userEmail = mIsLoggedIn ? getStringAsync(USER_EMAIL) : '';
      });
    } else {
      setState(() {
        mProfileImage = getStringAsync(PROFILE_IMAGE);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

    return Observer(
      builder: (_) {
        final wallet = spendingStore.wallet;
        final tierId = wallet?.currentTier.tierId ?? 'bronze';
        final tierName = wallet?.currentTier.tierName ?? appLocalization.translate('lbl_bronze') ?? 'برونزي';

        // ✅ كارت المستوى (يُبنى مرة واحدة ويُمرّر للهيدر المتحرك عشان يتلاشى أثناء الأسكرول)
        final bool showTierArea = mIsLoggedIn && !mIsGuest;
        final Widget? tierCardWidget = showTierArea ? _buildTierPointsCard(context) : null;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    // ═══════════════════════════════════════════
                    // ✅ الهيدر القابل للطي: بطاقة المستخدم + كارت المستوى
                    // يتصغر تدريجياً ويثبت (pinned) أثناء الأسكرول
                    // ═══════════════════════════════════════════
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CollapsingProfileHeaderDelegate(
                        appLocalization: appLocalization,
                        isLoggedIn: mIsLoggedIn,
                        isGuest: mIsGuest,
                        userName: userName,
                        userEmail: userEmail,
                        profileImage: mProfileImage,
                        tierId: tierId,
                        tierName: tierName,
                        tierEmoji: _tierEmoji,
                        onAvatarTap: _openImageViewer,
                        onCameraTap: () => _showPhotoOptionsSheet(appLocalization),
                        onEditTap: _openEditProfile,
                        onBellTap: () {
                          const NotificationScreen().launch(context);
                        },
                        unreadCount: appStore.unreadNotificationCount,
                        tierCard: tierCardWidget,
                        hasTierCard: showTierArea,
                      ),
                    ),

                    // ═══════════════════════════════════════════
                    // ✅ صف الوصول السريع: يثبت أسفل الهيدر المصغّر مباشرة
                    // ═══════════════════════════════════════════
                    if (showTierArea)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _QuickAccessHeaderDelegate(
                          title: appLocalization.translate('lbl_quick_access') ?? 'الوصول السريع',
                          row: _buildQuickAccessRow(context, appLocalization),
                        ),
                      ),

                    // ═══════════════════════════════════════════
                    // ✅ باقي محتوى الصفحة — يتمرر بحرية أسفل العناصر الثابتة
                    // ═══════════════════════════════════════════
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).padding.bottom + 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            appLocalization.translate('lbl_account_settings') ?? 'إعدادات الحساب',
                            style: boldTextStyle(size: 16),
                          ),
                          12.height,
                          ..._buildSettingsList(context, appLocalization),
                          20.height,
                          if (mIsLoggedIn)
                            _OutlinedActionButton(
                              label: appLocalization.translate('btn_sign_out') ?? 'تسجيل الخروج',
                              icon: Icons.logout_rounded,
                              color: kBrandPrimary,
                              onTap: () async {
                                await logout(context);
                              },
                            ),
                          if (mIsLoggedIn && !mIsGuest) ...[
                            12.height,
                            _OutlinedActionButton(
                              label: appLocalization.translate('delete_account') ?? 'حذف الحساب',
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red,
                              onTap: () async {
                                await deleteAccount(context);
                              },
                            ),
                          ],
                          if (!mIsLoggedIn && enableMultiDemo == true) ...[
                            16.height,
                            _SettingsRowCard(
                              title: appLocalization.translate('lbl_multiple_demo') ?? '',
                              icon: Icons.check_circle_outline_outlined,
                              softCardShadow: _softCardShadow,
                              onTap: () {
                                const ChooseDemo().launch(context);
                              },
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ مؤشر تحميل عام أثناء رفع الصورة
              Observer(builder: (context) => mProgress().center().visible(appStore.isLoading)),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ بطاقة النقاط/المستوى — تستخدم الكارت الموحّد TierProgressCard
  // ═══════════════════════════════════════════════════════════
  Widget _buildTierPointsCard(BuildContext context) {
    if (spendingStore.isLoadingWallet && spendingStore.wallet == null) {
      return Container(
        height: 130,
        decoration: BoxDecoration(color: kBrandPrimary, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }

    final wallet = spendingStore.wallet;
    if (wallet == null) return const SizedBox.shrink();

    return TierProgressCard(
      wallet: wallet,
      barProgress: spendingStore.barProgress,
      barAnimation: _barAnimation,
      margin: EdgeInsets.zero,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TierDetailsScreen()));
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // صف الوصول السريع (4 عناصر) — كارت بظل خفيف بدل الإطار
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickAccessRow(BuildContext context, AppLocalizations appLocalization) {
    Widget item(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: _ScaleOnTap(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _softCardShadow,
            ),
            child: Column(
              children: [
                Icon(icon, color: kBrandPrimary, size: 24),
                8.height,
                Text(label, textAlign: TextAlign.center, style: secondaryTextStyle(size: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(Icons.headset_mic_outlined, appLocalization.translate('lbl_contact_us') ?? 'تواصل معنا', () {
          redirectUrl('https://twomenu.shop/contact/');
        }),
        8.width,
        item(MaterialCommunityIcons.gift_outline, appLocalization.translate('lbl_rewards') ?? 'مكافآتي', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsWalletScreen()));
        }),
        8.width,
        item(Icons.favorite_rounded, appLocalization.translate('lbl_wish_list') ?? 'المفضلة', () {
          appStore.setBottomNavigationIndex(3);
        }),
        8.width,
        item(SimpleLineIcons.social_dropbox, appLocalization.translate('lbl_orders') ?? 'طلباتي', () {
          const OrderListScreen().launch(context);
        }),
      ],
    ).visible(!mIsGuest);
  }

  // ═══════════════════════════════════════════════════════════
  // قائمة إعدادات الحساب
  // ═══════════════════════════════════════════════════════════
  List<Widget> _buildSettingsList(BuildContext context, AppLocalizations appLocalization) {
    List<Widget> items = [];

    void add(Widget w) {
      items.add(Padding(padding: const EdgeInsets.only(bottom: 6), child: w));
    }

    if (!mIsLoggedIn) {
      add(_SettingsRowCard(
        title: appLocalization.translate('lbl_sign_in') ?? 'تسجيل الدخول',
        icon: Feather.user,
        softCardShadow: _softCardShadow,
        onTap: () {
          const SignInScreen().launch(context);
        },
      ));
    }
    if (!mIsLoggedIn) {
      add(_SettingsRowCard(
        title: appLocalization.translate('lbl_contact_us') ?? 'تواصل معنا',
        icon: Icons.headset_mic_outlined,
        softCardShadow: _softCardShadow,
        onTap: () {
          redirectUrl('https://twomenu.shop/contact/');
        },
      ));
    }

    if (mIsLoggedIn && !getBoolAsync(IS_SOCIAL_LOGIN) && !getBoolAsync(IS_GUEST_USER)) {
      add(_SettingsRowCard(
        title: appLocalization.translate('lbl_change_pwd') ?? 'تغيير كلمة المرور',
        icon: MaterialCommunityIcons.lock_outline,
        softCardShadow: _softCardShadow,
        onTap: () {
          const ChangePasswordScreen().launch(context);
        },
      ));
    }

    add(_SettingsRowCard(
      title: appLocalization.translate('lbl_notifications') ?? 'الإشعارات',
      icon: Icons.notifications_none_rounded,
      softCardShadow: _softCardShadow,
      trailing: appStore.unreadNotificationCount > 0
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: kBrandSecondary, borderRadius: BorderRadius.circular(999)),
        child: Text('${appStore.unreadNotificationCount}', style: boldTextStyle(color: white, size: 11)),
      )
          : null,
      onTap: () {
        const NotificationScreen().launch(context);
      },
    ));

    add(_SettingsRowCard(
      title: appLocalization.translate('lbl_select_language') ?? 'اللغة',
      icon: Ionicons.language_sharp,
      softCardShadow: _softCardShadow,
      trailing: DropdownButton(
        isDense: true,
        items: languages.map((e) => DropdownMenuItem<Language>(value: e, child: Text(e.name, style: primaryTextStyle(size: 14)))).toList(),
        dropdownColor: appStore.isDarkModeOn ? white : Theme.of(context).scaffoldBackgroundColor,
        value: language,
        underline: const SizedBox(),
        onChanged: (Language? v) async {
          hideKeyboard(context);
          appStore.setLanguage(v!.languageCode);
        },
      ),
      onTap: null,
    ));

    add(_SettingsRowCard(
      title: appLocalization.translate('lbl_dark') ?? 'الوضع الليلي',
      icon: MaterialCommunityIcons.weather_night,
      softCardShadow: _softCardShadow,
      trailing: Transform.scale(
        scale: 0.8,
        child: CupertinoSwitch(
          activeTrackColor: kBrandPrimary,
          value: appStore.isDarkModeOn,
          onChanged: (v) {
            appStore.setDarkMode(aIsDarkMode: v);
            setValue(THEME_MODE_INDEX, v ? ThemeModeDark : ThemeModeLight);
          },
        ),
      ),
      onTap: () {
        bool v = !appStore.isDarkModeOn;
        appStore.setDarkMode(aIsDarkMode: v);
        setValue(THEME_MODE_INDEX, v ? ThemeModeDark : ThemeModeLight);
      },
    ));

    add(_SettingsRowCard(
      title: appLocalization.translate('push_notification') ?? 'السماح بالإشعارات',
      icon: appStore.isNotificationOn ? Feather.bell : Feather.bell_off,
      softCardShadow: _softCardShadow,
      trailing: Transform.scale(
        scale: 0.8,
        child: CupertinoSwitch(
          activeTrackColor: kBrandPrimary,
          value: appStore.isNotificationOn,
          onChanged: (v) {
            appStore.setNotification(v);
          },
        ),
      ),
      onTap: () {
        appStore.setNotification(!getBoolAsync(IS_NOTIFICATION_ON, defaultValue: true));
      },
    ));

    add(_SettingsRowCard(
      title: appLocalization.translate('llb_privacy_policy') ?? 'سياسة الخصوصية',
      icon: Icons.privacy_tip_outlined,
      softCardShadow: _softCardShadow,
      onTap: () {
        redirectUrl(getStringAsync(PRIVACY_POLICY).isEmptyOrNull ? PRIVACY_POLICY_URL : getStringAsync(PRIVACY_POLICY));
      },
    ));

    add(_SettingsRowCard(
      title: appLocalization.translate('lbl_terms_conditions') ?? 'الشروط والأحكام',
      icon: Icons.assignment_outlined,
      softCardShadow: _softCardShadow,
      onTap: () {
        redirectUrl(getStringAsync(TERMS_AND_CONDITIONS).isEmptyOrNull ? TERMS_CONDITION_URL : getStringAsync(TERMS_AND_CONDITIONS));
      },
    ));

    if (enableBlog == true && mIsLoggedIn) {
      add(_SettingsRowCard(
        title: appLocalization.translate('lbl_blog') ?? 'المقالات',
        icon: FontAwesome.list_alt,
        softCardShadow: _softCardShadow,
        onTap: () {
          const BlogListScreen().launch(context);
        },
      ));
    }

    add(_SettingsRowCard(
      title: appLocalization.translate('lbl_rate_app') ?? 'تقييم التطبيق',
      icon: Icons.star_outline_rounded,
      softCardShadow: _softCardShadow,
      onTap: () async {
        final InAppReview inAppReview = InAppReview.instance;

        if (await inAppReview.isAvailable()) {
          inAppReview.requestReview();
        } else {
          redirectUrl(isIOS
              ? 'https://apps.apple.com/app/idXXXXXXXXX'
              : 'https://play.google.com/store/apps/details?id=shop.towmenu.app');
        }
      },
    ));

    add(_SettingsRowCard(
      title: appLocalization.translate('lbl_about') ?? 'من نحن',
      icon: MaterialCommunityIcons.information_outline,
      softCardShadow: _softCardShadow,
      onTap: () {
        redirectUrl('https://twomenu.shop/about-us/');
      },
    ));

    if (enableTeraWallet == true && mIsLoggedIn && !mIsGuest) {
      add(_SettingsRowCard(
        title: appLocalization.translate('lbl_wallet') ?? 'المحفظة',
        icon: MaterialCommunityIcons.wallet_outline,
        softCardShadow: _softCardShadow,
        onTap: () {
          const TeraWalletScreen().launch(context);
        },
      ));
    }

    if (enableDashboardVariant == true) {
      add(_SettingsRowCard(
        title: appLocalization.translate('choose_dashboard_page_variant') ?? '',
        icon: MaterialCommunityIcons.view_dashboard_outline,
        softCardShadow: _softCardShadow,
        onTap: () {
          const ChooseDashboardPageVariant().launch(context);
        },
      ));
      add(_SettingsRowCard(
        title: appLocalization.translate('choose_product_detail_page_variant') ?? '',
        icon: Icons.mobile_friendly,
        softCardShadow: _softCardShadow,
        onTap: () {
          const ChooseProductDetailVariant().launch(context);
        },
      ));
    }

    return items;
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ الهيدر القابل للطي: يحتوي على دوائر الخلفية + بطاقة المستخدم
// (صورة/اسم/بريد/بادچ المستوى/زر التعديل) + كارت المستوى.
// يتصغر تدريجياً مع الأسكرول ويثبت أعلى الشاشة (pinned) كبطاقة مصغّرة.
// ═══════════════════════════════════════════════════════════════
class _CollapsingProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AppLocalizations appLocalization;
  final bool isLoggedIn;
  final bool isGuest;
  final String userName;
  final String userEmail;
  final String profileImage;
  final String tierId;
  final String tierName;
  final String Function(String) tierEmoji;
  final VoidCallback onAvatarTap;
  final VoidCallback onCameraTap;
  final VoidCallback onEditTap;
  final VoidCallback onBellTap;
  final int unreadCount;
  final Widget? tierCard;
  final bool hasTierCard;

  static const double _titleRowHeight = 40;
  static const double _titleSpacing = 18;
  static const double _bigCardHeight = 150;
  static const double _cardSpacing = 16;
  static const double _tierCardHeight = 130;
  static const double _smallCardHeight = 64;
  static const double _topPadding = 12;
  static const double _bottomPaddingExpanded = 18;
  static const double _bottomPaddingCollapsed = 10;
  static const double _hPadding = 20;

  _CollapsingProfileHeaderDelegate({
    required this.appLocalization,
    required this.isLoggedIn,
    required this.isGuest,
    required this.userName,
    required this.userEmail,
    required this.profileImage,
    required this.tierId,
    required this.tierName,
    required this.tierEmoji,
    required this.onAvatarTap,
    required this.onCameraTap,
    required this.onEditTap,
    required this.onBellTap,
    required this.unreadCount,
    this.tierCard,
    this.hasTierCard = false,
  });

  @override
  double get minExtent => _topPadding + _smallCardHeight + _bottomPaddingCollapsed;

  @override
  double get maxExtent {
    double h = _topPadding + _titleRowHeight + _titleSpacing + _bigCardHeight;
    if (hasTierCard) h += _cardSpacing + _tierCardHeight;
    return h + _bottomPaddingExpanded;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double range = (maxExtent - minExtent);
    // t = 1 (موسّع بالكامل) -> t = 0 (مطوي بالكامل)
    final double t = range <= 0 ? 0 : (1 - (shrinkOffset / range)).clamp(0.0, 1.0);
    const double radius = 28;

    return Container(
      decoration: BoxDecoration(
        color: kBrandPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ✅ دوائر الخلفية الزخرفية — تتلاشى أثناء الطي
          Opacity(
            opacity: t,
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(top: -60, right: -40, child: _circle(180, 0.06)),
                  Positioned(top: 40, left: -70, child: _circle(140, 0.05)),
                  Positioned(top: 160, right: 30, child: _circle(70, 0.04)),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_hPadding, _topPadding, _hPadding, lerpDouble(_bottomPaddingCollapsed, _bottomPaddingExpanded, t) ?? _bottomPaddingExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── عنوان الصفحة + الجرس: يختفي تدريجياً عند الطي ──
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: t,
                    child: Opacity(
                      opacity: t,
                      child: SizedBox(
                        height: _titleRowHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _HeaderNotificationBell(onTap: onBellTap, unreadCount: unreadCount),
                            Text(appLocalization.translate('title_account') ?? 'حسابي', style: boldTextStyle(color: white, size: 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: lerpDouble(0, _titleSpacing, t)),

                // ── بطاقة المستخدم: تتحول من الشكل الكبير إلى الشكل المصغّر ──
                if (isLoggedIn)
                  SizedBox(
                    height: lerpDouble(_smallCardHeight, _bigCardHeight, t),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          // ملحوظة: نستخدم Positioned بدون تحديد height (بس left/right/top)
                          // عشان الكارت ياخد ارتفاعه الطبيعي (mainAxisSize.min) من غير ما
                          // نجبره على ارتفاع أصغر من محتواه، والـ ClipRect بيقص أي زيادة
                          // بشكل ناعم أثناء الأنيميشن بدل ما يعمل RenderFlex overflow.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: Opacity(
                              opacity: t,
                              child: IgnorePointer(
                                ignoring: t < 0.4,
                                child: _expandedCard(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: Opacity(
                              opacity: 1 - t,
                              child: IgnorePointer(
                                ignoring: t >= 0.4,
                                child: _collapsedCard(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── كارت المستوى: يظهر بالكامل عند الفتح ويختفي أثناء الأسكرول ──
                if (hasTierCard && tierCard != null)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: t,
                      child: Opacity(
                        opacity: t,
                        child: Padding(
                          padding: EdgeInsets.only(top: _cardSpacing),
                          child: SizedBox(
                            height: _tierCardHeight,
                            // ✅ OverflowBox بيدّي الكارت مساحة غير محدودة عشان يترتب طبيعي
                            // من غير أي إجبار على ارتفاع صغير، وبعدين ClipRect بيقص الزيادة
                            // بصريًا فقط، فمفيش أي RenderFlex overflow حتى لو الرقم صغير جداً.
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minHeight: 0,
                                maxHeight: double.infinity,
                                child: tierCard,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );

  Widget _avatar(double radius) {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: profileImage.isNotEmpty
                ? CircleAvatar(backgroundColor: white, backgroundImage: NetworkImage(profileImage.validate()), radius: radius)
                : CircleAvatar(backgroundColor: white, backgroundImage: Image.asset(User_Profile).image, radius: radius),
          ),
          PositionedDirectional(
            bottom: -2,
            end: -2,
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                width: radius > 26 ? 26 : 18,
                height: radius > 26 ? 26 : 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBrandSecondary,
                  border: Border.all(color: kBrandPrimary, width: 2),
                ),
                child: Icon(Icons.camera_alt_rounded, color: white, size: radius > 26 ? 13 : 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBadge({int fontSize = 12, double iconSize = 13}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kBrandSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tierEmoji(tierId), style: TextStyle(fontSize: iconSize)),
          6.width,
          Text(tierName, style: boldTextStyle(color: white, size: fontSize)),
        ],
      ),
    );
  }

  // ── الشكل الكبير (عند فتح الشاشة) ──
  Widget _expandedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(34),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(color: white, size: 18)),
                    4.height,
                    Text(userEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(color: Colors.white70, size: 13)),
                  ],
                ),
              ),
            ],
          ),
          12.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tierBadge(),
              GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, color: white, size: 14),
                      6.width,
                      Text(appLocalization.translate('lbl_edit_profile') ?? 'تعديل الملف الشخصي', style: secondaryTextStyle(color: white, size: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── الشكل المصغّر (بعد الأسكرول): صف أفقي واحد ثابت ──
  Widget _collapsedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _avatar(20),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(color: white, size: 14)),
                2.height,
                Text(userEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(color: Colors.white70, size: 11)),
              ],
            ),
          ),
          8.width,
          _tierBadge(fontSize: 10, iconSize: 11),
          8.width,
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: const Icon(Icons.edit_outlined, color: white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingProfileHeaderDelegate oldDelegate) {
    return oldDelegate.userName != userName ||
        oldDelegate.userEmail != userEmail ||
        oldDelegate.profileImage != profileImage ||
        oldDelegate.tierId != tierId ||
        oldDelegate.tierName != tierName ||
        oldDelegate.isLoggedIn != isLoggedIn ||
        oldDelegate.isGuest != isGuest ||
        oldDelegate.hasTierCard != hasTierCard ||
        oldDelegate.tierCard != tierCard ||
        oldDelegate.unreadCount != unreadCount;
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ هيدر ثانوي ثابت (pinned) لصف "الوصول السريع" أسفل بطاقة المستخدم مباشرة
// ═══════════════════════════════════════════════════════════════
class _QuickAccessHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final Widget row;
  final double height;

  _QuickAccessHeaderDelegate({required this.title, required this.row, this.height = 150});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: boldTextStyle(size: 16)),
          12.height,
          row,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuickAccessHeaderDelegate oldDelegate) {
    return oldDelegate.title != title || oldDelegate.row != row;
  }
}

// ═══════════════════════════════════════════════════════════════
// 🔔 جرس الإشعارات في الهيدر
// ═══════════════════════════════════════════════════════════════
class _HeaderNotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  final int unreadCount;
  const _HeaderNotificationBell({required this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, color: white, size: 26),
          if (unreadCount > 0)
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: kBrandSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: white, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsRowCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final List<BoxShadow> softCardShadow;

  const _SettingsRowCard({
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap,
    required this.softCardShadow,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: softCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kBrandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: kBrandPrimary),
            ),
            12.width,
            Expanded(child: Text(title, style: secondaryTextStyle(size: 15))),
            trailing ?? Icon(Icons.chevron_right, color: kTextMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: boldTextStyle(color: color, size: 15)),
            8.width,
            Icon(icon, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _ScaleOnTap({required this.child, this.onTap});

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1.0;

  void _setScale(double v) {
    if (widget.onTap == null) return;
    setState(() => _scale = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(0.97),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}