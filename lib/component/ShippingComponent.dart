import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../models/ShippingMethodResponse.dart';
import '/../screen/EditProfileScreen.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';

import '../AppLocalizations.dart';
import '../main.dart';

class ShippingComponent extends StatefulWidget {
  final Function? onCall;

  ShippingComponent({this.onCall});

  @override
  _ShippingComponentState createState() => _ShippingComponentState();
}

class _ShippingComponentState extends State<ShippingComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    return getBoolAsync(IS_GUEST_USER) == true || cartStore.shipping != null && cartStore.shippingMethodResponse != null
        ? Observer(builder: (context) {
            return Column(
              children: [
                Divider(thickness: 6, color: Theme.of(context).textTheme.headlineMedium!.color),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(appLocalization.translate("lbl_Shipping")!, style: boldTextStyle()),
                        Text(appLocalization.translate("lbl_change")!, style: secondaryTextStyle(color: primaryColor, size: 12)).onTap(() async {
                          bool isChanged = await (EditProfileScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade));
                          if (isChanged) {
                          /*  cartStore.countryList.clear();*/
                         /*   cartStore.shippingMethodResponse = null;*/
                            appStore.setLoading(true);
                            widget.onCall!();
                            setState(() {});
                          }
                          setState(() {});
                        }),
                      ],
                    ),
                    4.height,
                    getBoolAsync(IS_GUEST_USER) == true
                        ? Text(appLocalization.translate('lbl_please_update_shipping_address')!, style: primaryTextStyle())
                        : cartStore.shipping!.getAddress()!.isNotEmpty
                            ? Text("(" + cartStore.shipping!.getAddress()! + ")", style: secondaryTextStyle()).visible(cartStore.shipping!.getAddress()!.isNotEmpty)
                            : Text(appLocalization.translate('lbl_please_update_shipping_address')!, style: primaryTextStyle()),
                    cartStore.shippingMethods.isNotEmpty
                        ? AnimatedListView(
                            itemCount: cartStore.shippingMethods.length,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            padding: EdgeInsets.only(top: 8),
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              Method method = cartStore.shippingMethods[index];
                              return Container(
                                padding: EdgeInsets.only(top: 4, bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                        decoration: boxDecorationWithRoundedCorners(
                                            borderRadius: radius(4), backgroundColor: cartStore.selectedShipment == index ? primaryColor! : Colors.grey.withOpacity(0.3)),
                                        width: 16,
                                        height: 16,
                                        child: Icon(Icons.done, size: 12, color: Colors.white).visible(cartStore.selectedShipment == index)),
                                    Text(
                                      method.id != "free_shipping" ? method.methodTitle! + ":" : method.methodTitle!,
                                      style: primaryTextStyle(),
                                    ).paddingLeft(8),
                                    Text(getStringAsync(DEFAULT_CURRENCY) + method.cost.toString(), style: primaryTextStyle()).paddingLeft(8).visible(method.id != "free_shipping")
                                  ],
                                ),
                              ).onTap(() {
                                cartStore.selectedShipment = index;
                              });
                            }).visible(cartStore.shipping!.getAddress()!.isNotEmpty)
                        : Text(appLocalization.translate('lbl_free_shipping')!, style: primaryTextStyle())
                  ],
                ).paddingOnly(left: 16, right: 16, top: 16),
              ],
            );
          })
        : SizedBox();
  }
}
