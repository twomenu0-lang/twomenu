import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '/../component/HomeScreenComponent/ProductCard.dart';
import '/../component/LayoutSelection.dart';
import '/../main.dart';
import '/../models/CategoryData.dart';
import '/../models/ProductResponse.dart';
import '/../models/SearchRequest.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppBarWidget.dart';
import '/../screen/ProductDetail/ProductDetailScreen2.dart';
import '/../screen/SubCategoryScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';

import 'ProductDetail/ProductDetailScreen1.dart';
import 'ProductDetail/ProductDetailScreen2.dart';
import 'ProductDetail/ProductDetailScreen3.dart';

// ─────────────────────────────────────────────────────────────
// الثوابت الجمالية — نفس نظام ألوان SmartCategoryScreen
// ─────────────────────────────────────────────────────────────
const Color _kPrimary   = Color(0xFF343892);
const Color _kSecondary = Color(0xFFF6C657);
const Color _kMuted     = Color(0xFF9098B1);

// ignore: must_be_immutable
class ViewAllScreen extends StatefulWidget {
  static String tag = '/ViewAllScreen';

  bool? isFeatured = false;
  bool? isNewest = false;
  bool? isSpecialProduct = false;
  bool? isBestSelling = false;
  bool? isSale = false;
  bool? isCategory = false;
  int?  categoryId = 0;

  /// ✅ معرّف القسم الأب لجلب الـ siblings
  int?  parentCategoryId;

  String? specialProduct = "";
  String? startDate      = "";
  String? endDate        = "";
  String? headerName     = "";

  ViewAllScreen(
      this.headerName, {
        this.isFeatured,
        this.isSale,
        this.isCategory,
        this.categoryId,
        this.parentCategoryId,
        this.isNewest,
        this.isSpecialProduct,
        this.isBestSelling,
        this.specialProduct,
        this.startDate,
        this.endDate,
      });

  @override
  ViewAllScreenState createState() => ViewAllScreenState();
}

class ViewAllScreenState extends State<ViewAllScreen> {
  List<ProductResponse> mProductModel   = [];
  List<Category>        mCategoryModel  = [];   // أقسام فرعية (children)
  List<Category>        mSiblingModel   = [];   // أقسام الأب (siblings)

  var searchRequest    = SearchRequest();
  var scrollController = ScrollController();

  // ✅ متغيرات تحسين الـ UX لشريط الأقسام (Smart Centering Scroll)
  final ScrollController _siblingScrollController = ScrollController();
  bool _siblingHintDone = false;

  int  page           = 1;
  int? noPages;
  int  crossAxisCount = 2;

  // ✅ القسم المحدد حالياً في الشريط العلوي
  int? _selectedSiblingId;
  // ✅ اسم القسم النشط وتحديث الـ AppBar
  String? _selectedSiblingName;

  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    _selectedSiblingId = widget.categoryId;
    _selectedSiblingName = widget.headerName;

    afterBuildCreated(() => init());
  }

  // ─────────────────────────────────────────────────────────────
  // init
  // ─────────────────────────────────────────────────────────────
  init() async {
    var crossAxisCount1 = getIntAsync(CROSS_AXIS_COUNT, defaultValue: 2);
    setState(() => crossAxisCount = crossAxisCount1);

    if (widget.isCategory == true) {
      fetchCategoryData();
      fetchSubCategoryData();
      if ((widget.parentCategoryId ?? 0) != 0) {
        _fetchSiblingCategories();
      }
    } else {
      searchRequest.onSale = widget.isSale != null
          ? widget.isSale! ? "_sale_price" : ""
          : "";
      searchRequest.featured = widget.isFeatured != null
          ? widget.isFeatured! ? "product_visibility" : ""
          : "";
      searchRequest.bestSelling = widget.isBestSelling != null
          ? widget.isBestSelling! ? "total_sales" : ""
          : "";
      searchRequest.newest = widget.isNewest != null
          ? widget.isNewest! ? "newest" : ""
          : "";
      searchRequest.specialProduct = widget.isSpecialProduct != null
          ? widget.isSpecialProduct! ? widget.specialProduct : ""
          : "";
      page = 1;
      getAllProducts();
    }

    scrollController.addListener(() => scrollHandler());
  }

  @override
  void dispose() {
    scrollController.dispose();
    _siblingScrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // دالة الـ Smart Scroll Hint المُصلَحة بالكامل
  // ─────────────────────────────────────────────────────────────
  Future<void> _triggerScrollHint() async {
    if (_siblingHintDone) return;
    if (mSiblingModel.length <= 1) return;

    _siblingHintDone = true;

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (!_siblingScrollController.hasClients) return;

    final int selectedIndex =
    mSiblingModel.indexWhere((cat) => cat.id == _selectedSiblingId);

    // ✅ إصلاح 1: لو التصنيف في البداية (index 0 أو 1) → حركة بسيطة ذهاب وإياب للتنبيه بالمسحب
    if (selectedIndex <= 1) {
      // تأكد أن في محتوى خارج الشاشة أصلاً قبل الحركة
      if (_siblingScrollController.position.maxScrollExtent <= 0) return;

      await _siblingScrollController.animateTo(
        60,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      await _siblingScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeIn,
      );
      return;
    }

    // ✅ إصلاح 2: لو التصنيف في المنتصف أو النهاية → توسيط دقيق مع ضمان ظهوره كاملاً
    if (_siblingScrollController.position.maxScrollExtent <= 0) return;

    // حساب متوسط عرض الـ chip بناءً على المحتوى الفعلي المحدّث
    const double estimatedChipWidth = 130.0; // زيادة من 120 لضمان ظهور النص كاملاً
    const double chipMargin = 8.0;
    const double totalChipWidth = estimatedChipWidth + chipMargin;

    // ✅ إصلاح 3: حساب الـ offset بحيث يظهر التصنيف كاملاً في منتصف الشاشة
    final double viewportWidth =
        _siblingScrollController.position.viewportDimension;

    final double targetOffset =
        (selectedIndex * totalChipWidth) - (viewportWidth / 2) + (estimatedChipWidth / 2);

    // ✅ إصلاح 4: clamp يضمن عدم قطع أو تجاوز آخر تصنيف خارج حدود الشاشة الشغالة
    final double maxScroll =
        _siblingScrollController.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

    // لو الـ offset صغير جداً معناه التصنيف ظاهر بالفعل → حركة تنبيهية بسيطة
    if (clampedOffset < 30) {
      await _siblingScrollController.animateTo(
        60,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      await _siblingScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeIn,
      );
      return;
    }

    // التمرير الذكي للتوسيط الفعلي للملف المختار
    await _siblingScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // جلب أقسام الأب (siblings)
  // ─────────────────────────────────────────────────────────────
  Future<void> _fetchSiblingCategories() async {
    try {
      final res = await getSubCategories(widget.parentCategoryId, 1);
      if (!mounted) return;
      final Iterable raw = res as Iterable;
      final list = raw.map((e) => Category.fromJson(e)).toList();
      if (list.isNotEmpty) {
        setState(() => mSiblingModel = list);

        // استدعاء الـ Hint بعد الـ Frame لضمان وجود الـ Clients وجاهزية الأبعاد
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerScrollHint();
        });
      }
    } catch (_) {
      // Silently fail
    }
  }

  // ─────────────────────────────────────────────────────────────
  // عند الضغط على قسم في الشريط العلوي
  // ─────────────────────────────────────────────────────────────
  void _onSiblingTap(Category sibling) {
    if (_selectedSiblingId == sibling.id) return;

    setState(() {
      _selectedSiblingId = sibling.id;
      _selectedSiblingName = sibling.name;
      mProductModel.clear();
      mCategoryModel.clear();
      page = 1;
    });

    _fetchProductsForCategory(sibling.id);
    _fetchChildrenForCategory(sibling.id);
  }

  Future<void> _fetchProductsForCategory(int? catId) async {
    appStore.setLoading(true);
    var data = {"category": catId, "page": 1, "perPage": TOTAL_ITEM_PER_PAGE};
    await searchProduct(data).then((res) {
      if (!mounted) return;
      appStore.setLoading(false);
      ProductListResponse listResponse = ProductListResponse.fromJson(res);
      setState(() {
        noPages = listResponse.numOfPages;
        mProductModel.addAll(listResponse.data!);
      });
    }).catchError((_) {
      if (!mounted) return;
      appStore.setLoading(false);
    });
  }

  Future<void> _fetchChildrenForCategory(int? catId) async {
    await getSubCategories(catId, 1).then((res) {
      if (!mounted) return;
      final Iterable raw = res as Iterable;
      setState(() {
        mCategoryModel = raw.map((e) => Category.fromJson(e)).toList();
      });
    }).catchError((_) {});
  }

  // ─────────────────────────────────────────────────────────────
  // شريط الـ Siblings المطور والمصقول بالحجم والـ End Padding الجديد
  // ─────────────────────────────────────────────────────────────
  Widget _buildSiblingStrip() {
    if (mSiblingModel.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ عنوان الشريط المصغر لـ Compact Look ─
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4), // تصميم مضغوط
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16, // تصغير من 18
                  decoration: BoxDecoration(
                    color: _kSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                8.width,
                Text(
                  'الأقسام',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12, // تصغير من 13
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ─ الشريط الأفقي الرشيق ─
          SizedBox(
            height: 52, // تقليص الارتفاع الإجمالي من 64 إلى 52
            child: Stack(
              children: [
                ListView.builder(
                  controller: _siblingScrollController,
                  scrollDirection: Axis.horizontal,
                  // ✅ إصلاح آخر عنصر: جعل الـ padding متناسق لمنع قطع الحافة
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 4),
                  itemCount: mSiblingModel.length,
                  itemBuilder: (ctx, i) {
                    final cat       = mSiblingModel[i];
                    final isActive  = _selectedSiblingId == cat.id;
                    final bool hasImg =
                        cat.image?.src != null && cat.image!.src!.isNotEmpty;

                    return GestureDetector(
                      onTap: () => _onSiblingTap(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // تصغير الـ padding الداخلي
                        decoration: BoxDecoration(
                          color: isActive ? _kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: isActive
                                ? _kPrimary
                                : _kPrimary.withOpacity(0.18),
                            width: isActive ? 1.5 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                            BoxShadow(
                              color: _kPrimary.withOpacity(0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasImg)
                              Container(
                                width: 20, // تصغير من 22
                                height: 20,
                                margin: const EdgeInsetsDirectional.only(end: 5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? Colors.white.withOpacity(0.2)
                                      : _kPrimary.withOpacity(0.06),
                                  image: DecorationImage(
                                    image: NetworkImage(cat.image!.src!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 20, // تصغير من 22
                                height: 20,
                                margin: const EdgeInsetsDirectional.only(end: 5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? Colors.white.withOpacity(0.2)
                                      : _kPrimary.withOpacity(0.06),
                                ),
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  size: 11, // تصغير من 12
                                  color: isActive ? Colors.white : _kPrimary,
                                ),
                              ),

                            Text(
                              parseHtmlString(cat.name.validate()),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11, // تصغير من 12
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : _kPrimary,
                              ),
                            ),

                            if ((cat.count ?? 0) > 0) ...[
                              5.width,
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? _kSecondary
                                      : _kPrimary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${cat.count}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 9, // تصغير من 10
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? _kPrimary : _kMuted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // تأثير تلاشي الحافة اليمنى (Fade Effect)
                Positioned(
                  right: 0, top: 0, bottom: 4, width: 24,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // تأثير تلاشي الحافة اليسرى (Fade Effect)
                Positioned(
                  left: 0, top: 0, bottom: 4, width: 24,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: _kPrimary.withOpacity(0.08)),
        ],
      ),
    );
  }

  // ─── الشريط القديم: الأقسام الفرعية (children) ──
  Widget mSubCategory(List<Category> category) {
    return Container(
      height: 110,
      child: AnimatedListView(
        itemCount: category.length,
        padding: const EdgeInsets.only(right: 12, left: 12),
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              SubCategoryScreen(mCategoryModel[i].name,
                  categoryId: mCategoryModel[i].id)
                  .launch(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  mCategoryModel[i].image != null
                      ? CircleAvatar(
                      backgroundColor: context.cardColor,
                      backgroundImage:
                      NetworkImage(mCategoryModel[i].image!.src.validate()),
                      radius: 35)
                      : CircleAvatar(
                      backgroundColor: context.cardColor,
                      backgroundImage: AssetImage(ic_placeholder_logo),
                      radius: 35),
                  2.height,
                  Text(parseHtmlString(category[i].name),
                      style: primaryTextStyle(size: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Scroll handler
  // ─────────────────────────────────────────────────────────────
  scrollHandler() {
    if (widget.isCategory == true) {
      setState(() {
        if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
            noPages! > page &&
            !appStore.isLoading) {
          page++;
          loadMoreCategoryProduct(page);
        }
      });
    } else {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent &&
          noPages! > page &&
          !appStore.isLoading) {
        page++;
        getAllProducts();
      }
    }
  }

  Future loadMoreCategoryProduct(page) async {
    appStore.setLoading(true);
    var catId = _selectedSiblingId ?? widget.categoryId;
    var data  = {"category": catId, "page": page, "perPage": TOTAL_ITEM_PER_PAGE};
    await searchProduct(data).then((res) {
      if (!mounted) return;
      appStore.setLoading(false);
      setState(() {
        ProductListResponse listResponse = ProductListResponse.fromJson(res);
        noPages = listResponse.numOfPages;
        mProductModel.addAll(listResponse.data!);
      });
    }).catchError((error) {
      if (!mounted) return;
      appStore.setLoading(false);
    });
  }

  Future fetchCategoryData() async {
    appStore.setLoading(true);
    var data = {
      "category": widget.categoryId,
      "page": 1,
      "perPage": TOTAL_ITEM_PER_PAGE,
    };
    await searchProduct(data).then((res) {
      if (!mounted) return;
      setState(() {
        appStore.setLoading(false);
        ProductListResponse listResponse = ProductListResponse.fromJson(res);
        if (page == 1) mProductModel.clear();
        noPages = listResponse.numOfPages;
        mProductModel.addAll(listResponse.data!);
        appStore.setLoading(false);
      });
    }).catchError((error) {
      if (!mounted) return;
      appStore.setLoading(false);
    });
  }

  Future fetchSubCategoryData() async {
    appStore.setLoading(true);
    await getSubCategories(widget.categoryId, page).then((res) {
      if (!mounted) return;
      appStore.setLoading(false);
      setState(() {
        Iterable mCategory = res;
        mCategoryModel =
            mCategory.map((model) => Category.fromJson(model)).toList();
      });
    }).catchError((error) {
      if (!mounted) return;
      appStore.setLoading(false);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    setValue(CARTCOUNT, appStore.count);

    Widget _gridProducts = AlignedGridView.count(
      scrollDirection: Axis.vertical,
      itemCount: mProductModel.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(left: 12, right: 12),
      itemBuilder: (context, index) {
        return ProductCard(
            mProductModel: mProductModel[index], width: context.width());
      },
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    );

    Widget _listProduct = AnimatedListView(
      scrollDirection: Axis.vertical,
      itemCount: mProductModel.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(right: 12, left: 12, bottom: 8),
      itemBuilder: (context, index) {
        return ProductCard(
          mProductModel: mProductModel[index],
          width: context.width(),
          isListView: true,
        ).paddingOnly(bottom: 12);
      },
    );

    return Scaffold(
      appBar: mTop(
        context,
        parseHtmlString(_selectedSiblingName ?? widget.headerName ?? ''),
        showBack: true,
        actions: [
          IconButton(
            onPressed: () => layoutSelectionBottomSheet(context),
            icon: Icon(MaterialCommunityIcons.view_dashboard_outline,
                color: Colors.white, size: 30),
          ),
          mCart(context, getBoolAsync(IS_LOGGED_IN)),
        ],
      ) as PreferredSizeWidget?,
      backgroundColor: const Color(0xFFF7F8FC),
      body: Observer(builder: (context) {
        return BodyCornerWidget(
          child: Column(
            children: [
              // شريط الأقسام الثابت بتأثيرات الـ UX المطورة والتوسيط التلقائي الرشيق
              _buildSiblingStrip(),

              // المحتوى قابل للتمرير تحت الشريط بمرونة تامة
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          16.height,
                          mSubCategory(mCategoryModel).visible(
                            widget.isCategory != null &&
                                widget.isCategory! &&
                                mCategoryModel.isNotEmpty,
                          ),
                          crossAxisCount == 1
                              ? _listProduct.visible(mProductModel.isNotEmpty)
                              : _gridProducts.visible(mProductModel.isNotEmpty),
                          mProgress()
                              .visible(appStore.isLoading && page > 1)
                              .center(),
                        ],
                      ),
                    ),
                    mProgress()
                        .paddingAll(24)
                        .center()
                        .visible(appStore.isLoading && page == 1),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  getAllProducts() async {
    afterBuildCreated(() => appStore.setLoading(true));
    setState(() => searchRequest.page = page);
    await searchProduct(searchRequest.toJson()).then((res) {
      if (!mounted) return;
      ProductListResponse listResponse = ProductListResponse.fromJson(res);
      setState(() {
        if (page == 1) mProductModel.clear();
        noPages = listResponse.numOfPages;
        mProductModel.addAll(listResponse.data!);
        appStore.setLoading(false);
      });
    }).catchError((error) {
      setState(() {
        appStore.setLoading(false);
        errorMsg = "No Data Found";
        if (page == 1) mProductModel.clear();
      });
    });
  }

  void layoutSelectionBottomSheet(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return LayoutSelection(
          crossAxisCount: crossAxisCount,
          callBack: (crossvalue) {
            crossAxisCount = crossvalue;
            setState(() {});
          },
        );
      },
    );
  }
}