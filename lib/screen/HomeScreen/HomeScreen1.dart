import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import '/../component/HomeScreenComponent/ProductCard.dart';
import '/../component/HomeScreenComponent/FloatingAppBar.dart';
import '/../component/HomeScreenComponent/HeroBannerSlider.dart';
import '/../component/HomeDataComponent.dart';
import '/../component/HomeScreenComponent/VendorWidget.dart';
import '/../component/HomeScreenComponent/DashboardComponent.dart';
import '/../main.dart';
import '/../models/CategoryData.dart';
import '/../models/ProductResponse.dart';
import '/../screen/SaleScreen.dart';
import '/../screen/SearchScreen.dart';
import '/../screen/ViewAllScreen.dart';
import '/../screen/WebViewExternalProductScreen.dart';
import '/../screen/NotificationScreen.dart';
import '/../screen/SmartCategoryScreen.dart';
import '/../utils/AppColors.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../AppLocalizations.dart';

// ─────────────────────────────────────────────────────────────
// ثوابت الـ Grid
// ─────────────────────────────────────────────────────────────
const int _kMaxVisibleCategories = 11;

class HomeScreen1 extends StatefulWidget {
  static String tag = '/HomeScreen1';

  @override
  HomeScreen1State createState() => HomeScreen1State();
}

class HomeScreen1State extends State<HomeScreen1> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final PageController salePageController = PageController(initialPage: 0);

  static const String _supportWhatsApp = '+201036363282';

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

      appStore.setLoading(false);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    salePageController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    const String message = 'مرحباً، أحتاج مساعدة في تطبيق تو مينو 🛒';
    final String encoded = Uri.encodeComponent(message);
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/${_supportWhatsApp.replaceAll('+', '').replaceAll(' ', '')}?text=$encoded',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      final Uri telUri = Uri.parse('tel:$_supportWhatsApp');
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (mounted) toast('تعذر فتح واتساب');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _availableOfferAndDeal(
      String title,
      List<ProductResponse> product,
      String subTitle,
      BuildContext context,
      AppLocalizations appLocalization, {
        String? badgeText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: boldTextStyle(size: 16, color: kBrandPrimary))
                .paddingOnly(right: 16),
            Text(subTitle,
                style: boldTextStyle(color: kBrandPrimary, size: 13))
                .paddingAll(8)
                .onTap(() {
              if (title ==
                  builderResponse.dashboard!.dealOfTheDay!.title) {
                ViewAllScreen(title,
                    isSpecialProduct: true,
                    specialProduct: "deal_of_the_day")
                    .launch(context);
              } else if (title ==
                  builderResponse.dashboard!.offerProduct!.title) {
                ViewAllScreen(title,
                    isSpecialProduct: true, specialProduct: "offer")
                    .launch(context);
              } else {
                ViewAllScreen(title);
              }
            }).visible(product.length >= TOTAL_DASHBOARD_ITEM),
          ],
        ).paddingOnly(top: 12, bottom: 8),
        HorizontalList(
          padding: const EdgeInsets.only(left: 16, right: 16),
          itemCount: product.length.clamp(0, 6),
          itemBuilder: (context, i) {
            return SizedBox(
              height: 270,
              child: ProductCard(
                mProductModel: product[i],
                width: context.width() * 0.42,
                badgeText: badgeText,
              ).paddingOnly(left: 8),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY — Grid ذكي ومكبر مع زر المزيد الذي يعرض كل الأقسام
  // ─────────────────────────────────────────────────────────────
  Widget _category(BuildContext context) {
    if (mCategoryModel.isEmpty) return const SizedBox.shrink();

    final List<Category> categories =
    mCategoryModel.map((e) => e as Category).toList();

    final bool needsMore = categories.length > _kMaxVisibleCategories;
    final List<Category> visible = needsMore
        ? categories.sublist(0, _kMaxVisibleCategories)
        : categories;

    final int itemCount = visible.length + (needsMore ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 0.72, // ✅ تم التعديل لاستيعاب الحجم الجديد للأيقونة
        ),
        itemCount: itemCount,
        itemBuilder: (ctx, i) {
          if (needsMore && i == itemCount - 1) {
            // ✅ تمرير كل الأقسام بدلاً من المخفية فقط
            return _buildMoreButton(ctx, categories);
          }
          return _buildCategoryItem(ctx, visible[i]);
        },
      ),
    );
  }

  // ─── بطاقة التصنيف الواحدة المكبرة ───────────────────────────
  Widget _buildCategoryItem(BuildContext context, Category cat) {
    final bool hasImg =
        cat.image?.src != null && (cat.image?.src ?? '').isNotEmpty;

    return GestureDetector(
      onTap: () => SmartCategoryScreen(
        categoryName: cat.name,
        categoryId: cat.id,
      ).launch(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── الصورة المكبرة ──
          Container(
            width: 75, // ✅ تم التكبير من 60 إلى 75
            height: 75, // ✅ تم التكبير من 60 إلى 75
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), // ✅ تم التعديل ليتناسب مع الحجم الجديد
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6), // ✅ تقليل الـ padding يعطي مساحة أكبر للصورة بداخل الكرت
            child: hasImg
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: commonCacheImageWidget(
                cat.image!.src ?? '',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            )
                : Image.asset(ic_placeholder_logo, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          // ── الاسم ──
          Text(
            parseHtmlString(cat.name ?? ''),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: primaryTextStyle(size: 11, color: kBrandPrimary),
          ),
        ],
      ),
    );
  }

  // ─── زر "المزيد +" المكبر ───────────────────────────────────
  Widget _buildMoreButton(BuildContext context, List<Category> allCategories) {
    return GestureDetector(
      // ✅ فتح الـ Bottom Sheet ممرراً القائمة الكاملة
      onTap: () => _showMoreBottomSheet(context, allCategories),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 75, // ✅ تم التكبير من 60 إلى 75
            height: 75, // ✅ تم التكبير من 60 إلى 75
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [kBrandPrimary, Color(0xFF4B52B8)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: kBrandPrimary.withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 30, // ✅ تم التكبير من 26 إلى 30 ليتناسب مع الكرت
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'المزيد +',
            textAlign: TextAlign.center,
            style: primaryTextStyle(size: 11, color: kBrandPrimary),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Sheet لعرض جميع الأقسام بالكامل ─────────────────
  void _showMoreBottomSheet(BuildContext context, List<Category> allCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBrandPrimary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // ── العنوان ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: kBrandSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  8.width,
                  const Text(
                    'جميع الأقسام',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kBrandPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: kBrandSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      // ✅ عرض إجمالي عدد الأقسام بالكامل
                      '${allCategories.length} قسم',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kBrandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Grid يحتوي على كافة الأقسام ──
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65, // ✅ زيادة الارتفاع لراحة أكبر أثناء التصفح
              ),
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.72, // ✅ متوافق مع النسبة المحدثة للأقسام المكبرة
                ),
                itemCount: allCategories.length, // ✅ يعرض كل الأقسام
                itemBuilder: (ctx, i) {
                  final cat = allCategories[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      SmartCategoryScreen(
                        categoryName: cat.name,
                        categoryId: cat.id,
                      ).launch(context);
                    },
                    child: _buildCategoryItem(ctx, cat), // ✅ يستدعي التصميم المحدث المكبر تلقائياً
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CAROUSEL
  // ─────────────────────────────────────────────────────────────
  Widget _carousel(BuildContext context) {
    if (mSliderModel.isEmpty) return const SizedBox.shrink();
    return HeroBannerSlider(
      height: 200,
      items: List.generate(
        mSliderModel.length,
            (index) {
          final i = mSliderModel[index];
          return HeroBannerItem(
            image: i.image.validate(),
            heroTag: 'slider_$index',
            onTap: () {
              if (i.url!.isNotEmpty) {
                WebViewExternalProductScreen(
                    mExternal_URL: i.url, title: i.title)
                    .launch(context);
              } else {
                toast('Sorry');
              }
            },
          );
        },
      ),
    );
  }

  Widget _saleBannerWidget(
      BuildContext context, AppLocalizations appLocalization) {
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
              decoration: boxDecorationRoundedWithShadow(8,
                  backgroundColor:
                  Theme.of(context).cardTheme.color!),
              child: Column(
                children: [
                  Text(banner.title!,
                      style: boldTextStyle(color: primaryColor)),
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
  // DASHBOARD SECTIONS
  // ─────────────────────────────────────────────────────────────

  Widget _newProduct(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.newProduct!.title!,
    subTitle: builderResponse.dashboard!.newProduct!.viewAll!,
    product: mNewestProductModel,
    onTap: () => ViewAllScreen(
        builderResponse.dashboard!.newProduct!.title,
        isNewest: true)
        .launch(context),
  );

  Widget _featureProduct(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.featureProduct!.title!,
    subTitle: builderResponse.dashboard!.featureProduct!.viewAll!,
    product: mFeaturedProductModel,
    onTap: () => ViewAllScreen(
        builderResponse.dashboard!.featureProduct!.title,
        isFeatured: true)
        .launch(context),
  );

  Widget _bestSelling(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.bestSaleProduct!.title!,
    subTitle: builderResponse.dashboard!.bestSaleProduct!.viewAll!,
    product: mSellingProductModel,
    bestSellerText: 'الأكثر مبيعاً',
    onTap: () => ViewAllScreen(
        builderResponse.dashboard!.bestSaleProduct!.title,
        isBestSelling: true)
        .launch(context),
  );

  Widget _saleProduct(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.saleProduct!.title!,
    subTitle: builderResponse.dashboard!.saleProduct!.viewAll!,
    product: mSaleProductModel,
    onTap: () => ViewAllScreen(
        builderResponse.dashboard!.saleProduct!.title,
        isSale: true)
        .launch(context),
  );

  Widget _suggested(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.suggestionProduct!.title!,
    subTitle: builderResponse.dashboard!.suggestionProduct!.viewAll!,
    product: mSuggestedProductModel,
    onTap: () => ViewAllScreen(
        builderResponse.dashboard!.suggestionProduct!.title,
        isSpecialProduct: true,
        specialProduct: "suggested_for_you")
        .launch(context),
  );

  Widget _youMayLike(BuildContext context) => DashboardComponent(
    title: builderResponse.dashboard!.youMayLikeProduct!.title!,
    subTitle: builderResponse.dashboard!.youMayLikeProduct!.viewAll!,
    product: mYouMayLikeProductModel,
    onTap: () => ViewAllScreen(
        builderResponse.dashboard!.youMayLikeProduct!.title,
        isSpecialProduct: true,
        specialProduct: "you_may_like")
        .launch(context),
  );

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;

    final dashboard = builderResponse.dashboard;
    if (dashboard == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
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
                return _carousel(context)
                    .paddingTop(8)
                    .visible(dashboard.sliderView!.enable!);
              case 'categories':
                return _category(context)
                    .paddingTop(8)
                    .visible(dashboard.category!.enable!);
              case 'Sale_Banner':
                return _saleBannerWidget(context, appLocalization)
                    .paddingTop(8)
                    .visible(dashboard.saleBanner!.enable!);
              case 'newest_product':
                return _newProduct(context)
                    .paddingTop(8)
                    .visible(dashboard.newProduct!.enable!);
              case 'vendor':
                return mVendorWidget(
                    context,
                    mVendorModel,
                    dashboard.vendor!.title,
                    dashboard.vendor!.viewAll)
                    .paddingOnly(top: 8, bottom: 8)
                    .visible(dashboard.vendor!.enable!);
              case 'feature_products':
                return _featureProduct(context)
                    .paddingTop(8)
                    .visible(dashboard.featureProduct!.enable!);
              case 'deal_of_the_day':
                return _availableOfferAndDeal(
                  dashboard.dealOfTheDay!.title!,
                  mDealProductModel,
                  dashboard.dealOfTheDay!.viewAll!,
                  context,
                  appLocalization,
                  badgeText: 'عرض اليوم',
                )
                    .paddingTop(8)
                    .visible(dashboard.dealOfTheDay!.enable! &&
                    mDealProductModel.isNotEmpty);
              case 'best_selling_product':
                return _bestSelling(context)
                    .paddingTop(8)
                    .visible(dashboard.bestSaleProduct!.enable!);
              case 'sale_product':
                return _saleProduct(context)
                    .paddingTop(8)
                    .visible(dashboard.saleProduct!.enable!);
              case 'offer':
                return _availableOfferAndDeal(
                  dashboard.offerProduct!.title!,
                  mOfferProductModel,
                  dashboard.dealOfTheDay!.viewAll!,
                  context,
                  appLocalization,
                  badgeText: 'خصم',
                )
                    .paddingTop(8)
                    .visible(dashboard.offerProduct!.enable! &&
                    mOfferProductModel.isNotEmpty);
              case 'suggested_for_you':
                return _suggested(context)
                    .paddingTop(8)
                    .visible(dashboard.suggestionProduct!.enable!);
              case 'you_may_like':
                return _youMayLike(context)
                    .paddingTop(8)
                    .visible(dashboard.youMayLikeProduct!.enable!);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
        mBottom(context)
            .visible(!appStore.isLoading && isDone == true),
        100.height,
      ],
    );

    return Scaffold(
      backgroundColor: kBrandBackground,
      appBar: FloatingAppBar(
        title: AppName,
        onSearchTap: () => SearchScreen().launch(context),
        onChatTap: _openWhatsApp,
        onNotificationTap: () => NotificationScreen().launch(context),
        hasNotification: true,
      ),
      key: scaffoldKey,
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: context.cardColor,
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
    );
  }
}