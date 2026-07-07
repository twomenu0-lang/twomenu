import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../main.dart';
import '/../models/WalletPaymentModel.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppBarWidget.dart';
import '/../utils/AppWidget.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';
import 'WalletPaymentPendingScreen.dart';

class WalletMobileInputScreen extends StatefulWidget {
  static String tag = '/WalletMobileInputScreen';

  final int orderId;
  final String amount;
  final String? orderNumber;   // ✅ إضافة لاستقبال رقم الطلب
  final String? dateCreated;   // ✅ إضافة لاستقبال تاريخ الطلب

  const WalletMobileInputScreen({
    super.key,
    required this.orderId,
    required this.amount,
    this.orderNumber,
    this.dateCreated,
  });

  @override
  WalletMobileInputScreenState createState() => WalletMobileInputScreenState();
}

class WalletMobileInputScreenState extends State<WalletMobileInputScreen> {
  final formKey = GlobalKey<FormState>();
  final mobileController = TextEditingController();

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  void submitMobile() {
    hideKeyboard(context);
    if (!formKey.currentState!.validate()) return;

    appStore.setLoading(true);
    initiateWalletPayment(widget.orderId, mobileController.text.trim()).then((response) {
      appStore.setLoading(false);
      WalletPaymentPendingScreen(
        orderId: widget.orderId,
        amount: widget.amount,
        initialMessage: response.message,
        orderNumber: widget.orderNumber,   // ✅ تمرير للشاشة التالية
        dateCreated: widget.dateCreated,   // ✅ تمرير للشاشة التالية
      ).launch(context, pageRouteAnimation: PageRouteAnimation.Scale);
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: mTop(context, appLocalization.translate('lbl_wallet_payment') ?? 'الدفع بالمحفظة', showBack: true) as PreferredSizeWidget?,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  24.height,
                  Text(
                    appLocalization.translate('lbl_wallet_mobile_hint') ?? 'أدخل رقم الموبايل المرتبط بمحفظتك الإلكترونية',
                    style: secondaryTextStyle(),
                  ).paddingSymmetric(horizontal: 16),
                  16.height,
                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    decoration: InputDecoration(
                      hintText: '01xxxxxxxxx',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: radius(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return appLocalization.translate('lbl_field_required') ?? 'هذا الحقل مطلوب';
                      }
                      if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(value.trim())) {
                        return appLocalization.translate('lbl_invalid_mobile') ?? 'رقم موبايل غير صحيح';
                      }
                      return null;
                    },
                  ).paddingSymmetric(horizontal: 16),
                  24.height,
                ],
              ),
            ),
          ),
          Observer(builder: (context) => mProgress().center().visible(appStore.isLoading)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cardColor),
        child: AppButton(
          text: appLocalization.translate('lbl_continue'),
          textStyle: primaryTextStyle(color: white),
          color: primaryColor,
          width: context.width(),
          onTap: submitMobile,
        ),
      ),
    );
  }
}