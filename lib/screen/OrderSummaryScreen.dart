import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
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
import 'DashBoardScreen.dart';
import 'PlaceOrderScreen.dart';
import 'WebViewPaymentScreen.dart';
import 'WalletMobileInputScreen.dart'; // ✅ الانتقال لشاشة المحفظة
import 'CardPaymentSheet.dart'; // ✅ Bottom Sheet الدفع بالكارت
// import 'EditProfileScreen.dart'; // ✅ قم بإلغاء التعليق عن هذا السطر واستيراد الشاشة إذا لم تكن مستوردة تلقائياً

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
  var mOrderModel = OrderResponse();
  List<PaymentClass>? paymentList = [];

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
        // ✅ محفظة إلكترونية: ننتقل لشاشة إدخال رقم الموبايل لطلب الدفع
        WalletMobileInputScreen(
          orderId: response['id'],
          amount: widget.mPrice,
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
          await PlaceOrderScreen(
            mOrderID: response['id'],
            total: widget.mPrice,
            transactionId: response['transaction_id'],
            orderKey: response['order_key'],
            paymentMethod: response['payment_method'],
            dateCreated: response['date_created'],
          ).launch(context, pageRouteAnimation: PageRouteAnimation.Scale);
        } else {
          toast('لم تكتمل عملية الدفع، حاول مرة أخرى');
        }
      } else {
        // الدفع الافتراضي كاش عند الاستلام
        await PlaceOrderScreen(
          mOrderID: response['id'],
          total: widget.mPrice,
          transactionId: response['transaction_id'],
          orderKey: response['order_key'],
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
  // التعديل 3 — فحص الحماية داخل دالة createWebViewOrder مع توجيه ذكي
  // ───────────────────────────────────────────────────────────────
  Future createWebViewOrder() async {
    if (!accessAllowed) return;

    // ✅ منع الاستمرار وتوجيه المستخدم لتعديل الملف الشخصي إذا كانت البيانات ناقصة
    if (shipping == null || billing == null) {
      toast('من فضلك أكمل بيانات العنوان في الملف الشخصي أولاً');
      // const EditProfileScreen().launch(context); // 👈 تفعيل التوجيه المباشر هنا
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
      processPaymentApi(response['id']);
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  processPaymentApi(var mOrderId) async {
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
        appStore.setLoading(true);
        if (!await isGuestUser()) {
          await clearCartItems();
          if (!context.mounted) return;
          appStore.setLoading(false);
          appStore.setCount(0);
          const DashBoardScreen().launch(context, isNewTask: true);
        } else {
          appStore.setCount(0);
          removeKey(CART_DATA);
          const DashBoardScreen().launch(context, isNewTask: true);
        }
      }
    } catch (error) {
      appStore.setLoading(false);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // التعديل 2 — فحص الحماية داخل دالة payments مع توجيه ذكي
  // ───────────────────────────────────────────────────────────────
  void payments() {
    var appLocalization = AppLocalizations.of(context)!;

    // ✅ منع الاستمرار وتوجيه المستخدم لتعديل الملف الشخصي إذا كانت البيانات ناقصة
    if (shipping == null || billing == null) {
      toast('من فضلك أكمل بيانات العنوان في الملف الشخصي أولاً');
      // const EditProfileScreen().launch(context); // 👈 تفعيل التوجيه المباشر هنا
      return;
    }

    if (paymentIndex == 0) {
      createNativeOrder('cod', appLocalization.translate('lbl_cash_on_delivery'));
    } else if (paymentIndex == 1) {
      createNativeOrder(PAYMENT_METHOD_KASHIER_WALLET, appLocalization.translate('lbl_wallet_payment') ?? 'الدفع بالمحفظة');
    } else if (paymentIndex == 2) {
      createNativeOrder(PAYMENT_METHOD_KASHIER_CARD, appLocalization.translate('lbl_card_payment') ?? 'الدفع بالكارت');
    }
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

    // بناء وتصفير مصفوفة طرق الدفع ديناميكياً لتشمل المحفظة والكارت
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
      paymentMethod: appLocalization.translate('lbl_card_payment') ?? 'الدفع بالكارت (فيزا/ماستركارد)',
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: mTop(context, appLocalization.translate('lbl_order_summary'), showBack: true) as PreferredSizeWidget?,
      body: BodyCornerWidget(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.height,
                  if (shipping != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appLocalization.translate("lbl_shipping_address")!, style: boldTextStyle()),
                        4.height,
                        Text(
                          "${shipping!.firstName.validate()} ${shipping!.lastName.validate()}\n${shipping!.address1.validate()}\n${shipping!.city.validate()}\n${shipping!.state.validate()}-${shipping!.country.validate()}-${shipping!.postcode.validate()}",
                          style: secondaryTextStyle(),
                        ),
                      ],
                    ).paddingSymmetric(horizontal: 16),
                  Divider(thickness: 6, color: Theme.of(context).textTheme.headlineMedium!.color).visible(isNativePayment),
                  if (isNativePayment)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appLocalization.translate('lbl_payment_methods')!, style: boldTextStyle()).paddingLeft(16),
                        8.height,
                        AnimatedListView(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: paymentList!.length,
                          itemBuilder: (context, index) {
                            bool isSelectedMethod = paymentIndex == index;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: boxDecorationWithRoundedCorners(
                                borderRadius: radius(8),
                                backgroundColor: context.cardColor,
                                border: Border.all(color: isSelectedMethod ? primaryColor! : context.dividerColor),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelectedMethod ? primaryColor : Colors.transparent,
                                    border: Border.all(color: primaryColor!),
                                  ),
                                  child: isSelectedMethod ? const Icon(Icons.done, color: Colors.white, size: 14) : const SizedBox(),
                                ),
                                title: Text(paymentList![index].paymentMethod!, style: boldTextStyle(color: isSelectedMethod ? primaryColor : null)),
                                onTap: () {
                                  setState(() {
                                    paymentIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  Divider(thickness: 6, color: Theme.of(context).textTheme.headlineMedium!.color),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appLocalization.translate("lbl_price_detail")!, style: boldTextStyle()),
                      8.height,
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(appLocalization.translate("lbl_total_mrp")!, style: secondaryTextStyle(size: 16)),
                          PriceWidget(price: nf.format(widget.subtotal.validate()), size: 16)
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(appLocalization.translate('lbl_total_amount')!, style: boldTextStyle(color: primaryColor)),
                          PriceWidget(price: widget.mPrice, size: 16),
                        ],
                      ),
                    ],
                  ).paddingAll(16),
                ],
              ),
            ),
            Observer(builder: (context) => mProgress().center().visible(appStore.isLoading)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cardColor),
        child: Row(
          children: [
            PriceWidget(price: widget.mPrice, size: 16).expand(),
            16.width,
            AppButton(
              text: appLocalization.translate('lbl_continue'),
              textStyle: primaryTextStyle(color: white),
              color: primaryColor,
              onTap: () {
                if (isNativePayment) {
                  payments();
                } else {
                  createWebViewOrder();
                }
              },
            ).expand(),
          ],
        ),
      ),
    );
  }
}