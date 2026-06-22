import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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

  // ── مفاتيح أسباب الإلغاء (تطابق lbl_cancel1 … lbl_cancel6) ────────────────
  final List<String> mCancelKeys = [
    'lbl_cancel1',
    'lbl_cancel2',
    'lbl_cancel3',
    'lbl_cancel4',
    'lbl_cancel5',
    'lbl_cancel6',
  ];

  String? mValue; // سيتم ضبطها بالقيمة المترجمة لاحقاً
  String? deliveryDate = "";

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.mOrderModel;
    afterBuildCreated(() => init());
  }

  init() async {
    // ضبط القيمة الافتراضية لأول سبب مترجم
    mValue = AppLocalizations.of(context)!.translate(mCancelKeys.first);
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
        toast(AppLocalizations.of(context)!.translate('msg_order_updated_success')!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      if (showFeedback) {
        toast(AppLocalizations.of(context)!.translate('msg_order_update_failed')!);
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
    final loc = AppLocalizations.of(context)!;
    final order   = _currentOrder;
    final orderId = order?.id?.toString() ?? '';
    final status  = _statusLabel(context, order?.status);
    final total   = order?.total ?? '0';
    final date    = order?.dateCreated != null
        ? createDateFormat(order!.dateCreated,
        locale: Localizations.localeOf(context).languageCode)
        : '';
    final itemNames = (order?.lineItems ?? [])
        .map((i) => '• ${i.name ?? ''} (${loc.translate('lbl_qty')!}: ${i.quantity ?? 0})')
        .join('\n');

    final text = loc.translate('msg_share_order_text', {
      'order_id': orderId,
      'date': date,
      'status': status,
      'items': itemNames,
      'total': total,
      'wa_number': _waNumber,
    })!;

    await Share.share(
      text,
      subject: loc.translate('msg_share_order_subject', {'order_id': orderId}),
    );
  }

  // ── URL launchers ─────────────────────────────────────────────────────────
  Future<void> _openWhatsApp() async {
    final loc = AppLocalizations.of(context)!;
    final orderId = _currentOrder?.id?.toString() ?? '';
    final msg = Uri.encodeComponent(
      loc.translate('msg_whatsapp_inquiry', {'order_id': orderId})!,
    );
    final uri = Uri.parse('https://wa.me/$_waNumber?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      toast(loc.translate('msg_whatsapp_failed')!);
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

  String _statusLabel(BuildContext context, String? status) {
    final loc = AppLocalizations.of(context)!;
    switch (status) {
      case 'processing': return loc.translate('lbl_status_processing')!;
      case 'shipped':    return loc.translate('lbl_status_shipped')!;
      case 'completed':  return loc.translate('lbl_status_completed')!;
      case 'on-hold':    return loc.translate('lbl_status_on_hold')!;
      case 'cancelled':  return loc.translate('lbl_cancelled')!;
      case 'pending':    return loc.translate('lbl_status_pending')!;
      case 'refunded':   return loc.translate('lbl_status_refunded')!;
      case 'failed':     return loc.translate('lbl_status_failed')!;
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
    final loc = AppLocalizations.of(context)!;
    final steps = [
      {'icon': Icons.receipt_long_outlined,   'label': loc.translate('lbl_ordered')!},
      {'icon': Icons.inventory_2_outlined,    'label': loc.translate('lbl_processing')!},
      {'icon': Icons.local_shipping_outlined, 'label': loc.translate('lbl_shipped')!},
      {'icon': Icons.home_outlined,           'label': loc.translate('lbl_delivered')!}, // مفتاح جديد
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
    final cancelReasons = mCancelKeys.map((key) => loc.translate(key)!).toList();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) {
          // التأكد من أن القيمة المختارة حالياً ما زالت موجودة في القائمة
          if (!cancelReasons.contains(mValue)) {
            mValue = cancelReasons.first;
          }
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text(loc.translate('lbl_cancel_order')!, style: boldTextStyle()),
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
                    items: cancelReasons
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
                  text: loc.translate('lbl_confirm_cancel')!, // مفتاح جديد
                  color: primaryColor,
                  onTap: () {
                    finish(context);
                    cancelOrderData(mValue);
                  },
                ),
              ],
            ),
          );
        },
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

    // إعداد النصوص المساعدة
    final statusText = _statusLabel(context, order?.status);
    final statusSubText = () {
      switch (order?.status) {
        case 'shipped':
          return loc.translate('msg_order_shipped_soon')!; // مفتاح جديد
        case 'completed':
          return loc.translate('msg_order_completed_thanks')!; // مفتاح جديد
        case 'cancelled':
          return loc.translate('msg_order_cancelled')!; // مفتاح جديد
        default:
          return loc.translate('msg_order_default_notification')!; // مفتاح جديد
      }
    }();

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
          loc.translate('lbl_order_details')!,
          style: boldTextStyle(color: Colors.white, size: 18),
        ),
        centerTitle: true,
        actions: [
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
            onPressed: () => _refreshOrder(showFeedback: true),
            tooltip: loc.translate('lbl_update'), // موجود
          ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: _shareOrder,
            tooltip: loc.translate('lbl_share'), // مفتاح جديد (يُضاف لملفات JSON)
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
                            _infoRow(
                              loc.translate('lbl_order_id')!, // موجود
                              '#${order?.id ?? ''}',
                            ),
                            6.height,
                            _infoRow(
                              loc.translate('lbl_transaction_date')!, // موجود
                              order?.dateCreated != null
                                  ? createDateFormat(order!.dateCreated,
                                  locale: Localizations.localeOf(context).languageCode)
                                  : '',
                            ),
                            6.height,
                            _infoRow(
                              loc.translate('lbl_total_amount')!, // موجود
                              '${getStringAsync(DEFAULT_CURRENCY)} ${order?.total ?? ''}',
                            ),
                            6.height,
                            _infoRow(
                              loc.translate('lbl_payment_methods')!, // موجود
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
                              loc.translate('lbl_current_order_status')!, // مفتاح جديد
                              style: secondaryTextStyle(size: 12, color: Colors.grey),
                            ),
                            6.height,
                            Text(
                              statusText,
                              style: boldTextStyle(
                                  color: _statusColor(order?.status), size: 15),
                            ),
                            4.height,
                            Text(
                              statusSubText,
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

                // Progress Tracker
                _buildProgressTracker(),

                16.height,

                // عنوان التوصيل
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
                              Text(
                                loc.translate('lbl_delivery_address')!, // موجود
                                style: boldTextStyle(size: 15),
                              ),
                            ],
                          ),
                          if (canCancel)
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  loc.translate('lbl_change_address')!, // مفتاح جديد
                                  style: secondaryTextStyle(size: 12),
                                ),
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

                // الأصناف في هذا الطلب
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
                          loc.translate('lbl_items_in_order', {'count': lineItems.length.toString()})!, // مفتاح جديد مع placeholder
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
                              ProductDetailScreen2(mProId: item.productId)
                                  .launch(context);
                            } else if (variant == 3) {
                              ProductDetailScreen3(mProId: item.productId)
                                  .launch(context);
                            } else {
                              ProductDetailScreen1(mProId: item.productId)
                                  .launch(context);
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
                                        '${loc.translate('lbl_qty')!} ${item.quantity ?? 0}',
                                        style: secondaryTextStyle(size: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${loc.translate('lbl_egp')!} ${item.total ?? '0'}',
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
                            Text(
                              loc.translate('lbl_total_order_price')!, // موجود
                              style: boldTextStyle(color: primaryColor, size: 15),
                            ),
                            Text(
                              '${loc.translate('lbl_egp')!} ${order?.total ?? '0'}',
                              style: boldTextStyle(color: primaryColor, size: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                16.height,

                // تفاصيل الطلب (دفع + شحن + إجمالي)
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
                            Text(
                              loc.translate('lbl_order_details')!, // موجود
                              style: boldTextStyle(size: 15),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 16),
                      _detailRow(
                        loc.translate('lbl_payment_methods')!,
                        _translatePayment(
                          order?.paymentMethodTitle ?? order?.paymentMethod,
                        ),
                      ),
                      _detailRow(
                        loc.translate('lbl_shipping_fee')!, // موجود
                        (double.tryParse(order?.shippingTotal?.toString() ?? '0') ?? 0) > 0
                            ? '${loc.translate('lbl_egp')!} ${order?.shippingTotal}'
                            : loc.translate('lbl_free')!,
                      ),
                      Divider(height: 16),
                      _detailRow(
                        loc.translate('lbl_total_amount')!,
                        '${loc.translate('lbl_egp')!} ${order?.total ?? '0'}',
                        isBold: true,
                      ),
                      12.height,
                    ],
                  ),
                ),

                16.height,

                // زر تتبع الطلب (واتساب)
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
                        Icon(Icons.location_on_outlined,
                            color: Colors.white, size: 20),
                        8.width,
                        Text(
                          loc.translate('lbl_track_order_whatsapp')!, // مفتاح جديد
                          style: boldTextStyle(color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                16.height,

                // طلب مساعدة
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
                        Icon(Icons.headset_mic_outlined,
                            color: primaryColor, size: 20),
                        8.width,
                        Text(
                          loc.translate('lbl_request_help')!, // مفتاح جديد
                          style: boldTextStyle(size: 15),
                        ),
                      ],
                    ),
                  ),
                ),

                16.height,

                // تحتاج مساعدة؟
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
                      Text(
                        loc.translate('lbl_need_help')!, // مفتاح جديد
                        style: boldTextStyle(size: 16),
                      ),
                      4.height,
                      Text(
                        loc.translate('msg_support_team_available')!, // مفتاح جديد
                        style: secondaryTextStyle(size: 13, color: Colors.grey),
                      ),
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
                                    Text(
                                      loc.translate('lbl_call_us')!, // مفتاح جديد
                                      style: boldTextStyle(size: 13),
                                    ),
                                    4.height,
                                    Text(
                                      _storePhone,
                                      style: secondaryTextStyle(
                                          size: 11, color: Colors.grey),
                                    ),
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
                                    Text(
                                      loc.translate('lbl_email_us')!, // مفتاح جديد
                                      style: boldTextStyle(size: 13),
                                    ),
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

                // إلغاء الطلب
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
                            loc.translate('lbl_cancel_order')!, // موجود
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
    final loc = AppLocalizations.of(context)!;
    switch (method?.toLowerCase()) {
      case 'cash on delivery':
      case 'cod':
        return loc.translate('lbl_cash_on_delivery')!; // موجود
      case 'credit card':
        return loc.translate('lbl_credit_card')!; // مفتاح جديد
      case 'paypal':
        return loc.translate('lbl_paypal')!; // مفتاح جديد
      case 'stripe':
        return loc.translate('lbl_stripe')!; // مفتاح جديد
      default:
        return method ?? '';
    }
  }
}