class WishListResponse {
  int? proId;
  String? name;
  String? sku;
  String? price;
  String? regularPrice;
  String? salePrice;
  int? stockQuantity;
  bool? inStock;
  String? thumbnail;
  String? full;
  List<String>? gallery;
  String? createdAt;

  WishListResponse(
      {this.proId,
        this.name,
        this.sku,
        this.price,
        this.regularPrice,
        this.salePrice,
        this.stockQuantity,
        this.inStock,
        this.thumbnail,
        this.full,
        this.gallery,
        this.createdAt});

  WishListResponse.fromJson(Map<String, dynamic> json) {
    proId = json['pro_id'];
    name = json['name'];
    sku = json['sku'];
    price = json['price'];
    regularPrice = json['regular_price'];
    salePrice = json['sale_price'];
    stockQuantity = json['stock_quantity'];
    inStock = json['in_stock'];
    thumbnail = json['thumbnail'];
    full = json['full'];
    gallery = json['gallery'].cast<String>();
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pro_id'] = proId;
    data['name'] = name;
    data['sku'] = sku;
    data['price'] = price;
    data['regular_price'] = regularPrice;
    data['sale_price'] = salePrice;
    data['stock_quantity'] = stockQuantity;
    data['in_stock'] = inStock;
    data['thumbnail'] = thumbnail;
    data['full'] = full;
    data['gallery'] = gallery;
    data['created_at'] = createdAt;
    return data;
  }
}

