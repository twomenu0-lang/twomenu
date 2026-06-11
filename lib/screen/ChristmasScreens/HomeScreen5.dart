import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/../component/HomeDataComponent.dart';
import '/../component/HomeScreenComponent5/DashBoard5Product.dart';
import '/../component/HomeScreenComponent5/DashBoard5VendorComponent.dart';
import '/../component/HomeScreenComponent5/DashboardComponent5.dart';
import '/../main.dart';
import '/../models/ProductResponse.dart';
import '/../screen/SearchScreen.dart';
import '/../screen/ViewAllScreen.dart';
import '/../screen/WebViewExternalProductScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Colors.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../AppLocalizations.dart';

class HomeScreen5 extends StatefulWidget {
  static String tag = '/HomeScreen5';

  @override
  HomeScreen5State createState() => HomeScreen5State();
}

class HomeScreen5State extends State<HomeScreen5> {
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
      setValue(CARTCOUNT, appStore.count); // ✅ fire & forget

      // ✅ تحميل بالتوازي
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
    saleBannerPageController.dispose(); // ✅ كان ناقص في النسخة القديمة
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // OFFER & DEAL — Christmas style
  // ─────────────────────────────────────────────────────────────
  Widget _availableOfferAndDeal(
      String title,
      List<ProductResponse> product,
      String subtitle,
      BuildContext context,
      ) {
    return Stack(
      children: [
        Image.asset(ic_christmas_horizontal, width: context.width(), height: 380, fit: BoxFit.cover),
        Column(
          children: [
            16.height,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "#$title",
                  style: GoogleFonts.pacifico(color: white, fontSize: 28, fontWeight: FontWeight.bold),
                ).paddingRight(4),
                Image.asset(ic_christmas_gift, height: 60, width: 60, fit: BoxFit.fill),
              ],
            ),
            8.height,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  HorizontalList(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    itemCount: product.length.clamp(0, 6), // ✅ clamp
                    itemBuilder: (context, i) {
                      return DashBoard5Product(
                        mProductModel: product[i],
                        width: context.width() * 0.42,
                        isHorizontal: true,
                      ).paddingRight(6);
                    },
                  ),
                  Text(subtitle, style: boldTextStyle(color: white)).center().onTap(() {
                    if (title == builderResponse.dashboard!.dealOfTheDay!.title) {
                      ViewAllScreen(title, isSpecialProduct: true, specialProduct: "deal_of_the_day").launch(context);
                    } else if (title == builderResponse.dashboard!.offerProduct!.title) {
                      ViewAllScreen(title, isSpecialProduct: true, specialProduct: "offer").launch(context);
                    } else {
                      ViewAllScreen(title);
                    }
                  }).visible(product.length >= TOTAL_DASHBOARD_ITEM),
                  const Icon(Icons.arrow_right_alt_rounded, color: white),
                  16.width,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY — مع commonCacheImageWidget بدل NetworkImage
  // ─────────────────────────────────────────────────────────────
  Widget _category(BuildContext context, AppLocalizations appLocalization) {
    if (mCategoryModel.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        10.height,
        Stack(
          alignment: Alignment.centerRight,
          children: [
            Text(
              "#${appLocalization.translate("lbl_categories")!}",
              style: GoogleFonts.pacifico(color: mChristmasColor, fontSize: 28, fontWeight: FontWeight.bold),
            ).paddingOnly(bottom: 12, left: 12, right: 26),
            Image.asset(ic_christmas_hat, height: 40, width: 40, fit: BoxFit.cover),
          ],
        ),
        8.height,
        SizedBox(
          height: 250,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mCategoryModel.length,
            padding: const EdgeInsets.only(left: 8, right: 4, bottom: 2),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final cat = mCategoryModel[index];
              return GestureDetector(
                onTap: () => ViewAllScreen(cat.name, isCategory: true, categoryId: cat.id).launch(context),
                child: Column(
                  children: [
                    Container(
                      width: context.width() * .24,
                      height: 95,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        image: DecorationImage(image: AssetImage(ic_christmas_categories)),
                      ),
                      // ✅ commonCacheImageWidget بدل NetworkImage مباشرة في CircleAvatar
                      child: cat.image != null
                          ? CircleAvatar(
                        backgroundColor: context.cardColor,
                        maxRadius: 60,
                        child: ClipOval(
                          child: commonCacheImageWidget(
                            cat.image!.src.validate(),
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : CircleAvatar(
                        backgroundColor: context.cardColor,
                        backgroundImage: AssetImage(ic_placeholder_logo),
                        maxRadius: 60,
                      ),
                    ),
                    8.height,
                    Text(
                      parseHtmlString(cat.name),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: boldTextStyle(size: 14, color: blackColor),
                    ).center(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CAROUSEL — Christmas style
  // ─────────────────────────────────────────────────────────────
  Widget _carousel(BuildContext context) {
    if (mSliderModel.isEmpty) return const SizedBox.shrink();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Image.asset(
          ic_christmas_banner,
          height: 230,
          width: context.width(),
          fit: BoxFit.cover,
        ).cornerRadiusWithClipRRect(8).paddingSymmetric(horizontal: 12),
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: PageView(
              controller: bannerPageController,
              onPageChanged: (_) => setState(() {}),
              children: mSliderModel.map((i) {
                return commonCacheImageWidget(
                  i.image.validate(),
                  fit: BoxFit.cover,
                  height: 200,
                  width: context.width(),
                ).cornerRadiusWithClipRRect(defaultRadius).paddingAll(6).onTap(() {
                  if (i.url!.isNotEmpty) {
                    WebViewExternalProductScreen(mExternal_URL: i.url, title: i.title).launch(context);
                  } else {
                    toast('Sorry');
                  }
                });
              }).toList(),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          child: DotIndicator(
            pageController: bannerPageController,
            currentDotSize: 8,
            dotSize: 6,
            pages: mSliderModel,
            unselectedIndicatorColor: mChristmasColor.withOpacity(0.4),
            indicatorColor: mChristmasColor,
          ).paddingTop(8),
        ),
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
        16.height,
        SizedBox(
          height: 220,
          child: PageView(
            controller: saleBannerPageController,
            onPageChanged: (_) => setState(() {}),
            children: mSaleBanner.map((i) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  commonCacheImageWidget(
                    i.image.validate(),
                    fit: BoxFit.cover,
                    height: 220,
                  ).cornerRadiusWithClipRRect(defaultRadius),
                  Positioned(
                    bottom: -40,
                    child: Container(
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: boxDecorationRoundedWithShadow(8, backgroundColor: context.cardColor),
                      child: Column(
                        children: [
                          Text(i.title!, style: boldTextStyle(size: 18)),
                          2.height,
                          Text(
                            '${appLocalization.translate('lbl_sale_start_from')!} '
                                '${DateFormat('dd MMM').format(DateTime.parse(i.startDate.toString()))} - '
                                '${DateFormat('dd MMM').format(DateTime.parse(i.endDate.toString()))}',
                            style: secondaryTextStyle(size: 16, color: mChristmasColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).paddingOnly(bottom: 16).visible(i.title!.isNotEmpty && i.image!.isNotEmpty);
            }).toList(),
          ),
        ),
        DotIndicator(
          pageController: saleBannerPageController,
          currentDotSize: 6,
          dotSize: 6,
          pages: mSaleBanner,
          indicatorColor: mChristmasColor,
        ).paddingBottom(8),
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
      return Scaffold(
        appBar: AppBar(backgroundColor: mChristmasColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Section widgets — كل واحدة بتاخد الـ product الصح
    Widget newProduct()     => DashboardComponent5(title: dashboard.newProduct!.title!,        subTitle: dashboard.newProduct!.viewAll!,        product: mNewestProductModel,    onTap: () => ViewAllScreen(dashboard.newProduct!.title,        isNewest: true).launch(context));
    Widget featureProduct() => DashboardComponent5(title: dashboard.featureProduct!.title!,    subTitle: dashboard.featureProduct!.viewAll!,    product: mFeaturedProductModel,  onTap: () => ViewAllScreen(dashboard.featureProduct!.title,    isFeatured: true).launch(context));
    Widget bestSelling()    => DashboardComponent5(title: dashboard.bestSaleProduct!.title!,   subTitle: dashboard.bestSaleProduct!.viewAll!,   product: mSellingProductModel,   onTap: () => ViewAllScreen(dashboard.bestSaleProduct!.title,   isBestSelling: true).launch(context));
    Widget saleProduct()    => DashboardComponent5(title: dashboard.saleProduct!.title!,       subTitle: dashboard.saleProduct!.viewAll!,       product: mSaleProductModel,      onTap: () => ViewAllScreen(dashboard.saleProduct!.title,       isSale: true).launch(context));
    Widget suggested()      => DashboardComponent5(title: dashboard.suggestionProduct!.title!, subTitle: dashboard.suggestionProduct!.viewAll!, product: mSuggestedProductModel, onTap: () => ViewAllScreen(dashboard.suggestionProduct!.title,  isSpecialProduct: true, specialProduct: "suggested_for_you").launch(context));
    Widget youMayLike()     => DashboardComponent5(title: dashboard.youMayLikeProduct!.title!, subTitle: dashboard.youMayLikeProduct!.viewAll!, product: mYouMayLikeProductModel,onTap: () => ViewAllScreen(dashboard.youMayLikeProduct!.title,  isSpecialProduct: true, specialProduct: "you_may_like").launch(context));

    final Widget body = Stack(
      children: [
        ListView(
          shrinkWrap: true,
          children: [
            Image.asset(ic_christmas_border, width: context.width()),
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
                    return _category(context, appLocalization).paddingTop(8).visible(dashboard.category!.enable!);
                  case 'Sale_Banner':
                    return _saleBannerWidget(context, appLocalization).paddingTop(16).visible(dashboard.saleBanner!.enable!);
                  case 'newest_product':
                    return newProduct().paddingTop(8).visible(dashboard.newProduct!.enable!);
                  case 'vendor':
                    return mVendor5Widget(context, mVendorModel, dashboard.vendor!.title, dashboard.vendor!.viewAll)
                        .visible(dashboard.vendor!.enable!);
                  case 'feature_products':
                    return featureProduct().paddingTop(30).visible(dashboard.featureProduct!.enable!);
                  case 'deal_of_the_day':
                    return _availableOfferAndDeal(dashboard.dealOfTheDay!.title!, mDealProductModel, dashboard.dealOfTheDay!.viewAll!, context)
                        .paddingTop(16).visible(dashboard.dealOfTheDay!.enable! && mDealProductModel.isNotEmpty);
                  case 'best_selling_product':
                    return bestSelling().paddingTop(30).visible(dashboard.bestSaleProduct!.enable!);
                  case 'sale_product':
                    return saleProduct().paddingTop(8).visible(dashboard.saleProduct!.enable!);
                  case 'offer':
                    return _availableOfferAndDeal(dashboard.offerProduct!.title!, mOfferProductModel, dashboard.offerProduct!.viewAll!, context)
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
            Image.asset(ic_christmas_tag, fit: BoxFit.fitWidth, width: context.width(), height: 160),
            Image.asset(ic_christmas_bottom, fit: BoxFit.fitWidth, width: context.width()),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: mChristmasColor,
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
        backgroundColor: context.cardColor,
        onRefresh: () => fetchDashboardData(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            body.visible(!appStore.isLoading),
            mProgress().center().visible(appStore.isLoading),
          ],
        ),
      ),
    );
  }
}