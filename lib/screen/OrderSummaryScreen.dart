import 'dart:convert';
import 'dart:io';
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
import '/../utils/Colors.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/SharedPref.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import 'DashBoardScreen.dart';
import 'PlaceOrderScreen.dart';
import 'WebViewPaymentScreen.dart';

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

  OrderSummaryScreen({Key? key, this.mCartProduct, this.mCouponData, this.mPrice, this.shippingLines, this.method, this.subtotal, this.mRPDiscount, this.discount}) : super(key: key);

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

  var mUserId, mCurrency;
  int? paymentIndex = 0;
  int? currentTimeValue = 0;
  bool? isSelected = false;
  num mAmount = 0;

  @override
  void initState() {
    super.initState();
    addList();
    init();
  }

  init() async {
    setState(() {});
    fetchTotalBalance();
    if (getStringAsync(PAYMENTMETHOD) == PAYMENT_METHOD_NATIVE) {
      isNativePayment = true;
    } else {
      isNativePayment = false;
    }
    shipping = Shipping.fromJson(jsonDecode(getStringAsync(SHIPPING)));
    billing = Billing.fromJson(jsonDecode(getStringAsync(BILLING)));

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

  addList() {
    paymentList!.clear();
    paymentList!.add(PaymentClass(paymentIndex: 0, paymentMethod: 'Cash On Delivery'));
    setState(() {});
  }

  void createNativeOrder(String mPayMethod, String? mPayTitle) async {
    hideKeyboard(context);

    List<LineItemsRequest> lineItems = [];
    List<ShippingLines?> shippingLines = [];
    widget.mCartProduct!.forEach((item) {
      var lineItem = LineItemsRequest();
      lineItem.productId = item.proId;
      lineItem.quantity = item.quantity;
      lineItem.variationId = item.proId;
      lineItems.add(lineItem);
    });

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
    var request = {
      'billing': billing,
      'shipping': shipping,
      'line_items': lineItems,
      'payment_method': mPayMethod,
      'payment_method_title': mPayTitle,
      'transaction_id': "",
      'customer_id': getIntAsync(USER_ID),
      'coupon_lines': couponCode.isNotEmpty ? mCouponItems : '',
      'status': "processing",
      'set_paid': false,
      'shipping_lines': shippingLines
    };
    appStore.setLoading(true);

    createOrderApi(request).then((response) async {
      if (!mounted) return;
      appStore.setLoading(false);
      await PlaceOrderScreen(
        mOrderID: response['id'],
        total: widget.mPrice,
        transactionId: response['transaction_id'],
        orderKey: response['order_key'],
        paymentMethod: response['payment_method'],
        dateCreated: response['date_created'],
      ).launch(context, pageRouteAnimation: PageRouteAnimation.Scale);
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  Future createWebViewOrder() async {
    if (!accessAllowed) return;
    var request = CreateOrderRequestModel();
    if (widget.shippingLines != null) {
      List<ShippingLines?> shippingLines = [];
      shippingLines.add(widget.shippingLines);
      request.shippingLines = shippingLines;
    }
    List<LineItemsRequest> lineItems = [];
    widget.mCartProduct!.forEach((item) {
      var lineItem = LineItemsRequest();
      lineItem.productId = item.proId;
      lineItem.quantity = item.quantity;
      lineItem.variationId = item.proId;
      lineItems.add(lineItem);
    });

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
    getCheckOutUrl(request).then((res) async {
      if (!mounted) return;
      appStore.setLoading(false);
      bool isPaymentDone = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WebViewPaymentScreen(checkoutUrl: res['checkout_url'])),
      ) ?? false;
      if (isPaymentDone) {
        appStore.setLoading(true);
        if (!await isGuestUser()) {
          clearCartItems().then((response) {
            appStore.setLoading(false);
            appStore.setCount(0);
            DashBoardScreen().launch(context, isNewTask: true);
          });
        } else {
          appStore.setCount(0);
          removeKey(CART_DATA);
          DashBoardScreen().launch(context, isNewTask: true);
        }
      }
    }).catchError((error) { appStore.setLoading(false); });
  }

  void payments() {
    if (paymentIndex == 0) {
      createNativeOrder('cod', "Cash On Delivery");
    }
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

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
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: paymentList!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20, height: 20,
                                    decoration: boxDecorationWithRoundedCorners(
                                      borderRadius: radius(4),
                                      backgroundColor: context.cardColor,
                                      border: Border.all(color: primaryColor!),
                                    ),
                                    child: Icon(Icons.done, color: primaryColor, size: 14),
                                  ),
                                  12.width,
                                  Text(paymentList![index].paymentMethod!, style: boldTextStyle(color: primaryColor)),
                                ],
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
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(appLocalization.translate("lbl_total_mrp")!, style: secondaryTextStyle(size: 16)),
                          PriceWidget(price: nf.format(widget.subtotal.validate()), size: 16)
                        ],
                      ),
                      Divider(),
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
        padding: EdgeInsets.all(16),
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