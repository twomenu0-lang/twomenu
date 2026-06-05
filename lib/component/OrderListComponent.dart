import 'package:flutter/material.dart';
import '/../models/OrderModel.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Colors.dart';
import 'package:nb_utils/nb_utils.dart';

import '../AppLocalizations.dart';
import '../main.dart';

Widget orderListWidget(context, List<OrderResponse> mOrderModel, Function(int index) onCall) {
  var appLocalization = AppLocalizations.of(context)!;
  return AnimatedListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: mOrderModel.length,
      padding: EdgeInsets.only(left: 8, right: 8, top: 8),
      itemBuilder: (context, i) {
        final order = mOrderModel[i];

        // ✅ استخراج صورة المنتج بأمان - productImages قد تكون null في wc/v3/orders
        final String? productImageSrc = (order.lineItems != null &&
            order.lineItems!.isNotEmpty &&
            order.lineItems![0].productImages != null &&
            order.lineItems![0].productImages!.isNotEmpty)
            ? order.lineItems![0].productImages![0].src
            : null;

        // ✅ استخراج اسم المنتج الأول بأمان
        final String? firstItemName = (order.lineItems != null && order.lineItems!.isNotEmpty)
            ? order.lineItems![0].name
            : null;

        final bool hasMultipleItems = (order.lineItems != null && order.lineItems!.length > 1);

        return Container(
          margin: EdgeInsets.all(8),
          decoration: boxDecorationWithShadow(
              backgroundColor: context.cardColor, borderRadius: radius(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              10.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // ✅ عرض الصورة فقط لو موجودة، وإلا placeholder
                  if (productImageSrc != null && productImageSrc.isNotEmpty)
                    commonCacheImageWidget(productImageSrc,
                        height: 70, width: 70, fit: BoxFit.cover)
                        .cornerRadiusWithClipRRect(defaultRadius)
                  else
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(defaultRadius),
                      ),
                      child: Icon(Icons.shopping_bag_outlined,
                          color: Colors.grey, size: 32),
                    ),
                  10.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      8.height,
                      // ✅ عرض اسم المنتج أو رقم الطلب كـ fallback
                      if (firstItemName != null && firstItemName.isNotEmpty)
                        hasMultipleItems
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(firstItemName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: primaryTextStyle()),
                            4.height,
                            Text(
                                appLocalization
                                    .translate("lbl_more_item") ??
                                    '',
                                style: secondaryTextStyle(
                                    color: primaryColor!.withOpacity(0.5))),
                          ],
                        )
                            : Text(firstItemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: primaryTextStyle())
                      else
                        Text('#${order.id ?? ''}',
                            style: primaryTextStyle(size: 18)),
                      6.height,
                      Row(
                        children: [
                          PriceWidget(
                              price: order.total?.toString() ?? '0',
                              size: 14,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .color)
                              .expand(),
                          Text(
                              (order.status ?? '').toUpperCase(),
                              style: boldTextStyle(
                                  color: statusColor(order.status))),
                        ],
                      ),
                    ],
                  ).expand(),
                ],
              ),
              10.height,
            ],
          ).paddingOnly(left: 10, right: 10).onTap(() async {
            onCall(i);
          }),
        );
      });
}