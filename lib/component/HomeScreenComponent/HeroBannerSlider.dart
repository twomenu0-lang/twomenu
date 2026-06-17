import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/AppColors.dart';
import '../../utils/AppWidget.dart';

/// ─────────────────────────────────────────────────────────────
/// HeroBannerItem
/// ─────────────────────────────────────────────────────────────
class HeroBannerItem {
  final String image;
  final String? badge;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onTap;
  final String heroTag;

  const HeroBannerItem({
    required this.image,
    required this.heroTag,
    this.badge,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onTap,
  });
}

/// ─────────────────────────────────────────────────────────────
/// HeroBannerSlider — الإصدار النقي فائق الأداء والوضوح 🚀
/// ─────────────────────────────────────────────────────────────
class HeroBannerSlider extends StatefulWidget {
  final List<HeroBannerItem> items;
  final double? height;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const HeroBannerSlider({
    Key? key,
    required this.items,
    this.height,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<HeroBannerSlider> createState() => _HeroBannerSliderState();
}

class _HeroBannerSliderState extends State<HeroBannerSlider> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    if (widget.autoPlay && widget.items.length > 1) _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_controller.hasClients) return;

      final next = (_currentPage + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final double computedHeight = widget.height ?? MediaQuery.sizeOf(context).height * 0.24;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: computedHeight,
          child: RepaintBoundary(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is UserScrollNotification) {
                  _timer?.cancel();
                } else if (notification is ScrollEndNotification) {
                  if (widget.autoPlay && widget.items.length > 1) {
                    _startAutoPlay();
                  }
                }
                return false;
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return PageView.builder(
                    controller: _controller,
                    itemCount: widget.items.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    // ✅ التعديل 1: تبسيط الـ itemBuilder وإلغاء حسابات الـ Scale والـ Parallax تماماً
                    itemBuilder: (context, index) {
                      return _bannerSlide(context, widget.items[index], index, 0.0);
                    },
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.items.length > 1) ...[
          12.height,
          _indicators(),
        ],
      ],
    );
  }

  Widget _bannerSlide(BuildContext context, HeroBannerItem item, int index, double parallaxOffset) {
    return Semantics(
      label: "إعلان حركي: ${item.title ?? 'عرض مميز'}",
      button: true,
      child: GestureDetector(
        onTap: item.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kBannerRadius),
            color: kBrandPrimaryLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ✅ التعديل 2: تبسيط الـ Hero وإزالة الـ Transform الداخلي لمنع الإزاحة الغريبة للصورة
              Hero(
                tag: item.heroTag,
                child: commonCacheImageWidget(
                  item.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // ✅ التعديل 3: تم حذف حاوية الـ kGlassOverlayGradient تماماً لإرجاع ألوان البنر الأصلية والنقية بدون تشويش رمادي

              if (item.title != null || item.subtitle != null || item.badge != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 0.54,
                    margin: const EdgeInsets.all(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.badge != null && item.badge!.isNotEmpty)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kBrandSecondary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(item.badge!, style: boldTextStyle(size: 11, color: kBrandPrimary)),
                                  ),
                                ),
                              if (item.badge != null) 6.height,
                              if (item.title != null && item.title!.isNotEmpty)
                                Text(
                                  item.title!,
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: boldTextStyle(size: 18, color: kBrandPrimary),
                                ),
                              if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                                4.height,
                                Text(
                                  item.subtitle!,
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: secondaryTextStyle(size: 12, color: kBrandPrimary.withValues(alpha: 0.75)),
                                ),
                              ],
                              if (item.buttonText != null && item.buttonText!.isNotEmpty) ...[
                                12.height,
                                Material(
                                  color: kBrandPrimary,
                                  borderRadius: BorderRadius.circular(kPillRadius),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(kPillRadius),
                                    onTap: item.onTap,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(item.buttonText!, style: boldTextStyle(size: 12, color: Colors.white)),
                                          4.width,
                                          const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.items.length, (index) {
        final bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 24 : 6,
          decoration: BoxDecoration(
            color: isActive ? kBrandPrimary : kBrandPrimary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}