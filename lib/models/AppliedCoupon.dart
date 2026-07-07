// lib/models/AppliedCoupon.dart

class AppliedCoupon {
  final String couponCode;
  final String rewardTitle;
  final String partnerName;
  final String discountType;   // 'percentage' | 'fixed_amount'
  final double discountValue;
  final double? maxDiscount;
  final String expiresAt;

  const AppliedCoupon({
    required this.couponCode,
    required this.rewardTitle,
    required this.partnerName,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.expiresAt,
  });

  static double? _parseNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory AppliedCoupon.fromJson(Map<String, dynamic> json) => AppliedCoupon(
    couponCode:    json['coupon_code']    ?? '',
    rewardTitle:   json['reward_title']   ?? '',
    partnerName:   json['partner_name']   ?? '',
    discountType:  json['discount_type']  ?? '',
    discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
    maxDiscount:   _parseNullableDouble(json['max_discount']),
    expiresAt:     json['expires_at']     ?? '',
  );

  /// نص جاهز للعرض في الـ SnackBar — مثال: "خصم 10% (حتى 200 ج.م)"
  String get discountLabel {
    if (discountType == 'percentage') {
      final base = 'خصم ${discountValue.toStringAsFixed(0)}%';
      if (maxDiscount != null && maxDiscount! > 0) {
        return '$base (حتى ${maxDiscount!.toStringAsFixed(0)} ج.م)';
      }
      return base;
    }
    return 'خصم ${discountValue.toStringAsFixed(0)} ج.م';
  }
}