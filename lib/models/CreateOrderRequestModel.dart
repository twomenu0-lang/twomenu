import '/../models/OrderModel.dart';

import 'CustomerResponse.dart';

class CreateOrderRequestModel {
  List<LineItemsRequest>? lineItems = [];
  Shipping? shipping;
  Billing? billing;
  int? customerId;
  var paymentMethod;
  var status;
  var setPaid;
  var transactionId;
  List<ShippingLines?>? shippingLines;

  CreateOrderRequestModel({this.setPaid, this.status, this.lineItems, this.shipping, this.billing, this.customerId, this.paymentMethod, this.transactionId, this.shippingLines});

  CreateOrderRequestModel.fromJson(Map<String, dynamic> json) {
    setPaid = json['set_paid'];
    status = json['status'];
    if (json['line_items'] != null) {
      lineItems = <LineItemsRequest>[];
      json['line_items'].forEach((v) {
        lineItems!.add(LineItemsRequest.fromJson(v));
      });
    }

    shipping = json['shipping'] != null ? Shipping.fromJson(json['shipping']) : null;
    billing = json['billing'] != null ? Billing.fromJson(json['billing']) : null;
    paymentMethod = json['payment_method'];
    transactionId = json['transaction_id'];
    customerId = json['customer_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['set_paid'] = setPaid;
    data['status'] = status;
    if (lineItems != null) {
      data['line_items'] = lineItems!.map((v) => v.toJson()).toList();
    }
    if (shippingLines != null) {
      data['shipping_lines'] = shippingLines!.map((v) => v!.toJson()).toList();
    }
    data['shipping'] = shipping;
    data['billing'] = billing;
    data['payment_method'] = paymentMethod;
    data['transaction_id'] = transactionId;
    data['customer_id'] = customerId;
    return data;
  }
}

class LineItemsRequest {
  int? productId;
  String? quantity;
  int? variationId;

  LineItemsRequest({this.productId, this.quantity, this.variationId});

  factory LineItemsRequest.fromJson(Map<String, dynamic> json) {
    return LineItemsRequest(productId: json['product_id'], quantity: json['quantity'], variationId: json['variation_id']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['quantity'] = quantity;
    data['variation_id'] = variationId;
    return data;
  }
}

