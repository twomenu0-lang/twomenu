import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../component/HomeDataComponent.dart';
import '/../component/HomeScreenComponent4/DashBoard4Product.dart';
import '/../component/HomeScreenComponent4/DashBoard4VendorComponent.dart';
import '/../component/HomeScreenComponent4/DashboardComponent4.dart';
import '/../main.dart';
import '/../models/ProductResponse.dart';
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
import '../VendorListScreen.dart';

class HomeScreen4 extends StatefulWidget {
  static String tag = '/HomeScreen4';

  @override
  HomeScreen4State createState() => HomeScreen4State();
}

class HomeScreen4State extends State<HomeScreen4> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  final PageController bannerPageController     = PageController(initialPage: 0);
  final PageController saleBannerPageController = PageController(initialPage: 0);

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

      if (mounted) setState(() {});
      appStore.setLoading(false);
    });
  }

  @override
  void dispose() {
    bannerPageController.dispose();
    saleBannerPageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // OFFER & DEAL — Halloween style
  // ─────────────────────────────────────────────────────────────
  Widget _availableOfferAndDeal(
      String title,
      List<ProductResponse> product,
      BuildContext context,
      AppLocalizations appLocalization,
      ) {
    return Stack(
      children: [
        Image.asset(ic_halloween_background, height: 400, width: context.width(), fit: BoxFit.cover),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            20.height,
            Text(title, style: boldTextStyle(color: white, size: 20)).center(),
            8.height,
            Text(
              appLocalization.translate('lbl_see_all') ?? builderResponse.dashboard!.youMayLikeProduct!.viewAll!,
              style: boldTextStyle(color: white),
            ).center().onTap(() {
              if (title == (appLocalization.translate('lbl_deal_of_the_day') ?? builderResponse.dashboard!.dealOfTheDay!.title)) {
                ViewAllScreen(title, isSpecialProduct: true, specialProduct: "deal_of_the_day").launch(context);
              } else if (title == (appLocalization.translate('lbl_available_offers') ?? builderResponse.dashboard!.offerProduct!.title)) {
                ViewAllScreen(appLocalization.translate('lbl_offer'), isSpecialProduct: true, specialProduct: "offer").launch(context);
              } else {
                ViewAllScreen(title);
              }
            }).visible(product.length >= TOTAL_DASHBOARD_ITEM),
            16.height,
            HorizontalList(
              padding: const EdgeInsets.only(left: 12, right: 12),
              itemCount: product.length.clamp(0, 6),
              itemBuilder: (context, i) {
                return DashBoard4Product(
                  mProductModel: product[i],
                  width: context.width() * 0.42,
                ).paddingRight(6);
              },
            ),
            4.height,
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY
  // ─────────────────────────────────────────────────────────────
  Widget _category(BuildContext context) {
    if (mCategoryModel.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: HorizontalList(
        itemCount: mCategoryModel.length,
        padding: const EdgeInsets.only(left: 8),
        itemBuilder: (BuildContext context, int index) {
          final cat = mCategoryModel[index];
          return GestureDetector(
            onTap: () => SmartCategoryScreen(
              categoryName: cat.name,
              categoryId: cat.id,
            ).launch(context),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage(ic_halloween_category),
                      radius: 36,
                    ),
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
                  ],
                ),
                4.height,
                Text(
                  parseHtmlString(cat.name),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: primaryTextStyle(size: 14, color: white),
                ).center(),
              ],
            ).paddingOnly(left: 8, right: 8),
          );
        },
      ),
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
          height: 220,
          child: PageView(
            controller: bannerPageController,
            onPageChanged: (_) => setState(() {}),
            children: mSliderModel.map((i) {
              return Stack(
                children: [
                  Container(
                    decoration: boxDecorationWithRoundedCorners(
                      border: Border.all(color: mHalloweenYellow, width: 16),
                      borderRadius: radius(0),
                    ),
                  ),
                  commonCacheImageWidget(
                    i.image.validate(),
                    height: 220,
                    width: context.width(),
                    fit: BoxFit.cover,
                  ).onTap(() {
                    if (i.url!.isNotEmpty) {
                      WebViewExternalProductScreen(mExternal_URL: i.url, title: i.title).launch(context);
                    } else {
                      toast(AppLocalizations.of(context)!.translate('lbl_attribute') ?? 'Sorry');
                    }
                  }).paddingAll(2),
                ],
              ).paddingOnly(bottom: 4, left: 16, top: 16, right: 16);
            }).toList(),
          ),
        ),
        DotIndicator(
          pageController: bannerPageController,
          currentDotSize: 8,
          dotSize: 6,
          pages: mSliderModel,
          unselectedIndicatorColor: white.withOpacity(0.4),
          indicatorColor: white,
        ).paddingBottom(8),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SALE BANNER
  // ─────────────────────────────────────────────────────────────
  Widget _saleBannerWidget(BuildContext context, AppLocalizations appLocalization) {
    if (mSaleBanner.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 350,
          child: PageView(
            controller: saleBannerPageController,
            onPageChanged: (_) => setState(() {}),
            children: mSaleBanner.map((i) {
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  commonCacheImageWidget(
                    i.image.validate(),
                    height: 350,
                    width: context.width(),
                    fit: BoxFit.fitHeight,
                  ).paddingAll(2),
                  Container(
                    height: 100,
                    alignment: Alignment.bottomCenter,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 8,
                          blurRadius: 2,
                          offset: Offset(4, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(i.title!, style: boldTextStyle(color: white, size: 24)),
                        2.height,
                        Text(
                          '${appLocalization.translate('lbl_sale_start_from')!} ${i.startDate.validate()} to ${i.endDate.validate()}',
                          style: secondaryTextStyle(size: 18, color: white.withOpacity(0.4)),
                        ),
                      ],
                    ).paddingAll(16),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        DotIndicator(
          pageController: saleBannerPageController,
          currentDotSize: 6,
          dotSize: 6,
          pages: mSaleBanner,
          unselectedIndicatorColor: white.withOpacity(0.4),
          indicatorColor: white,
        ).paddingBottom(8),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VENDOR WIDGET
  // ─────────────────────────────────────────────────────────────
  Widget _vendor4Widget(
      BuildContext context,
      List<VendorResponse> vendorList,
      var title,
      var all,
      ) {
    if (vendorList.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Column(
          children: [
            Row(
              children: [
                const Divider(color: Colors.white24).expand(),
                Image.asset(ic_halloween_pumpkin_gif, height: 80, fit: BoxFit.cover).paddingOnly(left: 16, right: 16),
                const Divider(color: Colors.white24).expand(),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: boldTextStyle(size: 22, color: white)),
                RichText(
                  text: TextSpan(
                    children: [
                      WidgetSpan(child: Icon(Icons.add, size: 14, color: white.withOpacity(0.4))),
                      TextSpan(text: all, style: secondaryTextStyle(size: 14, color: white.withOpacity(0.4))),
                    ],
                  ),
                ),
              ],
            ).paddingOnly(left: 16, right: 16),
          ],
        ).onTap(() => VendorListScreen().launch(context)),
        8.height,
        DashBoard4VendorComponent(vendorList),
      ],
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
      return const Scaffold(
        backgroundColor: mHalloweenBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Widget newProduct()     => DashboardComponent4(title: appLocalization.translate('lbl_new_collections') ?? dashboard.newProduct!.title!,        subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.newProduct!.viewAll!,        product: mNewestProductModel,    onTap: () => ViewAllScreen(dashboard.newProduct!.title,        isNewest: true).launch(context));
    Widget featureProduct() => DashboardComponent4(title: appLocalization.translate('lbl_featured_product') ?? dashboard.featureProduct!.title!,    subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.featureProduct!.viewAll!,    product: mFeaturedProductModel,  onTap: () => ViewAllScreen(dashboard.featureProduct!.title,    isFeatured: true).launch(context));
    Widget bestSelling()    => DashboardComponent4(title: appLocalization.translate('lbl_top_selling') ?? dashboard.bestSaleProduct!.title!,   subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.bestSaleProduct!.viewAll!,   product: mSellingProductModel,   onTap: () => ViewAllScreen(dashboard.bestSaleProduct!.title,   isBestSelling: true).launch(context));
    Widget saleProduct()    => DashboardComponent4(title: appLocalization.translate('lbl_trending_product') ?? dashboard.saleProduct!.title!,       subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.saleProduct!.viewAll!,       product: mSaleProductModel,      onTap: () => ViewAllScreen(dashboard.saleProduct!.title,       isSale: true).launch(context));
    Widget suggested()      => DashboardComponent4(title: appLocalization.translate('lbl_recommendation_for_you') ?? dashboard.suggestionProduct!.title!, subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.suggestionProduct!.viewAll!, product: mSuggestedProductModel, onTap: () => ViewAllScreen(dashboard.suggestionProduct!.title,  isSpecialProduct: true, specialProduct: "suggested_for_you").launch(context));
    Widget youMayLike()     => DashboardComponent4(title: appLocalization.translate('lbl_you_might_like') ?? dashboard.youMayLikeProduct!.title!, subTitle: appLocalization.translate('lbl_see_all') ?? dashboard.youMayLikeProduct!.viewAll!, product: mYouMayLikeProductModel,onTap: () => ViewAllScreen(dashboard.youMayLikeProduct!.title,  isSpecialProduct: true, specialProduct: "you_may_like").launch(context));

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
                return _saleBannerWidget(context, appLocalization).paddingTop(16).visible(dashboard.saleBanner!.enable!);
              case 'newest_product':
                return newProduct().paddingTop(8).visible(dashboard.newProduct!.enable!);
              case 'vendor':
                return _vendor4Widget(
                    context,
                    mVendorModel,
                    appLocalization.translate('lbl_vendors') ?? dashboard.vendor!.title,
                    appLocalization.translate('lbl_see_all') ?? dashboard.vendor!.viewAll
                ).visible(dashboard.vendor!.enable!);
              case 'feature_products':
                return featureProduct().paddingTop(30).visible(dashboard.featureProduct!.enable!);
              case 'deal_of_the_day':
                return _availableOfferAndDeal(appLocalization.translate('lbl_deal_of_the_day') ?? dashboard.dealOfTheDay!.title!, mDealProductModel, context, appLocalization)
                    .paddingTop(16).visible(dashboard.dealOfTheDay!.enable! && mDealProductModel.isNotEmpty);
              case 'best_selling_product':
                return bestSelling().paddingTop(30).visible(dashboard.bestSaleProduct!.enable!);
              case 'sale_product':
                return saleProduct().paddingTop(8).visible(dashboard.saleProduct!.enable!);
              case 'offer':
                return _availableOfferAndDeal(appLocalization.translate('lbl_available_offers') ?? dashboard.offerProduct!.title!, mOfferProductModel, context, appLocalization)
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
        Image.asset(
          ic_halloween_bg,
          fit: BoxFit.fitWidth,
          width: context.width(),
          height: 100,
        ),
      ],
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: mHalloweenBackgroundColor,
        appBar: AppBar(
          elevation: 1,
          backgroundColor: mHalloweenBackgroundColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_sharp, color: white),
              onPressed: () => SearchScreen().launch(context),
            ),
          ],
          title: Text(AppName, style: boldTextStyle(size: 18, color: white)),
          automaticallyImplyLeading: false,
        ),
        key: scaffoldKey,
        body: RefreshIndicator(
          color: primaryColor,
          backgroundColor: Theme.of(context).cardTheme.color,
          onRefresh: () => fetchDashboardData(),
          child: Observer(
            builder: (context) => Stack(
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