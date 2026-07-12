import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ لفتح رابط صفحة الدعم
import '/../main.dart';
import '/../models/CartModel.dart';
import '/../models/Coupon_lines.dart';
import '/../models/CreateOrderRequestModel.dart';
import '/../models/CustomerResponse.dart';
import '/../models/OrderModel.dart';
import '/../models/PaymentModel.dart';
import '/../models/ShippingMethodResponse.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Constants.dart';
import '/../utils/SharedPref.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import 'PlaceOrderScreen.dart';
import 'WebViewPaymentScreen.dart';
import 'WalletMobileInputScreen.dart'; // ✅ الانتقال لشاشة المحفظة
import 'CardPaymentSheet.dart'; // ✅ Bottom Sheet الدفع بالكارت
import 'EditProfileScreen.dart'; // ✅ شاشة تعديل العنوان (بيانات الشحن)

/// رابط صفحة الدعم/التواصل التي يفتحها زر السماعة أعلى الشاشة
const String kSupportContactUrl = 'https://twomenu.shop/contact/';

class OrderSummaryScreen extends StatefulWidget {
  static String tag = '/OrderSummaryScreen';

  final List<CartModel>? mCartProduct;
  final mCouponData;
  final mPrice;
  final bool isNativePayment = false;
  final ShippingLines? shippingLines;
  final Method? method;
  final double? subtotal;
  final double? mRPDiscount;
  final double? discount;

  const OrderSummaryScreen({super.key, this.mCartProduct, this.mCouponData, this.mPrice, this.shippingLines, this.method, this.subtotal, this.mRPDiscount, this.discount});

  @override
  OrderSummaryScreenState createState() => OrderSummaryScreenState();
}

class OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final formKey = GlobalKey<FormState>();
  OrderResponse mOrderModel = OrderResponse();
  List<PaymentClass>? paymentList = [];

  // أيقونة لكل وسيلة دفع بنفس ترتيب paymentList (كاش / محفظة / كارت)
  final List<IconData> paymentIcons = [
    Icons.payments_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.credit_card_rounded,
  ];

  Shipping? shipping;
  Billing? billing;

  NumberFormat nf = NumberFormat('##.00');
  String? mTotalBalance;
  bool isNativePayment = false;

  int? mUserId;
  String? mCurrency;

  int? paymentIndex = 0; // 0 = كاش عند الاستلام، 1 = المحفظة الإلكترونية، 2 = الكارت
  int? currentTimeValue = 0;
  bool? isSelected = false;
  num mAmount = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  // ───────────────────────────────────────────────────────────────
  // التعديل 1 — حماية دالة init من قراءة الـ null أو النصوص الفارغة
  // ───────────────────────────────────────────────────────────────
  init() async {
    setState(() {});
    fetchTotalBalance();
    if (getStringAsync(PAYMENTMETHOD) == PAYMENT_METHOD_NATIVE) {
      isNativePayment = true;
    } else {
      isNativePayment = false;
    }

    final shippingRaw = getStringAsync(SHIPPING);
    final billingRaw = getStringAsync(BILLING);

    if (shippingRaw.isNotEmpty && shippingRaw != 'null') {
      shipping = Shipping.fromJson(jsonDecode(shippingRaw));
    }
    if (billingRaw.isNotEmpty && billingRaw != 'null') {
      billing = Billing.fromJson(jsonDecode(billingRaw));
    }

    mUserId = getIntAsync(USER_ID);
    mCurrency = getStringAsync(DEFAULT_CURRENCY);
    setState(() {});
  }

  Future fetchTotalBalance() async {
    afterBuildCreated(() {
      appStore.setLoading(true);
    });
    await getBalance().then((res) {
      mTotalBalance = res;
      appStore.setLoading(false);
    }).catchError((error) {
      appStore.setLoading(false);
    });
    mAmount = double.parse(widget.mPrice);
  }

  void createNativeOrder(String mPayMethod, String? mPayTitle) async {
    hideKeyboard(context);

    List<LineItemsRequest> lineItems = [];
    List<ShippingLines?> shippingLines = [];
    for (var item in widget.mCartProduct!) {
      var lineItem = LineItemsRequest();
      lineItem.productId = item.proId;
      lineItem.quantity = item.quantity;
      lineItem.variationId = item.proId;
      lineItems.add(lineItem);
    }

    var couponCode = widget.mCouponData;
    List<CouponLines> mCouponItems = [];
    if (couponCode.isNotEmpty) {
      var mCoupon = CouponLines();
      mCoupon.code = couponCode;
      mCouponItems.clear();
      mCouponItems.add(mCoupon);
    }

    if (widget.shippingLines != null) {
      shippingLines.add(widget.shippingLines);
    }

    // كاش عند الاستلام = processing، أما المحفظة أو الكارت = pending لحين إتمام السداد فعليًا
    final bool requiresOnlinePayment = (mPayMethod == PAYMENT_METHOD_KASHIER_WALLET || mPayMethod == PAYMENT_METHOD_KASHIER_CARD);
    String targetStatus = requiresOnlinePayment ? "pending" : "processing";

    var request = {
      'billing': billing,
      'shipping': shipping,
      'line_items': lineItems,
      'payment_method': mPayMethod,
      'payment_method_title': mPayTitle,
      'transaction_id': "",
      'customer_id': getIntAsync(USER_ID),
      'coupon_lines': couponCode.isNotEmpty ? mCouponItems : '',
      'status': targetStatus,
      'set_paid': false,
      'shipping_lines': shippingLines
    };
    appStore.setLoading(true);

    try {
      final response = await createOrderApi(request);
      appStore.setLoading(false);

      if (!context.mounted) return;

      if (mPayMethod == PAYMENT_METHOD_KASHIER_WALLET) {
        // ✅ التعديل ب — تمرير رقم وتاريخ الطلب لشاشة المحفظة الإلكترونية
        WalletMobileInputScreen(
          orderId: response['id'],
          amount: widget.mPrice,
          orderNumber: response['number'].toString(),
          dateCreated: response['date_created'],
        ).launch(context, pageRouteAnimation: PageRouteAnimation.Scale);
      } else if (mPayMethod == PAYMENT_METHOD_KASHIER_CARD) {
        // ✅ الدفع بالكارت: نعرض صفحة كاشير المستضافة داخل Bottom Sheet
        final bool? isPaymentDone = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CardPaymentSheet(orderId: response['id'], amount: widget.mPrice),
        );

        if (!context.mounted) return;

        if (isPaymentDone == true) {
          // ✅ التعديل أ — استبدال orderKey بـ orderNumber في شاشة الكارت
          await PlaceOrderScreen(
            mOrderID: response['id'],
            total: widget.mPrice,
            transactionId: response['transaction_id'],
            orderNumber: response['number'].toString(),
            paymentMethod: response['payment_method'],
            dateCreated: response['date_created'],
          ).launch(context, pageRouteAnimation: PageRouteAnimation.Scale);
        } else {
          toast('لم تكتمل عملية الدفع، حاول مرة أخرى');
        }
      } else {
        // ✅ التعديل أ — استبدال orderKey بـ orderNumber في شاشة الكاش
        await PlaceOrderScreen(
          mOrderID: response['id'],
          total: widget.mPrice,
          transactionId: response['transaction_id'],
          orderNumber: response['number'].toString(),
          paymentMethod: response['payment_method'],
          dateCreated: response['date_created'],
        ).launch(context, pageRouteAnimation: PageRouteAnimation.Scale);
      }
    } catch (error) {
      appStore.setLoading(false);
      if (!context.mounted) return;
      toast(error.toString());
    }
  }

  // ───────────────────────────────────────────────────────────────
  // التعديل ج — توحيد مسار الـ webview وتمرير القيم المحدثة لقاعدة البيانات
  // ───────────────────────────────────────────────────────────────
  Future createWebViewOrder() async {
    if (!accessAllowed) return;

    if (shipping == null || billing == null) {
      toast('من فضلك أكمل بيانات العنوان في الملف الشخصي أولاً');
      return;
    }

    var request = CreateOrderRequestModel();
    if (widget.shippingLines != null) {
      List<ShippingLines?> shippingLines = [];
      shippingLines.add(widget.shippingLines);
      request.shippingLines = shippingLines;
    }
    List<LineItemsRequest> lineItems = [];
    for (var item in widget.mCartProduct!) {
      var lineItem = LineItemsRequest();
      lineItem.productId = item.proId;
      lineItem.quantity = item.quantity;
      lineItem.variationId = item.proId;
      lineItems.add(lineItem);
    }

    request.paymentMethod = "webview";
    request.customerId = await isGuestUser() ? 0 : getIntAsync(USER_ID);
    request.status = "pending";
    request.setPaid = false;
    request.lineItems = lineItems;
    request.shipping = shipping;
    request.billing = billing;

    appStore.setLoading(true);
    await createOrderApi(request.toJson()).then((response) {
      if (!mounted) return;
      // ✅ تمرير رقم الطلب وتاريخ الإنشاء لمعالج الدفع
      processPaymentApi(response['id'], response['number'], response['date_created']);
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  // ✅ تعديل التوقيع وبنية معالجة دفع الويب فيو للعبور الإلزامي بـ PlaceOrderScreen
  processPaymentApi(var mOrderId, var mOrderNumber, var mDateCreated) async {
    var request = {"order_id": mOrderId};
    try {
      final res = await getCheckOutUrl(request);
      if (!context.mounted) return;
      appStore.setLoading(false);

      bool isPaymentDone = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WebViewPaymentScreen(checkoutUrl: res['checkout_url'])),
      ) ?? false;

      if (!context.mounted) return;

      if (isPaymentDone) {
        // ✅ التوحيد: التوجه إلى شاشة تتبع الطلب PlaceOrderScreen لمسح السلة والحفاظ على التسلسل الموحد
        await PlaceOrderScreen(
          mOrderID: mOrderId,
          total: widget.mPrice,
          transactionId: '',
          orderNumber: mOrderNumber.toString(),
          paymentMethod: 'webview',
          dateCreated: mDateCreated ?? DateTime.now().toIso8601String(),
        ).launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Scale);
      }
    } catch (error) {
      appStore.setLoading(false);
    }
  }

  void payments() {
    var appLocalization = AppLocalizations.of(context)!;

    if (shipping == null || billing == null) {
      toast('من فضلك أكمل بيانات العنوان في الملف الشخصي أولاً');
      return;
    }

    if (paymentIndex == 0) {
      createNativeOrder('cod', appLocalization.translate('lbl_cash_on_delivery'));
    } else if (paymentIndex == 1) {
      createNativeOrder(PAYMENT_METHOD_KASHIER_WALLET, appLocalization.translate('lbl_wallet_payment') ?? 'الدفع بالمحفظة');
    } else if (paymentIndex == 2) {
      createNativeOrder(PAYMENT_METHOD_KASHIER_CARD, appLocalization.translate('lbl_card_payment') ?? 'البطاقات البنكية');
    }
  }

  // ✅ فتح صفحة الدعم/التواصل عند الضغط على أيقونة السماعة أعلى الشاشة
  Future<void> _openSupport() async {
    final uri = Uri.parse(kSupportContactUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) toast('تعذر فتح صفحة الدعم');
    } catch (_) {
      toast('تعذر فتح صفحة الدعم');
    }
  }

  // ✅ فتح شاشة تعديل بيانات العنوان، وتحديث البيانات المعروضة عند العودة
  Future<void> _editAddress() async {
    final navContext = context;
    await EditProfileScreen().launch(navContext);
    if (!navContext.mounted) return;
    init();
  }

  String _paymentSubtitle(AppLocalizations appLocalization, int index) {
    switch (index) {
      case 0:
        return appLocalization.translate('lbl_cod_subtitle') ?? 'ادفع للمندوب عند استلام الطلب';
      case 1:
        return appLocalization.translate('lbl_wallet_subtitle') ?? 'ادفع باستخدام محفظتك الإلكترونية';
      case 2:
        return appLocalization.translate('lbl_card_subtitle') ?? 'ادفع باستخدام بطاقة بنكية';
      default:
        return '';
    }
  }

  // قيمة رسوم التوصيل مشتقة من الإجمالي والمنتجات والخصومات (لا يوجد حقل مستقل لها حاليًا في الـ widget)
  double get _shippingCharge {
    final total = double.tryParse(widget.mPrice?.toString() ?? '') ?? 0;
    final calculated = total - widget.subtotal.validate() + widget.discount.validate();
    return calculated < 0 ? 0 : calculated;
  }

  // ظل ناعم وخفيف يُستخدم بدل الإطارات (Border) في كروت الشاشة
  final List<BoxShadow> _softCardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  Widget _priceDetailItem({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Column(
        children: [
          PriceWidget(price: value, size: 12),
          4.height,
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: primaryColor!.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: primaryColor),
          ),
          4.height,
          Text(label, style: secondaryTextStyle(size: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

    paymentList!.clear();
    paymentList!.add(PaymentClass(
      paymentIndex: 0,
      paymentMethod: appLocalization.translate('lbl_cash_on_delivery'),
    ));
    paymentList!.add(PaymentClass(
      paymentIndex: 1,
      paymentMethod: appLocalization.translate('lbl_wallet_payment') ?? 'الدفع بالمحفظة الإلكترونية',
    ));
    paymentList!.add(PaymentClass(
      paymentIndex: 2,
      paymentMethod: appLocalization.translate('lbl_card_payment') ?? 'البطاقات البنكية',
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor!,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => finish(context),
        ),
        title: Text(
          appLocalization.translate('lbl_order_summary') ?? 'ملخص الطلب',
          style: boldTextStyle(color: Colors.white, size: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'الدعم',
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
            onPressed: _openSupport,
          ),
        ],
      ),
      body: BodyCornerWidget(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── بانر ترحيبي أعلى الشاشة "إكمال عملية الشراء" ──
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(16),
                      backgroundColor: primaryColor!,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appLocalization.translate('lbl_complete_purchase') ?? 'إكمال عملية الشراء',
                                style: boldTextStyle(color: Colors.white, size: 14),
                              ),
                              4.height,
                              Text(
                                appLocalization.translate('lbl_complete_purchase_desc') ?? 'راجع بيانات الطلب ثم اختر طريقة الدفع المناسبة.',
                                style: secondaryTextStyle(color: Colors.white.withValues(alpha: 0.9), size: 11),
                              ),
                            ],
                          ),
                        ),
                        10.width,
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.fact_check_outlined, color: primaryColor, size: 22),
                        ),
                      ],
                    ),
                  ),

                  // ── عنوان التوصيل + زر تعديل (تصميم مُصغّر) ──
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(12),
                      backgroundColor: context.cardColor,
                      boxShadow: _softCardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primaryColor!.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.location_on_outlined, color: primaryColor, size: 18),
                        ),
                        10.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appLocalization.translate("lbl_shipping_address")!, style: boldTextStyle(size: 13)),
                              3.height,
                              if (shipping != null)
                                Text(
                                  "${shipping!.firstName.validate()} ${shipping!.lastName.validate()}، ${shipping!.address1.validate()}، ${shipping!.city.validate()}، ${shipping!.state.validate()}-${shipping!.country.validate()}-${shipping!.postcode.validate()}",
                                  style: secondaryTextStyle(size: 12).copyWith(height: 1.35),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                Text(
                                  appLocalization.translate('lbl_no_address') ?? 'لا يوجد عنوان محدد، من فضلك أضف عنوان التوصيل',
                                  style: secondaryTextStyle(size: 12),
                                ),
                              6.height,
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: OutlinedButton.icon(
                                  onPressed: _editAddress,
                                  icon: Icon(Icons.edit_outlined, size: 14, color: primaryColor),
                                  label: Text(
                                    appLocalization.translate('lbl_edit_address') ?? 'تعديل العنوان',
                                    style: secondaryTextStyle(color: primaryColor, size: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    side: BorderSide(color: primaryColor!),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── طرق الدفع ──
                  if (isNativePayment)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appLocalization.translate('lbl_payment_methods')!, style: boldTextStyle()).paddingSymmetric(horizontal: 16),
                        6.height,
                        AnimatedListView(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: paymentList!.length,
                          itemBuilder: (context, index) {
                            bool isSelectedMethod = paymentIndex == index;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: boxDecorationWithRoundedCorners(
                                borderRadius: radius(12),
                                backgroundColor: context.cardColor,
                                border: isSelectedMethod ? Border.all(color: primaryColor!, width: 1.5) : null,
                                boxShadow: _softCardShadow,
                              ),
                              child: ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  isSelectedMethod ? Icons.check_circle : Icons.circle_outlined,
                                  color: isSelectedMethod ? primaryColor : context.dividerColor,
                                  size: 20,
                                ),
                                title: Text(
                                  paymentList![index].paymentMethod!,
                                  style: boldTextStyle(size: 13, color: isSelectedMethod ? primaryColor : null),
                                ),
                                subtitle: Text(_paymentSubtitle(appLocalization, index), style: secondaryTextStyle(size: 10)),
                                trailing: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: primaryColor!.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(paymentIcons[index], color: primaryColor, size: 18),
                                ),
                                onTap: () {
                                  setState(() {
                                    paymentIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        6.height,
                      ],
                    ),

                  // ── ملخص الدفع ──
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(12),
                      backgroundColor: context.cardColor,
                      boxShadow: _softCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appLocalization.translate("lbl_price_detail")!, style: boldTextStyle(size: 13)),
                        10.height,
                        Row(
                          children: [
                            _priceDetailItem(
                              icon: Icons.shopping_bag_outlined,
                              label: appLocalization.translate('lbl_total_mrp') ?? 'إجمالي المنتجات',
                              value: nf.format(widget.subtotal.validate()),
                            ),
                            _priceDetailItem(
                              icon: Icons.local_shipping_outlined,
                              label: appLocalization.translate('lbl_shipping_charge') ?? 'رسوم التوصيل',
                              value: nf.format(_shippingCharge),
                            ),
                            _priceDetailItem(
                              icon: Icons.sell_outlined,
                              label: appLocalization.translate('lbl_discount') ?? 'الخصومات',
                              value: nf.format(widget.discount.validate()),
                            ),
                          ],
                        ),
                        10.height,
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: primaryColor!.withValues(alpha: 0.08), borderRadius: radius(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(appLocalization.translate('lbl_total_amount')!, style: boldTextStyle(color: primaryColor, size: 13)),
                              PriceWidget(price: widget.mPrice, size: 15, color: primaryColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── ملاحظة الأمان ──
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: primaryColor!.withValues(alpha: 0.06), borderRadius: radius(8)),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 16, color: primaryColor),
                        8.width,
                        Expanded(
                          child: Text(
                            appLocalization.translate('lbl_secure_payment_note') ?? 'جميع بياناتك محمية ومشفرة لضمان أمان معلوماتك',
                            style: secondaryTextStyle(size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  4.height,
                ],
              ),
            ),
            Observer(builder: (context) => mProgress().center().visible(appStore.isLoading)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: context.cardColor),
        child: Row(
          children: [
            AppButton(
              text: appLocalization.translate('lbl_continue'),
              textStyle: primaryTextStyle(color: Colors.white),
              color: primaryColor,
              shapeBorder: const StadiumBorder(),
              onTap: () {
                if (isNativePayment) {
                  payments();
                } else {
                  createWebViewOrder();
                }
              },
            ).expand(flex: 2),
            16.width,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PriceWidget(price: widget.mPrice, size: 16),
                  2.height,
                  Text(
                    appLocalization.translate('lbl_total_amount') ?? 'الإجمالي الكلي',
                    style: secondaryTextStyle(size: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}