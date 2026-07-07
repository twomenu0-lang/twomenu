import 'CustomerResponse.dart';

class OrderResponse {
  Billing? billing;
  var cartHash;
  var cartTax;
  var createdVia;
  var currency;
  int? customerId;
  var customerIpAddress;
  var customerNote;
  var customerUserAgent;
  var dateCompleted;
  var dateCreated;
  var dateModified;
  var datePaid;
  var discountTax;
  var discountTotal;
  int? id;
  List<LineItem>? lineItems;
  List<MetaData>? metaData;
  var number;
  var orderKey;
  int? parentId;
  var paymentMethod;
  var paymentMethodTitle;
  bool? pricesIncludeTax;
  Shipping? shipping;
  var shippingTax;
  var shippingTotal;
  var status;
  var total;
  var totalTax;
  var transactionId;
  var version;

  OrderResponse(
      {this.billing,
        this.cartHash,
        this.cartTax,
        this.createdVia,
        this.currency,
        this.customerId,
        this.customerIpAddress,
        this.customerNote,
        this.customerUserAgent,
        this.dateCompleted,
        this.dateCreated,
        this.dateModified,
        this.datePaid,
        this.discountTax,
        this.discountTotal,
        this.id,
        this.lineItems,
        this.metaData,
        this.number,
        this.orderKey,
        this.parentId,
        this.paymentMethod,
        this.paymentMethodTitle,
        this.pricesIncludeTax,
        this.shipping,
        this.shippingTax,
        this.shippingTotal,
        this.status,
        this.total,
        this.totalTax,
        this.transactionId,
        this.version});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      billing: json['billing'] != null ? Billing.fromJson(json['billing']) : null,
      cartHash: json['cart_hash'],
      cartTax: json['cart_tax'],
      createdVia: json['created_via'],
      currency: json['currency'],
      customerId: json['customer_id'],
      customerIpAddress: json['customer_ip_address'],
      customerNote: json['customer_note'],
      customerUserAgent: json['customer_user_agent'],
      dateCompleted: json['date_completed'],
      dateCreated: json['date_created'] is String
          ? json['date_created']
          : (json['date_created'] is Map ? json['date_created']['date'] : null),
      dateModified: json['date_modified'] is String
          ? json['date_modified']
          : (json['date_modified'] is Map ? json['date_modified']['date'] : null),
      datePaid: json['date_paid'],
      discountTax: json['discount_tax'],
      discountTotal: json['discount_total'],
      id: json['id'],
      lineItems: json['line_items'] != null
          ? (json['line_items'] as List).map((i) => LineItem.fromJson(i)).toList()
          : null,
      metaData: json['meta_data'] != null
          ? (json['meta_data'] as List).map((i) => MetaData.fromJson(i)).toList()
          : null,
      number: json['number'],
      orderKey: json['order_key'],
      parentId: json['parent_id'],
      paymentMethod: json['payment_method'],
      paymentMethodTitle: json['payment_method_title'],
      pricesIncludeTax: json['prices_include_tax'],
      shipping: json['shipping'] != null ? Shipping.fromJson(json['shipping']) : null,
      shippingTax: json['shipping_tax'],
      shippingTotal: json['shipping_total'],
      status: json['status'],
      total: json['total'],
      totalTax: json['total_tax'],
      transactionId: json['transaction_id'],
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cart_hash'] = cartHash;
    data['cart_tax'] = cartTax;
    data['created_via'] = createdVia;
    data['currency'] = currency;
    data['customer_id'] = customerId;
    data['customer_ip_address'] = customerIpAddress;
    data['customer_note'] = customerNote;
    data['customer_user_agent'] = customerUserAgent;
    data['date_completed'] = dateCompleted;
    data['date_created'] = dateCreated;
    data['date_modified'] = dateModified;
    data['date_paid'] = datePaid;
    data['discount_tax'] = discountTax;
    data['discount_total'] = discountTotal;
    data['id'] = id;
    data['number'] = number;
    data['order_key'] = orderKey;
    data['parent_id'] = parentId;
    data['paymentMethod'] = paymentMethod;
    data['payment_method_title'] = paymentMethodTitle;
    data['prices_include_tax'] = pricesIncludeTax;
    data['shipping_tax'] = shippingTax;
    data['shipping_total'] = shippingTotal;
    data['status'] = status;
    data['total'] = total;
    data['total_tax'] = totalTax;
    data['transaction_id'] = transactionId;
    data['version'] = version;
    if (billing != null) {
      data['billing'] = billing!.toJson();
    }
    if (lineItems != null) {
      data['line_items'] = lineItems!.map((v) => v.toJson()).toList();
    }
    if (metaData != null) {
      data['meta_data'] = metaData!.map((v) => v.toJson()).toList();
    }
    if (shipping != null) {
      data['shipping'] = shipping!.toJson();
    }
    return data;
  }
}

class DateCreated {
  String? date;
  String? timezone;
  int? timezoneType;

  DateCreated({this.date, this.timezone, this.timezoneType});

  factory DateCreated.fromJson(Map<String, dynamic> json) {
    return DateCreated(
      date: json['date'],
      timezone: json['timezone'],
      timezoneType: json['timezone_type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['timezone'] = timezone;
    data['timezone_type'] = timezoneType;
    return data;
  }
}

class LineItem {
  int? productId;
  List<MetaData>? metaData;
  String? name;
  int? orderId;
  int? pId;
  List<ProductImage>? productImages;
  String? imageUrl; // ✅ جديد — صورة المنتج من WooCommerce API مباشرة
  int? quantity;
  String? subtotal;
  String? subtotalTax;
  String? taxClass;
  String? total;
  String? totalTax;
  int? variationId;

  LineItem(
      {this.productId,
        this.metaData,
        this.name,
        this.orderId,
        this.pId,
        this.productImages,
        this.imageUrl, // ✅ جديد
        this.quantity,
        this.subtotal,
        this.subtotalTax,
        this.taxClass,
        this.total,
        this.totalTax,
        this.variationId});

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      productId: json['id'],
      metaData: json['meta_data'] != null
          ? (json['meta_data'] as List).map((i) => MetaData.fromJson(i)).toList()
          : null,
      name: json['name'],
      orderId: json['order_id'],
      pId: json['product_id'],
      productImages: json['product_images'] != null
          ? (json['product_images'] as List).map((i) => ProductImage.fromJson(i)).toList()
          : null,
      // ✅ جديد — يقرأ صورة المنتج من حقل image في WooCommerce API
      imageUrl: json['image'] != null ? json['image']['src'] : null,
      quantity: json['quantity'],
      subtotal: json['subtotal'],
      subtotalTax: json['subtotal_tax'],
      taxClass: json['tax_class'],
      total: json['total'],
      totalTax: json['total_tax'],
      variationId: json['variation_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = productId;
    data['name'] = name;
    data['order_id'] = orderId;
    data['product_id'] = pId;
    data['quantity'] = quantity;
    data['subtotal'] = subtotal;
    data['subtotal_tax'] = subtotalTax;
    data['tax_class'] = taxClass;
    data['total'] = total;
    data['total_tax'] = totalTax;
    data['variation_id'] = variationId;
    if (metaData != null) {
      data['meta_data'] = metaData!.map((v) => v.toJson()).toList();
    }
    if (productImages != null) {
      data['product_images'] = productImages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductImage {
  String? alt;
  String? dateCreated;
  String? dateModified;
  int? id;
  String? name;
  int? position;
  String? src;

  ProductImage(
      {this.alt,
        this.dateCreated,
        this.dateModified,
        this.id,
        this.name,
        this.position,
        this.src});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      alt: json['alt'],
      dateCreated: json['date_created'],
      dateModified: json['date_modified'],
      id: json['id'],
      name: json['name'],
      position: json['position'],
      src: json['src'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['alt'] = alt;
    data['date_created'] = dateCreated;
    data['date_modified'] = dateModified;
    data['id'] = id;
    data['name'] = name;
    data['position'] = position;
    data['src'] = src;
    return data;
  }
}

class MetaData {
  int? id;
  var key;
  var value;

  MetaData({this.id, this.key, this.value});

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      id: json['id'],
      key: json['key'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['key'] = key;
    data['value'] = value;
    return data;
  }
}

class DateModified {
  String? date;
  String? timezone;
  int? timezoneType;

  DateModified({this.date, this.timezone, this.timezoneType});

  factory DateModified.fromJson(Map<String, dynamic> json) {
    return DateModified(
      date: json['date'],
      timezone: json['timezone'],
      timezoneType: json['timezone_type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['timezone'] = timezone;
    data['timezone_type'] = timezoneType;
    return data;
  }
}

class Value {
  String? dateShipped;
  String? trackingId;
  String? trackingNumber;
  String? trackingProductCode;
  String? trackingProvider;

  Value(
      {this.dateShipped,
        this.trackingId,
        this.trackingNumber,
        this.trackingProductCode,
        this.trackingProvider});

  factory Value.fromJson(Map<String, dynamic> json) {
    return Value(
      dateShipped: json['date_shipped'],
      trackingId: json['tracking_id'],
      trackingNumber: json['tracking_number'],
      trackingProductCode: json['tracking_product_code'],
      trackingProvider: json['tracking_provider'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date_shipped'] = dateShipped;
    data['tracking_id'] = trackingId;
    data['tracking_number'] = trackingNumber;
    data['tracking_product_code'] = trackingProductCode;
    data['tracking_provider'] = trackingProvider;
    return data;
  }
}

class ShippingLines {
  String? methodId;
  String? methodTitle;
  String? total;

  ShippingLines({this.methodId, this.methodTitle, this.total});

  factory ShippingLines.fromJson(Map<String, dynamic> json) {
    return ShippingLines(
      methodId: json['method_id'],
      methodTitle: json['method_title'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['method_id'] = methodId;
    data['method_title'] = methodTitle;
    data['total'] = total ?? "";
    return data;
  }
}
