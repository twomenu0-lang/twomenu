import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import '/../component/HomeDataComponent.dart';
import '/../component/HomeScreenComponent3/DashBoard3Product.dart';
import '/../component/HomeScreenComponent3/DashBoard3AppWidget.dart';
import '/../component/HomeScreenComponent3/DashboardComponent3.dart';
import '/../component/HomeScreenComponent3/VendorWidget3.dart';
import '/../main.dart';
import '/../models/ProductResponse.dart';
import '/../utils/AppBarWidget.dart';
import '/../screen/SaleScreen.dart';
import '/../screen/SearchScreen.dart';
import '/../screen/ViewAllScreen.dart';
import '/../screen/WebViewExternalProductScreen.dart';
import '/../screen/SmartCategoryScreen.dart'; // ✅ إضافة الـ import للشاشة الذكية هنا أيضاً
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../AppLocalizations.dart';

class HomeScreen3 extends StatefulWidget {
  static String tag = '/HomeScreen3';

  @override
  HomeScreen3State createState() => HomeScreen3State();
}

class HomeScreen3State extends State<HomeScreen3> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  final PageController salePageController   = PageController(initialPage: 0);
  final PageController bannerPageController = PageController(initialPage: 0);

  int _currentPage = 0;

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
      List<ProductResponse> product,
      String subtitle,
      BuildContext context,
      AppLocalizations appLocalization,
      ) {
    return Stack(
      children: [
        commonCacheImageWidget(
          ic_horizontal_bg,
          height: 285,
          width: context.width(),
          fit: BoxFit.cover,
        ),
        Container(height: 285, color: black.withOpacity(0.2)),
        Container(
          padding: const EdgeInsets.only(left: 8),
          width: context.width() * 0.3,
          margin: EdgeInsets.only(top: context.height() * 0.17),
          child: Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.alata(
              fontSize: 23,
              color: appStore.isDarkMode! ? context.iconColor : white,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                HorizontalList(
                  padding: EdgeInsets.only(left: context.width() * 0.3, right: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.length.clamp(0, 6),
                  itemBuilder: (context, i) {
                    return DashBoard3Product(
                      mProductModel: product[i],
                      width: context.width() * 0.42,
                    );
                  },
                ),
                viewAllDashBoard3(
                  context,
                  viewAll: builderResponse.dashboard!.youMayLikeProduct!.viewAll!,
                ).paddingOnly(right: 16).onTap(() {
                  if (title == builderResponse.dashboard!.dealOfTheDay!.title) {
                    ViewAllScreen(title, isSpecialProduct: true, specialProduct: "deal_of_the_day").launch(context);
                  } else if (title == builderResponse.dashboard!.offerProduct!.title) {
                    ViewAllScreen(appLocalization.translate('lbl_offer'), isSpecialProduct: true, specialProduct: "offer").launch(context);
                  } else {
                    ViewAllScreen(title);
                  }
                }).visible(product.length >= TOTAL_DASHBOARD_ITEM),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY
  // ─────────────────────────────────────────────────────────────
  Widget _category(BuildContext context) {
    if (mCategoryModel.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 260,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mCategoryModel.length,
        padding: const EdgeInsets.only(left: 8, right: 4, bottom: 2),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          childAspectRatio: 1.02,
        ),
        itemBuilder: (context, index) {
          final cat = mCategoryModel[index];
          return Container(
            margin: const EdgeInsets.only(left: 4, right: 8),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                cat.image != null
                    ? commonCacheImageWidget(
                  cat.image!.src.validate(),
                  height: 120,
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRect(8)
                    : Image.asset(
                  ic_placeholder_logo,
                  height: 120,
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRect(8),
                Container(
                  decoration: boxDecorationWithRoundedCorners(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    backgroundColor: black.withOpacity(0.3),
                  ),
                  height: 120,
                ),
                Text(
                  parseHtmlString(cat.name),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: boldTextStyle(size: 14, color: white),
                ).paddingOnly(bottom: 4),
              ],
            ),
          ).onTap(() {
            // ✅ تعديل الـ onTap هنا ليوجه للمنطق الذكي بدلاً من شاشة عرض الكل مباشرة
            SmartCategoryScreen(
              categoryName: cat.name,
              categoryId: cat.id,
            ).launch(context);
          });
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CAROUSEL
  // ─────────────────────────────────────────────────────────────
  Widget _carousel(BuildContext context) {
    if (mSliderModel.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            controller: bannerPageController,
            onPageChanged: (i) {
              _currentPage = i;
              setState(() {});
            },
            children: mSliderModel.map((i) {
              return Container(
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radius(10),
                  border: Border.all(color: textSecondaryColorGlobal.withOpacity(0.4)),
                ),
                margin: const EdgeInsets.only(left: 12, right: 12),
                child: commonCacheImageWidget(
                  i.image.validate(),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.fill,
                ).cornerRadiusWithClipRRect(10),
              ).onTap(() {
                if (i.url!.isNotEmpty) {
                  WebViewExternalProductScreen(mExternal_URL: i.url, title: i.title).launch(context);
                } else {
                  toast('Sorry');
                }
              });
            }).toList(),
          ),
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
          ).paddingBottom(8),
        ],
      ),
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
              decoration: boxDecorationRoundedWithShadow(
                8,
                backgroundColor: Theme.of(context).cardTheme.color!,
              ),
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

    Widget newProduct()     => DashboardComponent3(title: dashboard.newProduct!.title!,        subTitle: dashboard.newProduct!.viewAll!,        product: mNewestProductModel,    onTap: () => ViewAllScreen(dashboard.newProduct!.title,        isNewest: true).launch(context));
    Widget featureProduct() => DashboardComponent3(title: dashboard.featureProduct!.title!,    subTitle: dashboard.featureProduct!.viewAll!,    product: mFeaturedProductModel,  onTap: () => ViewAllScreen(dashboard.featureProduct!.title,    isFeatured: true).launch(context));
    Widget bestSelling()    => DashboardComponent3(title: dashboard.bestSaleProduct!.title!,   subTitle: dashboard.bestSaleProduct!.viewAll!,   product: mSellingProductModel,   onTap: () => ViewAllScreen(dashboard.bestSaleProduct!.title,   isBestSelling: true).launch(context));
    Widget saleProduct()    => DashboardComponent3(title: dashboard.saleProduct!.title!,       subTitle: dashboard.saleProduct!.viewAll!,       product: mSaleProductModel,      onTap: () => ViewAllScreen(dashboard.saleProduct!.title,       isSale: true).launch(context));
    Widget suggested()      => DashboardComponent3(title: dashboard.suggestionProduct!.title!, subTitle: dashboard.suggestionProduct!.viewAll!, product: mSuggestedProductModel, onTap: () => ViewAllScreen(dashboard.suggestionProduct!.title,  isSpecialProduct: true, specialProduct: "suggested_for_you").launch(context));
    Widget youMayLike()     => DashboardComponent3(title: dashboard.youMayLikeProduct!.title!, subTitle: dashboard.youMayLikeProduct!.viewAll!, product: mYouMayLikeProductModel,onTap: () => ViewAllScreen(dashboard.youMayLikeProduct!.title,  isSpecialProduct: true, specialProduct: "you_may_like").launch(context));

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
                return _carousel(context).paddingTop(8).visible(dashboard.sliderView!.enable!);
              case 'categories':
                return _category(context).paddingTop(8).visible(dashboard.category!.enable!);
              case 'Sale_Banner':
                return _saleBannerWidget(context, appLocalization).paddingTop(8).visible(dashboard.saleBanner!.enable!);
              case 'newest_product':
                return newProduct().paddingTop(16).visible(dashboard.newProduct!.enable!);
              case 'vendor':
                return mVendorDashBoard3Widget(context, mVendorModel, dashboard.vendor!.title, dashboard.vendor!.viewAll)
                    .paddingTop(8).visible(dashboard.vendor!.enable!);
              case 'feature_products':
                return featureProduct().paddingTop(8).visible(dashboard.featureProduct!.enable!);
              case 'deal_of_the_day':
                return _availableOfferAndDeal(dashboard.dealOfTheDay!.title!, mDealProductModel, dashboard.dealOfTheDay!.viewAll!, context, appLocalization)
                    .paddingTop(8).visible(dashboard.dealOfTheDay!.enable! && mDealProductModel.isNotEmpty);
              case 'best_selling_product':
                return bestSelling().paddingTop(8).visible(dashboard.bestSaleProduct!.enable!);
              case 'sale_product':
                return saleProduct().paddingTop(8).visible(dashboard.saleProduct!.enable!);
              case 'offer':
                return _availableOfferAndDeal(dashboard.offerProduct!.title!, mOfferProductModel, dashboard.dealOfTheDay!.viewAll!, context, appLocalization)
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search_sharp, color: white),
            onPressed: () => SearchScreen().launch(context),
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