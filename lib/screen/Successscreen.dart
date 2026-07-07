// lib/screen/Successscreen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/Reward.dart';

class SuccessScreen extends StatefulWidget {
  final Reward reward;
  const SuccessScreen({super.key, required this.reward});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {          // ✅ تغيير 1: SingleTicker → TickerProviderStateMixin
  static const Color _primaryColor   = Color(0xFF030048);
  static const Color _secondaryColor = Color(0xFF4B41E1);
  static const Color _warningColor   = Color(0xFFF59E0B);
  static const Color _onSurfaceVar   = Color(0xFF464650);

  int _selectedRating = 0;
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // ✅ تغيير 2: إضافة controllers للـ Glow والـ Confetti
  late AnimationController _glowCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();

    // Glow pulse مستمر
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.12, end: 0.32).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Confetti loop
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _glowCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usageTime = DateTime.now();
    final h = usageTime.hour > 12 ? usageTime.hour - 12 : usageTime.hour;
    final m = usageTime.minute.toString().padLeft(2, '0');
    final period = usageTime.hour >= 12 ? 'م' : 'ص';
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final dateText =
        '${usageTime.day} ${months[usageTime.month]} ${usageTime.year} - $h:$m $period';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: _primaryColor),
          onPressed: () => Navigator.of(context)
              .popUntil((route) => route.isFirst),
        ),
        title: const Text(
          'تم الاستخدام بنجاح',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // ✅ تغيير 3: Stack لإضافة Confetti خلف المحتوى
      body: Stack(
        children: [
          // Confetti في الخلفية
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_confettiCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),
          // المحتوى الأصلي بدون أي تغيير
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      children: [

                        // ── Checkmark مع Glow ──────────────────
                        AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (_, child) => Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow ring
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF10B981)
                                      .withOpacity(_glowAnim.value),
                                ),
                              ),
                              child!,
                            ],
                          ),
                          child: ScaleTransition(
                            scale: _scaleAnim,
                            child: Container(
                              width: 112, height: 112,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x4010B981),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── العنوان ────────────────────
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: const Column(
                            children: [
                              Text(
                                'تم استخدام مكافأتك بنجاح',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'نتمنى لك تجربة رائعة!',
                                style: TextStyle(
                                  fontSize: 16, color: _onSurfaceVar,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── كارت ملخص الاستخدام ────────
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8, offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        widget.reward.logoUrl,
                                        width: 48, height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 48, height: 48,
                                          color: const Color(0xFFECEEF0),
                                          child: const Icon(Icons.store,
                                              color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.reward.partnerName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.reward.rewardTitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _onSurfaceVar,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2DFFF),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 20,
                                        color: _secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'تاريخ ووقت الاستخدام',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _onSurfaceVar,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateText,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── تقييم بالنجوم ──────────────
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8, offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'كيف كانت تجربتك؟',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'ساعدنا في تحسين العروض والخدمات المقدمة لك',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12, color: _onSurfaceVar,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (i) {
                                    final filled = i < _selectedRating;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedRating = i + 1),
                                      child: AnimatedScale(
                                        scale: filled ? 1.15 : 1.0,
                                        duration:
                                        const Duration(milliseconds: 150),
                                        child: Icon(
                                          filled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 40,
                                          color: filled
                                              ? _warningColor
                                              : const Color(0xFFC7C5D2),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── زر العودة ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.redeem_outlined),
                      label: const Text(
                        'العودة للمكافآت',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
// Confetti Painter
// ─────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rnd       = Random(42);
  static final _particles = List.generate(30, (_) => _Particle(_rnd));

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = t * (size.height + 40) - 20;
      if (y < 0 || y > size.height) continue;

      final paint = Paint()..color = p.color.withOpacity(0.55);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * pi * 4 * p.rotSpeed);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x, offset, size, rotSpeed;
  final bool isCircle;
  final Color color;

  _Particle(Random r)
      : x        = r.nextDouble(),
        offset   = r.nextDouble(),
        size     = r.nextDouble() * 7 + 4,
        rotSpeed = r.nextDouble() * 2 + 0.5,
        isCircle = r.nextBool(),
        color    = const [
          Color(0xFF4B41E1),
          Color(0xFF10B981),
          Color(0xFFF59E0B),
          Color(0xFFE11D48),
          Color(0xFF030048),
        ][r.nextInt(5)];
}