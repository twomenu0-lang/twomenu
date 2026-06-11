import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '/../models/CartModel.dart';
import '/../models/ProductResponse.dart';
import '/../models/WalletResponse.dart';
import '/../models/WishListResponse.dart';
import '/../utils/Constants.dart';
import '/../utils/SharedPref.dart';
import 'package:nb_utils/nb_utils.dart';
import 'NetworkUtils.dart';
import 'mighty_api.dart';

// ─────────────────────────────────────────────────────────────────
// AUTH STATE CACHE
// بدل ما كل function تعمل await isGuestUser() && await isLoggedIn()
// (= 2 disk reads لكل استدعاء)، بنحسبها مرة واحدة ونخزنها في الذاكرة
// ─────────────────────────────────────────────────────────────────
bool? _cachedIsLoggedIn;
DateTime? _authCacheTime;

Future<bool> _isAuthenticatedUser() async {
  // لو عندنا cache وعمره أقل من 5 دقايق، رجّعه من الذاكرة
  if (_cachedIsLoggedIn != null && _authCacheTime != null) {
    if (DateTime.now().difference(_authCacheTime!).inMinutes < 5) {
      return _cachedIsLoggedIn!;
    }
  }
  final result = !await isGuestUser() && await isLoggedIn();
  _cachedIsLoggedIn = result;
  _authCacheTime = DateTime.now();
  return result;
}

// استدعيها بعد login/logout عشان تمسح الـ cache
void clearAuthCache() {
  _cachedIsLoggedIn = null;
  _authCacheTime = null;
}

// ─────────────────────────────────────────────────────────────────
// DASHBOARD CACHE
// أهم cache في التطبيق — بيمنع إعادة تحميل الـ Dashboard في كل مرة
// ─────────────────────────────────────────────────────────────────
dynamic _dashboardCache;
DateTime? _dashboardCacheTime;
const int _dashboardCacheMinutes = 5;

void clearDashboardCache() {
  _dashboardCache = null;
  _dashboardCacheTime = null;
}

// ─────────────────────────────────────────────────────────────────
// CATEGORIES CACHE
// التصنيفات بتتغير نادراً — مش محتاجين نجيبها في كل تشغيل
// ─────────────────────────────────────────────────────────────────
dynamic _categoriesCache;
DateTime? _categoriesCacheTime;
const int _categoriesCacheMinutes = 30;

// ─────────────────────────────────────────────────────────────────
// PRODUCT DETAIL CACHE
// العودة لنفس المنتج تبقى فورية بدل network call جديد كل مرة
// Map<productId, {data, time}>
// ─────────────────────────────────────────────────────────────────
final Map<int, dynamic> _productCache = {};
final Map<int, DateTime> _productCacheTime = {};
const int _productCacheMinutes = 10;

void clearProductCache([int? productId]) {
  if (productId != null) {
    _productCache.remove(productId);
    _productCacheTime.remove(productId);
  } else {
    _productCache.clear();
    _productCacheTime.clear();
  }
}

// ─────────────────────────────────────────────────────────────────
// AUTH APIs
// ─────────────────────────────────────────────────────────────────

Future createCustomer(request) async {
  return handleResponse(await MightyAPI().postAsync('store/api/v1/auth/registration', request));
}

Future login(request) async {
  clearAuthCache(); // مسح الـ cache عند الـ login
  return handleResponse(await MightyAPI().postAsync('store/api/v1/auth/login', request));
}

Future forgetPassword(request) async {
  return handleResponse(await MightyAPI().postAsync('store/api/v1/customer/forget-password', request));
}

Future changePassword(request) async {
  return handleResponse(await MightyAPI().postAsync('store/api/v1/customer/change-password', request, requireToken: true));
}

Future socialLoginApi(request) async {
  clearAuthCache(); // مسح الـ cache عند الـ social login
  log(jsonEncode(request));
  return handleResponse(await MightyAPI().postAsync('store/api/v1/customer/social_login', request));
}

Future deleteAccountApi() async {
  clearAuthCache();
  return handleResponse(await MightyAPI().postAsync('store/api/v1/customer/delete-account', {}, requireToken: true));
}

// ─────────────────────────────────────────────────────────────────
// CUSTOMER APIs
// ─────────────────────────────────────────────────────────────────

Future updateCustomer(id, request) async {
  return handleResponse(await MightyAPI().postAsync('wc/v3/customers/$id', request));
}

Future getCustomer(id) async {
  return handleResponse(await MightyAPI().getAsync('wc/v3/customers/$id'));
}

// ─────────────────────────────────────────────────────────────────
// DASHBOARD API — مع Cache
// ─────────────────────────────────────────────────────────────────

Future getDashboardApi() async {
  // ✅ رجّع من الـ cache لو لسه صالح
  if (_dashboardCache != null && _dashboardCacheTime != null) {
    if (DateTime.now().difference(_dashboardCacheTime!).inMinutes < _dashboardCacheMinutes) {
      return _dashboardCache;
    }
  }

  // ✅ استدعاء واحد لـ isGuestUser/isLoggedIn بدل اثنين
  final bool useToken = await _isAuthenticatedUser();

  final result = await handleResponse(
    await MightyAPI().getAsync(
      'store/api/v1/woocommerce/get-dashboard?per_page=$TOTAL_DASHBOARD_ITEM',
      requireToken: useToken,
    ),
  );

  // حفظ في الـ cache
  _dashboardCache = result;
  _dashboardCacheTime = DateTime.now();
  return result;
}

// ─────────────────────────────────────────────────────────────────
// PRODUCT APIs
// ─────────────────────────────────────────────────────────────────

Future getProductDetail(int? productId) async {
  // ✅ لو المنتج متحمّل قبل كده وعمر الـ cache مناسب، رجّعه فوراً
  if (productId != null &&
      _productCache.containsKey(productId) &&
      _productCacheTime.containsKey(productId)) {
    if (DateTime.now().difference(_productCacheTime[productId]!).inMinutes < _productCacheMinutes) {
      return _productCache[productId];
    }
  }

  final bool useToken = await _isAuthenticatedUser();
  final result = await handleResponse(
    await MightyAPI().getAsync(
      'store/api/v1/woocommerce/get-product-details?product_id=$productId',
      requireToken: useToken,
    ),
  );

  // حفظ في الـ cache
  if (productId != null) {
    _productCache[productId] = result;
    _productCacheTime[productId] = DateTime.now();
  }

  return result;
}

Future searchProduct(request) async {
  final bool useToken = await _isAuthenticatedUser();
  return handleResponse(
    await MightyAPI().postAsync(
      'store/api/v1/woocommerce/get-product',
      request,
      requireToken: useToken,
    ),
  );
}

Future getProductAttribute() async {
  return handleResponse(await MightyAPI().getAsync('store/api/v1/woocommerce/get-product-attributes'));
}

Future getProductReviews(id) async {
  return handleResponse(await MightyAPI().getAsync('wc/v3/products/reviews?product=$id'));
}

Future postReview(request) async {
  return handleResponse(await MightyAPI().postAsync('wc/v3/products/reviews', request));
}

Future updateReview(id1, request) async {
  return handleResponse(await MightyAPI().postAsync('wc/v3/products/reviews/$id1', request));
}

Future deleteReview(id1) async {
  return handleResponse(await MightyAPI().deleteAsync('wc/v3/products/reviews/$id1'));
}

Future<List<ProductResponse>> getPrivateProduct() async {
  Iterable it = await handleResponse(await MightyAPI().getAsync('wc/v3/products?status=private'));
  return it.map((e) => ProductResponse.fromJson(e)).toList();
}

Future getSaleInfo(startDate, endDate) async {
  return handleResponse(
    await MightyAPI().getAsync(
      'store/api/v1/woocommerce/get-sale-product?start_date=$startDate&end_date=$endDate',
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// CATEGORIES APIs — مع Cache
// ─────────────────────────────────────────────────────────────────

Future getCategories(page, total) async {
  // ✅ Cache للتصنيفات — بتتغير نادراً جداً
  if (_categoriesCache != null && _categoriesCacheTime != null) {
    if (DateTime.now().difference(_categoriesCacheTime!).inMinutes < _categoriesCacheMinutes) {
      return _categoriesCache;
    }
  }

  final result = await handleResponse(
    await MightyAPI().getAsync(
      'wc/v3/products/categories?page=$page&per_page=$total&parent=0',
    ),
  );

  _categoriesCache = result;
  _categoriesCacheTime = DateTime.now();
  return result;
}

Future getSubCategories(parent, page) async {
  return handleResponse(
    await MightyAPI().getAsync('wc/v3/products/categories?page=$page&parent=$parent'),
  );
}

Future getAllCategories(category, page, total) async {
  return handleResponse(
    await MightyAPI().getAsync('wc/v3/products?category=$category&page=$page&per_page=$total'),
  );
}

// ─────────────────────────────────────────────────────────────────
// WISHLIST APIs
// ─────────────────────────────────────────────────────────────────

Future<List<WishListResponse>> getWishList() async {
  Iterable it = (await handleResponse(
    await MightyAPI().getAsync('store/api/v1/wishlist/get-wishlist/', requireToken: true),
  ));
  return it.map((e) => WishListResponse.fromJson(e)).toList();
}

Future addWishList(request) async {
  return handleResponse(
    await MightyAPI().postAsync('store/api/v1/wishlist/add-wishlist/', request, requireToken: true),
  );
}

Future removeWishList(request) async {
  return handleResponse(
    await MightyAPI().postAsync('store/api/v1/wishlist/delete-wishlist/', request, requireToken: true),
  );
}

// ─────────────────────────────────────────────────────────────────
// CART APIs
// ─────────────────────────────────────────────────────────────────

Future addToCart(request) async {
  return handleResponse(
    await MightyAPI().postAsync('store/api/v1/cart/add-cart/', request, requireToken: true),
  );
}

Future removeCartItem(request) async {
  return handleResponse(
    await MightyAPI().postAsync('store/api/v1/cart/delete-cart/', request, requireToken: true),
  );
}

Future getCartList() async {
  return handleResponse(
    await MightyAPI().getAsync('store/api/v1/cart/get-cart/', requireToken: true),
  );
}

Future<CartResponse> getCartListApi() async {
  return CartResponse.fromJson(
    await handleResponse(
      await MightyAPI().getAsync('store/api/v1/cart/get-cart/', requireToken: true),
    ),
  );
}

Future updateCartItem(request) async {
  return handleResponse(
    await MightyAPI().postAsync('store/api/v1/cart/update-cart/', request, requireToken: true),
  );
}

Future clearCartItems() async {
  return handleResponse(
    await MightyAPI().getAsync('store/api/v1/cart/clear-cart/', requireToken: true),
  );
}

// ─────────────────────────────────────────────────────────────────
// ORDERS APIs
// ─────────────────────────────────────────────────────────────────

Future createOrderApi(request) async {
  // جلب الـ player_id من الـ SharedPref أولاً
  String playerId = getStringAsync(PLAYER_ID);

  // لو مش موجود، اجيبه من OneSignal مباشرة
  if (playerId.isEmpty) {
    playerId = OneSignal.User.pushSubscription.id ?? '';
    if (playerId.isNotEmpty) {
      await setValue(PLAYER_ID, playerId);
    }
  }

  if (playerId.isNotEmpty) {
    final meta = request['meta_data'] as List? ?? [];
    meta.add({'key': '_onesignal_player_id', 'value': playerId});
    request['meta_data'] = meta;
  }

  return handleResponse(await MightyAPI().postAsync('wc/v3/orders', request));
}

Future getOrders() async {
  final userId = getIntAsync(USER_ID);
  // ✅ قلّلنا per_page من 50 لـ 20 — أسرع وكافي للعرض الأولي
  return handleResponse(
    await MightyAPI().getAsync(
      'wc/v3/orders?customer=$userId&per_page=20&orderby=date&order=desc',
      requireToken: false,
    ),
  );
}

Future getOrderById(int? orderId) async {
  return handleResponse(
    await MightyAPI().getAsync('wc/v3/orders/$orderId', requireToken: false),
  );
}

Future getOrdersTracking(orderId) async {
  return handleResponse(await MightyAPI().getAsync('wc/v3/orders/$orderId/notes'));
}

Future createOrderNotes(orderId, request) async {
  return handleResponse(
    await MightyAPI().postAsync('wc/v3/orders/$orderId/notes', request),
  );
}

Future cancelOrder(orderId, request) async {
  return handleResponse(await MightyAPI().postAsync('wc/v3/orders/$orderId', request));
}

Future deleteOrder(id1) async {
  return handleResponse(await MightyAPI().deleteAsync('wc/v3/orders/$id1'));
}

// ─────────────────────────────────────────────────────────────────
// CHECKOUT & SHIPPING APIs
// ─────────────────────────────────────────────────────────────────

Future getCheckOutUrl(request) async {
  return handleResponse(
    await MightyAPI().postAsync(
      'store/api/v1/woocommerce/get-checkout-url',
      request,
      requireToken: true,
    ),
  );
}

Future getCountries() async {
  return handleResponse(
    await MightyAPI().getAsync('wc/v3/data/countries', requireToken: false),
  );
}

Future getStripeClientSecret(request) async {
  return handleResponse(
    await MightyAPI().postAsync(
      'store/api/v1/woocommerce/get-stripe-client-secret',
      request,
      requireToken: true,
    ),
  );
}

Future getShippingMethod(request) async {
  return handleResponse(
    await MightyAPI().postAsync(
      'store/api/v1/woocommerce/get-shipping-methods',
      request,
      requireToken: false,
    ),
  );
}

Future getCouponList() async {
  return handleResponse(await MightyAPI().getAsync('wc/v3/Coupons'));
}

// ─────────────────────────────────────────────────────────────────
// VENDOR APIs
// ─────────────────────────────────────────────────────────────────

Future getVendor() async {
  return handleResponse(await MightyAPI().getAsync('store/api/v1/woocommerce/get-vendors'));
}

Future getVendorProfile(id) async {
  return handleResponse(await MightyAPI().getAsync('dokan/v1/stores/$id'));
}

Future getVendorProduct(id) async {
  final bool useToken = await _isAuthenticatedUser();
  return handleResponse(
    await MightyAPI().getAsync(
      'store/api/v1/woocommerce/get-vendor-products?vendor_id=$id',
      requireToken: useToken,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// BLOG APIs
// ─────────────────────────────────────────────────────────────────

Future getBlogList(page, total) async {
  return handleResponse(
    await MightyAPI().getAsync(
      'store/api/v1/blog/get-blog-list?paged=$page&posts_per_page=$total',
    ),
  );
}

Future getBlogDetail(id) async {
  return handleResponse(
    await MightyAPI().getAsync('store/api/v1/blog/get-blog-detail?post_id=$id'),
  );
}

// ─────────────────────────────────────────────────────────────────
// TRACKING APIs
// ─────────────────────────────────────────────────────────────────

Future getTrackingInfo(id) async {
  return handleResponse(
    await MightyAPI().getAsync('wc-ast/v3/orders/$id/shipment-trackings/'),
  );
}

// ─────────────────────────────────────────────────────────────────
// WALLET APIs
// ─────────────────────────────────────────────────────────────────

Future<List<WalletResponse>> getWalletBalance(int? id) async {
  Iterable it = await handleResponse(
    await MightyAPI().getAsync('wp/v2/wallet/$id', requireToken: true),
  );
  return it.map((e) => WalletResponse.fromJson(e)).toList();
}

Future addTransaction(request) async {
  return handleResponse(
    await MightyAPI().postAsync(
      'wp/v2/wallet/${getIntAsync(USER_ID)}',
      request,
      requireToken: true,
    ),
  );
}

Future getBalance() async {
  String value = await handleResponse(
    await MightyAPI().getAsync(
      'wp/v2/current_balance/${getIntAsync(USER_ID)}',
      requireToken: true,
    ),
  );
  return value;
}

Future getWalletConfiguration() async {
  return handleResponse(
    await MightyAPI().getAsync(
      'store/api/v1/wallet/get-wallet-configuration',
      requireToken: true,
    ),
  );
}

Future addWallet(request) async {
  return handleResponse(
    await MightyAPI().postAsync('store/api/v1/wallet/add-to-wallet', request, requireToken: true),
  );
}

// ─────────────────────────────────────────────────────────────────
// PROFILE APIs
// ─────────────────────────────────────────────────────────────────

Future saveProfileImage(request) async {
  return handleResponse(
    await MightyAPI().postAsync(
      'store/api/v2/customer/save-profile-image',
      request,
      requireToken: true,
    ),
  );
}

Future<bool> updateProfile({File? file, String? toastMessage, bool showToast = true}) async {
  var multiPartRequest = MultipartRequest(
    'POST',
    Uri.parse('${getStringAsync(APP_URL)}store/api/v2/customer/save-profile-image'),
  );

  if (file != null) {
    multiPartRequest.files.add(await MultipartFile.fromPath('profile_image', file.path));
  }

  multiPartRequest.headers.addAll({
    "Authorization": "Bearer ${getStringAsync(TOKEN)}",
  });

  log(multiPartRequest.fields);
  Response response = await Response.fromStream(await multiPartRequest.send());
  log(response.body);

  if (response.statusCode.isSuccessful()) {
    Map<String, dynamic> res = jsonDecode(response.body);
    await setValue(PROFILE_IMAGE, res['store_profile_image']);
    if (showToast) toast(toastMessage ?? res['message']);
    return true;
  } else {
    toast(errorSomethingWentWrong);
    return false;
  }
}