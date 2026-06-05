import 'package:nb_utils/nb_utils.dart';

const AppName = 'Two Menu';

///OneSignalAppID
const mOneSignalAPPKey = 'f211bd10-9e3a-4064-a628-9fe6c266620e';

///ADMob Id
const bannerAdIdForAndroid = "ADD ADMOB BANNER ID FOR ANDROID";
const bannerAdIdForIos = "ADD BANNER ID FOR IOS";
const InterstitialAdIdForAndroid = "ADD INTERSTITIAL ID FOR ANDROID";
const interstitialAdIdForIos = "ADD INTERSTITIAL ANDROID FOR IOS";

//region  firebase data  for firebase_options.dart
const String FIREBASE_API_KEY = "AIzaSyBnJVuXp32nfkeqEg7VRc3-wnk3kK-iQkM";
const String FIREBASE_APP_ID = "1:161430194427:android:c2c6b2e43f7d8800a9c85e";
const String FIREBASE_MESSAGING_SENDER_ID = "161430194427";
const String FIREBASE_PROJECT_ID = "twomenu-790a0";
const String FIREBASE_STORAGE_BUCKET = "twomenu-790a0.firebasestorage.app";

//for ios
const String ANDROID_CLIENT_ID = 'YOUR ANDROID_CLIENT_ID';
const String IOS_CLIENT_ID = 'YOUR IOS_CLIENT_ID';
const String IOS_BUNDLE_ID = 'YOUR IOS_BUNDLE_ID';


/// PAYMENT METHOD ENABLE/DISABLE
const IS_STRIPE = true;
const IS_RAZORPAY = true;
const IS_PAY_STACK = true;
const IS_FLUTTER_WAVE = true;
const IS_PAY_FROM_WALLET = true;

///RazorPay
const razorKey = "ADD RAZOR PAY KEY";

///StripPayment
const stripPaymentKey = 'ADD STRIP PAYMENT SECRETE KEY';
const stripPaymentPublishKey = 'ADD STRIP PUBLISH KEY';
const merchantId = "YOUR_App_Identifier";

///FlutterWave
const flutterWavePublicKey = 'ADD FLUTTER WAVE PUBLISH KEY';
const flutterWaveSecretKey = 'ADD FLUTTER WAVE SECRET KEY';
const flutterWaveEncryptionKey = 'ADD FLUTTER WAVE ENCRYPTION KEY';

///PAY STACK DETAIL
const payStackPublicKey = 'ADD PAY STACK PUBLISH KEY';

/// الروابط الخاصة بـ Two Menu
const TERMS_CONDITION_URL = "https://twomenu.shop/terms-and-conditions/";
const PRIVACY_POLICY_URL = "https://twomenu.shop/privacy-policy/";
const SUPPORT_URL = "https://twomenu.shop/contact/"; // رابط الدعم الجديد

/// SharedPreferences Keys
const IS_LOGGED_IN = 'IS_LOGGED_IN';
const IS_SOCIAL_LOGIN = 'IS_SOCIAL_LOGIN';
const IS_GUEST_USER = 'IS_GUEST_USER';
const THEME_COLOR = 'THEME_COLOR';
const DASHBOARD_DATA = 'DASHBOARD_DATA';
const SLIDER_DATA = 'SLIDER_DATA';
const CROSS_AXIS_COUNT = 'CROSS_AXIS_COUNT';
const CATEGORY_CROSS_AXIS_COUNT = 'CATEGORY_CROSS_AXIS_COUNT';
const msg = 'message';
const CART_DATA = 'CART_DATA';
const WISH_LIST_DATA = 'WISH_LIST_DATA';
const GUEST_USER_DATA = 'GUEST_USER_DATA';
const TOKEN = 'TOKEN';
const USERNAME = 'USERNAME';
const FIRST_NAME = 'FIRST_NAME';
const LAST_NAME = 'LAST_NAME';
const USER_DISPLAY_NAME = 'USER_DISPLAY_NAME';
const USER_ID = 'USER_ID';
const USER_EMAIL = 'USER_EMAIL';
const USER_ROLE = 'USER_ROLE';
const AVATAR = 'AVATAR';
const PASSWORD = 'PASSWORD';
const PROFILE_IMAGE = 'PROFILE_IMAGE';
const BILLING = 'BILLING';
const SHIPPING = 'SHIPPING';
const COUNTRIES = 'COUNTRIES';
const LANGUAGE = 'LANGUAGE';
const CARTCOUNT = 'CARTCOUNT';
const WHATSAPP = 'WHATSAPP';
const FACEBOOK = 'FACEBOOK';
const TWITTER = 'TWITTER';
const INSTAGRAM = 'INSTAGRAM';
const CONTACT = 'CONTACT';
const PRIVACY_POLICY = 'PRIVACY_POLICY';
const TERMS_AND_CONDITIONS = 'TERMS_AND_CONDITIONS';
const COPYRIGHT_TEXT = 'COPYRIGHT_TEXT';
const PAYMENTMETHOD = 'PAYMENTMETHOD';
const ENABLECOUPON = 'ENABLECOUPON';
const PAYMENT_METHOD_NATIVE = "native";
const DEFAULT_CURRENCY = 'DEFAULT_CURRENCY';
const CURRENCY_CODE = 'CURRENCY_CODE';
const IS_NOTIFICATION_ON = "IS_NOTIFICATION_ON";
const DETAIL_PAGE_VARIANT = 'DetailPageVariant';
const IS_REMEMBERED = "IS_REMEMBERED";
const IS_DOKAN_ACTIVE = 'IS_DOKAN_ACTIVE';
const PLAYER_ID = 'PLAYER_ID';
const WALLET = 'WALLET';

//Start AppSetup
const APP_NAME = 'appName';
const PRIMARY_COLOR = 'primaryColor';
const SECONDARY_COLOR = 'secondaryColor';
const TEXT_PRIMARY_COLOR = 'textPrimaryColor';
const TEXT_SECONDARY_COLOR = 'textSecondaryColor';
const BACKGROUND_COLOR = 'backgroundColor';
const CONSUMER_KEY = 'consumerKey';
const CONSUMER_SECRET = 'consumerSecret';
const APP_URL = 'appUrl';
//End AppSetup

//Date Format
const orderDateFormat = 'dd-MM-yyyy';
const reviewDateFormat = 'dd MMM yy  hh:mm a';
const CreateDateFormat = 'MMM dd, yyyy';

const accessAllowed = true;
const demoPurposeMsg = 'This action is not allowed in demo app.';

const COMPLETED = "completed";
const REFUNDED = "refunded";
const CANCELED = "cancelled";
const TRASH = "trash";
const FAILED = "failed";
const SUCCESS = 'Success';

/* Theme Mode Type */
const ThemeModeLight = 0;
const ThemeModeDark = 1;
const ThemeModeSystem = 2;

const defaultLanguage = 'ar';

const VideoTypeCustom = 'custom_url';
const VideoTypeYouTube = 'youtube';
const VideoTypeIFrame = 'iframe';

const enableSignWithGoogle = true;
const enableSignWithApple = true;
const enableSignWithOtp = true;
const enableSocialSign = true;
const enableAdsLoading = true;
const enableAds = true;

const enableBlog = true;
const enableMultiDemo = false; // تم تعطيله لتثبيت هويتك
const enableDashboardVariant = false; // تم تعطيله لتثبيت هويتك

bool get enableTeraWallet => getBoolAsync(WALLET);

// Set per page item
const TOTAL_ITEM_PER_PAGE = 50;
const TOTAL_CATEGORY_PER_PAGE = 50;
const TOTAL_SUB_CATEGORY_PER_PAGE = 50;
const TOTAL_DASHBOARD_ITEM = 4;
const TOTAL_BLOG_ITEM = 6;

const WISHLIST_ITEM_LIST = 'WISHLIST_ITEM_LIST';
const CART_ITEM_LIST = 'CART_ITEM_LIST';

const DASHBOARD_PAGE_VARIANT = 'DashboardPageVariant';
const PRODUCT_DETAIL_VARIANT = 'ProductDetailVariant';

const streamRefresh = "streamRefresh";

// Set Theme
bool get isHalloween => getBoolAsync(HALLOWEEN_ENABLE);
const HALLOWEEN_ENABLE = 'halloween_enable';

// Halloween Theme - تم استعادة القيم الأصلية بناءً على طلبك
const base_URL = "https://meetmighty.com/mobile/halloween/wp-json/";
const consumerKey = "ADD CONSUMER KEY";
const consumerSecret = "ADD CONSUMER SECRET";

const Default_DASHBOARD_PAGE_VARIANT = 1;
const Default_PRODUCT_DETAIL_VARIANT = 1;