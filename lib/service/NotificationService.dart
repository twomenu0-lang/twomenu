import 'dart:convert';
import 'package:nb_utils/nb_utils.dart';

// ─────────────────────────────────────────────────────────────────
// NOTIFICATION TYPES
// أنواع الإشعارات القادمة من Backend عبر OneSignal
// الـ type بيجي في data payload مع كل إشعار
// ─────────────────────────────────────────────────────────────────
class NotificationType {
  // مكافآت
  static const String newReward        = 'new_reward';        // مكافأة جديدة متاحة
  static const String rewardExpiry48h  = 'reward_expiry_48h'; // :تنبيه قبل 48 ساعة
  static const String rewardExpiry24h  = 'reward_expiry_24h'; // تنبيه قبل 24 ساعة
  static const String rewardRedeemed   = 'reward_redeemed';   // تأكيد استخدام

  // مستويات الإنفاق
  static const String tierUpgraded     = 'tier_upgraded';     // وصول لمستوى جديد
  static const String cycleReminder    = 'cycle_reminder';    // تذكير قبل أسبوعين من التصفير
  static const String cycleReset       = 'cycle_reset';       // بداية دورة سنوية جديدة
}

// ─────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String type; // ✅ نوع الإشعار من NotificationType
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.type = '',   // ✅ القيمة الافتراضية نص فارغ لحماية الكود القديم
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'time': time.toIso8601String(),
    'type': type,     // ✅
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
        type: json['type'] ?? '',  // ✅
        isRead: json['isRead'] ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────

const String _NOTIFICATIONS_KEY = 'LOCAL_NOTIFICATIONS';
const int _MAX_NOTIFICATIONS = 50; // الحد الأقصى للإشعارات المحفوظة

class NotificationService {
  // ── جلب كل الإشعارات المحفوظة ──
  static List<AppNotification> getAll() {
    try {
      final String raw = getStringAsync(_NOTIFICATIONS_KEY);
      if (raw.isEmpty) return [];
      final List list = jsonDecode(raw);
      return list.map((e) => AppNotification.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── حفظ إشعار جديد (بيجي من OneSignal) ──
  static Future<void> save({
    required String id,
    required String title,
    required String body,
    String type = '',  // ✅ استقبال النوع الجديد
  }) async {
    // تجنب التكرار
    final List<AppNotification> existing = getAll();
    if (existing.any((n) => n.id == id)) return;

    final newNotification = AppNotification(
      id: id,
      title: title,
      body: body,
      time: DateTime.now(),
      type: type,  // ✅ تمرير النوع للموديل
      isRead: false,
    );

    existing.insert(0, newNotification); // الأحدث في الأول

    // الاحتفاظ بآخر 50 إشعار بس
    final trimmed = existing.take(_MAX_NOTIFICATIONS).toList();
    await setValue(_NOTIFICATIONS_KEY, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  // ── تعليم كل الإشعارات كمقروءة (بمجرد فتح الصفحة) ──
  static Future<void> markAllAsRead() async {
    final List<AppNotification> list = getAll();
    if (list.isEmpty) return;
    final updated = list.map((n) => AppNotification(
      id: n.id,
      title: n.title,
      body: n.body,
      time: n.time,
      type: n.type, // ✅ إضافة مهمة: الحفاظ على نوع الإشعار وعدم تصفيره عند التحديث
      isRead: true,
    )).toList();
    await setValue(_NOTIFICATIONS_KEY, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }

  // ── عدد الإشعارات غير المقروءة (للـ badge) ──
  static int unreadCount() {
    return getAll().where((n) => !n.isRead).length;
  }

  // ── مسح كل الإشعارات ──
  static Future<void> clearAll() async {
    await setValue(_NOTIFICATIONS_KEY, '');
  }
}