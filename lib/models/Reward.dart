// lib/models/Reward.dart

class Reward {
  final int rewardId;
  final String partnerName;
  final String logoUrl;
  final String rewardTitle;
  final String rewardDescription;
  final String rewardType;
  final double rewardValue;
  final DateTime expiryDate;
  final String status;
  final int maxUsesPerUser;
  // 🆕 الحد الأقصى للخصم بالجنيه (مهم بس لو reward_type = percentage)
  // مستخدم في حساب discount داخل التطبيق وفي عرض "خصم حتى X جنيه"
  final double? maxDiscountAmount;
  // 🆕 مكان الصرف المتاح للعميل — يتحكم فيه الأدمن من لوحة التحكم لكل مكافأة
  final bool availableInBranch;
  final bool availableInApp;

  const Reward({
    required this.rewardId,
    required this.partnerName,
    required this.logoUrl,
    required this.rewardTitle,
    required this.rewardDescription,
    required this.rewardType,
    required this.rewardValue,
    required this.expiryDate,
    required this.status,
    required this.maxUsesPerUser,
    this.maxDiscountAmount,
    this.availableInBranch = true,
    this.availableInApp = true,
  });

  // ✅ معالجة دفاعية: قيم WordPress/$wpdb الرقمية غالباً ترجع كـ String
  // (مثلاً "37" بدل 37، أو "10.00" بدل 10.0) — فبنتعامل مع الحالتين بأمان
  // بدل استخدام (as int) أو (as num) المباشر اللي ممكن يعمل Crash فوري.
  static int _parseInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _parseDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static double? _parseNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // 🆕 أعمدة TINYINT(1) بترجع من $wpdb كـ String زي "1"/"0" مش true/false،
  // فبنتعامل مع كل الاحتمالات بأمان. الافتراضي true للتوافق مع أي رد قديم
  // من نسخة API أقدم لسه ما بترجّعش الحقلين دول خالص.
  static bool _parseBool(dynamic v, [bool fallback = true]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return fallback;
    return s == '1' || s == 'true' || s == 'yes';
  }

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    // ✅ الـ API الحالي (get_user_rewards) بيرجع 'user_reward_id'، ومش بيرجع 'reward_id' خالص.
    // ده بالضبط نفس المعرّف المطلوب في generate-code / renew-code / redeem / apply-to-cart،
    // فلازم نقرأه هو بالاسم الصحيح ده مش 'reward_id'.
    rewardId: _parseInt(json['user_reward_id']),
    partnerName: json['partner_name'] ?? '',
    logoUrl: json['logo_url'] ?? '',
    rewardTitle: json['reward_title'] ?? '',
    rewardDescription: json['reward_description'] ?? '',
    rewardType: json['reward_type'] ?? '',
    rewardValue: _parseDouble(json['reward_value']),
    // ✅ الـ API بيرجع 'date_expiry'، مش 'expiry_date'.
    // تاريخ بعيد جداً كـ fallback لو الحقل مفقود لأي سبب، لحماية المكافأة من الظهور كـ "منتهية" بالخطأ.
    expiryDate: json['date_expiry'] != null
        ? DateTime.parse(json['date_expiry'])
        : DateTime(2099, 12, 31),
    status: json['status'] ?? 'active',
    // ⚠️ ملحوظة: 'max_uses_per_user' غير موجود حالياً في استجابة get_user_rewards
    // (موجود في جدول twomenu_rewards بس مش مُضاف لـ SELECT في class-api.php)
    // فهياخد القيمة الافتراضية 1 دايماً لحد ما يُضاف للـ SELECT في الباك-إند.
    maxUsesPerUser: _parseInt(json['max_uses_per_user'], 1),
    // 🆕 نفس ملحوظة max_uses_per_user — لو مش موجود في الـ SELECT لسه، هيفضل null
    // وده مقبول لأنه مهم فقط وقت تطبيق الخصم داخل التطبيق (rewards_store.applyToCart)
    maxDiscountAmount: _parseNullableDouble(json['max_discount_amount']),
    // 🆕 مكان الصرف — الافتراضي true لو الحقل غير موجود (توافق مع نسخ أقدم من الـ API)
    availableInBranch: _parseBool(json['available_in_branch']),
    availableInApp: _parseBool(json['available_in_app']),
  );

  // ✅ تحقق مما إذا كانت المكافأة قد استُخدمت بالفعل
  bool get isUsed =>
      status.toLowerCase() == 'used' ||
          status.toLowerCase() == 'redeemed';

  // ✅ تحقق مما إذا كانت المكافأة منتهية الصلاحية (ولم تُستخدم بعد لتجنب تداخل الحالات)
  bool get isExpired => expiryDate.isBefore(DateTime.now()) && !isUsed;

  // ✅ تحقق مما إذا كانت المكافأة أوشكت على الانتهاء (أقل من 48 ساعة ولسه صالحة)
  bool get isExpiringSoon =>
      expiryDate.difference(DateTime.now()).inHours < 48 &&
          expiryDate.isAfter(DateTime.now());

  // ✅ تحديد مفتاح اللون بناءً على المدة المتبقية مباشرة (حساب مركزي نظيف)
  /// أحمر = أقل من 48 ساعة | كهرماني = من 3 إلى 7 أيام (أقل من 168 ساعة) | رمادي = أكثر من أسبوع
  String get expiryColorKey {
    final hoursLeft = expiryDate.difference(DateTime.now()).inHours;
    if (hoursLeft < 48) return 'red';
    if (hoursLeft < 168) return 'amber'; // 7 أيام * 24 ساعة
    return 'grey';
  }

  // 🆕 الباك إند (apply-to-cart) بيقبل فقط النوعين دول للاستخدام داخل التطبيق
  // (free_drink / free_product مرفوضين هناك لأنهم منتجات فعلية مش خصم نقدي)
  // + لازم الأدمن يكون فعّل إتاحة التطبيق لهذه المكافأة تحديداً
  bool get supportsInAppRedemption =>
      (rewardType == 'percentage' || rewardType == 'fixed_amount') &&
          availableInApp;

  // 🆕 هل يُسمح باستخدام هذه المكافأة في الفرع عن طريق الكاشير؟
  bool get supportsBranchRedemption => availableInBranch;

  Reward copyWith({String? status}) => Reward(
    rewardId: rewardId,
    partnerName: partnerName,
    logoUrl: logoUrl,
    rewardTitle: rewardTitle,
    rewardDescription: rewardDescription,
    rewardType: rewardType,
    rewardValue: rewardValue,
    expiryDate: expiryDate,
    status: status ?? this.status,
    maxUsesPerUser: maxUsesPerUser,
    maxDiscountAmount: maxDiscountAmount,
    availableInBranch: availableInBranch,
    availableInApp: availableInApp,
  );
}