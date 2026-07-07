// lib/screen/reward_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import '../models/Reward.dart';
import 'RedemptionScreen.dart';
import 'MyCartScreen.dart';
import '../main.dart';

class RewardDetailsScreen extends StatefulWidget {
  final Reward reward;
  const RewardDetailsScreen({super.key, required this.reward});

  @override
  State<RewardDetailsScreen> createState() => _RewardDetailsScreenState();
}

class _RewardDetailsScreenState extends State<RewardDetailsScreen> {
  bool _isLoading = false;

  // ─── 🆕 Dialog تأكيد استخدام في الفرع (التصميم الجديد والمطلوب) ───────────
  void _onRedeemConfirmed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة التحذير الصفراء داخل دائرة خلفية فاتحة
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFC107),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // العنوان الرئيسي
              const Text(
                'هل أنت أمام الكاشير الآن؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF030048),
                ),
              ),
              const SizedBox(height: 8),
              // نص التنبيه الفرعي
              const Text(
                'لا يمكن التراجع بعد إنشاء الكود',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // أزرار التحكم المتجاوبة
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _generateCode();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF030048),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'تأكيد',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── توليد الكود عبر الـ Store المركزي (مسار الفرع) ────────────────────
  Future<void> _generateCode() async {
    setState(() => _isLoading = true);
    try {
      await rewardsStore.generateCode(widget.reward.rewardId);
      if (!mounted) return;

      if (rewardsStore.activeCode != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RedemptionScreen(
              reward: widget.reward,
              rewardCode: rewardsStore.activeCode!,
            ),
          ),
        );
      } else {
        _showError(rewardsStore.error ?? 'تعذّر إنشاء الكود');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Dialog تأكيد استخدام في طلب التطبيق ───────────────────────────
  void _onInAppConfirmed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'استخدام في طلب التطبيق',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هيتم تطبيق الخصم تلقائياً على طلبك الحالي في السلة.\n'
              'تقدر تكمّل التسوق وتستخدمه وقت ما تحب.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyInApp();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تطبيق الخصم'),
          ),
        ],
      ),
    );
  }

  // ─── تطبيق المكافأة كخصم في السلة عبر الـ Store المركزي ─────────────
  Future<void> _applyInApp() async {
    setState(() => _isLoading = true);
    try {
      final success = await rewardsStore.applyToCart(widget.reward);
      if (!mounted) return;

      if (success && rewardsStore.appliedCoupon != null) {
        final coupon = rewardsStore.appliedCoupon!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 تم تطبيق ${coupon.discountLabel} من ${coupon.partnerName} على السلة',
            ),
            backgroundColor: const Color(0xFF38A169),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyCartScreen(isShowBack: true)),
        );
      } else {
        _showError(rewardsStore.error ?? 'تعذّر تطبيق الخصم');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _discountLabel {
    if (widget.reward.rewardType == 'percentage') {
      return 'خصم ${widget.reward.rewardValue.toInt()}%';
    } else if (widget.reward.rewardType == 'fixed_amount') {
      return 'خصم ${widget.reward.rewardValue.toInt()} جنيه';
    } else if (widget.reward.rewardType == 'free_drink') {
      return 'مشروب مجاني';
    } else if (widget.reward.rewardType == 'free_product') {
      return 'منتج مجاني';
    }
    return widget.reward.rewardTitle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final reward = widget.reward;
    final supportsInApp  = reward.supportsInAppRedemption;
    final supportsBranch = reward.supportsBranchRedemption;

    return Scaffold(
      appBar: AppBar(
        title: Text(reward.partnerName),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: NetworkImage(reward.logoUrl),
              onBackgroundImageError: (_, __) {},
            ),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 28),
                  // 1. لوجو الشريك الكبير
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          reward.logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.store, size: 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. عنوان العرض
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      reward.rewardTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Chip الخصم
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _discountLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. الوصف التفصيلي
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      reward.rewardDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(indent: 24, endIndent: 24),
                  const SizedBox(height: 16),

                  // 5. تعليمات الاستخدام
                  const _SectionTitle(title: 'تعليمات الاستخدام'),
                  const SizedBox(height: 10),
                  const _InstructionItem(text: 'الكود صالح لمدة 5 دقائق فقط (في الفرع)'),
                  const _InstructionItem(text: 'يمكن تجديد الكود مرة واحدة فقط'),
                  const _InstructionItem(text: 'لا يمكن استرجاع المكافأة بعد الاستخدام'),

                  const SizedBox(height: 16),
                  const Divider(indent: 24, endIndent: 24),
                  const SizedBox(height: 16),

                  // 6. الشروط والأحكام
                  const _SectionTitle(title: 'الشروط والأحكام'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'العرض صالح لمرة واحدة فقط لكل مستخدم. لا يمكن الجمع بين هذا العرض وأي عروض أخرى. '
                          'يحق للشريك تعديل أو إلغاء العرض في أي وقت دون إشعار مسبق.',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(indent: 24, endIndent: 24),
                  const SizedBox(height: 16),

                  // 7. تاريخ الانتهاء
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'تنتهي في: ${DateFormat('d MMMM yyyy', 'ar').format(reward.expiryDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Loading Overlay للحماية عند الضغط والتحميل المتزامن
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _isLoading
          ? const SizedBox(height: 90)
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر "في طلب التطبيق" — يظهر تلقائياً إذا كانت المكافأة تدعم ذلك
              if (supportsInApp) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _onInAppConfirmed,
                    icon: Icon(Icons.shopping_bag_outlined, color: primaryColor, size: 20),
                    label: Text(
                      'استخدمها في طلب التطبيق',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // مكون السحب للاستخدام الفوري بالفرع — يظهر فقط لو المكافأة متاحة في الفرع
              if (supportsBranch)
                SlideAction(
                  text: supportsInApp ? 'اسحب للاستخدام في الفرع ←' : 'اسحب للاستخدام ←',
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  outerColor: primaryColor,
                  innerColor: Colors.white,
                  sliderButtonIcon: Icon(
                    Icons.arrow_forward_ios,
                    color: primaryColor,
                    size: 20,
                  ),
                  borderRadius: 16,
                  height: 58,
                  elevation: 0,
                  onSubmit: () {
                    _onRedeemConfirmed();
                    return null;
                  },
                )
              else if (supportsInApp)
              // مكافأة In-App فقط (زي مكافآت توينيو نفسها) — نص توضيحي بدل زر الفرع
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'هذه المكافأة متاحة داخل التطبيق فقط',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// المكونات المساعدة (Widgets) المنفصلة لتنظيم وتنسيق النصوص
// ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String text;
  const _InstructionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, height: 1.5)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}