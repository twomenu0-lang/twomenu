import 'dart:async';
import 'package:flutter/material.dart';
import '/../main.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import 'DashBoardScreen.dart';
import 'PlaceOrderScreen.dart'; // ✅ إضافة الـ import للتوحيد

/// مراحل شاشة انتظار الدفع بالمحفظة — نفس فكرة الخطوات الظاهرة في صفحة الويب
/// (دفع ناجح / جار المعالجة / إشعار)
enum _WalletStep { processing, notified, success, failed }

class WalletPaymentPendingScreen extends StatefulWidget {
  static String tag = '/WalletPaymentPendingScreen';

  final int orderId;
  final String amount;
  final String? initialMessage;
  final String? orderNumber;   // ✅ إضافة لاستقبال رقم الطلب
  final String? dateCreated;   // ✅ إضافة لاستقبال تاريخ الطلب

  const WalletPaymentPendingScreen({
    super.key,
    required this.orderId,
    required this.amount,
    this.initialMessage,
    this.orderNumber,
    this.dateCreated,
  });

  @override
  WalletPaymentPendingScreenState createState() => WalletPaymentPendingScreenState();
}

class WalletPaymentPendingScreenState extends State<WalletPaymentPendingScreen> {
  Timer? pollTimer;
  int elapsedSeconds = 0;
  static const int timeoutSeconds = 120;
  static const int pollIntervalSeconds = 3;
  bool isChecking = false;

  _WalletStep currentStep = _WalletStep.processing;

  @override
  void initState() {
    super.initState();
    startPolling();
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  void startPolling() {
    // بعد أول نبضة فحص، نعتبر إن الإشعار وصل للسيرفر وبقينا في مرحلة "إشعار"
    Future.delayed(const Duration(seconds: pollIntervalSeconds), () {
      if (mounted && currentStep == _WalletStep.processing) {
        setState(() => currentStep = _WalletStep.notified);
      }
    });

    pollTimer = Timer.periodic(const Duration(seconds: pollIntervalSeconds), (timer) async {
      elapsedSeconds += pollIntervalSeconds;

      if (elapsedSeconds >= timeoutSeconds) {
        timer.cancel();
        if (mounted) showTimeoutDialog();
        return;
      }

      if (isChecking) return;
      isChecking = true;

      try {
        final result = await checkWalletPaymentStatus(widget.orderId);
        isChecking = false;
        if (!mounted) return;

        if (result.isSuccess) {
          timer.cancel();
          if (!mounted) return;

          setState(() => currentStep = _WalletStep.success);

          // مهلة بسيطة عشان المستخدم يشوف علامة النجاح قبل الانتقال
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;

          // ✅ التوحيد: بدل التوجه المباشر لـ DashBoardScreen، بنعدي على PlaceOrderScreen
          // مسح السلة أصبح مسؤولية PlaceOrderScreen وبدء تتبع الطلب
          PlaceOrderScreen(
            mOrderID: widget.orderId,
            total: widget.amount,
            transactionId: '',
            orderNumber: widget.orderNumber,
            paymentMethod: 'kashier_wallet',
            dateCreated: widget.dateCreated ?? DateTime.now().toIso8601String(),
          ).launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Scale);

        } else if (result.isFailed) {
          timer.cancel();
          if (mounted) {
            setState(() => currentStep = _WalletStep.failed);
            showFailedDialog();
          }
        }
      } catch (e) {
        isChecking = false;
      }
    });
  }

  void showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('لم يتم تأكيد الدفع بعد'),
        content: const Text('لم نستلم تأكيد العملية من محفظتك خلال الوقت المحدد. تأكد من موافقتك على الطلب في تطبيق المحفظة، أو حاول مرة أخرى.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              elapsedSeconds = 0;
              setState(() => currentStep = _WalletStep.processing);
              startPolling();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void showFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('فشلت عملية الدفع'),
        content: const Text('تم رفض عملية الدفع من محفظتك. برجاء المحاولة مرة أخرى أو استخدام وسيلة دفع أخرى.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final remainingSeconds = (timeoutSeconds - elapsedSeconds).clamp(0, timeoutSeconds);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: mTop(context, appLocalization.translate('lbl_wallet_payment') ?? 'الدفع بالمحفظة', showBack: false) as PreferredSizeWidget?,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // بطاقة المبلغ الإجمالي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'الإجمالي',
                      style: secondaryTextStyle(size: 13),
                    ),
                    4.height,
                    Text(
                      '${widget.amount} جنيه',
                      style: boldTextStyle(size: 24),
                    ),
                  ],
                ),
              ),
              32.height,

              // مؤشر الخطوات — نفس فكرة صفحة الويب (دفع ناجح / جار المعالجة / إشعار)
              _buildStepper(context),

              32.height,

              Text(
                widget.initialMessage ?? 'برجاء تأكيد الدفع من تطبيق محفظتك الإلكترونية',
                style: boldTextStyle(),
                textAlign: TextAlign.center,
              ),
              10.height,
              Text(
                'قم بإجراء الدفع باستخدام تطبيق محفظتك، وبمجرد الانتهاء من ذلك، قم بإعادة تحميل حالة الدفع لتتبع الدفع وتلقي الإيصال الخاص بك.',
                style: secondaryTextStyle(size: 13),
                textAlign: TextAlign.center,
              ),
              24.height,

              if (currentStep != _WalletStep.success)
                Text(
                  'إعادة الإرسال ${_formatSeconds(remainingSeconds)}',
                  style: secondaryTextStyle(size: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildStepper(BuildContext context) {
    // ترتيب الخطوات الثلاث: دفع ناجح -> جار المعالجة -> إشعار
    final steps = [
      _StepInfo(
        label: 'دفع ناجح',
        icon: Icons.check,
        isDone: true, // العميل بيوصله طلب الدفع فعليًا في هذه المرحلة
      ),
      _StepInfo(
        label: 'جار المعالجة',
        icon: Icons.sync,
        isDone: currentStep == _WalletStep.notified || currentStep == _WalletStep.success,
        isActive: currentStep == _WalletStep.processing,
        spin: currentStep == _WalletStep.processing,
      ),
      _StepInfo(
        label: 'إشعار',
        icon: Icons.mail_outline,
        isDone: currentStep == _WalletStep.success,
        isActive: currentStep == _WalletStep.notified,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // الخط الواصل بين الدوائر
          final leftStepDone = steps[index ~/ 2].isDone;
          return Container(
            width: 40,
            height: 2,
            color: leftStepDone ? Theme.of(context).primaryColor : Colors.grey.shade300,
          );
        }
        final step = steps[index ~/ 2];
        return _buildStepCircle(context, step);
      }),
    );
  }

  Widget _buildStepCircle(BuildContext context, _StepInfo step) {
    final primary = Theme.of(context).primaryColor;
    final isHighlighted = step.isDone || step.isActive;

    Widget iconWidget = Icon(
      step.icon,
      size: 20,
      color: isHighlighted ? primary : Colors.grey,
    );

    if (step.spin) {
      iconWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 1),
        onEnd: () {}, // الدوران المستمر بيتحقق عن طريق إعادة تشغيل التطبيق الحالي للـ Timer
        builder: (_, value, child) => Transform.rotate(angle: value * 6.28, child: child),
        child: iconWidget,
      );
    }

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighlighted ? primary.withOpacity(0.1) : Colors.grey.shade100,
            border: Border.all(color: isHighlighted ? primary : Colors.grey.shade300, width: 1.5),
          ),
          child: Center(child: iconWidget),
        ),
        6.height,
        Text(
          step.label,
          style: TextStyle(
            fontSize: 12,
            color: isHighlighted ? primary : Colors.grey,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StepInfo {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isActive;
  final bool spin;

  _StepInfo({
    required this.label,
    required this.icon,
    this.isDone = false,
    this.isActive = false,
    this.spin = false,
  });
}