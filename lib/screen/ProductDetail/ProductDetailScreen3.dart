import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '/../component/HtmlWidget.dart';
import '/../component/VideoPlayDialog.dart';
import '/../main.dart';
import '/../models/ProductDetailResponse.dart';
import '/../models/ProductReviewModel.dart';
import '/../network/rest_apis.dart';
import '/../screen/ViewAllScreen.dart';
import '/../screen/ZoomImageScreen.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/Countdown.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Colors.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../AppLocalizations.dart';
import 'ProductDetailScreen1.dart';
import 'ProductDetailScreen2.dart';
import '../ReviewScreen.dart';
import '../SignInScreen.dart';
import '../VendorProfileScreen.dart';
import '../WebViewExternalProductScreen.dart';

class ProductDetailScreen3 extends StatefulWidget {
  final int? mProId;
  const ProductDetailScreen3({Key? key, this.mProId}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen3> {
  ProductDetailResponse? productDetailNew;
  ProductDetailResponse? mainProduct; // المنتج الرئيسي

  String  mProfileImage             = '';
  int?    selectedOptionAvailableIn = 0;

  List<ProductDetailResponse> mProducts            = [];
  List<ProductReviewModel>    mReviewModel         = [];
  List<ProductDetailResponse> mProductsList        = [];
  List<String?>               mProductOptions      = [];
  List<int>                   mProductVariationsIds = [];
  List<ProductDetailResponse> product              = [];
  List<Widget>                productImg           = [];
  List<String?>               productImg1          = [];

  final PageController _pageController = PageController(initialPage: 0);

  // ✅ Timer مرجع — كان memory leak في النسخة القديمة
  Timer? _bannerTimer;

  bool    mIsGroupedProduct  = false;
  bool    mIsExternalProduct = false;
  bool    mIsLoggedIn        = false;
  double  rating             = 0.0;
  double  discount           = 0.0;
  int     selectIndex        = 0;
  int     _currentPage       = 0;
  String  videoType          = '';
  String? mSelectedVariation = '';
  String  mExternalUrl       = '';

  @override
  void initState() {
    super.initState();
    mIsLoggedIn = getBoolAsync(IS_LOGGED_IN);
    init();
  }

  void _startTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !_pageController.hasClients) return;
      // ✅ يلف على العدد الفعلي للصور
      _currentPage = _currentPage < (productImg1.length - 1) ? _currentPage + 1 : 0;
      _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 350), curve: Curves.easeIn);
    });
  }

  void init() {
    afterBuildCreated(() async {
      // ✅ تحميل بالتوازي بدل التسلسل
      await Future.wait([productDetail(), fetchReviewData()]);
      _startTimer();
    });
  }

  @override
  void setState(fn) { if (mounted) super.setState(fn); }

  @override
  void dispose() {
    _bannerTimer?.cancel(); // ✅ إيقاف التايمر
    _pageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // PRODUCT DETAIL
  // ─────────────────────────────────────────────────────────────
  Future<void> productDetail() async {
    try {
      final res = await getProductDetail(widget.mProId);
      if (!mounted) return;

      final Iterable mInfo = res;
      mProducts = mInfo.map((m) => ProductDetailResponse.fromJson(m)).toList();
      if (mProducts.isEmpty) return;

      productDetailNew = mProducts[0];
      mainProduct = mProducts[0]; // احفظ المنتج الرئيسي
      rating = double.tryParse(productDetailNew!.averageRating ?? '0') ?? 0.0;
      productDetailNew!.variations!.forEach((e) => mProductVariationsIds.add(e));
      mProductsList = List.from(mProducts.skip(1));

      final type = productDetailNew!.type;
      if (type == "variable" || type == "variation") {
        mProductOptions.clear();
        for (final p in mProductsList) {
          var option = p.attributes!.map((a) => a.option.validate()).where((o) => o.isNotEmpty).join(' - ');
          if (p.onSale!) option = '$option [Sale]';
          mProductOptions.add(option);
        }
        if (mProductOptions.isNotEmpty && (mSelectedVariation == null || mSelectedVariation!.isEmpty)) {
          mSelectedVariation = mProductOptions.first;
        }
        if (mProductsList.isNotEmpty) {
          int idx = mSelectedVariation!.isNotEmpty ? mProductOptions.indexOf(mSelectedVariation) : 0;
          if (idx < 0) idx = 0;
          selectedOptionAvailableIn = idx;
          productDetailNew = mProductsList[idx];
        }
      } else if (type == 'grouped') {
        mIsGroupedProduct = true;
        product = List.from(mProductsList);
      }

      if (productDetailNew!.woofVideoEmbed?.url?.isNotEmpty == true) {
        final url = productDetailNew!.woofVideoEmbed!.url.validate();
        videoType = url.contains(VideoTypeYouTube) ? VideoTypeYouTube
            : url.contains(VideoTypeIFrame) ? VideoTypeIFrame
            : VideoTypeCustom;
        productImg.add(
          Stack(fit: StackFit.expand, children: [
            commonCacheImageWidget(productDetailNew!.images![0].src.validate(), fit: BoxFit.cover, height: 400, width: double.infinity)
                .cornerRadiusWithClipRRectOnly(topLeft: 20, topRight: 20).paddingOnly(bottom: 24),
            const Icon(Icons.play_circle_fill_outlined, size: 40, color: Colors.black12).center(),
          ]).onTap(() => VideoPlayDialog(data: productDetailNew!.woofVideoEmbed).launch(context)),
        );
      }

      _mImage();
      _setPriceDetail();
      appStore.setLoading(false);
      setState(() {});
    } catch (error) {
      log('productDetail error: $error');
      appStore.setLoading(false);
      if (mounted) toast(error.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REVIEWS
  // ─────────────────────────────────────────────────────────────
  Future<void> fetchReviewData() async {
    try {
      final res = await getProductReviews(widget.mProId);
      if (!mounted) return;
      final Iterable list = res;
      mReviewModel = list.map((m) => ProductReviewModel.fromJson(m)).toList();
      _recalcRatingFromReviews();
      setState(() {});
    } catch (_) { appStore.setLoading(false); }
  }

  void _recalcRatingFromReviews() {
    if (mReviewModel.isEmpty) return;
    final double sum = mReviewModel.fold(0.0, (prev, r) => prev + (r.rating ?? 0));
    rating = sum / mReviewModel.length;
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────
  void _setPriceDetail() {
    if (productDetailNew!.onSale! && productDetailNew!.type != 'grouped') {
      final mrp  = double.parse(productDetailNew!.regularPrice!);
      final sale = double.parse(productDetailNew!.price!);
      discount = ((mrp - sale) / mrp) * 100;
    }
  }

  void _mImage() { productImg1 = productDetailNew!.images!.map((e) => e.src).toList(); }

  String getAllAttribute(Attribute attribute) => attribute.options!.join(', ');

  void mOtherAttribute() { toast('Product type not supported'); finish(context); }

  Widget _mDiscount(BuildContext context) {
    if (!productDetailNew!.onSale!) return const SizedBox.shrink();
    return Text(
      '${discount.toInt()} % ${AppLocalizations.of(context)!.translate('lbl_off1')!}',
      style: primaryTextStyle(color: Colors.red, size: 14, decoration: TextDecoration.underline, textDecorationStyle: TextDecorationStyle.solid),
    );
  }

  Widget _mSpecialPrice(String? value) {
    if (productDetailNew?.dateOnSaleTo?.isEmpty != false) return const SizedBox.shrink();
    final endDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse('${productDetailNew!.dateOnSaleTo} 23:59:59.000');
    final now = DateTime.now();
    final format = endDate.subtract(Duration(days: now.day, hours: now.hour, minutes: now.minute, seconds: now.second));
    return Countdown(
      duration: Duration(days: format.day, hours: format.hour, minutes: format.minute, seconds: format.second),
      onFinish: () {},
      builder: (_, Duration? remaining) {
        final sec = ((remaining!.inMilliseconds / 1000) % 60).toInt();
        final min = ((remaining.inMilliseconds / (1000 * 60)) % 60).toInt();
        final hrs = ((remaining.inMilliseconds / (1000 * 60 * 60)) % 24).toInt();
        return Container(
          decoration: boxDecorationWithRoundedCorners(borderRadius: radius(4), backgroundColor: colorAccent!.withOpacity(0.3)),
          child: Text('$value ${remaining.inDays}d ${hrs}h ${min}m ${sec}s', style: primaryTextStyle(size: 12)).paddingAll(8),
        ).paddingOnly(left: 16, right: 16, top: 16, bottom: 16);
      },
    );
  }

  Widget _mSetAttribute() {
    return AnimatedListView(
      itemCount: productDetailNew!.attributes!.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemBuilder: (context, i) {
        final attr = productDetailNew!.attributes![i];
        return attr.options != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(attr.name, style: primaryTextStyle()).visible(attr.options!.isNotEmpty),
          8.height.visible(productDetailNew!.attributes!.isNotEmpty),
          Text(getAllAttribute(attr), maxLines: 4, style: secondaryTextStyle()),
        ]).paddingOnly(left: 8)
            : const SizedBox.shrink();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    setValue(CARTCOUNT, appStore.count);
    final appLocalization = AppLocalizations.of(context)!;

    // الوصف المعروض: من المنتج الرئيسي إن وُجد، وإلا من productDetailNew
    final displayDescription = (mainProduct?.description?.isNotEmpty == true ? mainProduct!.description : productDetailNew?.description) ?? '';
    final displayShortDescription = (mainProduct?.shortDescription?.isNotEmpty == true ? mainProduct!.shortDescription : productDetailNew?.shortDescription) ?? '';

    // ── Upcoming Sale ─────────────────────────────────────────
    Widget mUpcomingSale() {
      if (productDetailNew?.dateOnSaleFrom?.isEmpty != false) return const SizedBox.shrink();
      final diff = DateTime.parse(productDetailNew!.dateOnSaleFrom.validate()).difference(DateTime.now()).inMilliseconds;
      if (diff <= 0) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Divider(thickness: 6, color: appStore.isDarkMode! ? white.withOpacity(0.2) : Theme.of(context).textTheme.headlineMedium!.color),
        Text(appLocalization.translate('lbl_upcoming_sale_on_this_item')!, style: boldTextStyle()).paddingAll(16),
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
          decoration: boxDecorationWithRoundedCorners(borderRadius: radius(8), backgroundColor: primaryColor!.withOpacity(0.2)),
          width: context.width(), padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          child: Marquee(directionMarguee: DirectionMarguee.oneDirection,
              child: Text(
                '${appLocalization.translate('lbl_sale_start_from')!} ${productDetailNew!.dateOnSaleFrom!} ${appLocalization.translate('lbl_to')!} ${productDetailNew!.dateOnSaleTo!}. ${appLocalization.translate('lbl_ge_amazing_discounts_on_the_products')!}',
                style: secondaryTextStyle(color: Theme.of(context).textTheme.titleSmall!.color, size: 16),
              ).paddingLeft(16)),
        ),
      ]);
    }

    // ── Reviews ───────────────────────────────────────────────
    Widget reviewWidget() {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(appLocalization.translate("lbl_reviews")!, style: boldTextStyle()).paddingOnly(left: 16, right: 16, bottom: 4).visible(mReviewModel.isNotEmpty),
        ListView.separated(
          separatorBuilder: (_, __) => const Divider(),
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: mReviewModel.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final r = mReviewModel[index];
            final starColor = r.rating == 1 || r.rating == 2 || r.rating == 3 ? yellowColor : const Color(0xFF66953A);
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ✅ commonCacheImageWidget بدل NetworkImage مباشرة
                  mProfileImage.isNotEmpty
                      ? CircleAvatar(radius: 24, child: ClipOval(child: commonCacheImageWidget(mProfileImage, height: 48, width: 48, fit: BoxFit.cover)))
                      : CircleAvatar(backgroundImage: Image.asset(User_Profile).image, radius: 24),
                  16.width,
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.reviewer!, style: boldTextStyle(size: 14)),
                    8.height,
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      RatingBar.builder(initialRating: r.rating!.toDouble(), minRating: 1, direction: Axis.horizontal, allowHalfRating: true, ignoreGestures: true, itemCount: 5, itemSize: 18,
                          itemBuilder: (_, __) => Icon(Icons.star, color: starColor, size: 14), onRatingUpdate: (_) {}),
                      8.width,
                      Text(reviewConvertDate(r.dateCreated), style: secondaryTextStyle()),
                    ]),
                  ]),
                ]),
                4.height,
                Text(parseHtmlString(r.review), style: secondaryTextStyle(), maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(appLocalization.translate("lbl_view_all_review")!, style: boldTextStyle(color: context.accentColor)),
          const Icon(Icons.chevron_right),
        ]).onTap(() {
          ReviewScreen(mProductId: widget.mProId, productName: productDetailNew?.name, productImage: productDetailNew?.images?.isNotEmpty == true ? productDetailNew!.images![0].src : null).launch(context);
        }).paddingAll(16).visible(mReviewModel.length >= 3 && productDetailNew!.reviewsAllowed == true),
      ]);
    }

    // ── Upsell ────────────────────────────────────────────────
    Widget upSaleProductList(List<UpsellId> ups) {
      final w = context.width();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        8.height,
        Text(appLocalization.translate('lbl_like')!, style: boldTextStyle()).paddingLeft(12),
        Container(
          margin: const EdgeInsets.only(top: 4), height: 320,
          child: AnimatedListView(
            itemCount: ups.length, shrinkWrap: true,
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () { final v = getIntAsync(PRODUCT_DETAIL_VARIANT, defaultValue: 1); if (v == 2) ProductDetailScreen2(mProId: ups[i].id).launch(context); else if (v == 3) ProductDetailScreen3(mProId: ups[i].id).launch(context); else ProductDetailScreen1(mProId: ups[i].id).launch(context); },
                child: Container(
                  width: w * 0.55, margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(border: Border.all(color: gray.withOpacity(0.5), width: 0.5)),
                  child: Column(children: [
                    Container(
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4, top: 16),
                      padding: const EdgeInsets.all(1.2),
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF37D5D6), Color(0xFF63A4FF)], begin: FractionalOffset(0.0, 0.0), end: FractionalOffset(1.0, 0.0))),
                      child: commonCacheImageWidget(ups[i].images!.first.src, height: 200, width: w, fit: BoxFit.cover),
                    ),
                    4.height,
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ups[i].name!, style: primaryTextStyle(size: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Row(children: [
                        PriceWidget(price: ups[i].salePrice.toString().isNotEmpty ? ups[i].salePrice.toString() : ups[i].price.toString(), size: 14),
                        4.width,
                        PriceWidget(price: ups[i].regularPrice.toString(), size: 12, isLineThroughEnabled: true, color: Theme.of(context).textTheme.titleSmall!.color).visible(ups[i].salePrice.toString().isNotEmpty),
                      ]),
                    ]).paddingSymmetric(horizontal: 16),
                  ]),
                ),
              );
            },
          ),
        ),
      ]);
    }

    // ── Grouped ───────────────────────────────────────────────
    Widget mGroupAttribute(List<ProductDetailResponse> grp) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(appLocalization.translate('lbl_product_Involve')!, style: boldTextStyle()).paddingOnly(left: 12, top: 8),
        AnimatedListView(
            physics: const NeverScrollableScrollPhysics(), scrollDirection: Axis.vertical, shrinkWrap: true, itemCount: grp.length,
            padding: const EdgeInsets.only(left: 12, right: 8),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () { final v = getIntAsync(PRODUCT_DETAIL_VARIANT, defaultValue: 1); if (v == 2) ProductDetailScreen2(mProId: grp[i].id).launch(context); else if (v == 3) ProductDetailScreen3(mProId: grp[i].id).launch(context); else ProductDetailScreen1(mProId: grp[i].id).launch(context); },
              child: Container(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  commonCacheImageWidget(grp[i].images![0].src, height: 90, width: 90, fit: BoxFit.cover).cornerRadiusWithClipRRect(8),
                  10.width,
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(grp[i].name!, style: primaryTextStyle()), 4.height,
                    Row(children: [PriceWidget(price: grp[i].salePrice.toString().isNotEmpty ? grp[i].salePrice.toString() : grp[i].price.toString(), size: 14, color: Theme.of(context).textTheme.titleSmall!.color), 2.width, PriceWidget(price: grp[i].regularPrice.toString(), size: 12, isLineThroughEnabled: true, color: Theme.of(context).textTheme.titleSmall!.color).visible(grp[i].salePrice.toString().isNotEmpty)]),
                    8.height,
                    Container(padding: const EdgeInsets.all(10),
                      decoration: boxDecorationWithRoundedCorners(borderRadius: radius(8), backgroundColor: grp[i].inStock == true ? primaryColor! : white, border: Border.all(color: primaryColor!)),
                      child: Text(grp[i].inStock == true ? grp[i].type == 'external' ? grp[i].buttonText! : cartStore.isItemInCart(grp[i].id.validate()) ? appLocalization.translate('lbl_remove_cart')!.toUpperCase() : appLocalization.translate('lbl_add_to_cart')!.toUpperCase() : appLocalization.translate('lbl_sold_out')!.toUpperCase(),
                          textAlign: TextAlign.center, style: boldTextStyle(color: grp[i].inStock == false ? primaryColor : white, size: 12)),
                    ).onTap(() {
                      if (grp[i].inStock == true) {
                        if (grp[i].type == 'external') WebViewExternalProductScreen(mExternal_URL: grp[i].externalUrl, title: appLocalization.translate('lbl_external_product')).launch(context);
                        else if (!getBoolAsync(IS_LOGGED_IN)) SignInScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                        else { addCart(data: grp[i]); init(); setState(() {}); }
                      }
                    }),
                  ]).expand(),
                ]),
              ),
            )),
      ]);
    }

    // ── Sliders ───────────────────────────────────────────────
    final dotIndicator = DotIndicator(pageController: _pageController, pages: productImg.isNotEmpty ? productImg : productImg1, indicatorColor: primaryColor, unselectedIndicatorColor: grey.withOpacity(0.2), currentBoxShape: BoxShape.rectangle, boxShape: BoxShape.rectangle, borderRadius: radius(2), currentBorderRadius: radius(3), currentDotSize: 18, currentDotWidth: 6, dotSize: 6);

    final videoSlider = productDetailNew != null ? Column(children: [
      Container(height: 400, width: context.width(), decoration: boxDecorationWithRoundedCorners(borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20)), backgroundColor: Theme.of(context).scaffoldBackgroundColor), margin: const EdgeInsets.only(bottom: 8),
          child: PageView(children: productImg, controller: _pageController, onPageChanged: (i) { selectIndex = i; setState(() {}); })),
      dotIndicator]) : const SizedBox.shrink();

    final imgSlider = productDetailNew != null ? Column(children: [
      Container(height: 400, width: context.width(), decoration: boxDecorationWithRoundedCorners(borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20)), backgroundColor: Theme.of(context).scaffoldBackgroundColor), margin: const EdgeInsets.only(bottom: 8),
          child: PageView(controller: _pageController, onPageChanged: (i) { selectIndex = i; setState(() {}); },
              children: productImg1.map((i) => commonCacheImageWidget(i.validate(), fit: BoxFit.cover, width: double.infinity).cornerRadiusWithClipRRectOnly(topLeft: 20, topRight: 20).onTap(() => ZoomImageScreen(mImgList: productDetailNew!.images!).launch(context))).toList())),
      dotIndicator]) : const SizedBox.shrink();

    // ── Favourite & Cart ──────────────────────────────────────
    final mFavourite = productDetailNew != null ? Observer(builder: (_) => GestureDetector(
        onTap: () { if (productDetailNew!.type! == 'external') toast(appLocalization.translate('lbl_external_wishlist_msg')!); else { checkWishList(productDetailNew, context); setState(() {}); } },
        child: Container(padding: const EdgeInsets.all(8), decoration: boxDecorationWithRoundedCorners(borderRadius: BorderRadius.circular(8), backgroundColor: Theme.of(context).cardTheme.color!, border: Border.all(color: primaryColor!)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [wishListStore.isItemInWishlist(productDetailNew!.id!) == false ? Icon(Icons.favorite_border, color: primaryColor) : Icon(Icons.favorite, color: redColor)])).visible(productDetailNew!.isAddedWishList != null))) : const SizedBox.shrink();

    final mCartData = productDetailNew != null ? Observer(builder: (_) => GestureDetector(
        onTap: () { if (productDetailNew!.inStock == true) { if (mIsExternalProduct) WebViewExternalProductScreen(mExternal_URL: mExternalUrl, title: appLocalization.translate('lbl_external_product')).launch(context); else if (!getBoolAsync(IS_LOGGED_IN)) SignInScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Slide); else { addCart(data: productDetailNew!); init(); setState(() {}); } } },
        child: Container(padding: const EdgeInsets.all(10), decoration: boxDecorationWithRoundedCorners(borderRadius: BorderRadius.circular(8), backgroundColor: productDetailNew!.inStock! ? context.primaryColor : textSecondaryColorGlobal.withOpacity(0.3)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shopping_bag_outlined, color: white), 4.width,
              Text(productDetailNew!.inStock! == true ? productDetailNew!.type! == 'external' ? productDetailNew!.buttonText! : cartStore.isItemInCart(productDetailNew!.id.validate()) ? appLocalization.translate('lbl_remove_cart')!.toUpperCase() : appLocalization.translate('lbl_add_to_basket')!.toUpperCase() : appLocalization.translate('lbl_sold_out')!.toUpperCase(),
                  textAlign: TextAlign.center, style: boldTextStyle(color: white, wordSpacing: 1, size: 14))])))) : const SizedBox.shrink();

    // ── Price ─────────────────────────────────────────────────
    Widget mGetPrice() {
      if (productDetailNew == null) return const SizedBox.shrink();
      return productDetailNew!.onSale == true
          ? Row(children: [
        Text('${appLocalization.translate('lbl_mrp')!} : ', style: primaryTextStyle(color: context.iconColor)), 4.width,
        PriceWidget(price: productDetailNew!.salePrice.toString().isNotEmpty ? double.parse(productDetailNew!.salePrice.toString()).toStringAsFixed(2) : double.parse(productDetailNew!.price.toString()).toStringAsFixed(2), size: 18),
        PriceWidget(price: double.parse(productDetailNew!.regularPrice.toString()).toStringAsFixed(2), size: 12, color: Theme.of(context).textTheme.titleMedium!.color, isLineThroughEnabled: true).paddingOnly(left: 4).visible(productDetailNew!.salePrice.toString().isNotEmpty && productDetailNew!.onSale == true),
        8.width, Container(width: 1, height: 12, color: gray), 8.width,
        _mDiscount(context).visible(productDetailNew!.salePrice.toString().isNotEmpty && productDetailNew!.onSale == true),
      ])
          : Row(children: [Text('${appLocalization.translate('lbl_mrp')!} : ', style: primaryTextStyle(color: context.iconColor)), 4.width, PriceWidget(price: double.parse(productDetailNew!.price.toString()).toStringAsFixed(2), size: 18)]);
    }

    Widget mSavePrice() {
      if (productDetailNew?.onSale != true) return const SizedBox.shrink();
      final saved = double.parse(productDetailNew!.regularPrice.toString()) - double.parse(productDetailNew!.price.toString());
      if (saved <= 0) return const SizedBox.shrink();
      return Row(children: [Text('${appLocalization.translate('lbl_save')!} : ', style: secondaryTextStyle()), PriceWidget(price: saved.toStringAsFixed(2), size: 16, color: greenColor)]).paddingOnly(top: 4, left: 12, right: 8);
    }

    // ── Body ──────────────────────────────────────────────────
    final body = productDetailNew != null ? Stack(children: [SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (productDetailNew!.images!.isNotEmpty) productDetailNew!.woofVideoEmbed != null && productDetailNew!.woofVideoEmbed!.url != '' ? videoSlider : imgSlider,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(productDetailNew!.name!, style: boldTextStyle(size: 18)).paddingOnly(left: 12, right: 12).expand(),
          if (productDetailNew!.onSale == true) FittedBox(child: Container(padding: const EdgeInsets.fromLTRB(6, 2, 6, 2), alignment: Alignment.center, decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomRight: Radius.circular(8))), child: Text(appLocalization.translate('lbl_sale')!, style: boldTextStyle(color: Colors.white, size: 14))).cornerRadiusWithClipRRectOnly(topLeft: 0, bottomLeft: 4).paddingOnly(left: 12, right: 12, bottom: 8)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (productDetailNew!.type != 'grouped') mGetPrice(),
          FittedBox(child: Container(decoration: boxDecorationWithRoundedCorners(backgroundColor: Theme.of(context).cardTheme.color!, border: Border.all(color: view_color)), padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), margin: const EdgeInsets.only(right: 16),
              child: RichText(text: TextSpan(children: [TextSpan(text: '${rating.toStringAsFixed(1)} ', style: secondaryTextStyle(size: 12)), const WidgetSpan(child: Icon(Icons.star, size: 14, color: bgCardColor))])))).onTap(() async { await ReviewScreen(mProductId: widget.mProId, productName: productDetailNew?.name, productImage: productDetailNew?.images?.isNotEmpty == true ? productDetailNew!.images![0].src : null).launch(context); await fetchReviewData(); setState(() {}); }).visible(productDetailNew!.reviewsAllowed == true),
        ]).paddingOnly(top: 4, left: 12).visible(!productDetailNew!.type!.contains("grouped")),
        if (productDetailNew!.type != 'grouped') mSavePrice(),
        if (productDetailNew!.store != null && productDetailNew!.store!.shopName.validate().isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [Text(appLocalization.translate('lbl_vendor')!, style: primaryTextStyle(color: Theme.of(context).textTheme.titleMedium!.color)), 8.width, Text(productDetailNew!.store!.shopName ?? '', style: boldTextStyle(color: primaryColor))]),
            8.width, Icon(Icons.arrow_forward_ios_outlined, color: context.iconColor, size: 16),
          ]).paddingOnly(left: 12, right: 16, top: 8).onTap(() => VendorProfileScreen(mVendorId: productDetailNew!.store!.id).launch(context)),
        if (productDetailNew!.onSale! && productDetailNew!.dateOnSaleFrom!.isNotEmpty) _mSpecialPrice(appLocalization.translate('lbl_special_msg')),
        if (productDetailNew!.type == "variable" || productDetailNew!.type == "variation")
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.scale_outlined, size: 16, color: primaryColor), 6.width, Text(appLocalization.translate('lbl_possible')!, style: boldTextStyle(size: 14)), 6.width,
              if (mSelectedVariation?.isNotEmpty == true) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: boxDecorationWithRoundedCorners(backgroundColor: primaryColor!.withOpacity(0.1), borderRadius: radius(12)), child: Text(mSelectedVariation!, style: boldTextStyle(color: primaryColor, size: 12)))]).paddingOnly(left: 12, right: 12, top: 12, bottom: 4),
            Wrap(spacing: 8, runSpacing: 8, children: mProductOptions.map((e) { final idx = mProductOptions.indexOf(e); final selected = selectedOptionAvailableIn == idx; return GestureDetector(onTap: () { setState(() { mSelectedVariation = e; selectedOptionAvailableIn = idx; for (final p in mProducts) { if (mProductVariationsIds[idx] == p.id) productDetailNew = p; } _setPriceDetail(); _mImage(); }); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: selected ? primaryColor : context.cardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: selected ? primaryColor! : grey.withOpacity(0.4), width: selected ? 2 : 1), boxShadow: selected ? [BoxShadow(color: primaryColor!.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : []), child: Row(mainAxisSize: MainAxisSize.min, children: [if (selected) ...[const Icon(Icons.check_circle, size: 14, color: white).paddingOnly(left: 4), 4.width], Text(e!, style: boldTextStyle(color: selected ? white : textSecondaryColour, size: 13))]))); }).toList()).paddingOnly(left: 12, right: 12, top: 4, bottom: 8),
            Divider(thickness: 1, color: grey.withOpacity(0.2)).paddingOnly(top: 4),
          ]).visible(mProductOptions.isNotEmpty)
        else if (productDetailNew!.type == "grouped") mGroupAttribute(product)
        else if (productDetailNew!.type == "external") Builder(builder: (_) { mIsExternalProduct = true; mExternalUrl = productDetailNew!.externalUrl.toString(); _setPriceDetail(); return const SizedBox.shrink(); })
          else if (productDetailNew!.type != "simple") Builder(builder: (_) { mOtherAttribute(); return const SizedBox.shrink(); }),
        mUpcomingSale().visible(!productDetailNew!.onSale!),
        // Description - يعرض وصف المنتج الرئيسي إن وُجد
        Text(appLocalization.translate('lbl_product_details')!, style: boldTextStyle()).paddingOnly(left: 12, right: 12, top: 8).visible(displayDescription.isNotEmpty),
        HtmlWidget(postContent: displayDescription.toString().trim()).paddingOnly(right: 6, left: 6).visible(displayDescription.isNotEmpty),
        _mSetAttribute().paddingBottom(8).visible(productDetailNew!.attributes!.isNotEmpty),
        // Short description - يعرض الوصف المختصر من المنتج الرئيسي إن وُجد
        Text(appLocalization.translate('lbl_short_description')!, style: boldTextStyle()).paddingOnly(top: 8, left: 12, right: 12).visible(displayShortDescription.toString().isNotEmpty),
        HtmlWidget(postContent: displayShortDescription).paddingOnly(left: 6, right: 6).visible(displayShortDescription.toString().isNotEmpty),
        Text(appLocalization.translate('lbl_shop_category')!, style: boldTextStyle()).paddingOnly(left: 12, right: 12, top: 8).visible(productDetailNew!.categories!.isNotEmpty),
        4.height.visible(productDetailNew!.categories!.isNotEmpty),
        Wrap(children: productDetailNew!.categories!.map((e) => Container(margin: const EdgeInsets.only(right: 8, left: 6, top: 8, bottom: 8), padding: const EdgeInsets.all(8), decoration: boxDecorationWithRoundedCorners(backgroundColor: context.cardColor, border: Border.all(width: 0.1)), child: Text(e.name!, style: secondaryTextStyle())).onTap(() => ViewAllScreen(e.name, isCategory: true, categoryId: e.id).launch(context))).toList()).paddingOnly(left: 8, right: 8).visible(productDetailNew!.categories!.isNotEmpty),
        if (productDetailNew!.upSellId?.isNotEmpty == true) upSaleProductList(productDetailNew!.upSellId!),
        8.height,
        reviewWidget(),
        16.height,
      ]),
    ]))]) : const SizedBox.shrink();

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(elevation: 0, backgroundColor: primaryColor, leading: IconButton(icon: const Icon(Icons.arrow_back, color: white), onPressed: () { finish(context); appStore.setLoading(false); }), actions: [mCart(context, mIsLoggedIn, color: white)], title: Text(productDetailNew?.name ?? ' ', style: boldTextStyle(color: Colors.white, size: 18)), automaticallyImplyLeading: false),
      body: Observer(builder: (_) => BodyCornerWidget(child: mView(Stack(alignment: Alignment.bottomLeft, children: [productDetailNew != null ? body : const SizedBox.shrink(), Center(child: mProgress()).visible(appStore.isLoading)]), context))),
      bottomNavigationBar: productDetailNew != null ? Container(width: context.width(), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Theme.of(context).hoverColor.withOpacity(0.8), blurRadius: 15.0, offset: const Offset(0.0, 0.75))]),
          child: Row(children: [mFavourite, 16.width, mCartData.expand(flex: 1)]).paddingOnly(top: 8, bottom: 8, right: 16, left: 16).visible(!mIsGroupedProduct)) : null,
    );
  }
}
