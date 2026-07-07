import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppWidget.dart';

/// Bottom Sheet بيعرض صفحة الدفع بالكارت المستضافة عند كاشير داخل WebView.
/// بيرجع (pop) بقيمة true لو الدفع نجح، أو false لو فشل/اتقفل قبل الإتمام.
class CardPaymentSheet extends StatefulWidget {
  final int orderId;
  final String amount;

  const CardPaymentSheet({super.key, required this.orderId, required this.amount});

  @override
  State<CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<CardPaymentSheet> {
  WebViewController? _controller;
  bool _isBusy = true;
  bool _paymentHandled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prepareCheckout();
  }

  Future<void> _prepareCheckout() async {
    try {
      final result = await initiateCardPayment(widget.orderId);
      final checkoutUrl = result['checkout_url']?.toString();

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('تعذر تجهيز رابط الدفع، حاول مرة أخرى');
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              print('🔍 WEBVIEW STARTED LOADING URL: $url');
            },
            onPageFinished: (url) {
              print('🔍 WEBVIEW URL: $url');
              if (_paymentHandled) return;

              if (url.contains('card/redirect')) {
                _paymentHandled = true;
                _confirmAndClose();
              }
            },
            onWebResourceError: (error) {
              // ✅ التصحيح: تجاهل أخطاء الموارد الفرعية (ORB وغيرها) ولا نخفي صفحة الدفع
              print('⚠️ WEBVIEW RESOURCE ERROR (ignored): ${error.description}, Type: ${error.errorType}');
            },
          ),
        )
        ..loadRequest(Uri.parse(checkoutUrl));

      if (!mounted) return;
      setState(() => _isBusy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _confirmAndClose() async {
    if (!mounted) return;
    setState(() => _isBusy = true);

    await Future.delayed(const Duration(seconds: 2));

    bool isSuccess = false;
    try {
      final status = await checkCardPaymentStatus(widget.orderId);
      isSuccess = (status['status']?.toString().toUpperCase() == 'SUCCESS');
      print('ℹ️ CHECK PAYMENT STATUS RESULT FOR ORDER ${widget.orderId}: ${status['status']}');
    } catch (e) {
      print('❌ ERROR CHECKING STATUS FOR ORDER ${widget.orderId}: ${e.toString()}');
      isSuccess = false;
    }

    if (!mounted) return;
    Navigator.of(context).pop(isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              10.height,
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              12.height,
              Row(
                children: [
                  16.width,
                  Text('الدفع بالكارت', style: boldTextStyle(size: 16)).expand(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  8.width,
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: _errorMessage != null
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      style: secondaryTextStyle(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                    : Stack(
                  children: [
                    if (_controller != null) WebViewWidget(controller: _controller!),
                    if (_isBusy) const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}