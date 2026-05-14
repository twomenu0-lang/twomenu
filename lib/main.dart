import 'dart:async';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:Twomenu/store/AppStore.dart';
import 'package:Twomenu/store/CartStore/CartStore.dart';
import 'package:Twomenu/store/WishListStore/WishListStore.dart';
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
import 'package:nb_utils/nb_utils.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

BuilderResponse builderResponse = BuilderResponse();
Color? primaryColor;
Color? colorAccent;
Color? textPrimaryColour;
Color? textSecondaryColour;
Color? backgroundColor;
String? baseUrl;
String? ConsumerKey;
String? ConsumerSecret;
AppStore appStore = AppStore();
WishListStore wishListStore = WishListStore();
CartStore cartStore = CartStore();
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  });

  await initialize();

  if (isMobile) {
    OneSignal.initialize(mOneSignalAPPKey);
    OneSignal.Notifications.requestPermission(true);
    final playerId = OneSignal.User.pushSubscription.id;
    await setValue(PLAYER_ID, playerId);
    // تم حذف سطر إعدادات MobileAds من هنا
  }

  appStore.setCount(getIntAsync(CARTCOUNT, defaultValue: 0));
  appStore.setNotification(getBoolAsync(IS_NOTIFICATION_ON, defaultValue: true));

  await setValue(DASHBOARD_PAGE_VARIANT, Default_DASHBOARD_PAGE_VARIANT);
  await setValue(PRODUCT_DETAIL_VARIANT, Default_PRODUCT_DETAIL_VARIANT);

  builderResponse = await loadContent();

  if (isHalloween) {
    await setValue(PRIMARY_COLOR, mChristmasBg);
    if (base_URL.isEmpty) {
      await setValue(APP_URL, builderResponse.appsetup!.appUrl);
      await setValue(CONSUMER_KEY, builderResponse.appsetup!.consumerKey);
      await setValue(CONSUMER_SECRET, builderResponse.appsetup!.consumerSecret);
    } else {
      await setValue(APP_URL, base_URL);
      await setValue(CONSUMER_KEY, consumerKey);
      await setValue(CONSUMER_SECRET, consumerSecret);
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

  primaryColor = getColorFromHex(getStringAsync(PRIMARY_COLOR), defaultColor: appColorPrimary);
  colorAccent = getColorFromHex(getStringAsync(SECONDARY_COLOR), defaultColor: appColorAccent);
  textPrimaryColour = getColorFromHex(getStringAsync(TEXT_PRIMARY_COLOR), defaultColor: textColorPrimary);
  textSecondaryColour = getColorFromHex(getStringAsync(TEXT_SECONDARY_COLOR), defaultColor: textColorSecondary);
  backgroundColor = getColorFromHex(getStringAsync(BACKGROUND_COLOR), defaultColor: itemBackgroundColor);

  String cartString = getStringAsync(CART_ITEM_LIST);
  if (cartString.isNotEmpty) {
    cartStore.addAllCartItem(jsonDecode(cartString).map<CartModel>((e) => CartModel.fromJson(e)).toList());
  }

  String wishListString = getStringAsync(WISHLIST_ITEM_LIST);
  if (wishListString.isNotEmpty) {
    wishListStore.addAllWishListItem(jsonDecode(wishListString).map<WishListResponse>((e) => WishListResponse.fromJson(e)).toList());
  }

  baseUrl = getStringAsync(APP_URL);
  ConsumerKey = getStringAsync(CONSUMER_KEY);
  ConsumerSecret = getStringAsync(CONSUMER_SECRET);

  int themeModeIndex = getIntAsync(THEME_MODE_INDEX);
  if (themeModeIndex == ThemeModeLight) {
    appStore.setDarkMode(aIsDarkMode: false);
  } else if (themeModeIndex == ThemeModeDark) {
    appStore.setDarkMode(aIsDarkMode: true);
  }

  appStore.setLanguage(getStringAsync(LANGUAGE, defaultValue: defaultLanguage));

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
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
        push(NoInternetScreen());
      }
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((e) {
        if (e == ConnectivityResult.none) {
          push(NoInternetScreen());
        } else {
          pop();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
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
          themeMode: appStore.isDarkMode! ? ThemeMode.dark : ThemeMode.light,
          supportedLocales: Language.languagesLocale(),
          localizationsDelegates: [
            CountryLocalizations.delegate,
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) => locale,
          locale: Locale(appStore.selectedLanguageCode),
          home: isHalloween ? ChristmasSplashScreen() : SplashScreen(),
          builder: scrollBehaviour(),
        );
      },
    );
  }
}