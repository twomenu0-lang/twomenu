import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../component/HomeScreenComponent/Dashboard1ProductComponent.dart';
import '/../component/HomeDataComponent.dart';
import '/../component/HomeScreenComponent/VendorWidget.dart';
import '/../component/HomeScreenComponent/DashboardComponent.dart';
import '/../main.dart';
import '/../models/ProductResponse.dart';
import '/../screen/SaleScreen.dart';
import '/../screen/SearchScreen.dart';
import '/../screen/ViewAllScreen.dart';
import '/../screen/WebViewExternalProductScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../AppLocalizations.dart';
import '../../utils/AppBarWidget.dart';

class HomeScreen1 extends StatefulWidget {
  static String tag = '/HomeScreen1';

  @override
  HomeScreen1State createState() => HomeScreen1State();
}

class HomeScreen1State extends State<HomeScreen1> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  // ✅ PageControllers مع initialPage محدد — أسرع في الـ init
  final PageController salePageController   = PageController(initialPage: 0);
  final PageController bannerPageController = PageController(initialPage: 0);

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
      setValue(CARTCOUNT, appStore.count); // ✅ مش محتاج await — fire & forget

      // ✅ الأهم: التنفيذ بالتوازي بدل على التوالي
      // القديم: await fetchDashboardData() ثم await fetchCategoryData()
      // = وقت الاثنين مجمعين
      // الجديد: Future.wait = يشتغلوا في نفس الوقت = وقت الأطول بس
      await Future.wait([
        fetchDashboardData(),
        fetchCategoryData(),
      ]);

      appStore.setLoading(false);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    salePageController.dispose();
    bannerPageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _availableOfferAndDeal(
      String title,
      List<ProductResponse> product,
      String subTitle,
      BuildContext context,
      AppLocalizations appLocalization,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 4, thickness: 4, color: Theme.of(context).textTheme.headlineMedium!.color),
        8.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: boldTextStyle()).paddingOnly(left: 8),
            Text(subTitle, style: boldTextStyle(color: primaryColor))
                .paddingAll(8)
                .onTap(() {
              if (title == builderResponse.dashboard!.dealOfTheDay!.title) {
                ViewAllScreen(title, isSpecialProduct: true, specialProduct: "deal_of_the_day").launch(context);
              } else if (title == builderResponse.dashboard!.offerProduct!.title) {
                ViewAllScreen(title, isSpecialProduct: true, specialProduct: "offer").launch(context);
              } else {
                ViewAllScreen(title);
              }
            }).visible(product.length >= TOTAL_DASHBOARD_ITEM),
          ],
        ).paddingOnly(left: 4, top: 8, bottom: 8),
        HorizontalList(
          padding: EdgeInsets.only(left: 12, right: 12),
          // ✅ max 6 منتجات — مش محتاج نحسب product.length > 6 في كل build
          itemCount: product.length.clamp(0, 6),
          itemBuilder: (context, i) {
            return SizedBox(
              height: 280,
              child: Dashboard1ProductComponent(
                mProductModel: product[i],
                width: context.width() * 0.42,
              ).paddingRight(6),
            );
          },
        ),
        Divider(height: 4, thickness: 4, color: Theme.of(context).textTheme.headlineMedium!.color),
        4.height,
      ],
    );
  }

  Widget _category(BuildContext context) {
    if (mCategoryModel.isEmpty) return const SizedBox.shrink();
    return HorizontalList(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 8),
      itemCount: mCategoryModel.length,
      itemBuilder: (BuildContext context, int index) {
        final cat = mCategoryModel[index];
        return SizedBox(
          height: 95,
          child: GestureDetector(
            onTap: () => ViewAllScreen(
              cat.name,
              isCategory: true,
              categoryId: cat.id,
            ).launch(context),
            child: Column(
              children: [
                // ✅ commonCacheImageWidget بدل NetworkImage مباشرة في CircleAvatar
                cat.image != null
                    ? CircleAvatar(
                  backgroundColor: context.cardColor,
                  radius: 30,
                  child: ClipOval(
                    child: commonCacheImageWidget(
                      cat.image!.src.validate(),
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    : CircleAvatar(
                  backgroundColor: context.cardColor,
                  backgroundImage: AssetImage(ic_placeholder_logo),
                  radius: 30,
                ),
                4.height,
                Text(
                  parseHtmlString(cat.name),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: primaryTextStyle(size: 14),
                ).center(),
              ],
            ).paddingRight(8),
          ),
        );
      },
    );
  }

  Widget _carousel(BuildContext context) {
    if (mSliderModel.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            controller: bannerPageController,
            onPageChanged: (_) => setState(() {}),
            children: mSliderModel.map((i) {
              return Container(
                decoration: boxDecorationWithRoundedCorners(borderRadius: radius(10)),
                margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
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
          ).paddingBottom(8),
        ],
      ),
    );
  }

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
  // DASHBOARD SECTION WIDGETS — مش هيتبنوا لو مش visible
  // ─────────────────────────────────────────────────────────────

  Widget _newProduct(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.newProduct!.title!,
    subTitle: builderResponse.dashboard!.newProduct!.viewAll!,
    product: mNewestProductModel,
    onTap: () => ViewAllScreen(builderResponse.dashboard!.newProduct!.title, isNewest: true).launch(context),
  );

  Widget _featureProduct(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.featureProduct!.title!,
    subTitle: builderResponse.dashboard!.featureProduct!.viewAll!,
    product: mFeaturedProductModel,
    onTap: () => ViewAllScreen(builderResponse.dashboard!.featureProduct!.title, isFeatured: true).launch(context),
  );

  Widget _bestSelling(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.bestSaleProduct!.title!,
    subTitle: builderResponse.dashboard!.bestSaleProduct!.viewAll!,
    product: mSellingProductModel,
    onTap: () => ViewAllScreen(builderResponse.dashboard!.bestSaleProduct!.title, isBestSelling: true).launch(context),
  );

  Widget _saleProduct(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.saleProduct!.title!,
    subTitle: builderResponse.dashboard!.saleProduct!.viewAll!,
    product: mSaleProductModel,
    onTap: () => ViewAllScreen(builderResponse.dashboard!.saleProduct!.title, isSale: true).launch(context),
  );

  Widget _suggested(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.suggestionProduct!.title!,
    subTitle: builderResponse.dashboard!.suggestionProduct!.viewAll!,
    product: mSuggestedProductModel,
    onTap: () => ViewAllScreen(builderResponse.dashboard!.suggestionProduct!.title, isSpecialProduct: true, specialProduct: "suggested_for_you").launch(context),
  );

  Widget _youMayLike(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.youMayLikeProduct!.title!,
    subTitle: builderResponse.dashboard!.youMayLikeProduct!.viewAll!,
    product: mYouMayLikeProductModel,
    onTap: () => ViewAllScreen(builderResponse.dashboard!.youMayLikeProduct!.title, isSpecialProduct: true, specialProduct: "you_may_like").launch(context),
  );

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;

    // ✅ dashboard null check مرة واحدة بس
    final dashboard = builderResponse.dashboard;
    if (dashboard == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Widget body = ListView(
      shrinkWrap: true,
      children: [
        AnimatedListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dashboard.sorting?.length ?? 0,
          itemBuilder: (_, index) {
            final section = dashboard.sorting![index];
            switch (section) {
              case 'slider':
                return _carousel(context).paddingTop(8).visible(dashboard.sliderView!.enable!);
              case 'categories':
                return _category(context).paddingTop(8).visible(dashboard.category!.enable!);
              case 'Sale_Banner':
                return _saleBannerWidget(context, appLocalization).paddingTop(8).visible(dashboard.saleBanner!.enable!);
              case 'newest_product':
                return _newProduct(context).paddingTop(8).visible(dashboard.newProduct!.enable!);
              case 'vendor':
                return mVendorWidget(context, mVendorModel, dashboard.vendor!.title, dashboard.vendor!.viewAll)
                    .paddingOnly(top: 8, bottom: 8)
                    .visible(dashboard.vendor!.enable!);
              case 'feature_products':
                return _featureProduct(context).paddingTop(8).visible(dashboard.featureProduct!.enable!);
              case 'deal_of_the_day':
                return _availableOfferAndDeal(
                  dashboard.dealOfTheDay!.title!,
                  mDealProductModel,
                  dashboard.dealOfTheDay!.viewAll!,
                  context,
                  appLocalization,
                ).paddingTop(8).visible(dashboard.dealOfTheDay!.enable! && mDealProductModel.isNotEmpty);
              case 'best_selling_product':
                return _bestSelling(context).paddingTop(8).visible(dashboard.bestSaleProduct!.enable!);
              case 'sale_product':
                return _saleProduct(context).paddingTop(8).visible(dashboard.saleProduct!.enable!);
              case 'offer':
                return _availableOfferAndDeal(
                  dashboard.offerProduct!.title!,
                  mOfferProductModel,
                  dashboard.dealOfTheDay!.viewAll!,
                  context,
                  appLocalization,
                ).paddingTop(8).visible(dashboard.offerProduct!.enable! && mOfferProductModel.isNotEmpty);
              case 'suggested_for_you':
                return _suggested(context).paddingTop(8).visible(dashboard.suggestionProduct!.enable!);
              case 'you_may_like':
                return _youMayLike(context).paddingTop(8).visible(dashboard.youMayLikeProduct!.enable!);
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
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: context.cardColor,
        onRefresh: () => fetchDashboardData(),
        child: Observer(
          builder: (context) => BodyCornerWidget(
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