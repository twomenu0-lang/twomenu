import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart'; // ✅ إضافة الـ import الخاص بـ MobX لإدارة التفاعلات الحية
import '../models/Reward.dart';
import '../models/RewardCode.dart';
import '../main.dart';
import 'Successscreen.dart';

class RedemptionScreen extends StatefulWidget {
  final Reward reward;
  final RewardCode rewardCode;

  const RedemptionScreen({
    super.key,
    required this.reward,
    required this.rewardCode,
  });

  @override
  State<RedemptionScreen> createState() => _RedemptionScreenState();
}

class _RedemptionScreenState extends State<RedemptionScreen> {
  // ── ألوان التصميم ────────────────────────────────
  static const Color _primaryColor    = Color(0xFF030048);
  static const Color _secondaryColor  = Color(0xFF4B41E1);
  static const Color _surfaceLow      = Color(0xFFF2F4F6);
  static const Color _surfaceHigh     = Color(0xFFE6E8EA);
  static const Color _onSurfaceVar    = Color(0xFF464650);
  static const Color _warningColor    = Color(0xFFF59E0B);
  static const Color _criticalColor   = Color(0xFFE11D48);

  // ── State ─────────────────────────────────────────
  late RewardCode _code;
  late Duration   _remaining;
  late Duration   _totalDuration;
  Timer?          _countdownTimer;
  Timer?          _renewWaitTimer;

  bool _isExpired      = false;
  bool _isRenewing     = false;
  bool _isConfirming   = false;
  int  _renewWaitSecs  = 30; // الـ 30 ثانية الأولى قبل تفعيل زر التجديد
  bool _renewWaitDone  = false;

  // ✅ v1.7.4 — مفسخ ومعرّف الـ reaction لمنع تسريب الذاكرة (Memory Leaks)
  ReactionDisposer? _redeemedReaction;

  @override
  void initState() {
    super.initState();
    _code = widget.rewardCode;
    _remaining = _code.expiresAt.difference(DateTime.now());
    _totalDuration = const Duration(minutes: 5);

    // ⬇️ الـ Guard: لو الكود انتهى فعلاً قبل ما الشاشة تفتح
    if (_remaining.isNegative || _remaining.inSeconds < 5) {
      _isExpired = true;
      _remaining = Duration.zero;
    } else {
      _startCountdown();
    }
    _startRenewWait();

    // ✅ v1.7.4 — استماع فوري وتلقائي لمتغير isRedeemed من الـ store
    // بمجرد قيام الكاشير بالـ redeem وتحديث الـ store عبر الـ Push Notification
    // يشتغل الـ reaction فوراً لإلغاء التوقيت، تصفير الفلاج، والانتقال لواجهة النجاح
    _redeemedReaction = reaction(
          (_) => rewardsStore.isRedeemed,
          (bool redeemed) {
        if (redeemed && mounted) {
          _countdownTimer?.cancel();
          _renewWaitTimer?.cancel();
          rewardsStore.clearRedeemedFlag(); // تصفير الفلاج ليكون جاهزاً للعملية القادمة
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(reward: widget.reward),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _renewWaitTimer?.cancel();
    _redeemedReaction?.call(); // ✅ تنظيف وإلغاء الـ reaction فور مغادرة الشاشة لحماية موارد النظام
    super.dispose();
  }

  // ── Countdown Timer ───────────────────────────────
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final rem = _code.expiresAt.difference(DateTime.now());
      if (rem.isNegative || rem.inSeconds == 0) {
        setState(() { _remaining = Duration.zero; _isExpired = true; });
        _countdownTimer?.cancel();
      } else {
        setState(() => _remaining = rem);
      }
    });
  }

  // ── 30 ثانية انتظار قبل تفعيل زر التجديد ─────────
  void _startRenewWait() {
    _renewWaitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_renewWaitSecs > 0) _renewWaitSecs--;
        if (_renewWaitSecs == 0) {
          _renewWaitDone = true;
          _renewWaitTimer?.cancel();
        }
      });
    });
  }

  // ── Progress (1.0 → 0.0) ─────────────────────────
  double get _progress {
    if (_totalDuration.inSeconds == 0) return 0;
    return (_remaining.inSeconds / _totalDuration.inSeconds).clamp(0.0, 1.0);
  }

  String get _timerText {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _ringColor {
    if (_remaining.inSeconds < 60)  return _criticalColor;
    if (_remaining.inSeconds < 120) return _warningColor;
    return _secondaryColor;
  }

  String get _expiryTimeText {
    final t = _code.expiresAt;
    final h = t.hour > 12 ? t.hour - 12 : t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'م' : 'ص';
    return 'صالح حتى $h:$m $period';
  }

  // ── Actions ───────────────────────────────────────
  Future<void> _renewCode() async {
    if (_isRenewing || !_code.canRenew) return;
    setState(() => _isRenewing = true);
    await rewardsStore.renewCode(widget.reward.rewardId);
    if (!mounted) return;
    if (rewardsStore.activeCode != null) {
      setState(() {
        _code          = rewardsStore.activeCode!;
        _remaining     = _code.expiresAt.difference(DateTime.now());
        _totalDuration = const Duration(minutes: 5);
        _isExpired     = false;
      });
      _startCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rewardsStore.error ?? 'تعذّر تجديد الكود'),
          backgroundColor: _criticalColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    setState(() => _isRenewing = false);
  }

  Future<void> _confirmUsage() async {
    if (_isConfirming || _isExpired) return;
    setState(() => _isConfirming = true);
    final success = await rewardsStore.redeem(_code.code, widget.reward.rewardId);
    if (!mounted) return;
    if (success) {
      _countdownTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SuccessScreen(reward: widget.reward)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rewardsStore.error ?? 'تعذّر تأكيد الاستخدام'),
          backgroundColor: _criticalColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _isConfirming = false);
    }
  }

  // ── Build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تفاصيل المكافأة',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [

              // ── 1. كارت الشريك ───────────────────
              _PartnerCard(reward: widget.reward),
              const SizedBox(height: 24),

              // ── 2. عنوان الكود ───────────────────
              const Text(
                'كود الاستخدام',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'أعرض هذا الكود للكاشير ليتم تطبيق الخصم',
                style: TextStyle(fontSize: 14, color: _onSurfaceVar),
              ),
              const SizedBox(height: 24),

              // ── 3. دائرة العداد + الكود ──────────
              SizedBox(
                width: 256,
                height: 256,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring الخلفية
                    const SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        color: _surfaceHigh,
                      ),
                    ),
                    // Ring التقدم
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        color: _ringColor,
                      ),
                    ),
                    // محتوى الدائرة
                    Container(
                      margin: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F9FB),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // العداد
                            Text(
                              _isExpired ? '00:00' : _timerText,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _isExpired ? _criticalColor : _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // الكبير (تم التحديث لمنع انكسار السطر)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isExpired ? '------' : _code.code,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: _isExpired ? Colors.grey.shade400 : _secondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // وقت الانتهاء
                            Text(
                              _expiryTimeText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _onSurfaceVar,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. تعليمات الاستخدام ─────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تعليمات الاستخدام',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _InfoRow(text: 'الكود صالح لمدة 5 دقائق فقط'),
                    _InfoRow(
                      text: _code.canRenew
                          ? 'يمكن تجديد الكود مرة واحدة فقط'
                          : 'تم استخدام فرصة التجديد',
                      faded: !_code.canRenew,
                    ),
                    const _InfoRow(text: 'لا يمكن استرجاع المكافأة بعد الاستخدام'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 5. زر التجديد ────────────────────
              _RenewButton(
                canRenew:      _code.canRenew,
                renewWaitDone: _renewWaitDone,
                renewWaitSecs: _renewWaitSecs,
                isRenewing:    _isRenewing,
                isExpired:     _isExpired,
                onRenew:       _renewCode,
              ),

              // ── 6. زر تم الاستخدام ───────────────
              if (!_isExpired) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _confirmUsage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'تم الاستخدام',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// كارت الشريك
// ─────────────────────────────────────────────────
class _PartnerCard extends StatelessWidget {
  final Reward reward;
  const _PartnerCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              reward.logoUrl,
              width: 64, height: 64, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64, height: 64,
                color: const Color(0xFFECEEF0),
                child: const Icon(Icons.store, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.rewardTitle,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Color(0xFF030048),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reward.rewardDescription,
                  style: const TextStyle(
                    fontSize: 13, color: Color(0xFF464650),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// زر التجديد مع منطق الـ 30 ثانية
// ─────────────────────────────────────────────────
class _RenewButton extends StatelessWidget {
  final bool canRenew;
  final bool renewWaitDone;
  final int  renewWaitSecs;
  final bool isRenewing;
  final bool isExpired;
  final VoidCallback onRenew;

  const _RenewButton({
    required this.canRenew,
    required this.renewWaitDone,
    required this.renewWaitSecs,
    required this.isRenewing,
    required this.isExpired,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpired && !canRenew) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E3E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'انتهت صلاحية الكود',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      );
    }

    final bool active = renewWaitDone && canRenew;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: active && !isRenewing ? onRenew : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: active
              ? const Color(0xFF4B41E1)
              : const Color(0xFFE0E3E5),
          foregroundColor: active ? Colors.white : Colors.grey,
          disabledBackgroundColor: const Color(0xFFE0E3E5),
          disabledForegroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isRenewing
            ? const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.refresh),
        label: Text(
          isRenewing
              ? 'جاري التجديد...'
              : active
              ? 'تجديد الكود الآن'
              : 'يمكنك تجديد الكود بعد 00:${renewWaitSecs.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// صف معلومة واحدة
// ─────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String text;
  final bool faded;
  const _InfoRow({required this.text, this.faded = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6,
              color: faded ? Colors.grey.shade300 : const Color(0xFF464650)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: faded ? Colors.grey.shade400 : const Color(0xFF464650),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}