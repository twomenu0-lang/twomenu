import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '/../main.dart';
import '/../service/NotificationService.dart';
import '/../utils/AppColors.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/AppWidget.dart';

class NotificationScreen extends StatefulWidget {
  static String tag = '/NotificationScreen';

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadAndMarkRead();
  }

  Future<void> _loadAndMarkRead() async {
    final data = NotificationService.getAll();
    setState(() => _notifications = data);
    await NotificationService.markAllAsRead();
    appStore.setUnreadNotificationCount(0);
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('مسح الإشعارات', style: boldTextStyle()),
        content: Text('هل تريد مسح جميع الإشعارات؟', style: primaryTextStyle()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('مسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotificationService.clearAll();
      setState(() => _notifications = []);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ دالة تحدد الأيقونة واللون تلقائياً حسب عنوان الإشعار
  // الكلمات المفتاحية بتتطابق مع نصوص الـ OneSignal في order-journey.php
  // ─────────────────────────────────────────────────────────────
  _NotificationStyle _getStyle(String title) {
    final t = title.toLowerCase();

    // تم استلام الطلب / processing
    if (t.contains('استلام') || t.contains('استقبل') || t.contains('جديد')) {
      return _NotificationStyle(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF27AE60),
      );
    }

    // قيد التجهيز / preparing
    if (t.contains('تجهيز') || t.contains('تحضير') || t.contains('جاري')) {
      return _NotificationStyle(
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFF39C12),
      );
    }

    // طلبك في الطريق / shipped
    if (t.contains('طريق') || t.contains('شحن') || t.contains('شحنه') ||
        t.contains('توصيل') || t.contains('مندوب')) {
      return _NotificationStyle(
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF2980B9),
      );
    }

    // تم التسليم بنجاح / completed
    if (t.contains('تسليم') || t.contains('وصل') || t.contains('اكتمل') ||
        t.contains('completed')) {
      return _NotificationStyle(
        icon: Icons.celebration_rounded,
        color: kBrandPrimary,
      );
    }

    // إلغاء الطلب / cancelled
    if (t.contains('إلغاء') || t.contains('الغاء') || t.contains('ملغي') ||
        t.contains('رفض')) {
      return _NotificationStyle(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFE74C3C),
      );
    }

    // فشل الدفع / payment failed
    if (t.contains('دفع') || t.contains('فشل') || t.contains('payment')) {
      return _NotificationStyle(
        icon: Icons.credit_card_off_rounded,
        color: const Color(0xFFE74C3C),
      );
    }

    // عروض وخصومات / offers
    if (t.contains('خصم') || t.contains('عرض') || t.contains('تخفيض') ||
        t.contains('كوبون') || t.contains('مجاناً')) {
      return _NotificationStyle(
        icon: Icons.local_offer_rounded,
        color: const Color(0xFFE74C3C),
      );
    }

    // منتج عاد للمخزون / back in stock
    if (t.contains('مخزون') || t.contains('متاح') || t.contains('stock')) {
      return _NotificationStyle(
        icon: Icons.inventory_rounded,
        color: const Color(0xFF27AE60),
      );
    }

    // تقييم طلبك / review request
    if (t.contains('تقييم') || t.contains('رأيك') || t.contains('review')) {
      return _NotificationStyle(
        icon: Icons.star_rounded,
        color: const Color(0xFFF1C40F),
      );
    }

    // استرداد / refund
    if (t.contains('استرداد') || t.contains('رجع') || t.contains('refund')) {
      return _NotificationStyle(
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF8E44AD),
      );
    }

    // افتراضي — جرس عادي
    return _NotificationStyle(
      icon: Icons.notifications_rounded,
      color: kBrandPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: mTop(
        context,
        'الإشعارات',
        showBack: true,
        actions: _notifications.isEmpty
            ? []
            : [
          IconButton(
            icon: Icon(Icons.delete_outline, color: kTextMuted),
            tooltip: 'مسح الكل',
            onPressed: _clearAll,
          ),
        ],
      ) as PreferredSizeWidget?,
      body: BodyCornerWidget(
        child: _notifications.isEmpty
            ? _emptyState(context)
            : RefreshIndicator(
          onRefresh: _loadAndMarkRead,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => 12.height,
            itemBuilder: (context, index) {
              return _notificationCard(context, _notifications[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification item) {
    // ✅ جلب الأيقونة واللون المناسبين لهذا الإشعار
    final style = _getStyle(item.title);

    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? context.cardColor : kBrandPrimaryLight,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kFloatingShadow(
          opacity: 0.05,
          blur: 12,
          offset: const Offset(0, 4),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ أيقونة ديناميكية — تتغير حسب نوع الإشعار
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(style.icon, color: Colors.white, size: 22),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title, style: boldTextStyle(size: 15)),
                    ),
                    if (!item.isRead)
                      Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: kBrandSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                4.height,
                Text(
                  item.body,
                  style: secondaryTextStyle(size: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                6.height,
                Text(
                  _formatTime(item.time),
                  style: secondaryTextStyle(size: 11, color: kTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${time.day}/${time.month}/${time.year}';
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: kTextMuted),
          12.height,
          Text('لا توجد إشعارات حالياً', style: boldTextStyle(size: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Model بسيط يحمل الأيقونة واللون لكل نوع إشعار
// ─────────────────────────────────────────────────────────────
class _NotificationStyle {
  final IconData icon;
  final Color color;

  const _NotificationStyle({required this.icon, required this.color});
}