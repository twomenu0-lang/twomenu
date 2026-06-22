import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart'; // ✅ إضافة مسار الـ main للوصول لـ cartStore
import '../../models/CartModel.dart'; // ✅ إضافة موديل السلة
import '../../models/ProductResponse.dart';
import '../../utils/AppColors.dart';
import '../../utils/AppWidget.dart';
import '../../utils/Common.dart';
import '../../utils/ProductWishListExtension.dart';

/// ─────────────────────────────────────────────────────────────
/// ProductCard — Premium UI مع دعم RTL صحيح وسلوك "أضف للسلة" الذكي
///
/// السلوك:
/// • ضغط الصورة/الاسم          ← فتح صفحة المنتج
/// • ضغط "أضف للسلة" + بسيط    ← إضافة فورية + تأثير ✓ أخضر (الـ Toast من الـ Store)
/// • ضغط "أضف للسلة" + خيارات  ← Bottom Sheet لاختيار Options
/// • الزرار بيعكس حالة السلة الحقيقية دايمًا (مش حالة مؤقتة محلية):
///     - المنتج مش في السلة  → "أضف للسلة" (أزرق)
///     - لسه واصل توه         → "تمت الإضافة" (أخضر + ✓ متحرك) لمدة ~1.2 ثانية
///     - المنتج في السلة فعلاً → "✓ في السلة" (أخضر ثابت) لحد ما يتشال
///
/// العرض:
/// • isListView = false (افتراضي) ← كارت شبكة (Grid) — صورة فوق، البيانات تحتها
/// • isListView = true            ← كارت قائمة (List) — صورة يمين/يسار، البيانات جنبها
/// ─────────────────────────────────────────────────────────────
class ProductCard extends StatefulWidget {
  static String tag = '/ProductCard';

  final ProductResponse? mProductModel;
  final double? width;
  final String? badgeText;
  final String? bestSellerText;
  final VoidCallback? onAddTap;
  final bool isListView;

  const ProductCard({
    super.key,
    this.mProductModel,
    this.width,
    this.badgeText,
    this.bestSellerText,
    this.onAddTap,
    this.isListView = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  /// ✅ ومضة التأكيد المؤقتة فقط ("تمت الإضافة") — مش مصدر الحقيقة لحالة السلة
  bool _justAdded = false;

  late final AnimationController _checkController;
  late final Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkAnim =
        CurvedAnimation(parent: _checkController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  String _safePrice(String? value) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null ? '' : parsed.toStringAsFixed(2);
  }

  /// هل المنتج يحتاج اختيار خيارات
  bool get _isVariableOrGrouped {
    final type = widget.mProductModel?.type ?? '';
    return type.contains('grouped') || type.contains('variable');
  }

  bool get _hasDiscount =>
      widget.mProductModel?.onSale == true &&
          (widget.mProductModel?.salePrice ?? '').isNotEmpty;

  String get _displayPrice {
    final p = widget.mProductModel!;
    if (_hasDiscount) return _safePrice(p.salePrice);
    if ((p.regularPrice ?? '').isNotEmpty) return _safePrice(p.regularPrice);
    return _safePrice(p.price);
  }

  String get _oldPrice => _safePrice(widget.mProductModel!.regularPrice);

  /// ✅ هل المنتج ده فعلاً موجود في السلة دلوقتي؟ — مصدر الحقيقة الوحيد لحالة الزرار الدائمة
  bool get _isInCart {
    final id = widget.mProductModel?.id;
    if (id == null) return false;
    return cartStore.isItemInCart(id);
  }

  /// ✅ التعديل الثاني: استخدام الـ thumbnail لبناء الـ CartModel لتسريع السلة أيضاً
  CartModel _buildCartModel(ProductResponse product,
      {int quantity = 1, String? nameOverride}) {
    final images = product.images ?? [];
    final firstImage = images.isNotEmpty
        ? (images.first.thumbnail ?? images.first.src ?? '')
        : '';

    return CartModel(
      proId: product.id,
      name: nameOverride ?? product.name,
      sku: product.sku,
      price: product.price,
      onSale: product.onSale ?? false,
      regularPrice: (product.regularPrice ?? '').isNotEmpty
          ? product.regularPrice
          : product.price,
      salePrice: (product.salePrice ?? '').isNotEmpty
          ? product.salePrice
          : product.price,
      stockQuantity: product.stockQuantity,
      stockStatus: product.inStock == false ? 'outofstock' : 'instock',
      thumbnail: firstImage,
      full: images.isNotEmpty ? (images.first.src ?? '') : '',
      gallery: images.map((e) => e.src ?? '').toList(),
      createdAt: DateTime.now().toIso8601String(),
      quantity: quantity.toString(),
    );
  }

  // ─────────────────────────────────────────────────────────
  // LOGIC
  // ─────────────────────────────────────────────────────────

  void _handleAddTap() {
    HapticFeedback.lightImpact();

    if (widget.onAddTap != null) {
      widget.onAddTap!();
      return;
    }

    final product = widget.mProductModel!;

    // ✅ المنتج البسيط: لو مش في السلة → ضيفه. لو موجود فعلاً → شيله.
    // (cartStore.addToMyCart بتعمل toggle داخليًا أصلاً، فإحنا بس بنستدعيها
    // ومنسيب الواجهة تتابع _isInCart الحقيقي بدل ما نخمّن الحالة محليًا)
    if (_isVariableOrGrouped) {
      _showVariationSheet(product);
      return;
    }

    final wasInCart = _isInCart;
    _addOrRemoveSimpleProduct(product, wasInCart);
  }

  /// ✅ ربط الـ Simple Product بالسلة الحقيقية عبر الـ Store ومزامنة الـ Caching
  void _addOrRemoveSimpleProduct(ProductResponse product, bool wasInCart) async {
    final cartModel = _buildCartModel(product);

    // الومضة الخضراء "تمت الإضافة" تظهر بس لما إحنا فعلاً بنضيف (مش بنشيل)
    if (!wasInCart) {
      setState(() => _justAdded = true);
      _checkController.forward(from: 0);
    }

    // استدعاء الأكشن الأصلي المسؤول عن الإضافة/الحذف (toggle) وحفظ البيانات محلياً
    await cartStore.addToMyCart(cartModel);

    if (!wasInCart) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() => _justAdded = false);
          _checkController.reverse();
        }
      });
    }
  }

  void _showVariationSheet(ProductResponse product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariationBottomSheet(product: product),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final product = widget.mProductModel;
    if (product == null) return const SizedBox.shrink();

    // ✅ التعديل الأول: جلب رابط الصورة المصغرة thumbnail لعرض كروت المنتجات الرئيسية
    final String img = (product.images ?? []).isNotEmpty
        ? (product.images!.first.thumbnail ?? product.images!.first.src ?? '')
        : '';

    return GestureDetector(
      onTap: () => onClickProduct(context, product),
      child: Semantics(
        label: product.name ?? '',
        button: true,
        child: widget.isListView
            ? _buildListCard(context, product, img)
            : _buildGridCard(context, product, img),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // GRID CARD (الشكل الحالي — بدون أي تعديل)
  // ─────────────────────────────────────────────────────────

  Widget _buildGridCard(
      BuildContext context, ProductResponse product, String img) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kFloatingShadow(
          opacity: 0.05,
          blur: 14,
          offset: const Offset(0, 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _imageStack(context, product, img),
          8.height,
          _title(product),
          _shortDesc(product),
          6.height,
          if (!_isVariableOrGrouped) _priceRow(),
          8.height,
          _addButton(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // LIST CARD (الشكل الجديد المطلوب)
  // ─────────────────────────────────────────────────────────

  Widget _buildListCard(
      BuildContext context, ProductResponse product, String img) {
    return Stack(
      children: [
        Container(
          width: widget.width,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: kFloatingShadow(
              opacity: 0.05,
              blur: 14,
              offset: const Offset(0, 6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: commonCacheImageWidget(
                      img,
                      height: 92,
                      width: 92,
                      fit: BoxFit.contain,
                    ),
                  ),
                  mSale(product),
                ],
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    4.height,
                    _title(product, maxLines: 2),
                    _shortDesc(product),
                    6.height,
                    if (!_isVariableOrGrouped) _priceRow(),
                    8.height,
                    _addButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
        PositionedDirectional(
          top: 4,
          end: 8,
          child: ProductWishListExtension(mProductModel: product),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────

  Widget _imageStack(
      BuildContext context, ProductResponse product, String img) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: commonCacheImageWidget(
            img,
            height: 110,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
        if (widget.badgeText != null && widget.badgeText!.isNotEmpty)
          PositionedDirectional(
            top: 0,
            start: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: const BoxDecoration(
                color: kBrandSecondary,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(8),
                  bottomEnd: Radius.circular(8),
                ),
              ),
              child: Text(
                widget.badgeText!,
                style: boldTextStyle(size: 10, color: kBrandPrimary),
              ),
            ),
          ),
        mSale(product),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: ProductWishListExtension(mProductModel: product),
        ),
      ],
    );
  }

  Widget _title(ProductResponse product, {int maxLines = 1}) {
    return Text(
      product.name.validate(),
      style: boldTextStyle(size: 13),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _shortDesc(ProductResponse product) {
    final desc = parseHtmlString(product.shortDescription ?? '').trim();
    if (desc.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '"$desc"',
        style: secondaryTextStyle(size: 11, color: kTextMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _priceRow() {
    if (_displayPrice.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PriceWidget(price: _displayPrice, size: 15, color: kBrandPrimary),
        if (_hasDiscount && _oldPrice.isNotEmpty) ...[
          4.width,
          PriceWidget(
            price: _oldPrice,
            size: 11,
            isLineThroughEnabled: true,
            color: kTextMuted,
          ),
        ],
        const Spacer(),
        if (widget.bestSellerText != null && widget.bestSellerText!.isNotEmpty)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: kBrandSecondary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.bestSellerText!,
              style: boldTextStyle(size: 9, color: kBrandPrimary),
            ),
          ),
      ],
    );
  }

  /// ✅ الزرار — بيتابع حالة السلة الحقيقية عن طريق Observer (MobX)
  /// بدل ما يعتمد على متغير محلي بيرجع لأصله بعد ثانيتين.
  ///
  /// الحالات:
  /// 1) منتج فيه خيارات (variable/grouped)  → "اختر خياراتك" دايمًا (أزرق)
  /// 2) لسه واصل توه (_justAdded = true)     → "تمت الإضافة" + ✓ متحرك (أخضر، ~1.2 ثانية)
  /// 3) موجود في السلة فعلاً (_isInCart)      → "✓ في السلة" (أخضر ثابت لحد ما يتشال)
  /// 4) مش موجود في السلة                    → "أضف للسلة" (أزرق)
  Widget _addButton() {
    return Observer(
      builder: (_) {
        final inCart = _isInCart;
        final showGreen = _justAdded || (inCart && !_isVariableOrGrouped);

        return GestureDetector(
          onTap: _handleAddTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: showGreen ? Colors.green.shade600 : kBrandPrimary,
              borderRadius: BorderRadius.circular(kPillRadius),
              boxShadow: [
                BoxShadow(
                  color: (showGreen ? Colors.green : kBrandPrimary)
                      .withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(kPillRadius),
                onTap: _handleAddTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: _buildButtonContent(inCart),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildButtonContent(bool inCart) {
    // منتج فيه خيارات → دايمًا "اختر خياراتك"، الزرار ده بيفتح Bottom Sheet بس
    if (_isVariableOrGrouped) {
      return [
        Text('اختر خياراتك', style: boldTextStyle(size: 13, color: Colors.white)),
        4.width,
        const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
      ];
    }

    // ومضة التأكيد المؤقتة لسه شغالة
    if (_justAdded) {
      return [
        ScaleTransition(
          scale: _checkAnim,
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        ),
        4.width,
        Text('تمت الإضافة', style: boldTextStyle(size: 12, color: Colors.white)),
      ];
    }

    // الحالة الدائمة: المنتج فعلاً في السلة
    if (inCart) {
      return [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
        4.width,
        Text('في السلة', style: boldTextStyle(size: 12, color: Colors.white)),
      ];
    }

    // الحالة الافتراضية: مش في السلة
    return [
      Text('أضف للسلة', style: boldTextStyle(size: 13, color: Colors.white)),
      4.width,
      const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// _VariationBottomSheet
// يعمل مع البنية الحقيقية: Attributes → name + options: List<String>
// ─────────────────────────────────────────────────────────────
class _VariationBottomSheet extends StatefulWidget {
  final ProductResponse product;
  const _VariationBottomSheet({required this.product});

  @override
  State<_VariationBottomSheet> createState() => _VariationBottomSheetState();
}

class _VariationBottomSheetState extends State<_VariationBottomSheet> {
  /// Map: اسم الـ Attribute (مثل "اللون") → الـ Option المختار
  final Map<String, String?> _selectedOptions = {};

  /// قائمة الـ Attributes من ProductResponse مباشرة
  List<Attributes> get _attributes {
    return widget.product.attributes ?? [];
  }

  @override
  void initState() {
    super.initState();
    for (final attr in _attributes) {
      _selectedOptions[attr.name ?? ''] = null;
    }
  }

  bool get _allSelected =>
      _selectedOptions.isNotEmpty &&
          _selectedOptions.values.every((v) => v != null);

  // ✅ بناء اسم المنتج مع الخيارات المختارة
  String get _nameWithOptions {
    final product = widget.product;
    final selectedLabel = _selectedOptions.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}: ${e.value}')
        .join(' | ');
    return selectedLabel.isNotEmpty
        ? '${product.name ?? ''} ($selectedLabel)'
        : (product.name ?? '');
  }

  // ✅ التعديل الثالث: إضافة خيار الـ thumbnail للمنتجات المتعددة عند الرفع للسلة
  void _addToCart() async {
    HapticFeedback.mediumImpact();

    final product = widget.product;
    final images = product.images ?? [];
    final firstImage = images.isNotEmpty
        ? (images.first.thumbnail ?? images.first.src ?? '')
        : '';

    final cartModel = CartModel(
      proId: product.id,
      name: _nameWithOptions, // ✅ الاسم + الخيارات المختارة
      sku: product.sku,
      price: product.price,
      onSale: product.onSale ?? false,
      regularPrice: (product.regularPrice ?? '').isNotEmpty
          ? product.regularPrice
          : product.price,
      salePrice: (product.salePrice ?? '').isNotEmpty
          ? product.salePrice
          : product.price,
      stockQuantity: product.stockQuantity,
      stockStatus: product.inStock == false ? 'outofstock' : 'instock',
      thumbnail: firstImage,
      full: images.isNotEmpty ? (images.first.src ?? '') : '',
      gallery: images.map((e) => e.src ?? '').toList(),
      createdAt: DateTime.now().toIso8601String(),
      quantity: '1',
    );

    Navigator.pop(context); // ✅ قفل الـ Sheet أولاً

    await cartStore.addToMyCart(cartModel); // ✅ الإضافة الحقيقية للسلة
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final attrs = _attributes;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ── رأس الـ Sheet ───────────────────────────────────────
          Row(
            children: [
              if ((product.images ?? []).isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: commonCacheImageWidget(
                    // ✅ التعديل الرابع: استخدام الـ thumbnail لرأس الـ Sheet المنبثقة للخيارات المتعددة
                    product.images!.first.thumbnail ?? product.images!.first.src ?? '',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? '',
                      style: boldTextStyle(size: 14, color: kBrandPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.height,
                    if ((product.price ?? '').isNotEmpty)
                      PriceWidget(
                        price: double.tryParse(product.price ?? '')
                            ?.toStringAsFixed(2) ??
                            '',
                        size: 14,
                        color: kBrandSecondary,
                      ),
                  ],
                ),
              ),
            ],
          ),

          24.height,
          const Divider(height: 1),
          16.height,

          // ── لو لا يوجد attributes أصلاً ───────────────────────
          if (attrs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'لا توجد خيارات متاحة لهذا المنتج',
                style: secondaryTextStyle(size: 13, color: kTextMuted),
              ),
            )
          else
          // ── Attributes ─────────────────────────────────────
            ...attrs.map((attr) => _attributeSection(attr)),

          20.height,

          // ── زر الإضافة ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: AnimatedOpacity(
              opacity: _allSelected ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 250),
              child: ElevatedButton.icon(
                onPressed: _allSelected ? _addToCart : null,
                icon: const Icon(Icons.shopping_cart_checkout_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  _allSelected
                      ? 'أضف للسلة'
                      : 'اختر جميع الخيارات أولاً',
                  style: boldTextStyle(size: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandPrimary,
                  disabledBackgroundColor: kBrandPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kPillRadius),
                  ),
                  elevation: _allSelected ? 3 : 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// قسم خيارات كل Attribute — يعرض Options كـ Chips
  Widget _attributeSection(Attributes attr) {
    final name = attr.name ?? '';
    final options = attr.options ?? [];
    final selected = _selectedOptions[name];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم الـ Attribute + الـ Option المختار
          Row(
            children: [
              Text(name,
                  style: boldTextStyle(size: 13, color: kBrandPrimary)),
              if (selected != null) ...[
                4.width,
                Text(
                  '— $selected',
                  style: secondaryTextStyle(size: 12, color: kTextMuted),
                ),
              ],
            ],
          ),
          10.height,

          // إذا لم تكن هناك options
          if (options.isEmpty)
            Text(
              'لا توجد قيم لـ $name',
              style: secondaryTextStyle(size: 11, color: kTextMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = selected == option;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedOptions[name] = option);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kBrandPrimary
                          : kBrandPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? kBrandPrimary
                            : kBrandPrimary.withValues(alpha: 0.25),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      option,
                      style: boldTextStyle(
                        size: 12,
                        color: isSelected ? Colors.white : kBrandPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}