import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '/../main.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppBarWidget.dart';
import '/../screen/DashBoardScreen.dart';
import '/../screen/OrderListScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Constants.dart';
import '/../utils/SharedPref.dart';
import 'package:nb_utils/nb_utils.dart';

import '../AppLocalizations.dart';
import '../utils/Colors.dart';

// ignore: must_be_immutable
class PlaceOrderScreen extends StatefulWidget {
  static String tag = '/PlaceOrderScreen';
  var mOrderID, total, transactionId, orderKey, paymentMethod, dateCreated;

  PlaceOrderScreen({
    Key? key,
    this.mOrderID,
    this.total,
    this.transactionId,
    this.orderKey,
    this.paymentMethod,
    this.dateCreated,
  }) : super(key: key);

  @override
  PlaceOrderScreenState createState() => PlaceOrderScreenState();
}

class PlaceOrderScreenState extends State<PlaceOrderScreen>
    with SingleTickerProviderStateMixin {
  DateTime? date = DateTime.now();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
    init();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  init() async {
    // ← أضف السطر ده مؤقتاً للاختبار
    print('DEBUG PLAYER_ID = ${getStringAsync(PLAYER_ID)}');

    createOrderTracking();
    try {
      date = DateTime.parse(widget.dateCreated);
    } catch (_) {
      date = DateTime.now();
    }
  }

  Future createOrderTracking() async {
    appStore.setLoading(true);
    var request = {
      'customer_note': true,
      'note': "{\n\"status\":\"Ordered\",\n\"message\":\"Your order has been placed.\"\n} ",
    };
    await createOrderNotes(widget.mOrderID, request).then((res) {
      if (!mounted) return;
      appStore.setLoading(false);
    }).catchError((error) {
      if (!mounted) return;
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  onComplete() async {
    if (!await isGuestUser()) {
      clearCartItems().then((response) async {
        if (!mounted) return;
        cartStore.clearCart();
        appStore.setCount(0);
        await DashBoardScreen().launch(context, isNewTask: true);
        await Future.delayed(Duration(milliseconds: 800));
        if (!mounted) return;
        OrderListScreen().launch(context);
      }).catchError((error) {
        setState(() {});
        toast(error.toString());
      });
    } else {
      appStore.setCount(0);
      cartStore.clearCart();
      await DashBoardScreen().launch(context, isNewTask: true);
      await Future.delayed(Duration(milliseconds: 800));
      if (!mounted) return;
      OrderListScreen().launch(context);
    }
  }

  void _shareOrder(AppLocalizations appLocalization) {
    final text =
        '🛍️ ${appLocalization.translate('lbl_oder_placed_successfully')}\n\n'
        '💰 ${appLocalization.translate('lbl_total_amount_')}: ${widget.total}\n'
        '🔖 ${appLocalization.translate('order_id')}: ${widget.orderKey}\n'
        '📅 ${appLocalization.translate('lbl_transaction_date')}: ${date.toString()}';
    Share.share(text);
  }

  // ── Progress Tracker — نفس تصميم OrderDetailScreen ──────────────────────
  Widget _buildProgressTracker() {
    // processing = step 1 (تم الطلب + جاري التجهيز)
    // الشاشة دي بتظهر مباشرة بعد الطلب يعني دايماً step = 1
    const int currentStep = 1;

    final steps = [
      {'icon': Icons.receipt_long_outlined,   'label': 'تم الطلب'},
      {'icon': Icons.inventory_2_outlined,    'label': 'جاري التجهيز'},
      {'icon': Icons.local_shipping_outlined, 'label': 'تم الشحن'},
      {'icon': Icons.home_outlined,           'label': 'تم التسليم'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl, // ✅ RTL من اليمين لليسار
        child: Row(
          children: List.generate(steps.length, (i) {
            final isActive  = i <= currentStep;
            final isLast    = i == steps.length - 1;
            final textColor = isActive ? primaryColor! : Colors.grey;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isActive
                                ? primaryColor!.withValues(alpha: 0.12)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? primaryColor!
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            steps[i]['icon'] as IconData,
                            color: isActive
                                ? primaryColor
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                        4.height,
                        Text(
                          steps[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // نقطة المؤشر على الخطوة الحالية فقط
                        if (i == currentStep) ...[
                          4.height,
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: i < currentStep
                              ? primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Color(0xFF1E2235) : Color(0xFFF4F5FA);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: isHalloween ? mChristmasColor : primaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: white),
            onPressed: () => onComplete(),
          ),
          automaticallyImplyLeading: false,
        ),
      ),
      body: BodyCornerWidget(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [

                // ── أيقونة النجاح ────────────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF66953A).withOpacity(0.08),
                        ),
                      ),
                      Container(
                        width: 85, height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF66953A).withOpacity(0.15),
                        ),
                      ),
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF66953A),
                        ),
                        child: Icon(Icons.check, color: white, size: 34),
                      ),
                      Positioned(
                        top: 2, right: 10,
                        child: Icon(Icons.star,
                            color: primaryColor!.withOpacity(0.5), size: 10),
                      ),
                      Positioned(
                        bottom: 4, left: 8,
                        child: Icon(Icons.star,
                            color: primaryColor!.withOpacity(0.4), size: 8),
                      ),
                      Positioned(
                        top: 10, left: 14,
                        child: Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor!.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                20.height,

                // ── العنوان ──────────────────────────────────────────────
                Text(
                  'تم الطلب بنجاح!',
                  style: boldTextStyle(size: 22),
                  textAlign: TextAlign.center,
                ),
                10.height,
                Text(
                  'شكراً لثقتك بنا، سنقوم بتجهيز طلبك\nوإرساله إليك في أقرب وقت.',
                  style: secondaryTextStyle(size: 13),
                  textAlign: TextAlign.center,
                ),
                24.height,

                // ── بطاقة تفاصيل الطلب ──────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: appLocalization.translate('lbl_total_amount_')!,
                        value: widget.total.toString(),
                        isPrice: true,
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16),
                      _DetailRow(
                        icon: Icons.copy_outlined,
                        label: appLocalization.translate('order_id')!,
                        value: widget.orderKey.toString(),
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: widget.orderKey.toString()));
                          toast('تم نسخ رقم الطلب');
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: appLocalization.translate('lbl_transaction_date')!,
                        value: date.toString(),
                      ),
                    ],
                  ),
                ),
                20.height,

                // ── Progress Tracker — موحد مع OrderDetailScreen ─────────
                _buildProgressTracker(),
                28.height,

                // ── زر مشاركة تفاصيل الطلب ──────────────────────────────
                SizedBox(
                  width: context.width(),
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareOrder(appLocalization),
                    icon: Icon(Icons.share_outlined, color: white, size: 20),
                    label: Text('مشاركة تفاصيل الطلب',
                        style: primaryTextStyle(color: white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                12.height,

                // ── زر العودة للرئيسية ───────────────────────────────────
                SizedBox(
                  width: context.width(),
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => onComplete(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor!.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('العودة إلى الرئيسية',
                        style: primaryTextStyle(color: primaryColor)),
                  ),
                ),
                16.height,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget: صف تفصيلة ────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPrice;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPrice = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: primaryColor, size: 18),
            ),
            12.width,
            Text(label, style: secondaryTextStyle(size: 13)).expand(),
            isPrice
                ? PriceWidget(price: value, size: 14)
                : Text(
              value,
              style: boldTextStyle(size: 13, color: primaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (onTap != null) ...[
              4.width,
              Icon(Icons.copy, size: 14, color: primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}
