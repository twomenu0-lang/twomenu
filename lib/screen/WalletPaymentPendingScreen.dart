import 'dart:async';
import 'package:flutter/material.dart';
import '/../main.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppWidget.dart'; // ✅ الصحيح
import '/../utils/Constants.dart'; // ✅ إضافة — كانت السبب في undefined CART_DATA
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import 'DashBoardScreen.dart';
// ✅ تم حذف import 'Successscreen.dart' لأنه غير مستخدم فعلياً هنا

class WalletPaymentPendingScreen extends StatefulWidget {
  static String tag = '/WalletPaymentPendingScreen';

  final int orderId;
  final String amount;
  final String? initialMessage;

  const WalletPaymentPendingScreen({super.key, required this.orderId, required this.amount, this.initialMessage});

  @override
  WalletPaymentPendingScreenState createState() => WalletPaymentPendingScreenState();
}

class WalletPaymentPendingScreenState extends State<WalletPaymentPendingScreen> {
  Timer? pollTimer;
  int elapsedSeconds = 0;
  static const int timeoutSeconds = 120;
  static const int pollIntervalSeconds = 3;
  bool isChecking = false;

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
          clearCartItems().catchError((_) {});
          appStore.setCount(0);
          removeKey(CART_DATA);
          const DashBoardScreen().launch(context, isNewTask: true);
        } else if (result.isFailed) {
          timer.cancel();
          if (mounted) showFailedDialog();
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: mTop(context, appLocalization.translate('lbl_wallet_payment') ?? 'الدفع بالمحفظة', showBack: false) as PreferredSizeWidget?,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            24.height,
            Text(
              widget.initialMessage ?? 'برجاء تأكيد الدفع من تطبيق محفظتك الإلكترونية',
              style: boldTextStyle(),
              textAlign: TextAlign.center,
            ).paddingSymmetric(horizontal: 24),
            8.height,
            const Text(
              'في انتظار التأكيد...',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}