import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:Twomenu/main.dart';
import 'package:Twomenu/models/ProductReviewModel.dart';
import 'package:Twomenu/network/rest_apis.dart';
import 'package:Twomenu/utils/AppBarWidget.dart';
import 'package:Twomenu/utils/AppWidget.dart';
import 'package:Twomenu/utils/Colors.dart';
import 'package:Twomenu/utils/Common.dart';
import 'package:Twomenu/utils/Constants.dart';
import 'package:Twomenu/utils/SharedPref.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';

Color get _primary => primaryColor ?? const Color(0xFF4358DD);

class ReviewScreen extends StatefulWidget {
  static String tag = '/ReviewScreen';
  final dynamic mProductId;
  final String? productName;
  final String? productVariant;
  final String? productImage;

  const ReviewScreen({
    Key? key,
    this.mProductId,
    this.productName,
    this.productVariant,
    this.productImage,
  }) : super(key: key);

  @override
  ReviewScreenState createState() => ReviewScreenState();
}

class ReviewScreenState extends State<ReviewScreen> {
  List<ProductReviewModel> reviewList = [];
  bool isLoading = false;
  String _activeFilter = 'latest';

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => isLoading = true);
    try {
      final Iterable res = await getProductReviews(widget.mProductId);
      setState(() {
        reviewList =
            res.map((e) => ProductReviewModel.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      toast(e.toString());
    }
  }

  double get _averageRating {
    if (reviewList.isEmpty) return 0;
    final double sum =
    reviewList.fold(0, (prev, r) => prev + (r.rating ?? 0));
    return sum / reviewList.length;
  }

  Map<int, int> get _ratingCounts {
    final Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviewList) {
      final int star = (r.rating ?? 0).clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return counts;
  }

  List<ProductReviewModel> get _filteredReviews {
    final List<ProductReviewModel> list = List.from(reviewList);
    switch (_activeFilter) {
      case 'highest':
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'lowest':
        list.sort((a, b) => (a.rating ?? 0).compareTo(b.rating ?? 0));
        break;
    }
    return list;
  }

  void _showWriteReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(onSubmit: _submitReview),
    );
  }

  Future<void> _submitReview(double rating, String text) async {
    if (!getBoolAsync(IS_LOGGED_IN)) {
      toast(
        AppLocalizations.of(context)?.translate('lbl_login_required') ??
            'يجب تسجيل الدخول',
      );
      return;
    }
    appStore.setLoading(true);
    try {
      final Map<String, dynamic> request = {
        'product_id': widget.mProductId,
        'rating': rating.toInt(),
        'review': text,
        'reviewer': getStringAsync(FIRST_NAME),
        'reviewer_email': getStringAsync(USER_EMAIL),
        'status': 'approved',
      };
      await postReview(request);
      if (mounted) Navigator.pop(context);
      toast(
        AppLocalizations.of(context)?.translate('lbl_review_submitted') ??
            'تم إرسال التقييم',
      );
      await _fetchReviews();
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: mTop(
        context,
        t.translate('lbl_reviews') ?? 'التعليقات والتقييمات',
      ) as PreferredSizeWidget?,
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _fetchReviews,
            child: CustomScrollView(
              slivers: [
                // ── بطاقة المنتج ──
                SliverToBoxAdapter(
                  child: _ProductHeaderCard(
                    productName: widget.productName ?? '',
                    variant: widget.productVariant ?? '',
                    imageUrl: widget.productImage,
                  ),
                ),
                // ── ملخص التقييمات ──
                if (reviewList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _RatingSummaryCard(
                      average: _averageRating,
                      total: reviewList.length,
                      counts: _ratingCounts,
                    ),
                  ),
                // ── شريط الفلاتر ──
                if (reviewList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FilterBar(
                      active: _activeFilter,
                      onChanged: (v) =>
                          setState(() => _activeFilter = v),
                    ),
                  ),
                // ── القائمة أو الحالة الفارغة ──
                reviewList.isEmpty
                    ? SliverFillRemaining(
                  child: _EmptyReviewsState(
                    onWriteReview: _showWriteReviewSheet,
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _ReviewCard(
                        review: _filteredReviews[i]),
                    childCount: _filteredReviews.length,
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: 88)),
              ],
            ),
          ),

          // ── زر "اكتب تقييماً" الثابت ──
          if (!isLoading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _showWriteReviewSheet,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  t.translate('lbl_write_review') ?? 'اكتب تقييماً',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: _primary.withOpacity(0.4),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          Observer(
              builder: (_) => Loader().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// بطاقة المنتج
// ═══════════════════════════════════════════════════════
class _ProductHeaderCard extends StatelessWidget {
  final String productName;
  final String variant;
  final String? imageUrl;

  const _ProductHeaderCard({
    required this.productName,
    required this.variant,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── صورة المنتج ──
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon(),
              ),
            )
          else
            _placeholderIcon(),
          const SizedBox(width: 12),
          // ── النصوص ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    variant,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_left,
              color: Color(0xFFBBBBCC), size: 20),
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.shopping_bag_outlined,
          color: Color(0xFFBBBBCC), size: 28),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ملخص التقييمات
// ═══════════════════════════════════════════════════════
class _RatingSummaryCard extends StatelessWidget {
  final double average;
  final int total;
  final Map<int, int> counts;

  const _RatingSummaryCard({
    required this.average,
    required this.total,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── الرقم الكبير ──
          Column(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              RatingBarIndicator(
                rating: average,
                itemBuilder: (_, __) =>
                const Icon(Icons.star, color: Color(0xFFFFC107)),
                itemCount: 5,
                itemSize: 17,
              ),
              const SizedBox(height: 5),
              Text(
                'بناءً على ($total) تقييم',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // ── أشرطة النجوم ──
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final int count = counts[star] ?? 0;
                final double ratio = total > 0 ? count / total : 0;
                final Color barColor = star >= 4
                    ? _primary
                    : star == 3
                    ? const Color(0xFFFFC107)
                    : const Color(0xFFFF6B6B);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      Text('$star',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444466))),
                      const SizedBox(width: 4),
                      const Icon(Icons.star,
                          size: 12, color: Color(0xFFFFC107)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 7,
                            backgroundColor:
                            const Color(0xFFEEEFF5),
                            valueColor:
                            AlwaysStoppedAnimation(barColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 26,
                        child: Text('$count',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// شريط الفلاتر
// ═══════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'latest', 'label': 'الأحدث', 'icon': Icons.access_time},
      {
        'key': 'highest',
        'label': 'الأعلى تقييماً',
        'icon': Icons.trending_up
      },
      {
        'key': 'lowest',
        'label': 'الأقل تقييماً',
        'icon': Icons.trending_down
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDDEE8)),
            ),
            child: const Icon(Icons.tune_rounded,
                size: 18, color: Color(0xFF555577)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: filters.map((f) {
                  final bool isActive = active == f['key'];
                  return GestureDetector(
                    onTap: () => onChanged(f['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? _primary
                              : const Color(0xFFDDDEE8),
                        ),
                        boxShadow: isActive
                            ? [
                          BoxShadow(
                            color: _primary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : [],
                      ),
                      child: Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF555577),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// الحالة الفارغة
// ═══════════════════════════════════════════════════════
class _EmptyReviewsState extends StatelessWidget {
  final VoidCallback onWriteReview;

  const _EmptyReviewsState({required this.onWriteReview});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _primary.withOpacity(0.12),
                    _primary.withOpacity(0.03),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 60,
                    color: _primary.withOpacity(0.45),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 22,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star,
                          size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'لا توجد تقييمات بعد',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'كن أول من يشاركنا رأيك في هذا المنتج\nوساعد الآخرين على اتخاذ القرار المناسب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onWriteReview,
              icon: Icon(Icons.edit_outlined, size: 16, color: _primary),
              label: Text(
                'اكتب أول تقييم',
                style:
                TextStyle(color: _primary, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// بطاقة التقييم
// ═══════════════════════════════════════════════════════
class _ReviewCard extends StatefulWidget {
  final ProductReviewModel review;

  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final String reviewText = widget.review.review ?? '';
    final bool isLong = reviewText.length > 150;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _primary.withOpacity(0.13),
                child: Text(
                  (widget.review.reviewerName?.isNotEmpty == true)
                      ? widget.review.reviewerName![0].toUpperCase()
                      : '؟',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.review.reviewerName ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        if (widget.review.verified == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified,
                                    size: 10, color: Color(0xFF4CAF50)),
                                SizedBox(width: 3),
                                Text(
                                  'مشتري موثق',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: (widget.review.rating ?? 0).toDouble(),
                      itemBuilder: (_, __) => const Icon(
                          Icons.star,
                          color: Color(0xFFFFC107)),
                      itemCount: 5,
                      itemSize: 14,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(widget.review.dateCreated),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (reviewText.isNotEmpty) ...[
            Text(
              _expanded || !isLong
                  ? reviewText
                  : '${reviewText.substring(0, 150)}...',
              style: const TextStyle(
                fontSize: 13,
                height: 1.65,
                color: Color(0xFF444466),
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'عرض أقل' : 'عرض المزيد',
                  style: TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'هل كان هذا التعليق مفيداً؟',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
              const Spacer(),
              _HelpfulButton(
                  icon: Icons.thumb_up_outlined, label: 'نعم'),
              const SizedBox(width: 10),
              _HelpfulButton(icon: Icons.thumb_down_outlined, label: 'لا'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateCreated) {
    if (dateCreated == null) return '';
    try {
      final dt = DateTime.parse(dateCreated.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _HelpfulButton extends StatefulWidget {
  final IconData icon;
  final String label;

  const _HelpfulButton({required this.icon, required this.label});

  @override
  State<_HelpfulButton> createState() => _HelpfulButtonState();
}

class _HelpfulButtonState extends State<_HelpfulButton> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _active = !_active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _active ? _primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _active ? _primary.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: _active ? _primary : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                color: _active ? _primary : Colors.grey.shade400,
                fontWeight:
                _active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Bottom Sheet: كتابة تقييم — بدون خيار الصور
// ═══════════════════════════════════════════════════════
class _WriteReviewSheet extends StatefulWidget {
  final Future<void> Function(double rating, String text) onSubmit;

  const _WriteReviewSheet({required this.onSubmit});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 0;
  final TextEditingController _ctrl = TextEditingController();
  bool _isSubmitting = false;

  static const List<String> _ratingLabels = [
    '',
    'سيء',
    'مقبول',
    'جيد',
    'جيد جداً',
    'رائع',
  ];

  static const List<Color> _ratingColors = [
    Colors.transparent,
    Color(0xFFFF6B6B),
    Color(0xFFFF9762),
    Color(0xFFFFC107),
    Color(0xFF66BB6A),
    Color(0xFF43A047),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الـ handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── العنوان ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.black54, size: 18),
                      ),
                    ),
                    const Text(
                      'اكتب تقييماً',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F5)),
              const SizedBox(height: 20),

              // ── السؤال ──
              const Text(
                'ما رأيك في هذا المنتج؟',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 14),

              // ── النجوم ──
              Center(
                child: Column(
                  children: [
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      itemCount: 5,
                      itemSize: 44,
                      glow: true,
                      glowColor:
                      const Color(0xFFFFC107).withOpacity(0.3),
                      itemBuilder: (_, __) => const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC107)),
                      unratedColor: const Color(0xFFDDDEE8),
                      onRatingUpdate: (r) =>
                          setState(() => _rating = r),
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _rating > 0 ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _rating > 0
                              ? _ratingColors[_rating.toInt()]
                              .withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _rating > 0
                              ? _ratingLabels[_rating.toInt()]
                              : '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _rating > 0
                                ? _ratingColors[_rating.toInt()]
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── حقل التعليق ──
              StatefulBuilder(
                builder: (_, setInner) => TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  maxLength: 1000,
                  textDirection: TextDirection.rtl,
                  onChanged: (_) => setInner(() {}),
                  decoration: InputDecoration(
                    hintText: 'اكتب تعليقك هنا...',
                    hintTextDirection: TextDirection.rtl,
                    counterText: '${_ctrl.text.length}/1000',
                    filled: true,
                    fillColor: const Color(0xFFF7F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFDDDEE8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFDDDEE8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      BorderSide(color: _primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── زر الإرسال ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                    if (_rating == 0) {
                      toast('يرجى اختيار تقييم بالنجوم');
                      return;
                    }
                    setState(() => _isSubmitting = true);
                    await widget.onSubmit(_rating, _ctrl.text);
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text('إرسال التقييم'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}