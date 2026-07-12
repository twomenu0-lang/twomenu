import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '/../AppLocalizations.dart';
import '/../main.dart';
import '/../service/NotificationService.dart';
import '/../utils/AppColors.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/AppWidget.dart';

class NotificationScreen extends StatefulWidget {
  static String tag = '/NotificationScreen';

  const NotificationScreen({super.key});

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
    var appLocalization = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: appLocalization.translate('clear_notifications_title') ?? 'مسح الإشعارات',
      message: appLocalization.translate('clear_notifications_msg') ?? 'هل تريد مسح جميع الإشعارات؟',
      icon: Icons.delete_sweep_rounded,
      positiveText: appLocalization.translate('lbl_clear') ?? 'مسح',
      negativeText: appLocalization.translate('lbl_cancel') ?? 'إلغاء',
    );
    if (confirmed == true) {
      await NotificationService.clearAll();
      setState(() => _notifications = []);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ دالة تحدد الأيقونة واللون تلقائياً حسب نوع الإشعار أو عنوانه
  // (منطق تحديد النوع نفسه يعتمد على القيمة الخام item.type/النص، فمش محتاج ترجمة،
  // الترجمة مطلوبة بس للنصوص اللي بتظهر فعليًا للمستخدم)
  // ─────────────────────────────────────────────────────────────
  _NotificationStyle _getStyle(AppNotification item) {
    switch (item.type) {
    // حالات الطلب
      case 'order_confirmed':
        return const _NotificationStyle(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF27AE60),
        );
      case 'order_pending':
        return const _NotificationStyle(
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFFF39C12),
        );
      case 'order_processing':
        return const _NotificationStyle(
          icon: Icons.inventory_2_rounded,
          color: Color(0xFFF39C12),
        );
      case 'order_on_hold':
        return const _NotificationStyle(
          icon: Icons.pause_circle_rounded,
          color: Color(0xFFF39C12),
        );
      case 'order_shipped':
        return const _NotificationStyle(
          icon: Icons.local_shipping_rounded,
          color: Color(0xFF2980B9),
        );
      case 'order_completed':
        return const _NotificationStyle(
          icon: Icons.celebration_rounded,
          color: kBrandPrimary,
        );
      case 'order_cancelled':
        return const _NotificationStyle(
          icon: Icons.cancel_rounded,
          color: Color(0xFFE74C3C),
        );
      case 'order_failed':
        return const _NotificationStyle(
          icon: Icons.credit_card_off_rounded,
          color: Color(0xFFE74C3C),
        );
      case 'order_refunded':
        return const _NotificationStyle(
          icon: Icons.currency_exchange_rounded,
          color: Color(0xFF8E44AD),
        );

    // مكافآت ومستويات (NotificationType)
      case NotificationType.newReward:
        return const _NotificationStyle(
          icon: Icons.card_giftcard_rounded,
          color: kBrandPrimary,
        );
      case NotificationType.rewardExpiry48h:
      case NotificationType.rewardExpiry24h:
        return const _NotificationStyle(
          icon: Icons.timer_rounded,
          color: Color(0xFFF39C12),
        );
      case NotificationType.rewardRedeemed:
        return const _NotificationStyle(
          icon: Icons.redeem_rounded,
          color: Color(0xFF27AE60),
        );
      case NotificationType.tierUpgraded:
        return const _NotificationStyle(
          icon: Icons.workspace_premium_rounded,
          color: Color(0xFFF1C40F),
        );
      case NotificationType.cycleReminder:
        return const _NotificationStyle(
          icon: Icons.event_repeat_rounded,
          color: Color(0xFFF39C12),
        );
      case NotificationType.cycleReset:
        return const _NotificationStyle(
          icon: Icons.refresh_rounded,
          color: kBrandPrimary,
        );
    }

    // ⚠️ Fallback: لإشعارات قديمة اتسجلت قبل إضافة الـ type (type فاضي)
    // بيحلل النص العربي زي الأول (ده منطق تحليل داخلي مش نص ظاهر للمستخدم، فمش محتاج ترجمة)
    final t = '${item.title} ${item.body}'.toLowerCase();

    if (t.contains('استلام') || t.contains('استقبل') || t.contains('جديد')) {
      return const _NotificationStyle(icon: Icons.check_circle_rounded, color: Color(0xFF27AE60));
    }
    if (t.contains('تجهيز') || t.contains('تحضير') || t.contains('جاري')) {
      return const _NotificationStyle(icon: Icons.inventory_2_rounded, color: Color(0xFFF39C12));
    }
    if (t.contains('طريق') || t.contains('شحن') || t.contains('توصيل') || t.contains('مندوب')) {
      return const _NotificationStyle(icon: Icons.local_shipping_rounded, color: Color(0xFF2980B9));
    }
    if (t.contains('تسليم') || t.contains('وصل') || t.contains('اكتمل') || t.contains('completed')) {
      return const _NotificationStyle(icon: Icons.celebration_rounded, color: kBrandPrimary);
    }
    if (t.contains('إلغاء') || t.contains('الغاء') || t.contains('ملغي') || t.contains('رفض')) {
      return const _NotificationStyle(icon: Icons.cancel_rounded, color: Color(0xFFE74C3C));
    }
    if (t.contains('فشل') || t.contains('لم تكتمل عملية الدفع')) {
      return const _NotificationStyle(icon: Icons.credit_card_off_rounded, color: Color(0xFFE74C3C));
    }
    if (t.contains('خصم') || t.contains('عرض') || t.contains('كوبون') || t.contains('مجاناً')) {
      return const _NotificationStyle(icon: Icons.local_offer_rounded, color: Color(0xFFE74C3C));
    }
    if (t.contains('مخزون') || t.contains('متاح') || t.contains('stock')) {
      return const _NotificationStyle(icon: Icons.inventory_rounded, color: Color(0xFF27AE60));
    }
    if (t.contains('تقييم') || t.contains('رأيك') || t.contains('review')) {
      return const _NotificationStyle(icon: Icons.star_rounded, color: Color(0xFFF1C40F));
    }
    if (t.contains('استرداد') || t.contains('رجع') || t.contains('refund')) {
      return const _NotificationStyle(icon: Icons.currency_exchange_rounded, color: Color(0xFF8E44AD));
    }

    return const _NotificationStyle(icon: Icons.notifications_rounded, color: kBrandPrimary);
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: mTop(
        context,
        appLocalization.translate('lbl_notifications') ?? 'الإشعارات',
        showBack: true,
        actions: _notifications.isEmpty
            ? []
            : [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kTextMuted),
            tooltip: appLocalization.translate('lbl_clear_all') ?? 'مسح الكل',
            onPressed: _clearAll,
          ),
        ],
      ) as PreferredSizeWidget?,
      body: BodyCornerWidget(
        child: _notifications.isEmpty
            ? _emptyState(context, appLocalization)
            : RefreshIndicator(
          onRefresh: _loadAndMarkRead,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => 12.height,
            itemBuilder: (context, index) {
              return _notificationCard(context, _notifications[index], appLocalization);
            },
          ),
        ),
      ),
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification item, AppLocalizations appLocalization) {
    // ✅ جلب الأيقونة واللون المناسبين لهذا الإشعار
    final style = _getStyle(item);

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
                  _formatTime(item.time, appLocalization),
                  style: secondaryTextStyle(size: 11, color: kTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ نصوص الوقت النسبي بقت بتتترجم، مع الاحتفاظ بالعربي كـ fallback
  // مفاتيح الترجمة بتستخدم %d كعنصر نائب للرقم يتم استبداله يدويًا
  // ─────────────────────────────────────────────────────────────
  String _formatTime(DateTime time, AppLocalizations appLocalization) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return appLocalization.translate('time_just_now') ?? 'الآن';
    }
    if (diff.inMinutes < 60) {
      final template = appLocalization.translate('time_minutes_ago') ?? 'منذ %d دقيقة';
      return template.replaceAll('%d', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      final template = appLocalization.translate('time_hours_ago') ?? 'منذ %d ساعة';
      return template.replaceAll('%d', '${diff.inHours}');
    }
    if (diff.inDays == 1) {
      return appLocalization.translate('time_yesterday') ?? 'أمس';
    }
    if (diff.inDays < 7) {
      final template = appLocalization.translate('time_days_ago') ?? 'منذ %d أيام';
      return template.replaceAll('%d', '${diff.inDays}');
    }
    return '${time.day}/${time.month}/${time.year}';
  }

  Widget _emptyState(BuildContext context, AppLocalizations appLocalization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 64, color: kTextMuted),
          12.height,
          Text(
            appLocalization.translate('lbl_no_notifications_yet') ?? 'لا توجد إشعارات حالياً',
            style: boldTextStyle(size: 16),
          ),
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