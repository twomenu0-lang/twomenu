import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '/../models/ProductResponse.dart';
import '/../utils/Constants.dart';
import '/../utils/AppColors.dart';
import 'package:nb_utils/nb_utils.dart';
import 'ProductCard.dart';

/// ─────────────────────────────────────────────────────────────
/// DashboardComponent — يستخدم ProductCard المحدَّث بسلوك "أضف للسلة" الذكي
///
/// السلوك الجديد المورَّث تلقائياً من ProductCard:
/// • ضغط الصورة/الاسم        ← فتح صفحة المنتج
/// • ضغط "أضف للسلة"          ← إضافة فورية (منتج بسيط) أو Bottom Sheet (متعدد الخيارات)
/// ─────────────────────────────────────────────────────────────
class DashboardComponent extends StatefulWidget {
  const DashboardComponent({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.product,
    required this.onTap,
    this.badgeText,
    this.bestSellerText,
  }) : super(key: key);

  final String title;
  final String subTitle;
  final List<ProductResponse> product;
  final Function onTap;

  /// شارة أعلى صورة المنتج (مثال: "جديد" / "عرض اليوم")
  final String? badgeText;

  /// شارة بجانب السعر (مثال: "الأكثر مبيعاً")
  final String? bestSellerText;

  @override
  _DashboardComponentState createState() => _DashboardComponentState();
}

class _DashboardComponentState extends State<DashboardComponent> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ─────────────────────────────────────────────────────────
  // Grid بـ ProductCard
  // ─────────────────────────────────────────────────────────
  Widget _productGrid(BuildContext context, List<ProductResponse> product) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 16 * 2;
    const double gap = 12;
    final double cardWidth = (screenWidth - horizontalPadding - gap) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AlignedGridView.count(
        scrollDirection: Axis.vertical,
        itemCount: product.length >= TOTAL_DASHBOARD_ITEM
            ? TOTAL_DASHBOARD_ITEM
            : product.length,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: gap,
        itemBuilder: (context, i) {
          return ProductCard(
            mProductModel: product[i],
            width: cardWidth,
            badgeText: widget.badgeText,
            bestSellerText: widget.bestSellerText,
            // onAddTap: null → يستخدم المنطق الذكي الافتراضي في ProductCard
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Header: عنوان القسم + رابط "عرض الكل"
  // ─────────────────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          // نقطة برتقالية-صفراء كمؤشر للقسم
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              color: kBrandSecondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: boldTextStyle(size: 16, color: kBrandPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // "عرض الكل" — يظهر فقط لو عدد المنتجات >= الحد الأدنى
          if (widget.product.length >= TOTAL_DASHBOARD_ITEM)
            GestureDetector(
              onTap: () => widget.onTap.call(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.subTitle,
                    style: boldTextStyle(size: 13, color: kBrandPrimary),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: kBrandPrimary,
                    size: 18,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.product.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        _productGrid(context, widget.product),
      ],
    );
  }
}