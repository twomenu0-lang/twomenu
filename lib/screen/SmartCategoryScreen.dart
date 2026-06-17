import 'package:flutter/material.dart';
import '/../models/CategoryData.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/AppWidget.dart';
import '/../utils/AppImages.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import '../main.dart';
import 'ViewAllScreen.dart';

// ─────────────────────────────────────────────────────────────
// SmartCategoryScreen
// لما العميل يضغط على أي تصنيف رئيسي:
//   • لو فيه sub-categories → يعرضها في grid جميل
//   • لو مفيش             → يروح لـ ViewAllScreen (المنتجات) مباشرة
//
// ✅ تحديث: يمرّر parentCategoryId لـ ViewAllScreen
//    عشان يعرض شريط الـ siblings في الأعلى
// ─────────────────────────────────────────────────────────────

const Color _kPrimary   = Color(0xFF343892);
const Color _kSecondary = Color(0xFFF6C657);
const Color _kPrimaryBg = Color(0xFFEDEEF8);
const Color _kMuted     = Color(0xFF9098B1);

class SmartCategoryScreen extends StatefulWidget {
  static String tag = '/SmartCategoryScreen';

  final String? categoryName;
  final int?    categoryId;

  /// ✅ الجديد: معرّف القسم الجد — يُمرَّر للأسفل ليظهر الشريط في ViewAllScreen
  /// • لما SmartCategory نفسه يروح لـ ViewAllScreen  → يمرر categoryId الخاص به كـ parent
  /// • لما Sub-SmartCategory يروح لـ ViewAllScreen   → يمرر categoryId الحالي كـ parent
  final int?    parentCategoryId;

  const SmartCategoryScreen({
    Key? key,
    required this.categoryName,
    required this.categoryId,
    this.parentCategoryId,       // ← اختياري (القسم الجد لو موجود)
  }) : super(key: key);

  @override
  State<SmartCategoryScreen> createState() => _SmartCategoryScreenState();
}

class _SmartCategoryScreenState extends State<SmartCategoryScreen> {
  List<Category> _subCategories  = [];
  bool           _loading        = true;
  bool           _navigatedAway  = false;

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() => _loadSubCategories());
  }

  // ─── جلب التصنيفات الفرعية ───────────────────────────────
  Future<void> _loadSubCategories() async {
    try {
      final res = await getSubCategories(widget.categoryId, 1);
      if (!mounted) return;

      final Iterable raw  = res as Iterable;
      final List<Category> list = raw.map((e) => Category.fromJson(e)).toList();

      if (list.isEmpty) {
        _goToProducts();
        return;
      }

      setState(() {
        _subCategories = list;
        _loading       = false;
      });
    } catch (e) {
      if (!mounted) return;
      _goToProducts();
    }
  }

  // ─── الانتقال لشاشة المنتجات ─────────────────────────────
  // ✅ نمرر categoryId الحالي كـ parentCategoryId
  //    عشان ViewAllScreen يجيب siblings من نفس المستوى
  void _goToProducts() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ViewAllScreen(
          widget.categoryName,
          isCategory: true,
          categoryId: widget.categoryId,
          // ✅ الجديد: لو عندنا parentId من الـ caller نمرره، وإلا نمرر الـ parent المباشر
          parentCategoryId: widget.parentCategoryId ?? widget.categoryId,
        ),
      ),
    );
  }

  // ─── الضغط على تصنيف فرعي ────────────────────────────────
  void _onSubCategoryTap(Category sub) {
    SmartCategoryScreen(
      categoryName:     sub.name,
      categoryId:       sub.id,
      // ✅ الجديد: نمرر الـ categoryId الحالي كـ parent للشاشة الفرعية
      //    حتى لو وصلت لمنتجات تعرف siblings القسم اللي جاءت منه
      parentCategoryId: widget.categoryId,
    ).launch(context);
  }

  // ─── بطاقة التصنيف ───────────────────────────────────────
  Widget _buildCard(Category cat, double cardWidth) {
    final String name    = parseHtmlString(cat.name.validate());
    final bool   hasImage =
        cat.image?.src != null && cat.image!.src!.isNotEmpty;

    return GestureDetector(
      onTap: () => _onSubCategoryTap(cat),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── صورة التصنيف ──
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? commonCacheImageWidget(
                    cat.image!.src.validate(),
                    fit: BoxFit.cover,
                  )
                      : Container(
                    color: _kPrimaryBg,
                    child: Image.asset(
                      ic_placeholder_logo,
                      fit: BoxFit.contain,
                    ).paddingAll(20),
                  ),
                  // تدرج سفلي
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.28),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // شارة عدد المنتجات
                  if ((cat.count ?? 0) > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kSecondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${cat.count}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── اسم التصنيف ──
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header بانر اسم التصنيف الرئيسي ─────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, Color(0xFF4B52B8)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
                Icons.grid_view_rounded, color: _kPrimary, size: 22),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parseHtmlString(widget.categoryName.validate()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'اختر القسم المناسب',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          // عدد الأقسام
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_subCategories.length} قسم',
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mTop(
        context,
        parseHtmlString(widget.categoryName.validate()),
        showBack: true,
        actions: [mCart(context, getBoolAsync(IS_LOGGED_IN))],
      ) as PreferredSizeWidget?,
      backgroundColor: const Color(0xFFF7F8FC),
      body: _loading
      // ── شاشة التحميل ──
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kPrimary),
            16.height,
            const Text(
              'جاري تحميل الأقسام...',
              style: TextStyle(
                color: _kMuted,
                fontFamily: 'Cairo',
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
      // ── Grid التصنيفات ──
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1, // ✅ تم التعديل من 0.85 إلى 1.1 لتصغير ارتفاع البطاقات وضغطها رأسياً
              ),
              itemCount: _subCategories.length,
              itemBuilder: (context, i) {
                final double cardWidth =
                    (context.width() - 16 * 2 - 12) / 2;
                return _buildCard(_subCategories[i], cardWidth);
              },
            ),
          ),
        ],
      ),
    );
  }
}