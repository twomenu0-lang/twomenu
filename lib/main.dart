// lib/main.dart
import 'dart:async';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:Twomenu/store/AppStore.dart';
import 'package:Twomenu/store/CartStore/CartStore.dart';
import 'package:Twomenu/store/WishListStore/WishListStore.dart';
import 'package:Twomenu/store/RewardsStore/rewards_store.dart';
import 'package:Twomenu/store/SpendingStore/spending_store.dart';
import 'package:Twomenu/utils/firebase_options.dart';
import '/../AppTheme.dart';
import '/../AppLocalizations.dart';
import '/../models/BuilderResponse.dart';
import '/../models/CartModel.dart';
import '/../models/LanguageModel.dart';
import '/../models/WishListResponse.dart';
import '/../screen/ChristmasScreens/ChristmasSplashScreen.dart';
import '/../screen/NoInternetScreen.dart';
import '/../screen/SplashScreen.dart';
import '/../utils/Colors.dart';
import '/../utils/Constants.dart';
import '/../service/NotificationService.dart';
import '/../network/rest_apis.dart'; // ✅ v1.7.5-fix — لازم نستورده عشان نقدر ننادي savePlayerIdToServer()
import 'package:nb_utils/nb_utils.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

BuilderResponse builderResponse = BuilderResponse();
Color? primaryColor;
Color? colorAccent;
Color? textPrimaryColour;
Color? textSecondaryColour;
Color? backgroundColor;
String? baseUrl;
String? consumerKey;
String? consumerSecret;
AppStore appStore = AppStore();
WishListStore wishListStore = WishListStore();
CartStore cartStore = CartStore();
RewardsStore rewardsStore = RewardsStore();
SpendingStore spendingStore = SpendingStore();

Language? language;
List<Language> languages = Language.getLanguages();

Future<String> loadBuilderData() async {
  return await rootBundle.loadString('assets/builder.json');
}

Future<BuilderResponse> loadContent() async {
  String jsonString = await loadBuilderData();
  final jsonResponse = json.decode(jsonString);
  return BuilderResponse.fromJson(jsonResponse);
}

String _safeGetString(String key, {String defaultValue = ''}) {
  try {
    return getStringAsync(key, defaultValue: defaultValue);
  } catch (e) {
    removeKey(key);
    return defaultValue;
  }
}

void _initOneSignal() {
  if (!isMobile) return;

  OneSignal.initialize(mOneSignalAPPKey);
  OneSignal.Notifications.requestPermission(false);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    final notification = event.notification;
    final String type = notification.additionalData?['type'] ?? '';

    // ✅ v1.7.4 — لما الكاشير يعمل redeem، الـ plugin بيبعت reward_redeemed
    // نحدّث الـ store فوراً عشان RedemptionScreen يستجيب
    if (type == NotificationType.rewardRedeemed) {
      final dynamic rawId = notification.additionalData?['reward_id'];
      final int rewardId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '') ?? 0;
      if (rewardId > 0) {
        rewardsStore.markRedeemed(rewardId);
      }
    }

    NotificationService.save(
      id: notification.notificationId,
      title: notification.title ?? '',
      body: notification.body ?? '',
      type: type,
    ).then((_) {
      appStore.setUnreadNotificationCount(NotificationService.unreadCount());
      if (type == NotificationType.tierUpgraded) {
        appStore.setTierUpgraded(true);
        spendingStore.fetchWallet(); // ✅ تم التعديل: نحدّث الـ store فوراً وبشكل مسبق للتخلص من الـ race condition
      }
    });

    event.preventDefault();
    event.notification.display();
  });

  OneSignal.Notifications.addClickListener((event) {
    final notification = event.notification;
    final String type = notification.additionalData?['type'] ?? '';

    // ✅ v1.7.4 — نفس المعالجة لو الإشعار وصل وهو في الـ background
    if (type == NotificationType.rewardRedeemed) {
      final dynamic rawId = notification.additionalData?['reward_id'];
      final int rewardId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '') ?? 0;
      if (rewardId > 0) {
        rewardsStore.markRedeemed(rewardId);
      }
    }

    NotificationService.save(
      id: notification.notificationId,
      title: notification.title ?? '',
      body: notification.body ?? '',
      type: type,
    ).then((_) {
      appStore.setUnreadNotificationCount(NotificationService.unreadCount());
      if (type == NotificationType.tierUpgraded) {
        appStore.setTierUpgraded(true);
        spendingStore.fetchWallet(); // ✅ تم التعديل: نحدّث الـ store فوراً عند النقر على الإشعار لتهيئة الـ cache
      }
    });
  });

  // ✅ v1.7.5-fix — حفظ الـ Player ID محلياً وإرساله فوراً للسيرفر
  OneSignal.User.pushSubscription.addObserver((state) async {
    final playerId = state.current.id;
    if (playerId != null && playerId.isNotEmpty) {
      await setValue(PLAYER_ID, playerId);
      await savePlayerIdToServer();
    }
  });

  final playerId = OneSignal.User.pushSubscription.id;
  if (playerId != null && playerId.isNotEmpty) {
    setValue(PLAYER_ID, playerId);
  }
}

void _initFirebaseBackground() {
  FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  _initOneSignal();
}

void _initColors() {
  primaryColor = getColorFromHex(_safeGetString(PRIMARY_COLOR),
      defaultColor: appColorPrimary);
  colorAccent = getColorFromHex(_safeGetString(SECONDARY_COLOR),
      defaultColor: appColorAccent);
  textPrimaryColour = getColorFromHex(_safeGetString(TEXT_PRIMARY_COLOR),
      defaultColor: textColorPrimary);
  textSecondaryColour = getColorFromHex(_safeGetString(TEXT_SECONDARY_COLOR),
      defaultColor: textColorSecondary);
  backgroundColor = getColorFromHex(_safeGetString(BACKGROUND_COLOR),
      defaultColor: itemBackgroundColor);
}

void _initLocalData() {
  String cartString = _safeGetString(CART_ITEM_LIST);
  if (cartString.isNotEmpty) {
    try {
      cartStore.addAllCartItem(jsonDecode(cartString)
          .map<CartModel>((e) => CartModel.fromJson(e))
          .toList());
    } catch (e) {
      removeKey(CART_ITEM_LIST);
    }
  }

  String wishListString = _safeGetString(WISHLIST_ITEM_LIST);
  if (wishListString.isNotEmpty) {
    try {
      wishListStore.addAllWishListItem(jsonDecode(wishListString)
          .map<WishListResponse>((e) => WishListResponse.fromJson(e))
          .toList());
    } catch (e) {
      removeKey(WISHLIST_ITEM_LIST);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  });

  await initialize();
  await initializeDateFormatting();

  builderResponse = await loadContent();
  final bool isFirstRun = _safeGetString(APP_URL).isEmpty;

  if (isFirstRun) {
    if (isHalloween) {
      await setValue(PRIMARY_COLOR, mChristmasBg);
      if (base_URL.isEmpty) {
        await setValue(APP_URL, builderResponse.appsetup!.appUrl);
        await setValue(CONSUMER_KEY, builderResponse.appsetup!.consumerKey);
        await setValue(CONSUMER_SECRET, builderResponse.appsetup!.consumerSecret);
      } else {
        await setValue(APP_URL, base_URL);
        await setValue(CONSUMER_KEY, consumerKey ?? '');
        await setValue(CONSUMER_SECRET, consumerSecret ?? '');
      }
    } else {
      await setValue(PRIMARY_COLOR, builderResponse.appsetup!.primaryColor);
      await setValue(APP_URL, builderResponse.appsetup!.appUrl);
      await setValue(CONSUMER_KEY, builderResponse.appsetup!.consumerKey);
      await setValue(CONSUMER_SECRET, builderResponse.appsetup!.consumerSecret);
    }

    await setValue(BACKGROUND_COLOR, builderResponse.appsetup!.backgroundColor);
    await setValue(SECONDARY_COLOR, builderResponse.appsetup!.secondaryColor);
    await setValue(TEXT_PRIMARY_COLOR, builderResponse.appsetup!.textPrimaryColor);
    await setValue(TEXT_SECONDARY_COLOR, builderResponse.appsetup!.textSecondaryColor);
  }

  appStore.setCount(getIntAsync(CARTCOUNT, defaultValue: 0));
  appStore.setNotification(getBoolAsync(IS_NOTIFICATION_ON, defaultValue: true));

  if (_safeGetString(DASHBOARD_PAGE_VARIANT).isEmpty) {
    await setValue(DASHBOARD_PAGE_VARIANT, Default_DASHBOARD_PAGE_VARIANT);
  }
  if (_safeGetString(PRODUCT_DETAIL_VARIANT).isEmpty) {
    await setValue(PRODUCT_DETAIL_VARIANT, Default_PRODUCT_DETAIL_VARIANT);
  }

  baseUrl = _safeGetString(APP_URL);
  consumerKey = _safeGetString(CONSUMER_KEY);
  consumerSecret = _safeGetString(CONSUMER_SECRET);

  appStore.setUnreadNotificationCount(NotificationService.unreadCount());

  try {
    int themeModeIndex = getIntAsync(THEME_MODE_INDEX, defaultValue: ThemeModeLight);
    if (themeModeIndex == ThemeModeLight) {
      appStore.setDarkMode(aIsDarkMode: false);
    } else if (themeModeIndex == ThemeModeDark) {
      appStore.setDarkMode(aIsDarkMode: true);
    } else {
      appStore.setDarkMode(aIsDarkMode: false);
    }
  } catch (e) {
    appStore.setDarkMode(aIsDarkMode: false);
  }

  String savedLanguage = _safeGetString(LANGUAGE);
  if (savedLanguage.isEmpty) {
    appStore.setLanguage(defaultLanguage);
  } else {
    appStore.setLanguage(savedLanguage);
  }

  _initColors();
  _initLocalData();

  runApp(const MyApp());

  _initFirebaseBackground();

  // تأمين إرسال الـ Player ID عند تشغيل التطبيق للمستخدمين المسجلين مسبقاً
  await savePlayerIdToServer();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() async {
      await 1.seconds.delay;
      if (!await isNetworkAvailable()) {
        push(const NoInternetScreen());
      }

      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
            if (results.contains(ConnectivityResult.none)) {
              push(const NoInternetScreen());
            } else {
              pop();
            }
          });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          navigatorKey: navigatorKey,
          themeMode: (appStore.isDarkMode ?? false) ? ThemeMode.dark : ThemeMode.light,
          supportedLocales: Language.languagesLocale(),
          localizationsDelegates: const [
            CountryLocalizations.delegate,
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) => locale,
          locale: Locale(appStore.selectedLanguageCode),
          home: isHalloween ? const ChristmasSplashScreen() : const SplashScreen(),
          builder: scrollBehaviour(),
        );
      },
    );
  }
}