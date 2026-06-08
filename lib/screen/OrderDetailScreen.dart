import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // ✅ أضف هذا في pubspec.yaml: share_plus: ^7.0.0
import '/../main.dart';
import '/../models/OrderModel.dart';
import '/../models/OrderTracking.dart';
import '/../models/TrackingResponse.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import 'ProductDetail/ProductDetailScreen1.dart';
import 'ProductDetail/ProductDetailScreen2.dart';
import 'ProductDetail/ProductDetailScreen3.dart';

class OrderDetailScreen extends StatefulWidget {
  static String tag = '/OrderDetailScreen';
  final OrderResponse? mOrderModel;
  OrderDetailScreen({this.mOrderModel});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<OrderTracking> mOrderTrackingModel = [];
  List<TrackingResponse> mGetTrackingModel = [];

  // ✅ بيانات الطلب المحدثة من API
  OrderResponse? _currentOrder;

  // ✅ حالة تحديث يدوي مستقلة عن appStore.isLoading
  bool _isRefreshing = false;

  // ── بيانات المتجر ─────────────────────────────────────────────────────────
  static const String _storePhone = '01036464686';
  static const String _storeEmail = 'info@twomenu.shop';
  static const String _waNumber   = '201036363282';

  // ── أسباب الإلغاء بالعربي ────────────────────────────────────────────────
  final List<String> mCancelList = [
    'العنوان المدخل غير صحيح',
    'لم أعد بحاجة للمنتج',
    'وجدت بديلاً بسعر أفضل',
    'انخفض سعر المنتج بعد الطلب',
    'تقييمات سلبية من الأصدقاء',
    'تم الطلب بشكل خاطئ',
  ];

  String? mValue;
  String? deliveryDate = "";

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.mOrderModel;
    afterBuildCreated(() => init());
  }

  init() async {
    mValue = mCancelList.first;
    await _refreshOrder();
    fetchTrackingData();
    getTracking();
    if (_currentOrder?.metaData != null) {
      for (var element in _currentOrder!.metaData!) {
        if (element.key == "delivery_date") deliveryDate = element.value;
      }
    }
  }

  // ✅ جلب أحدث بيانات الطلب — مع feedback واضح للمستخدم
  Future _refreshOrder({bool showFeedback = false}) async {
    final orderId = widget.mOrderModel?.id;
    if (orderId == null) return;

    if (showFeedback) {
      setState(() => _isRefreshing = true);
    }

    try {
      final res = await getOrderById(orderId);
      if (!mounted) return;
      setState(() {
        _currentOrder = OrderResponse.fromJson(res);
        _isRefreshing = false;
      });
      if (showFeedback) {
        toast('تم تحديث حالة الطلب بنجاح ✓');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      if (showFeedback) {
        toast('تعذّر تحديث الطلب، تحقق من الاتصال');
      }
    }
  }

  Future fetchTrackingData() async {
    appStore.setLoading(true);
    await getOrdersTracking(widget.mOrderModel!.id).then((res) {
      if (!mounted) return;
      appStore.setLoading(false);
      setState(() {
        mOrderTrackingModel =
            (res as Iterable).map((m) => OrderTracking.fromJson(m)).toList();
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  Future getTracking() async {
    appStore.setLoading(true);
    await getTrackingInfo(widget.mOrderModel!.id).then((res) {
      if (!mounted) return;
      appStore.setLoading(false);
      setState(() {
        mGetTrackingModel =
            (res as Iterable).map((m) => TrackingResponse.fromJson(m)).toList();
      });
    }).catchError((e) {
      if (!mounted) return;
      appStore.setLoading(false);
    });
  }

  void cancelOrderData(String? reason) async {
    appStore.setLoading(true);
    await cancelOrder(
      widget.mOrderModel!.id,
      {"status": "cancelled", "customer_note": reason},
    ).then((_) {
      if (!mounted) return;
      final note = {
        'customer_note': true,
        'note': '{"status":"Cancelled","message":"Order Canceled due to $reason."}',
      };
      createOrderNotes(widget.mOrderModel!.id, note).then((_) {
        appStore.setLoading(false);
        finish(context, true);
      }).catchError((e) {
        appStore.setLoading(false);
        finish(context, true);
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
      finish(context, true);
    });
  }

  // ── ✅ مشاركة تفاصيل الطلب ────────────────────────────────────────────────
  Future<void> _shareOrder() async {
    final order   = _currentOrder;
    final orderId = order?.id?.toString() ?? '';
    final status  = _statusLabel(order?.status);
    final total   = order?.total ?? '0';
    final date    = order?.dateCreated != null
        ? createDateFormat(order!.dateCreated)
        : '';
    final itemNames = (order?.lineItems ?? [])
        .map((i) => '• ${i.name ?? ''} (الكمية: ${i.quantity ?? 0})')
        .join('\n');

    final text = '''
تفاصيل الطلب #$orderId
────────────────────
📅 التاريخ: $date
📦 الحالة: $status
🛒 المنتجات:
$itemNames
💰 الإجمالي: EGP $total
────────────────────
للاستفسار تواصل معنا على واتساب:
https://wa.me/$_waNumber
'''.trim();

    await Share.share(text, subject: 'تفاصيل الطلب #$orderId');
  }

  // ── URL launchers ─────────────────────────────────────────────────────────
  Future<void> _openWhatsApp() async {
    final orderId = _currentOrder?.id?.toString() ?? '';
    final msg = Uri.encodeComponent('مرحباً، أريد الاستفسار عن طلبي رقم #$orderId');
    final uri = Uri.parse('https://wa.me/$_waNumber?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      toast('تعذّر فتح واتساب');
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:$_storePhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:$_storeEmail');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  String? _getItemImage(LineItem item) {
    if (item.productImages?.isNotEmpty == true) {
      return item.productImages![0].src;
    }
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return item.imageUrl;
    }
    return null;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':  return Colors.green;
      case 'processing': return Color(0xFF3D5AF1);
      case 'shipped':    return Colors.orange;
      case 'on-hold':    return Colors.orange;
      case 'cancelled':  return Colors.red;
      case 'refunded':   return Colors.purple;
      default:           return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'processing': return 'تم استلام الطلب وجاري التجهيز';
      case 'shipped':    return 'تم الشحن — الطلب في الطريق إليك';
      case 'completed':  return 'تم التسليم بنجاح';
      case 'on-hold':    return 'قيد الانتظار';
      case 'cancelled':  return 'ملغي';
      case 'pending':    return 'في انتظار الدفع';
      case 'refunded':   return 'تم الاسترداد';
      case 'failed':     return 'فشل الطلب';
      default:           return (status ?? '').toUpperCase();
    }
  }

  int _currentStep(String? status) {
    switch (status) {
      case 'pending':    return 0;
      case 'processing': return 1;
      case 'shipped':    return 2;
      case 'completed':  return 3;
      default:           return 0;
    }
  }

  Widget _buildProgressTracker() {
    final steps = [
      {'icon': Icons.receipt_long_outlined,   'label': 'تم الطلب'},
      {'icon': Icons.inventory_2_outlined,    'label': 'جاري التجهيز'},
      {'icon': Icons.local_shipping_outlined, 'label': 'تم الشحن'},
      {'icon': Icons.home_outlined,           'label': 'تم التسليم'},
    ];
    final current = _currentStep(_currentOrder?.status);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i <= current;
          final isLast   = i == steps.length - 1;
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
                            color: isActive ? primaryColor! : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          steps[i]['icon'] as IconData,
                          color: isActive ? primaryColor : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                      4.height,
                      Text(
                        steps[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (i == current) ...[
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
                        color: i < current ? primaryColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showCancelDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('إلغاء الطلب', style: boldTextStyle()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              16.height,
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(6),
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radius(8),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                child: DropdownButton<String>(
                  value: mValue,
                  isExpanded: true,
                  underline: SizedBox(),
                  dropdownColor: Theme.of(context).cardTheme.color,
                  onChanged: (v) => ss(() => mValue = v),
                  items: mCancelList
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: primaryTextStyle()),
                  ))
                      .toList(),
                ),
              ),
              20.height,
              AppButton(
                width: context.width(),
                textStyle: primaryTextStyle(color: white),
                text: 'تأكيد الإلغاء',
                color: primaryColor,
                onTap: () {
                  finish(context);
                  cancelOrderData(mValue);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc        = AppLocalizations.of(context)!;
    final order      = _currentOrder;
    final lineItems  = order?.lineItems ?? [];
    final firstItem  = lineItems.isNotEmpty ? lineItems[0] : null;
    final firstImg   = firstItem != null ? _getItemImage(firstItem) : null;
    final totalItems = lineItems.fold<int>(0, (sum, i) => sum + (i.quantity ?? 0));

    final canCancel = order?.status != COMPLETED &&
        order?.status != REFUNDED &&
        order?.status != CANCELED &&
        order?.status != TRASH &&
        order?.status != FAILED;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: Colors.white),
          onPressed: () => finish(context),
        ),
        title: Text(
          'تفاصيل الطلب',
          style: boldTextStyle(color: Colors.white, size: 18),
        ),
        centerTitle: true,
        actions: [
          // ✅ زر تحديث — مع مؤشر دوران أثناء التحديث
          _isRefreshing
              ? Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          )
              : IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _refreshOrder(showFeedback: true), // ✅ showFeedback: true
            tooltip: 'تحديث',
          ),

          // ✅ زر المشاركة — يستدعي _shareOrder() الذي يعمل فعلاً
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: _shareOrder, // ✅ كان () {} — الآن يستدعي دالة المشاركة
            tooltip: 'مشاركة',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.height,

                // ══════════════════════════════════════════════════════════
                // بطاقة رقم الطلب + معلوماته
                // ══════════════════════════════════════════════════════════
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: firstImg != null && firstImg.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: commonCacheImageWidget(
                                firstImg,
                                height: 90,
                                width: 90,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Icon(Icons.shopping_bag_outlined,
                                color: Colors.grey.shade400, size: 40),
                          ),
                          if (totalItems > 1)
                            Positioned(
                              top: -6,
                              left: -6,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$totalItems',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      16.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('رقم الطلب', '#${order?.id ?? ''}'),
                            6.height,
                            _infoRow(
                              'تاريخ الطلب',
                              order?.dateCreated != null
                                  ? createDateFormat(order!.dateCreated)
                                  : '',
                            ),
                            6.height,
                            _infoRow(
                              'إجمالي الطلب',
                              '${getStringAsync(DEFAULT_CURRENCY)} ${order?.total ?? ''}',
                            ),
                            6.height,
                            _infoRow(
                              'طريقة الدفع',
                              _translatePayment(
                                order?.paymentMethodTitle ?? order?.paymentMethod,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                16.height,

                // ══════════════════════════════════════════════════════════
                // حالة الطلب الحالية
                // ══════════════════════════════════════════════════════════
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حالة الطلب الحالية',
                              style: secondaryTextStyle(size: 12, color: Colors.grey),
                            ),
                            6.height,
                            Text(
                              _statusLabel(order?.status),
                              style: boldTextStyle(
                                  color: _statusColor(order?.status), size: 15),
                            ),
                            4.height,
                            Text(
                              order?.status == 'shipped'
                                  ? 'سيصلك طلبك قريباً'
                                  : order?.status == 'completed'
                                  ? 'شكراً لتسوقك معنا!'
                                  : order?.status == 'cancelled'
                                  ? 'تم إلغاء الطلب'
                                  : 'سنقوم بإشعارك عند شحن طلبك',
                              style: secondaryTextStyle(size: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor!.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          order?.status == 'shipped'
                              ? Icons.local_shipping_outlined
                              : order?.status == 'completed'
                              ? Icons.check_circle_outline
                              : order?.status == 'cancelled'
                              ? Icons.cancel_outlined
                              : Icons.inventory_2_outlined,
                          color: _statusColor(order?.status),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                16.height,

                // ══════════════════════════════════════════════════════════
                // Progress Tracker
                // ══════════════════════════════════════════════════════════
                _buildProgressTracker(),

                16.height,

                // ══════════════════════════════════════════════════════════
                // عنوان التوصيل
                // ══════════════════════════════════════════════════════════
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  color: primaryColor, size: 18),
                              8.width,
                              Text('عنوان التوصيل', style: boldTextStyle(size: 15)),
                            ],
                          ),
                          if (canCancel)
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('تغيير العنوان',
                                    style: secondaryTextStyle(size: 12)),
                              ),
                            ),
                        ],
                      ),
                      10.height,
                      Text(
                        '${order?.shipping?.firstName ?? ''} ${order?.shipping?.lastName ?? ''}'
                            .trim(),
                        style: boldTextStyle(size: 13),
                      ),
                      4.height,
                      Text(
                        [
                          order?.shipping?.address1 ?? '',
                          order?.shipping?.city ?? '',
                          order?.shipping?.state ?? '',
                          order?.shipping?.country ?? '',
                        ].where((s) => s.isNotEmpty).join('، '),
                        style: secondaryTextStyle(size: 13),
                      ),
                    ],
                  ),
                ),

                16.height,

                // ══════════════════════════════════════════════════════════
                // الأصناف في هذا الطلب
                // ══════════════════════════════════════════════════════════
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Text(
                          'الأصناف في هذا الطلب (${lineItems.length})',
                          style: boldTextStyle(size: 15, color: primaryColor),
                        ),
                      ),
                      Divider(height: 16),
                      ...lineItems.map((item) {
                        final imgSrc = _getItemImage(item);
                        return GestureDetector(
                          onTap: () {
                            final variant =
                            getIntAsync(PRODUCT_DETAIL_VARIANT, defaultValue: 1);
                            if (variant == 2) {
                              ProductDetailScreen2(mProId: item.productId).launch(context);
                            } else if (variant == 3) {
                              ProductDetailScreen3(mProId: item.productId).launch(context);
                            } else {
                              ProductDetailScreen1(mProId: item.productId).launch(context);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: imgSrc != null && imgSrc.isNotEmpty
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: commonCacheImageWidget(
                                      imgSrc,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                      : Icon(Icons.shopping_bag_outlined,
                                      color: Colors.grey.shade400, size: 28),
                                ),
                                12.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name ?? '',
                                        style: primaryTextStyle(size: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      4.height,
                                      Text(
                                        'الكمية: ${item.quantity ?? 0}',
                                        style: secondaryTextStyle(size: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'EGP ${item.total ?? '0'}',
                                  style: boldTextStyle(size: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      Divider(height: 1),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('إجمالي الطلب',
                                style: boldTextStyle(color: primaryColor, size: 15)),
                            Text('EGP ${order?.total ?? '0'}',
                                style: boldTextStyle(color: primaryColor, size: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                16.height,

                // ══════════════════════════════════════════════════════════
                // تفاصيل الطلب (دفع + شحن + إجمالي)
                // ══════════════════════════════════════════════════════════
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: primaryColor, size: 18),
                            8.width,
                            Text('تفاصيل الطلب', style: boldTextStyle(size: 15)),
                          ],
                        ),
                      ),
                      Divider(height: 16),
                      _detailRow(
                        'طريقة الدفع',
                        _translatePayment(
                          order?.paymentMethodTitle ?? order?.paymentMethod,
                        ),
                      ),
                      _detailRow(
                        'رسوم التوصيل',
                        (double.tryParse(order?.shippingTotal?.toString() ?? '0') ?? 0) > 0
                            ? 'EGP ${order?.shippingTotal}'
                            : 'مجاني',
                      ),
                      Divider(height: 16),
                      _detailRow(
                        'إجمالي الطلب',
                        'EGP ${order?.total ?? '0'}',
                        isBold: true,
                      ),
                      12.height,
                    ],
                  ),
                ),

                16.height,

                // ══════════════════════════════════════════════════════════
                // زر تتبع الطلب (واتساب)
                // ══════════════════════════════════════════════════════════
                GestureDetector(
                  onTap: _openWhatsApp,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                        8.width,
                        Text('تتبع الطلب عبر واتساب',
                            style: boldTextStyle(color: Colors.white, size: 16)),
                      ],
                    ),
                  ),
                ),

                16.height,

                // ══════════════════════════════════════════════════════════
                // طلب مساعدة
                // ══════════════════════════════════════════════════════════
                GestureDetector(
                  onTap: _openWhatsApp,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.headset_mic_outlined, color: primaryColor, size: 20),
                        8.width,
                        Text('طلب مساعدة', style: boldTextStyle(size: 15)),
                      ],
                    ),
                  ),
                ),

                16.height,

                // ══════════════════════════════════════════════════════════
                // تحتاج مساعدة؟
                // ══════════════════════════════════════════════════════════
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تحتاج مساعدة؟', style: boldTextStyle(size: 16)),
                      4.height,
                      Text('فريق الدعم متاح لخدمتك',
                          style: secondaryTextStyle(size: 13, color: Colors.grey)),
                      14.height,
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _launchPhone,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.phone_outlined,
                                        color: primaryColor, size: 22),
                                    6.height,
                                    Text('اتصل بنا', style: boldTextStyle(size: 13)),
                                    4.height,
                                    Text(_storePhone,
                                        style: secondaryTextStyle(
                                            size: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          12.width,
                          Expanded(
                            child: GestureDetector(
                              onTap: _launchEmail,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.email_outlined,
                                        color: primaryColor, size: 22),
                                    6.height,
                                    Text('راسلنا', style: boldTextStyle(size: 13)),
                                    4.height,
                                    Text(
                                      _storeEmail,
                                      style: secondaryTextStyle(
                                          size: 11, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ══════════════════════════════════════════════════════════
                // إلغاء الطلب
                // ══════════════════════════════════════════════════════════
                if (canCancel) ...[
                  16.height,
                  GestureDetector(
                    onTap: () => _showCancelDialog(loc),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                          8.width,
                          Text(
                            'إلغاء الطلب',
                            style: boldTextStyle(color: Colors.red, size: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                24.height,
              ],
            ),
          ),
          mProgress().center().visible(appStore.isLoading),
        ],
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────
  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: secondaryTextStyle(size: 12, color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            style: primaryTextStyle(size: 13),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? boldTextStyle(size: 14) : secondaryTextStyle(size: 13),
          ),
          Text(
            value,
            style: isBold
                ? boldTextStyle(size: 14, color: primaryColor)
                : primaryTextStyle(size: 13),
          ),
        ],
      ),
    );
  }

  String _translatePayment(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash on delivery':
      case 'cod':              return 'الدفع عند الاستلام';
      case 'credit card':      return 'بطاقة ائتمان';
      case 'paypal':           return 'باي بال';
      case 'stripe':           return 'ستريب';
      default:                 return method ?? '';
    }
  }
}