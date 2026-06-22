import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import '/../component/HomeDataComponent.dart';
import '/../component/HomeScreenComponent2/DashBoard2Product.dart';
import '/../component/HomeScreenComponent2/DashboardComponent2.dart';
import '/../component/HomeScreenComponent2/VendorWidget2.dart';
import '/../main.dart';
import '/../models/ProductResponse.dart';
import '/../screen/SaleScreen.dart';
import '/../screen/SearchScreen.dart';
import '/../screen/ViewAllScreen.dart';
import '/../screen/WebViewExternalProductScreen.dart';
import '/../screen/SmartCategoryScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Colors.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../AppLocalizations.dart';
import '../../utils/AppBarWidget.dart';
import '/../utils/AppColors.dart';
import '/../screen/NotificationScreen.dart';

class HomeScreen2 extends StatefulWidget {
  static String tag = '/HomeScreen2';

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen2> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  final PageController salePageController   = PageController(initialPage: 0);
  final PageController bannerPageController = PageController(initialPage: 0);

  int _currentPage = 0;
  int selectIndex  = 0;

  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void init() {
    afterBuildCreated(() async {
      appStore.setLoading(true);
      setValue(CARTCOUNT, appStore.count);

      await Future.wait([
        fetchDashboardData(),
        fetchCategoryData(),
      ]);

      if (mounted) {
        setState(() {});
        _startBannerTimer();
      }
      appStore.setLoading(false);
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !bannerPageController.hasClients) return;
      _currentPage = (_currentPage < (mSliderModel.length - 1)) ? _currentPage + 1 : 0;
      bannerPageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    salePageController.dispose();
    bannerPageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // OFFER & DEAL WIDGET
  // ─────────────────────────────────────────────────────────────
  Widget _availableOfferAndDeal(
      String title,
      String subtitle,
      List<ProductResponse> product,
      BuildContext context,
      ) {
    return Stack(
      children: [
        Container(color: bgCardColor.withOpacity(0.6), height: 340),
        Column(
          children: [
            8.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 1.5, width: 24, color: context.iconColor),
                8.width,
                Text(title, style: GoogleFonts.alata(fontSize: 24, color: context.iconColor)).paddingOnly(left: 8),
                8.width,
                Container(height: 1.5, width: 24, color: context.iconColor),
              ],
            ).paddingSymmetric(vertical: 8),
            viewAll(() {
              final appLocalization = AppLocalizations.of(context)!;
              if (title == (appLocalization.translate('lbl_deal_of_the_day') ?? builderResponse.dashboard!.dealOfTheDay!.title)) {
                ViewAllScreen(title, isSpecialProduct: true, specialProduct: "deal_of_the_day").launch(context);
              } else if (title == (appLocalization.translate('lbl_available_offers') ?? builderResponse.dashboard!.offerProduct!.title)) {
                ViewAllScreen(title, isSpecialProduct: true, specialProduct: "offer").launch(context);
              } else {
                ViewAllScreen(title);
              }
            }, subtitle),
            HorizontalList(
              padding: const EdgeInsets.only(left: 12, right: 8),
              itemCount: product.length.clamp(0, 6),
              itemBuilder: (context, i) {
                return DashBoard2Product(
                  mProductModel: product[i],
                  width: context.width() * 0.45,
                  isHorizontal: true,
                );
              },
            ),
          ],
        ),
      ],
    ).paddingOnly(top: 8, bottom: 8);
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY
  // ─────────────────────────────────────────────────────────────
  Widget _category(BuildContext context) {
    if (mCategoryModel.isEmpty) return const SizedBox.shrink();
    return HorizontalList(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
      itemCount: mCategoryModel.length,
      itemBuilder: (BuildContext context, int index) {
        final cat = mCategoryModel[index];
        return GestureDetector(
          onTap: () => SmartCategoryScreen(
            categoryName: cat.name,
            categoryId: cat.id,
          ).launch(context),
          child: Container(
            width: context.width() * 0.2,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                cat.image != null
                    ? CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 36,
                  child: ClipOval(
                    child: commonCacheImageWidget(
                      cat.image!.src.validate(),
                      height: 72,
                      width: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    : CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage(ic_placeholder_logo),
                  radius: 36,
                ),
                8.height,
                Text(
                  parseHtmlString(cat.name),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: primaryTextStyle(size: 14),
                ).center(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CAROUSEL
  // ─────────────────────────────────────────────────────────────
  Widget _carousel(BuildContext context) {
    if (mSliderModel.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView(
            controller: bannerPageController,
            onPageChanged: (i) {
              selectIndex = i;
              _currentPage = i;
              setState(() {});
            },
            children: mSliderModel.map((i) {
              return Container(
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radius(10),
                  border: Border.all(color: textSecondaryColorGlobal.withOpacity(0.4)),
                ),
                margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: commonCacheImageWidget(
                  i.image.validate(),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRect(10),
              ).onTap(() {
                if (i.url!.isNotEmpty) {
                  WebViewExternalProductScreen(mExternal_URL: i.url, title: i.title).launch(context);
                } else {
                  toast(AppLocalizations.of(context)!.translate('lbl_attribute') ?? 'Sorry');
                }
              });
            }).toList(),
          ),
        ),
        8.height,
        DotIndicator(
          pageController: bannerPageController,
          pages: mSliderModel,
          indicatorColor: primaryColor,
          unselectedIndicatorColor: grey.withOpacity(0.2),
          currentBoxShape: BoxShape.rectangle,
          boxShape: BoxShape.rectangle,
          borderRadius: radius(2),
          currentBorderRadius: radius(3),
          currentDotSize: 18,
          currentDotWidth: 6,
          dotSize: 6,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SALE BANNER
  // ─────────────────────────────────────────────────────────────
  Widget _saleBannerWidget(BuildContext context, AppLocalizations appLocalization) {
    if (mSaleBanner.isEmpty) return const SizedBox.shrink();
    return AnimatedListView(
      itemCount: mSaleBanner.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemBuilder: (context, i) {
        final banner = mSaleBanner[i];
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 210,
              child: commonCacheImageWidget(
                banner.image.validate(),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ).paddingOnly(bottom: 20).onTap(() {
              SaleScreen(
                startDate: banner.startDate,
                endDate: banner.endDate,
                title: banner.title,
              ).launch(context);
            }),
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30),
              width: context.width(),
              padding: const EdgeInsets.all(8),
              decoration: boxDecorationRoundedWithShadow(8, backgroundColor: Theme.of(context).cardTheme.color!),
              child: Column(
                children: [
                  Text(banner.title!, style: boldTextStyle(color: primaryColor)),
                  2.height,
                  Text(
                    '${appLocalization.translate('lbl_sale_start_from')!} ${banner.startDate.validate()} to ${banner.endDate.validate()}',
                    style: secondaryTextStyle(size: 12),
                  ),
                ],
              ),
            ),
          ],
        ).paddingOnly(bottom: 16).visible(
          banner.title!.isNotEmpty && banner.image!.isNotEmpty,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;

    final dashboard = builderResponse.dashboard;
    if (dashboard == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget newProduct()     => DashboardComponent2(title: appLocalization.translate('lbl_new_collections') ?? dashboard.newProduct!.title!,       subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.newProduct!.viewAll!,       product: mNewestProductModel,    onTap: () => ViewAllScreen(dashboard.newProduct!.title,       isNewest: true).launch(context));
    Widget featureProduct() => DashboardComponent2(title: appLocalization.translate('lbl_featured_product') ?? dashboard.featureProduct!.title!,   subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.featureProduct!.viewAll!,   product: mFeaturedProductModel,  onTap: () => ViewAllScreen(dashboard.featureProduct!.title,   isFeatured: true).launch(context));
    Widget bestSelling()    => DashboardComponent2(title: appLocalization.translate('lbl_top_selling') ?? dashboard.bestSaleProduct!.title!,  subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.bestSaleProduct!.viewAll!,  product: mSellingProductModel,   onTap: () => ViewAllScreen(dashboard.bestSaleProduct!.title,  isBestSelling: true).launch(context));
    Widget saleProduct()    => DashboardComponent2(title: appLocalization.translate('lbl_trending_product') ?? dashboard.saleProduct!.title!,      subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.saleProduct!.viewAll!,      product: mSaleProductModel,      onTap: () => ViewAllScreen(dashboard.saleProduct!.title,      isSale: true).launch(context));
    Widget suggested()      => DashboardComponent2(title: appLocalization.translate('lbl_recommendation_for_you') ?? dashboard.suggestionProduct!.title!,subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.suggestionProduct!.viewAll!,product: mSuggestedProductModel, onTap: () => ViewAllScreen(dashboard.suggestionProduct!.title, isSpecialProduct: true, specialProduct: "suggested_for_you").launch(context));
    Widget youMayLike()     => DashboardComponent2(title: appLocalization.translate('lbl_you_might_like') ?? dashboard.youMayLikeProduct!.title!,subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.youMayLikeProduct!.viewAll!,product: mYouMayLikeProductModel,onTap: () => ViewAllScreen(dashboard.youMayLikeProduct!.title, isSpecialProduct: true, specialProduct: "you_may_like").launch(context));

    final Widget body = ListView(
      shrinkWrap: true,
      children: [
        AnimatedListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dashboard.sorting?.length ?? 0,
          itemBuilder: (_, index) {
            final key = dashboard.sorting![index];
            switch (key) {
              case 'slider':
                return _carousel(context).visible(dashboard.sliderView!.enable!);
              case 'categories':
                return _category(context).paddingTop(8).visible(dashboard.category!.enable!);
              case 'Sale_Banner':
                return _saleBannerWidget(context, appLocalization).paddingTop(8).visible(dashboard.saleBanner!.enable!);
              case 'newest_product':
                return newProduct().paddingTop(16).visible(dashboard.newProduct!.enable!);
              case 'vendor':
                return mVendorDashBoard2Widget(context, mVendorModel, dashboard.vendor!.title, dashboard.vendor!.viewAll)
                    .paddingTop(8).visible(dashboard.vendor!.enable!);
              case 'feature_products':
                return featureProduct().paddingTop(8).visible(dashboard.featureProduct!.enable!);
              case 'deal_of_the_day':
                return _availableOfferAndDeal(appLocalization.translate('lbl_deal_of_the_day') ?? dashboard.dealOfTheDay!.title!, appLocalization.translate('lbl_see_all') ?? dashboard.dealOfTheDay!.viewAll!, mDealProductModel, context)
                    .paddingTop(8).visible(dashboard.dealOfTheDay!.enable! && mDealProductModel.isNotEmpty);
              case 'best_selling_product':
                return bestSelling().paddingTop(8).visible(dashboard.bestSaleProduct!.enable!);
              case 'sale_product':
                return saleProduct().paddingTop(8).visible(dashboard.saleProduct!.enable!);
              case 'offer':
                return _availableOfferAndDeal(appLocalization.translate('lbl_available_offers') ?? dashboard.offerProduct!.title!, appLocalization.translate('lbl_see_all') ?? dashboard.offerProduct!.viewAll!, mOfferProductModel, context)
                    .paddingTop(8).visible(dashboard.offerProduct!.enable! && mOfferProductModel.isNotEmpty);
              case 'suggested_for_you':
                return suggested().paddingTop(8).visible(dashboard.suggestionProduct!.enable!);
              case 'you_may_like':
                return youMayLike().paddingTop(8).visible(dashboard.youMayLikeProduct!.enable!);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
        mBottom(context).visible(!appStore.isLoading && isDone == true),
      ],
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: mTop(
        context,
        AppName,
        leadingWidget: IconButton(
          icon: const Icon(Icons.search_sharp, color: white),
          onPressed: () => SearchScreen().launch(context),
        ),
        actions: [
          IconButton(
            icon: Image.asset(ic_WhatsUp, height: 24, width: 24),
            onPressed: () {
              final number = getStringAsync(WHATSAPP);
              if (number.isNotEmpty) {
                redirectUrl("https://wa.me/$number");
              } else {
                toast(appLocalization.translate('msg_whatsapp_failed') ?? 'رقم الواتساب غير متوفر حالياً');
              }
            },
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: white),
                onPressed: () => NotificationScreen().launch(context),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(color: kBrandSecondary, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ) as PreferredSizeWidget?,
      key: scaffoldKey,
      body: Observer(
        builder: (context) => RefreshIndicator(
          backgroundColor: context.cardColor,
          onRefresh: () => fetchDashboardData(),
          child: BodyCornerWidget(
            child: Stack(
              alignment: Alignment.center,
              children: [
                body.visible(!appStore.isLoading),
                mProgress().center().visible(appStore.isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}