import 'package:flutter/foundation.dart';

class RewardCode {
  final String code;
  final int rewardId;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final int renewCount;
  final bool isActive;

  const RewardCode({
    required this.code,
    required this.rewardId,
    required this.generatedAt,
    required this.expiresAt,
    required this.renewCount,
    required this.isActive,
  });

  // ✅ parser يعامل أي تاريخ بدون timezone كـ UTC
  static DateTime _parseUtc(String raw) {
    final normalized = raw.trim().endsWith('Z') || raw.contains('+')
        ? raw.trim()
        : '${raw.trim()}Z';
    return DateTime.parse(normalized).toLocal();
  }

  factory RewardCode.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expires_at'] != null
        ? _parseUtc(json['expires_at'].toString())
        : DateTime.now().add(const Duration(minutes: 5));

    debugPrint('✅ expiresAt local: $expiresAt | now: ${DateTime.now()} | diff: ${expiresAt.difference(DateTime.now()).inSeconds}s');

    return RewardCode(
      code: json['code'] ?? '',
      rewardId: json['reward_id'] ?? 0,
      generatedAt: json['generated_at'] != null
          ? _parseUtc(json['generated_at'].toString())
          : DateTime.now(),
      expiresAt: expiresAt,
      renewCount: json['renew_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  int get secondsRemaining {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canRenew => renewCount < 1 && !isExpired;
}