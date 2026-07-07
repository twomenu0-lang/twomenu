class CartResponse {
  int? totalQuantity;
  List<CartModel>? data;

  CartResponse({this.totalQuantity, this.data});

  CartResponse.fromJson(Map<String, dynamic> json) {
    totalQuantity = json['total_quantity'];
    if (json['data'] != null) {
      data = <CartModel>[];
      json['data'].forEach((v) {
        data!.add(CartModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_quantity'] = totalQuantity;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CartModel {
  var cartId;
  var proId;
  var name;
  var sku;
  var price;
  var onSale;
  var regularPrice;
  var salePrice;
  var stockQuantity;
  var stockStatus;
  var thumbnail;
  var full;
  List<String?>? gallery;
  var createdAt;
  var quantity;

  CartModel(
      {this.cartId,
      this.proId,
      this.name,
      this.sku,
      this.price,
      this.onSale,
      this.regularPrice,
      this.salePrice,
      this.stockQuantity,
      this.stockStatus,
      this.thumbnail,
      this.full,
      this.gallery,
      this.createdAt,
      this.quantity});

  CartModel.fromJson(Map<String, dynamic> json) {
    cartId = json['cart_id'];
    proId = json['pro_id'];
    name = json['name'];
    sku = json['sku'];
    price = json['price'];
    onSale = json['on_sale'];
    regularPrice = json['regular_price'];
    salePrice = json['sale_price'];
    stockQuantity = json['stock_quantity'];
    stockStatus = json['stock_status'];
    thumbnail = json['thumbnail'];
    full = json['full'];
    gallery = json['gallery'].cast<String>();
    createdAt = json['created_at'];
    quantity = json['quantity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cart_id'] = cartId;
    data['pro_id'] = proId;
    data['name'] = name;
    data['sku'] = sku;
    data['price'] = price;
    data['on_sale'] = onSale;
    data['regular_price'] = regularPrice;
    data['sale_price'] = salePrice;
    data['stock_quantity'] = stockQuantity;
    data['stock_status'] = stockStatus;
    data['thumbnail'] = thumbnail;
    data['full'] = full;
    data['gallery'] = gallery;
    data['created_at'] = createdAt;
    data['quantity'] = quantity;
    return data;
  }
}

