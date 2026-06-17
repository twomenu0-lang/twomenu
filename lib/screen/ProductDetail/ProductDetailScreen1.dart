import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import '/../component/HtmlWidget.dart';
import '/../component/VideoPlayDialog.dart';
import '/../main.dart';
import '/../models/ProductDetailResponse.dart';
import '/../models/ProductReviewModel.dart';
import '/../network/rest_apis.dart';
import '/../screen/ProductDetail/ProductDetailScreen2.dart';
import '/../screen/ViewAllScreen.dart';
import '/../screen/ZoomImageScreen.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/Countdown.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Colors.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../AppLocalizations.dart';
import '../ReviewScreen.dart';
import '../SignInScreen.dart';
import '../VendorProfileScreen.dart';
import '../WebViewExternalProductScreen.dart';
import 'ProductDetailScreen3.dart';

class ProductDetailScreen1 extends StatefulWidget {
  final int? mProId;
  const ProductDetailScreen1({Key? key, this.mProId}) : super(key: key);

  @override
  _ProductDetailScreen1State createState() => _ProductDetailScreen1State();
}

class _ProductDetailScreen1State extends State<ProductDetailScreen1> {
  ProductDetailResponse? productDetailNew;
  ProductDetailResponse? mainProduct; // المنتج الرئيسي

  List<ProductDetailResponse> mProducts      = [];
  List<ProductReviewModel>    mReviewModel   = [];
  List<ProductDetailResponse> mProductsList  = [];
  List<String?>               mProductOptions      = [];
  List<int>                   mProductVariationsIds = [];
  List<ProductDetailResponse> product        = [];
  List<Widget>                productImg     = [];
  List<String?>               productImg1    = [];

  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  final PageController _pageController = PageController(initialPage: 0);

  // ✅ Timer مع مرجع عشان نوقفه في dispose
  Timer? _bannerTimer;

  bool   mIsExternalProduct  = false;
  num    rating               = 0.0;
  double discount             = 0.0;
  int    selectIndex          = 0;
  int    _currentPage         = 0;
  String videoType            = '';
  String? mSelectedVariation  = '';
  String mExternalUrl         = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  void _startTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _currentPage = _currentPage < 2 ? _currentPage + 1 : 0;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    });
  }

  void init() {
    afterBuildCreated(() async {
      // ✅ تحميل التفاصيل والـ reviews بالتوازي — أسرع بكتير من التسلسل
      await Future.wait([
        productDetail(),
        fetchReviewData(),
      ]);
      _startTimer();
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel(); // ✅ كان memory leak في النسخة القديمة
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
      mProducts = mInfo.map((model) => ProductDetailResponse.fromJson(model)).toList();

      if (mProducts.isEmpty) return;

      productDetailNew = mProducts[0];
      mainProduct = mProducts[0]; // احفظ المنتج الرئيسي
      rating = double.tryParse(mProducts[0].averageRating ?? '0') ?? 0.0;

      // Variations IDs
      productDetailNew!.variations!.forEach((e) => mProductVariationsIds.add(e));

      // Related products (index > 0)
      mProductsList
        ..clear()
        ..addAll(mProducts.skip(1));

      final type = productDetailNew!.type;

      if (type == "variable" || type == "variation") {
        mProductOptions.clear();
        for (final p in mProductsList) {
          var option = p.attributes!
              .map((a) => a.option.validate())
              .where((o) => o.isNotEmpty)
              .join(' - ');
          if (p.onSale!) option = '$option [Sale]';
          mProductOptions.add(option);
        }

        if (mProductOptions.isNotEmpty &&
            (mSelectedVariation == null || mSelectedVariation!.isEmpty)) {
          mSelectedVariation = mProductOptions.first;
        }

        if (mProductsList.isNotEmpty) {
          int idx = mSelectedVariation!.isNotEmpty
              ? mProductOptions.indexOf(mSelectedVariation)
              : 0;
          if (idx < 0) idx = 0;
          productDetailNew = mProductsList[idx];
        }
      } else if (type == 'grouped') {
        product
          ..clear()
          ..addAll(mProductsList);
      }

      // Video
      if (productDetailNew!.woofVideoEmbed?.url?.isNotEmpty == true) {
        final url = productDetailNew!.woofVideoEmbed!.url.validate();
        if (url.contains(VideoTypeYouTube)) {
          videoType = VideoTypeYouTube;
        } else if (url.contains(VideoTypeIFrame)) {
          videoType = VideoTypeIFrame;
        } else {
          videoType = VideoTypeCustom;
        }
        productImg.add(
          Stack(
            fit: StackFit.expand,
            children: [
              commonCacheImageWidget(
                productDetailNew!.images![0].src.validate(),
                fit: BoxFit.cover,
                height: 400,
                width: double.infinity,
              ).cornerRadiusWithClipRRectOnly(topLeft: 20, topRight: 20).paddingOnly(bottom: 24),
              const Icon(Icons.play_circle_fill_outlined, size: 40, color: Colors.black12).center(),
            ],
          ).onTap(() {
            VideoPlayDialog(data: productDetailNew!.woofVideoEmbed).launch(context);
          }),
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
    } catch (_) {
      appStore.setLoading(false);
    }
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
      final mrp      = double.parse(productDetailNew!.regularPrice!);
      final salePrice = double.parse(productDetailNew!.price!);
      discount = ((mrp - salePrice) / mrp) * 100;
    }
  }

  void _mImage() {
    productImg1
      ..clear()
      ..addAll(productDetailNew!.images!.map((e) => e.src));
  }

  String? get _productImageUrl =>
      (productDetailNew?.images?.isNotEmpty == true)
          ? productDetailNew!.images![0].src
          : null;

  String getAllAttribute(Attribute attribute) =>
      attribute.options!.join(', ');

  void mOtherAttribute() {
    toast('Product type not supported');
    finish(context);
  }

  // ─────────────────────────────────────────────────────────────
  // SUB WIDGETS
  // ─────────────────────────────────────────────────────────────
  Widget _mDiscount() {
    if (productDetailNew!.onSale!) {
      return Text(
        "(${discount.toInt()} % ${AppLocalizations.of(context)!.translate('lbl_off1')!})",
        style: primaryTextStyle(color: Colors.red),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _mSetAttribute() {
    return AnimatedListView(
      itemCount: productDetailNew!.attributes!.length,
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemBuilder: (context, i) {
        final attr = productDetailNew!.attributes![i];
        return attr.options != null
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${attr.name} : ', style: boldTextStyle(size: 14))
                .visible(attr.options!.isNotEmpty),
            4.height,
            Text(getAllAttribute(attr), maxLines: 4, style: secondaryTextStyle()).expand(),
          ],
        ).paddingOnly(left: 8)
            : const SizedBox.shrink();
      },
    );
  }

  Widget _mSpecialPrice(String? value) {
    if (productDetailNew?.dateOnSaleTo?.isNotEmpty != true) return const SizedBox.shrink();
    final endTime  = '${productDetailNew!.dateOnSaleTo} 23:59:59.000';
    final endDate  = DateFormat('yyyy-MM-dd HH:mm:ss').parse(endTime);
    final now      = DateTime.now();
    final format   = endDate.subtract(Duration(
      days: now.day, hours: now.hour,
      minutes: now.minute, seconds: now.second,
    ));
    return Countdown(
      duration: Duration(
        days: format.day, hours: format.hour,
        minutes: format.minute, seconds: format.second,
      ),
      onFinish: () => log('countdown finished'),
      builder: (BuildContext ctx, Duration? remaining) {
        final sec  = ((remaining!.inMilliseconds / 1000) % 60).toInt();
        final min  = ((remaining.inMilliseconds / (1000 * 60)) % 60).toInt();
        final hrs  = ((remaining.inMilliseconds / (1000 * 60 * 60)) % 24).toInt();
        return Container(
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radius(4),
            backgroundColor: colorAccent!.withOpacity(0.3),
          ),
          child: Text(
            '$value ${remaining.inDays}d ${hrs}h ${min}m ${sec}s',
            style: primaryTextStyle(),
          ).paddingAll(8),
        ).paddingOnly(left: 16, right: 16, top: 16, bottom: 16);
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

    // ── Upcoming Sale ─────────────────────────────────────────
    Widget mUpcomingSale() {
      if (productDetailNew?.dateOnSaleFrom?.isEmpty != false) return const SizedBox.shrink();
      final diff = DateTime.parse(productDetailNew!.dateOnSaleFrom.validate())
          .difference(DateTime.now())
          .inMilliseconds;
      if (diff <= 0) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(thickness: 6, color: appStore.isDarkMode! ? white.withOpacity(0.2) : Theme.of(context).textTheme.headlineMedium!.color),
          Text(appLocalization.translate('lbl_upcoming_sale_on_this_item')!, style: boldTextStyle()).paddingAll(16),
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            decoration: boxDecorationWithRoundedCorners(borderRadius: radius(8), backgroundColor: primaryColor!.withOpacity(0.2)),
            width: context.width(),
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: Marquee(
              directionMarguee: DirectionMarguee.oneDirection,
              child: Text(
                '${appLocalization.translate('lbl_sale_start_from')!} ${productDetailNew!.dateOnSaleFrom!} '
                    '${appLocalization.translate('lbl_to')!} ${productDetailNew!.dateOnSaleTo!}. '
                    '${appLocalization.translate('lbl_ge_amazing_discounts_on_the_products')!}',
                style: secondaryTextStyle(color: Theme.of(context).textTheme.titleSmall!.color, size: 16),
              ).paddingLeft(16),
            ),
          ),
        ],
      );
    }

    // ── Reviews ───────────────────────────────────────────────
    Widget reviewWidget() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appLocalization.translate("lbl_customer_review")!, style: boldTextStyle())
              .paddingOnly(top: 8, bottom: 8, left: 16, right: 16)
              .visible(mReviewModel.isNotEmpty),
          ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mReviewModel.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final r = mReviewModel[index];
              final ratingColor = r.rating == 1 || r.rating == 2 || r.rating == 3
                  ? yellowColor
                  : const Color(0xFF66953A);
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.rating == 1 ? redColor : ratingColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(r.rating.toString(), style: primaryTextStyle(color: whiteColor, size: 12)),
                          4.width,
                          const Icon(Icons.star_border, size: 14, color: whiteColor),
                        ],
                      ),
                    ),
                    8.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.reviewer!, style: boldTextStyle()),
                            Container(height: 10, color: Theme.of(context).textTheme.titleMedium!.color, width: 2, margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Text(reviewConvertDate(r.dateCreated), style: secondaryTextStyle()),
                          ],
                        ).visible(r.reviewer != null),
                        5.height,
                        Text(parseHtmlString(r.review), style: primaryTextStyle()),
                      ],
                    ).expand(),
                  ],
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appLocalization.translate("lbl_view_all_customer_review")!, style: boldTextStyle(color: context.accentColor)),
              const Icon(Icons.chevron_right),
            ],
          ).onTap(() {
            ReviewScreen(mProductId: widget.mProId, productName: productDetailNew?.name, productImage: _productImageUrl).launch(context);
          }).paddingAll(16).visible(mReviewModel.length >= 5 && productDetailNew!.reviewsAllowed == true),
        ],
      );
    }

    // ── Upsell Products ───────────────────────────────────────
    Widget upSaleProductList(List<UpsellId> ups) {
      final w = context.width();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          8.height,
          Text(builderResponse.dashboard!.youMayLikeProduct!.title!, style: boldTextStyle()).paddingLeft(16),
          SizedBox(
            height: 233,
            child: AnimatedListView(
              itemCount: ups.length,
              shrinkWrap: true,
              padding: const EdgeInsets.only(left: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: boxDecorationWithRoundedCorners(borderRadius: radius(8), backgroundColor: Theme.of(context).colorScheme.surface),
                        child: commonCacheImageWidget(ups[i].images!.first.src, height: 150, width: w, fit: BoxFit.cover).cornerRadiusWithClipRRect(8),
                      ),
                      4.height,
                      Text(ups[i].name!, style: primaryTextStyle(size: 14), maxLines: 2),
                      8.height,
                      Row(
                        children: [
                          PriceWidget(price: ups[i].salePrice.toString().isNotEmpty ? ups[i].salePrice.toString() : ups[i].price.toString(), size: 14),
                          4.width,
                          PriceWidget(price: ups[i].regularPrice.toString(), size: 12, isLineThroughEnabled: true, color: Theme.of(context).textTheme.titleSmall!.color)
                              .visible(ups[i].salePrice.toString().isNotEmpty),
                        ],
                      ),
                    ],
                  ),
                ).onTap(() {
                  final variant = getIntAsync(PRODUCT_DETAIL_VARIANT, defaultValue: 1);
                  if (variant == 2) ProductDetailScreen2(mProId: ups[i].id).launch(context);
                  else if (variant == 3) ProductDetailScreen3(mProId: ups[i].id).launch(context);
                  else ProductDetailScreen1(mProId: ups[i].id).launch(context);
                });
              },
            ),
          ),
        ],
      );
    }

    // ── Grouped Attribute ─────────────────────────────────────
    Widget mGroupAttribute(List<ProductDetailResponse> grp) {
      return Observer(builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(thickness: 6, color: appStore.isDarkMode! ? white.withOpacity(0.2) : Theme.of(context).textTheme.headlineMedium!.color),
            Text(appLocalization.translate('lbl_product_include')!, style: boldTextStyle()).paddingOnly(left: 16, top: 8),
            AnimatedListView(
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: grp.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () {
                    final v = getIntAsync(PRODUCT_DETAIL_VARIANT, defaultValue: 1);
                    if (v == 2) ProductDetailScreen2(mProId: grp[i].id).launch(context);
                    else if (v == 3) ProductDetailScreen3(mProId: grp[i].id).launch(context);
                    else ProductDetailScreen1(mProId: grp[i].id).launch(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.only(right: 8, bottom: 8, top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        commonCacheImageWidget(grp[i].images![0].src, height: 85, width: 85, fit: BoxFit.cover).cornerRadiusWithClipRRect(8),
                        4.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(grp[i].name!, style: boldTextStyle()).paddingOnly(left: 8, right: 8),
                            16.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: boxDecorationWithRoundedCorners(
                                    borderRadius: radius(8),
                                    backgroundColor: grp[i].inStock == true ? primaryColor! : white,
                                    border: Border.all(color: primaryColor!),
                                  ),
                                  child: Text(
                                    grp[i].inStock! == true
                                        ? grp[i].type! == 'external' ? grp[i].buttonText!
                                        : cartStore.isItemInCart(grp[i].id.validate())
                                        ? appLocalization.translate('lbl_remove_cart')!.toUpperCase()
                                        : appLocalization.translate('lbl_add_to_cart')!.toUpperCase()
                                        : appLocalization.translate('lbl_sold_out')!.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: boldTextStyle(color: grp[i].inStock == false ? primaryColor : white, size: 12),
                                  ),
                                ).onTap(() {
                                  if (grp[i].inStock == true) {
                                    if (grp[i].type == 'external') {
                                      WebViewExternalProductScreen(mExternal_URL: mExternalUrl, title: appLocalization.translate('lbl_external_product')).launch(context);
                                    } else if (!getBoolAsync(IS_LOGGED_IN)) {
                                      SignInScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                                    } else {
                                      addCart(data: grp[i]);
                                      init();
                                      setState(() {});
                                    }
                                  }
                                }),
                                grp[i].onSale!
                                    ? Row(children: [
                                  PriceWidget(price: grp[i].salePrice.toString().isNotEmpty ? grp[i].salePrice.toString() : grp[i].price.toString(), size: 16),
                                  2.width,
                                  PriceWidget(price: grp[i].regularPrice.toString(), size: 12, isLineThroughEnabled: true, color: Theme.of(context).textTheme.titleSmall!.color)
                                      .visible(grp[i].salePrice.toString().isNotEmpty),
                                ])
                                    : PriceWidget(price: double.parse(grp[i].price.toString()).toStringAsFixed(2), size: 18),
                              ],
                            ).paddingOnly(left: 8),
                          ],
                        ).expand(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      });
    }

    // ── Image / Video Sliders ─────────────────────────────────
    final dividerColor = appStore.isDarkMode! ? white.withOpacity(0.2) : Theme.of(context).textTheme.headlineMedium!.color;

    final videoSlider = productDetailNew != null
        ? Container(
      height: 450, width: context.width(),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(children: [
        PageView(controller: _pageController, children: productImg, onPageChanged: (i) { selectIndex = i; setState(() {}); }),
        AnimatedPositioned(duration: const Duration(seconds: 1), bottom: 0, left: 0, right: 0,
            child: DotIndicator(pages: productImg, indicatorColor: primaryColor, pageController: _pageController)),
      ]),
    )
        : const SizedBox.shrink();

    final imgSlider = productDetailNew != null
        ? Container(
      height: 450, width: context.width(),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20)),
        backgroundColor: context.cardColor,
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(children: [
        PageView(
          controller: _pageController,
          onPageChanged: (i) { selectIndex = i; setState(() {}); },
          children: productImg1.map((i) {
            return commonCacheImageWidget(i.validate(), fit: BoxFit.cover, height: 400, width: double.infinity)
                .cornerRadiusWithClipRRectOnly(topLeft: 20, topRight: 20)
                .paddingOnly(bottom: 24)
                .onTap(() => ZoomImageScreen(mImgList: productDetailNew!.images, ind: selectIndex).launch(context));
          }).toList(),
        ),
        AnimatedPositioned(duration: const Duration(seconds: 1), bottom: 0, left: 0, right: 0,
            child: DotIndicator(pages: productImg1, indicatorColor: primaryColor, pageController: _pageController)),
      ]),
    )
        : const SizedBox.shrink();

    // ── Favourite & Cart Buttons ──────────────────────────────
    final mFavourite = productDetailNew != null
        ? Observer(builder: (_) {
      return GestureDetector(
        onTap: () {
          if (productDetailNew!.type! == 'external') {
            toast(appLocalization.translate('lbl_external_wishlist_msg')!);
          } else {
            checkWishList(productDetailNew, context);
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: boxDecorationWithRoundedCorners(borderRadius: radius(8), backgroundColor: Theme.of(context).cardTheme.color!, border: Border.all(color: primaryColor!)),
          child: Text(
            wishListStore.isItemInWishlist(productDetailNew!.id!) == false
                ? appLocalization.translate('lbl_wish_list')!.toUpperCase()
                : appLocalization.translate('lbl_wishlisted')!.toUpperCase(),
            textAlign: TextAlign.center,
            style: boldTextStyle(color: primaryColor, wordSpacing: 2),
          ),
        ),
      ).paddingOnly(bottom: 4).visible(productDetailNew!.isAddedWishList != null);
    })
        : const SizedBox.shrink();

    final mCartData = productDetailNew != null
        ? Observer(builder: (_) {
      final inCart = cartStore.isItemInCart(productDetailNew!.id.validate());
      return GestureDetector(
        onTap: () {
          if (productDetailNew!.inStock == true) {
            if (mIsExternalProduct) {
              WebViewExternalProductScreen(mExternal_URL: mExternalUrl, title: appLocalization.translate('lbl_external_product')).launch(context);
            } else if (!getBoolAsync(IS_LOGGED_IN)) {
              SignInScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
            } else {
              addCart(data: productDetailNew!);
              init();
              setState(() {});
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radius(8),
            backgroundColor: productDetailNew!.inStock! ? (inCart ? Theme.of(context).cardTheme.color! : primaryColor!) : textSecondaryColorGlobal.withOpacity(0.3),
            border: Border.all(color: inCart ? primaryColor! : Colors.transparent),
          ),
          child: Text(
            productDetailNew!.inStock! == true
                ? productDetailNew!.type! == 'external' ? productDetailNew!.buttonText!
                : inCart ? appLocalization.translate('lbl_remove_cart')!.toUpperCase()
                : appLocalization.translate('lbl_add_to_cart')!.toUpperCase()
                : appLocalization.translate('lbl_sold_out')!.toUpperCase(),
            textAlign: TextAlign.center,
            style: boldTextStyle(color: inCart ? primaryColor : white, wordSpacing: 2),
          ),
        ),
      );
    })
        : const SizedBox.shrink();

    // ── Price Widgets ─────────────────────────────────────────
    Widget mGetPrice() {
      if (productDetailNew == null) return const SizedBox.shrink();
      return productDetailNew!.onSale == true
          ? Row(children: [
        PriceWidget(
          price: productDetailNew!.salePrice.toString().isNotEmpty
              ? double.parse(productDetailNew!.salePrice.toString()).toStringAsFixed(2)
              : double.parse(productDetailNew!.price.validate().toString()).toStringAsFixed(2),
          size: 18,
        ),
        PriceWidget(price: double.parse(productDetailNew!.regularPrice.toString()).toStringAsFixed(2), size: 14, color: Theme.of(context).textTheme.titleMedium!.color, isLineThroughEnabled: true)
            .visible(productDetailNew!.salePrice.toString().isNotEmpty && productDetailNew!.onSale == true),
        8.width,
        _mDiscount().visible(productDetailNew!.salePrice.toString().isNotEmpty && productDetailNew!.onSale == true),
      ])
          : Row(children: [PriceWidget(price: double.parse(productDetailNew!.price.toString()).toStringAsFixed(2), size: 18)]);
    }

    Widget mSavePrice() {
      if (productDetailNew?.onSale != true) return const SizedBox.shrink();
      final saved = double.parse(productDetailNew!.regularPrice.toString()) - double.parse(productDetailNew!.price.toString());
      if (saved <= 0) return const SizedBox.shrink();
      return Row(children: [
        Text('${appLocalization.translate('lbl_you_saved')!} ', style: secondaryTextStyle(size: 16, color: Colors.green)),
        PriceWidget(price: saved.toStringAsFixed(2), size: 18, color: Colors.green),
      ]).paddingOnly(top: 4, left: 16, right: 8);
    }

    // ── Main Body ─────────────────────────────────────────────
    final body = productDetailNew != null
        ? SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Video
          if (productDetailNew!.images!.isNotEmpty)
            productDetailNew!.woofVideoEmbed != null && !productDetailNew!.woofVideoEmbed!.url.isEmptyOrNull
                ? videoSlider
                : imgSlider,

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              8.height,
              if (productDetailNew!.onSale == true)
                FittedBox(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                    decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: Text(appLocalization.translate('lbl_sale')!, style: boldTextStyle(color: Colors.white, size: 12)),
                  ).cornerRadiusWithClipRRectOnly(topLeft: 0, bottomLeft: 4).paddingOnly(left: 16, right: 16, bottom: 8),
                ),

              Text(productDetailNew!.name!, style: boldTextStyle(size: 18)).paddingOnly(left: 16, right: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (productDetailNew!.type != 'grouped') mGetPrice(),
                  FittedBox(
                    child: Container(
                      decoration: boxDecorationWithRoundedCorners(borderRadius: radius(4), backgroundColor: Theme.of(context).cardTheme.color!, border: Border.all(color: view_color)),
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 8),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(text: '${(rating as double).toStringAsFixed(1)} ', style: secondaryTextStyle(size: 14)),
                          const WidgetSpan(child: Icon(Icons.star, size: 14, color: yellowColor)),
                        ]),
                      ),
                    ),
                  ).onTap(() async {
                    await ReviewScreen(mProductId: widget.mProId, productName: productDetailNew?.name, productImage: _productImageUrl).launch(context);
                    await fetchReviewData();
                    setState(() {});
                  }),
                ],
              ).paddingOnly(top: 4, left: 16, right: 8, bottom: 4).visible(!productDetailNew!.type!.contains("grouped")),

              if (productDetailNew!.type != 'grouped') mSavePrice(),

              // Vendor
              if (productDetailNew!.store != null && productDetailNew!.store!.shopName.validate().isNotEmpty) ...[
                Divider(thickness: 6, color: dividerColor),
                Row(children: [
                  Text(appLocalization.translate('lbl_sold_by')!, style: primaryTextStyle(size: 14, color: Theme.of(context).textTheme.titleMedium!.color)),
                  8.width,
                  Text(productDetailNew!.store!.shopName ?? '', style: boldTextStyle(color: primaryColor))
                      .onTap(() => VendorProfileScreen(mVendorId: productDetailNew!.store!.id).launch(context)),
                ]).paddingOnly(top: 8, left: 16, right: 8, bottom: 8),
              ],

              // Sale countdown
              if (productDetailNew!.onSale! && productDetailNew!.dateOnSaleFrom!.isNotEmpty)
                Divider(thickness: 6, color: dividerColor),
              if (productDetailNew!.onSale! && productDetailNew!.dateOnSaleFrom!.isNotEmpty)
                _mSpecialPrice(appLocalization.translate('lbl_special_msg')),

              // Variations
              if (productDetailNew!.type == "variable" || productDetailNew!.type == "variation")
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(thickness: 6, color: dividerColor),
                    Row(children: [
                      Icon(Icons.scale_outlined, size: 16, color: primaryColor),
                      6.width,
                      Text(appLocalization.translate('lbl_possible')!, style: boldTextStyle(size: 14)),
                      6.width,
                      if (mSelectedVariation?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: boxDecorationWithRoundedCorners(backgroundColor: primaryColor!.withOpacity(0.1), borderRadius: radius(12)),
                          child: Text(mSelectedVariation!, style: boldTextStyle(color: primaryColor, size: 12)),
                        ),
                    ]).paddingOnly(left: 16, right: 16, top: 12, bottom: 4),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: mProductOptions.map((e) {
                        final idx      = mProductOptions.indexOf(e);
                        final selected = mSelectedVariation == e;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              mSelectedVariation = e;
                              for (final p in mProducts) {
                                if (mProductVariationsIds[idx] == p.id) productDetailNew = p;
                              }
                              _setPriceDetail();
                              _mImage();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? primaryColor : context.cardColor,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: selected ? primaryColor! : grey.withOpacity(0.4), width: selected ? 2 : 1),
                              boxShadow: selected ? [BoxShadow(color: primaryColor!.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selected) ...[const Icon(Icons.check_circle, size: 14, color: white).paddingOnly(left: 4), 4.width],
                                Text(e!, style: boldTextStyle(color: selected ? white : textSecondaryColour, size: 13)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ).paddingOnly(left: 16, right: 16, top: 4, bottom: 8),
                    Divider(thickness: 1, color: grey.withOpacity(0.2)).paddingOnly(top: 4),
                  ],
                ).visible(mProductOptions.isNotEmpty)
              else if (productDetailNew!.type == "grouped")
                mGroupAttribute(product)
              else if (productDetailNew!.type == "external")
                  Builder(builder: (_) { mIsExternalProduct = true; mExternalUrl = productDetailNew!.externalUrl.toString(); _setPriceDetail(); return const SizedBox.shrink(); })
                else if (productDetailNew!.type != "simple")
                    Builder(builder: (_) { mOtherAttribute(); return const SizedBox.shrink(); }),

              mUpcomingSale().visible(!productDetailNew!.onSale!),

              // Description
              if ((mainProduct?.description?.isNotEmpty == true ? mainProduct!.description : productDetailNew!.description)!.isNotEmpty) ...[
                Divider(thickness: 6, color: dividerColor),
                Text(appLocalization.translate('lbl_product_details')!, style: boldTextStyle()).paddingOnly(top: 4, left: 16, right: 16),
                HtmlWidget(postContent: (mainProduct?.description?.isNotEmpty == true ? mainProduct!.description : productDetailNew!.description)).paddingOnly(left: 10),
              ],

              if (productDetailNew!.attributes != null) _mSetAttribute().paddingBottom(8),

              // Short description
              if ((mainProduct?.shortDescription?.isNotEmpty == true ? mainProduct!.shortDescription : productDetailNew!.shortDescription).toString().isNotEmpty) ...[
                Divider(thickness: 6, color: dividerColor),
                Text(appLocalization.translate('lbl_short_description')!, style: boldTextStyle()).paddingOnly(top: 4, left: 16, right: 16),
                HtmlWidget(postContent: (mainProduct?.shortDescription?.isNotEmpty == true ? mainProduct!.shortDescription : productDetailNew!.shortDescription)).paddingOnly(left: 10, right: 16),
              ],

              // Categories
              if (productDetailNew!.categories?.isNotEmpty == true) ...[
                Divider(thickness: 6, color: dividerColor),
                Text(appLocalization.translate('lbl_category')!, style: boldTextStyle()).paddingOnly(top: 4, left: 16, right: 16),
                Wrap(
                  children: productDetailNew!.categories!.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8, bottom: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: boxDecorationWithRoundedCorners(
                        borderRadius: radius(8),
                        backgroundColor: appStore.isDarkMode! ? white.withOpacity(0.2) : Theme.of(context).colorScheme.surface,
                      ),
                      child: Text(e.name!, style: secondaryTextStyle()),
                    ).onTap(() => ViewAllScreen(e.name, isCategory: true, categoryId: e.id).launch(context));
                  }).toList(),
                ).paddingOnly(top: 16, left: 16, right: 16),
              ],

              // Upsell
              if (productDetailNew!.upSellId?.isNotEmpty == true) ...[
                Divider(thickness: 6, color: dividerColor),
                upSaleProductList(productDetailNew!.upSellId!),
              ],

              // Reviews
              if (mReviewModel.isNotEmpty) Divider(thickness: 6, color: dividerColor),
              8.height,
              reviewWidget(),
              40.height,
            ],
          ),
        ],
      ),
    )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: white),
          onPressed: () { finish(context, false); appStore.setLoading(false); },
        ),
        actions: [mCart(context, getBoolAsync(IS_LOGGED_IN), color: white)],
        title: Text(productDetailNew?.name ?? ' ', style: boldTextStyle(color: Colors.white, size: 18)),
        automaticallyImplyLeading: false,
      ),
      body: Observer(
        builder: (_) => BodyCornerWidget(
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              productDetailNew != null ? body : const SizedBox.shrink(),
              Center(child: mProgress()).visible(appStore.isLoading),
            ],
          ),
        ),
      ),
      bottomNavigationBar: productDetailNew != null
          ? Container(
        width: context.width(),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Theme.of(context).hoverColor.withOpacity(0.8), blurRadius: 15.0, offset: const Offset(0.0, 0.75))],
        ),
        child: Row(children: [mFavourite.expand(flex: 1), 16.width, mCartData.expand(flex: 1)])
            .paddingOnly(top: 8, bottom: 8, right: 16, left: 16)
            .visible(productDetailNew!.type != 'grouped'),
      )
          : null,
    );
  }
}
