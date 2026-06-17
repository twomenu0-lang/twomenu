import 'dart:convert';
import 'package:nb_utils/nb_utils.dart';

// ─────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
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
  }) async {
    // تجنب التكرار
    final List<AppNotification> existing = getAll();
    if (existing.any((n) => n.id == id)) return;

    final newNotification = AppNotification(
      id: id,
      title: title,
      body: body,
      time: DateTime.now(),
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