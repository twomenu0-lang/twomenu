import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../component/OrderListComponent.dart';
import '/../main.dart';
import '/../models/OrderModel.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppBarWidget.dart';
import '/../screen/OrderDetailScreen.dart';
import '/../utils/AppWidget.dart';
import 'package:nb_utils/nb_utils.dart';
import '../component/OrderListEmptyComponent.dart';
import '../AppLocalizations.dart';

class OrderListScreen extends StatefulWidget {
  static String tag = '/OrderList';

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<OrderResponse> mOrderModel = [];
  bool mHasError = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future fetchOrderData() async {
    appStore.setLoading(true);
    mHasError = false;

    await getOrders().then((res) {
      if (!mounted) return;
      appStore.setLoading(false);

      Iterable mOrderDetails = res;
      mOrderModel =
          mOrderDetails.map((model) => OrderResponse.fromJson(model)).toList();

      setState(() {});
    }).catchError((error) {
      if (!mounted) return;
      appStore.setLoading(false);
      mOrderModel.clear();
      mHasError = true;
      print('ORDER ERROR: $error');
      setState(() {});
    });
  }

  init() async {
    await Future.delayed(Duration(milliseconds: 500));
    await fetchOrderData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

    Widget mBody = orderListWidget(context, mOrderModel, (i) async {
      bool? isChanged =
      await OrderDetailScreen(mOrderModel: mOrderModel[i]).launch(context);
      if (isChanged != null) {
        await fetchOrderData();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: mTop(context, appLocalization.translate('lbl_orders'),
          showBack: true) as PreferredSizeWidget?,
      body: Observer(
        builder: (context) => BodyCornerWidget(
          child: Stack(
            children: [
              RefreshIndicator(
                key: _refreshIndicatorKey,
                color: primaryColor!,
                onRefresh: () async {
                  await fetchOrderData();
                },
                child: mOrderModel.isNotEmpty
                    ? mBody
                    : ListView(
                  children: [
                    SizedBox(height: 200),
                    // حالة فارغة طبيعية (لا يوجد خطأ)
                    OrderListEmptyComponent()
                        .visible(!appStore.isLoading && !mHasError),
                    // حالة خطأ: زر إعادة المحاولة بدل رسالة الخطأ
                    if (!appStore.isLoading && mHasError)
                      Column(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            appLocalization.translate('error_something_went_wrong') ?? 'حدث خطأ، يرجى المحاولة مجدداً',
                            style: primaryTextStyle(),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchOrderData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            child: Text(
                              appLocalization.translate('lbl_retry') ?? 'إعادة المحاولة',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ).center(),
                  ],
                ),
              ),
              mProgress().center().visible(appStore.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}