import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import '/../models/CartModel.dart';
import '/../models/CategoryData.dart';
import '/../models/ProductResponse.dart';
import '/../models/SaleBannerResponse.dart';
import '/../models/SliderModel.dart';
import '/../network/rest_apis.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import '../main.dart';

// ─────────────────────────────────────────────────────────────────
// GLOBAL STATE — بيانات الـ Dashboard
// ─────────────────────────────────────────────────────────────────
List<String?> mSliderImages      = [];
List<String?> mSaleBannerImages  = [];
List<ProductResponse> mNewestProductModel    = [];
List<ProductResponse> mFeaturedProductModel  = [];
List<ProductResponse> mDealProductModel      = [];
List<ProductResponse> mSellingProductModel   = [];
List<ProductResponse> mSaleProductModel      = [];
List<ProductResponse> mOfferProductModel     = [];
List<ProductResponse> mSuggestedProductModel = [];
List<ProductResponse> mYouMayLikeProductModel= [];
List<VendorResponse>  mVendorModel           = [];
List<Category>        mCategoryModel         = [];
List<SliderModel>     mSliderModel           = [];
List<Salebanner>      mSaleBanner            = [];
List<Widget>          data                   = [];
List<Widget>          pages                  = [];
List<String?>         mQuotes                = [];
CartResponse          mCartModel             = CartResponse();

// ✅ Random instance واحدة مشتركة بدل new Random() في كل مكان
final Random rnd = Random();

bool isWasConnectionLoss = false;
bool isDone              = false;

// ─────────────────────────────────────────────────────────────────
// FETCH CATEGORY
// ─────────────────────────────────────────────────────────────────
Future<void> fetchCategoryData() async {
  try {
    final res = await getCategories(1, TOTAL_CATEGORY_PER_PAGE);
    final Iterable mCategory = res;
    mCategoryModel = mCategory.map((model) => Category.fromJson(model)).toList();
  } catch (error) {
    log('fetchCategoryData error: $error');
  }
}

// ─────────────────────────────────────────────────────────────────
// FETCH DASHBOARD
// ─────────────────────────────────────────────────────────────────
Future<void> fetchDashboardData() async {
  final bool hasNetwork = await isNetworkAvailable();
  if (!hasNetwork) {
    toast('You are not connected to Internet');
    appStore.setLoading(false);
    return;
  }

  try {
    final res = await getDashboardApi();

    // ✅ حفظ البيانات الأساسية — كلها في batch واحد بدل await منفصل لكل واحدة
    // الـ SharedPreferences writes مش محتاجة await واحدة واحدة
    setValue(DEFAULT_CURRENCY, parseHtmlString(res['currency_symbol']['currency_symbol']));
    setValue(CURRENCY_CODE,    res['currency_symbol']['currency']);
    setValue(DASHBOARD_DATA,   jsonEncode(res));
    setValue(PAYMENTMETHOD,    res['payment_method']);
    setValue(ENABLECOUPON,     res['enable_coupons']);
    setValue(WALLET,           res['is_woo_wallet_active']);

    // ✅ Social links — في batch واحد كمان
    if (res['social_link'] != null) {
      final social = res['social_link'];
      setValue(WHATSAPP,            social['whatsapp']);
      setValue(FACEBOOK,            social['facebook']);
      setValue(TWITTER,             social['twitter']);
      setValue(INSTAGRAM,           social['instagram']);
      setValue(CONTACT,             social['contact']);
      setValue(PRIVACY_POLICY,      social['privacy_policy']);
      setValue(TERMS_AND_CONDITIONS,social['term_condition']);
      setValue(COPYRIGHT_TEXT,      social['copyright_text']);
    }

    // ✅ Parse المنتجات في Isolate-friendly طريقة (sync لكن مرة واحدة)
    setProductData(res);
    isDone = true;

  } catch (error) {
    log('fetchDashboardData error: $error');
    appStore.setLoading(false);
  }
}

// ─────────────────────────────────────────────────────────────────
// SET PRODUCT DATA
// ✅ كل الـ parsing بيحصل هنا مرة واحدة بدون await زيادة
// ─────────────────────────────────────────────────────────────────
void setProductData(Map res) {
  // ✅ Helper محلي — بيتجنب تكرار null check في كل سطر
  List<ProductResponse> _parseProducts(String key) {
    final raw = res[key];
    if (raw == null) return [];
    return (raw as Iterable).map((m) => ProductResponse.fromJson(m)).toList();
  }

  mNewestProductModel     = _parseProducts('newest');
  mFeaturedProductModel   = _parseProducts('featured');
  mDealProductModel       = _parseProducts('deal_of_the_day');
  mSellingProductModel    = _parseProducts('best_selling_product');
  mSaleProductModel       = _parseProducts('sale_product');
  mOfferProductModel      = _parseProducts('offer');
  mSuggestedProductModel  = _parseProducts('suggested_for_you');
  mYouMayLikeProductModel = _parseProducts('you_may_like');

  // Vendors
  if (res['vendors'] != null) {
    final Iterable vendorList = res['vendors'];
    mVendorModel = vendorList.map((m) => VendorResponse.fromJson(m)).toList();
  }

  // Sale banners
  if (res['salebanner'] != null) {
    mSaleBannerImages.clear();
    final Iterable bannerList = res['salebanner'];
    mSaleBanner = bannerList.map((m) => Salebanner.fromJson(m)).toList();
    // ✅ for loop بدل forEach — أسرع في Dart
    for (final s in mSaleBanner) {
      mSaleBannerImages.add(s.image);
    }
  }

  // Sliders
  mSliderImages.clear();
  final Iterable banners = res['banner'];
  mSliderModel = banners.map((m) => SliderModel.fromJson(m)).toList();
  for (final s in mSliderModel) {
    mSliderImages.add(s.image);
  }
}

// ─────────────────────────────────────────────────────────────────
// UTILITY
// ─────────────────────────────────────────────────────────────────
List<T?> map<T>(List list, Function handler) {
  List<T?> result = [];
  for (var i = 0; i < list.length; i++) {
    result.add(handler(i, list[i]));
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM WIDGET — اقتباس عشوائي
// ✅ mQuotes بتتبنى مرة واحدة بس لو فاضية
// ─────────────────────────────────────────────────────────────────
Widget mBottom(BuildContext context) {
  final appLocalization = AppLocalizations.of(context)!;

  // ✅ بنبني القائمة مرة واحدة بس — مش في كل build
  if (mQuotes.isEmpty) {
    mQuotes = [
      appLocalization.translate('msg_quote1'),
      appLocalization.translate('msg_quote2'),
      appLocalization.translate('msg_quote3'),
      appLocalization.translate('msg_quote4'),
      appLocalization.translate('msg_quote5'),
      appLocalization.translate('msg_quote6'),
    ];
  }

  final quote = mQuotes[rnd.nextInt(mQuotes.length)];

  return Container(
    color: appStore.isDarkModeOn
        ? Theme.of(context).dividerColor.withOpacity(0.02)
        : Theme.of(context).cardTheme.color!.withOpacity(0.5),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    child: Column(
      children: [
        Container(width: 40, color: Theme.of(context).dividerColor, height: 4),
        10.height,
        Text(
          "'$quote'",
          style: secondaryTextStyle(),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
