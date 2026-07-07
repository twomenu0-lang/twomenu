class ProductDetailResponse {
  List<Attribute>? attributes;
  String? averageRating;
  String? buttonText;
  String? catalogVisibility;
  List<Category>? categories;
  List<int>? crossSellIds;
  String? dateCreated;
  String? dateModified;
  String? dateOnSaleFrom;
  String? dateOnSaleTo;
  String? description;
  Dimensions? dimensions;
  int? downloadExpiry;
  int? downloadLimit;
  String? downloadType;
  bool? downloadable;
  String? externalUrl;
  bool? featured;
  int? id;
  List<ImageModel>? images;
  bool? inStock;
  bool? isAddedCart;
  bool? isAddedWishList;
  bool? manageStock;
  int? menuOrder;
  String? name;
  bool? onSale;
  int? parentId;
  String? permalink;
  String? price;
  String? priceHtml;
  bool? purchasable;
  String? purchaseNote;
  int? ratingCount;
  String? regularPrice;
  List<int>? relatedIds;
  bool? reviewsAllowed;
  String? salePrice;
  String? shippingClass;
  int? shippingClassId;
  bool? shippingRequired;
  bool? shippingTaxable;
  String? shortDescription;
  String? sku;
  String? slug;
  bool? soldIndividually;
  String? status;
  Store? store;
  String? taxClass;
  String? taxStatus;
  String? type;
  List<int>? upSellIds;
  List<UpsellId>? upSellId;
  List<int>? variations;
  bool? virtual;
  String? weight;
  VideoData? woofVideoEmbed;

  ProductDetailResponse(
      {this.attributes,
        this.averageRating,
        this.buttonText,
        this.catalogVisibility,
        this.categories,
        this.crossSellIds,
        this.dateCreated,
        this.dateModified,
        this.dateOnSaleFrom,
        this.dateOnSaleTo,
        this.description,
        this.dimensions,
        this.downloadExpiry,
        this.downloadLimit,
        this.downloadType,
        this.downloadable,
        this.externalUrl,
        this.featured,
        this.id,
        this.images,
        this.inStock,
        this.isAddedCart,
        this.isAddedWishList,
        this.manageStock,
        this.menuOrder,
        this.name,
        this.onSale,
        this.parentId,
        this.permalink,
        this.price,
        this.priceHtml,
        this.purchasable,
        this.purchaseNote,
        this.ratingCount,
        this.regularPrice,
        this.relatedIds,
        this.reviewsAllowed,
        this.salePrice,
        this.shippingClass,
        this.shippingClassId,
        this.shippingRequired,
        this.shippingTaxable,
        this.shortDescription,
        this.sku,
        this.slug,
        this.soldIndividually,
        this.status,
        this.store,
        this.taxClass,
        this.taxStatus,
        this.type,
        this.upSellIds,
        this.upSellId,
        this.variations,
        this.virtual,
        this.weight,
        this.woofVideoEmbed});

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponse(
      attributes: json['attributes'] != null ? (json['attributes'] as List).map((i) => Attribute.fromJson(i)).toList() : null,
      averageRating: json['average_rating'],
      buttonText: json['button_text'],
      catalogVisibility: json['catalog_visibility'],
      categories: json['categories'] != null ? (json['categories'] as List).map((i) => Category.fromJson(i)).toList() : null,
      crossSellIds: json['cross_sell_ids'] != null ? List<int>.from(json['cross_sell_ids']) : null,
      dateCreated: json['date_created'],
      dateModified: json['date_modified'],
      dateOnSaleFrom: json['date_on_sale_from'],
      dateOnSaleTo: json['date_on_sale_to'],
      description: json['description'],
      dimensions: json['dimensions'] != null ? Dimensions.fromJson(json['dimensions']) : null,
      downloadExpiry: json['download_expiry'],
      downloadLimit: json['download_limit'],
      downloadType: json['download_type'],
      /* downloadable: json['downloadable'],*/
      externalUrl: json['external_url'],
      featured: json['featured'],
      id: json['id'],
      images: json['images'] != null ? (json['images'] as List).map((i) => ImageModel.fromJson(i)).toList() : null,
      inStock: json['in_stock'],
      isAddedCart: json['is_added_cart'],
      isAddedWishList: json['is_added_wishlist'],
      //manageStock: json['manage_stock'],
      menuOrder: json['menu_order'],
      name: json['name'],
      onSale: json['on_sale'],
      parentId: json['parent_id'],
      permalink: json['permalink'],
      price: json['price'],
      priceHtml: json['price_html'],
      purchasable: json['purchasable'],
      purchaseNote: json['purchase_note'],
      ratingCount: json['rating_count'],
      regularPrice: json['regular_price'],
      relatedIds: json['related_ids'] != null ? List<int>.from(json['related_ids']) : null,
      reviewsAllowed: json['reviews_allowed'],
      salePrice: json['sale_price'],
      shippingClass: json['shipping_class'],
      shippingClassId: json['shipping_class_id'],
      shippingRequired: json['shipping_required'],
      shippingTaxable: json['shipping_taxable'],
      shortDescription: json['short_description'],
      sku: json['sku'],
      slug: json['slug'],
      soldIndividually: json['sold_individually'],
      status: json['status'],
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      taxClass: json['tax_class'],
      taxStatus: json['tax_status'],
      type: json['type'],
      upSellIds: json['upsell_ids'] != null ? List<int>.from(json['upsell_ids']) : null,
      variations: json['variations'] != null ? List<int>.from(json['variations']) : null,
      virtual: json['virtual'],
      weight: json['weight'],
      upSellId: json['upsell_id'] != null ? (json['upsell_id'] as List).map((i) => UpsellId.fromJson(i)).toList() : null,
      woofVideoEmbed: json['woofv_video_embed'] != null ? VideoData.fromJson(json['woofv_video_embed']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['average_rating'] = averageRating;
    data['button_text'] = buttonText;
    data['catalog_visibility'] = catalogVisibility;
    data['date_created'] = dateCreated;
    data['date_modified'] = dateModified;
    data['date_on_sale_from'] = dateOnSaleFrom;
    data['date_on_sale_to'] = dateOnSaleTo;
    data['description'] = description;
    data['download_expiry'] = downloadExpiry;
    data['download_limit'] = downloadLimit;
    data['download_type'] = downloadType;
    data['downloadable'] = downloadable;
    data['external_url'] = externalUrl;
    data['featured'] = featured;
    data['id'] = id;
    data['in_stock'] = inStock;
    data['is_added_cart'] = isAddedCart;
    data['is_added_wishlist'] = isAddedWishList;
    data['manage_stock'] = manageStock;
    data['menu_order'] = menuOrder;
    data['name'] = name;
    data['on_sale'] = onSale;
    data['parent_id'] = parentId;
    data['permalink'] = permalink;
    data['price'] = price;
    data['price_html'] = priceHtml;
    data['purchasable'] = purchasable;
    data['purchase_note'] = purchaseNote;
    data['rating_count'] = ratingCount;
    data['regular_price'] = regularPrice;
    data['reviews_allowed'] = reviewsAllowed;
    data['sale_price'] = salePrice;
    data['shipping_class'] = shippingClass;
    data['shipping_class_id'] = shippingClassId;
    data['shipping_required'] = shippingRequired;
    data['shipping_taxable'] = shippingTaxable;
    data['short_description'] = shortDescription;
    data['sku'] = sku;
    data['slug'] = slug;
    data['sold_individually'] = soldIndividually;
    data['status'] = status;
    data['tax_class'] = taxClass;
    data['tax_status'] = taxStatus;
    data['type'] = type;
    data['virtual'] = virtual;
    data['weight'] = weight;
    if (attributes != null) {
      data['attributes'] = attributes!.map((v) => v.toJson()).toList();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    if (crossSellIds != null) {
      data['cross_sell_ids'] = crossSellIds;
    }

    if (dimensions != null) {
      data['dimensions'] = dimensions!.toJson();
    }

    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    if (relatedIds != null) {
      data['related_ids'] = relatedIds;
    }
    if (store != null) {
      data['store'] = store!.toJson();
    }
    if (upSellIds != null) {
      data['upsell_ids'] = upSellIds;
    }
    if (variations != null) {
      data['variations'] = variations;
    }
    if (woofVideoEmbed != null) {
      data['woofv_video_embed'] = woofVideoEmbed!.toJson();
    }
    return data;
  }
}

class VideoData {
  bool? autoplay;
  String? poster;
  String? thumbnail;
  String? url;

  VideoData({this.autoplay, this.poster, this.thumbnail, this.url});

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      autoplay: json['autoplay'],
      poster: json['poster'],
      thumbnail: json['thumbnail'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['autoplay'] = autoplay;
    data['poster'] = poster;
    data['thumbnail'] = thumbnail;
    data['url'] = url;
    return data;
  }
}

class Store {
  Address? address;
  int? id;
  String? name;
  String? shopName;
  String? url;

  Store({this.address, this.id, this.name, this.shopName, this.url});

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      id: json['id'],
      name: json['name'],
      shopName: json['shop_name'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['shop_name'] = shopName;
    data['url'] = url;
    if (address != null) {
      data['address'] = address!.toJson();
    }
    return data;
  }
}

class Address {
  String? city;
  String? country;
  String? state;
  String? street_1;
  String? street_2;
  String? zip;

  Address({this.city, this.country, this.state, this.street_1, this.street_2, this.zip});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      city: json['city'],
      country: json['country'],
      state: json['state'],
      street_1: json['street_1'],
      street_2: json['street_2'],
      zip: json['zip'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['city'] = city;
    data['country'] = country;
    data['state'] = state;
    data['street_1'] = street_1;
    data['street_2'] = street_2;
    data['zip'] = zip;
    return data;
  }
}

class Dimensions {
  String? height;
  String? length;
  String? width;

  Dimensions({this.height, this.length, this.width});

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      height: json['height'],
      length: json['length'],
      width: json['width'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['height'] = height;
    data['length'] = length;
    data['width'] = width;
    return data;
  }
}

class Attribute {
  var id;
  var name;
  var position;
  var visible;
  var variation;
  List<String>? options;
  String? option;

  Attribute({this.id, this.name, this.position, this.visible, this.variation, this.option, this.options});

//  Attributes.fromJson(Map<String, dynamic> json) {
//    id = json['id'];
//    name = json['name'];
//    position = json['position'];
//    visible = json['visible'];
//    variation = json['variation'];
//    options = json['options'] != null
//        ? new List<String>.from(json['options'])
//        : null;
//  }
  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      visible: json['visible'],
      variation: json['variation'],
      option: json['option'],
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['position'] = position;
    data['visible'] = visible;
    data['variation'] = variation;
    data['option'] = option;
    if (options != null) {
      data['options'] = options;
    }
    return data;
  }
}

class Category {
  int? id;
  String? name;
  String? slug;

  Category({this.id, this.name, this.slug});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    return data;
  }
}

class ImageModel {
  String? alt;
  String? dateCreated;
  String? dateModified;
  int? id;
  String? name;
  int? position;
  String? src;

  ImageModel({this.alt, this.dateCreated, this.dateModified, this.id, this.name, this.position, this.src});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
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

class UpsellId {
  int? id;
  List<ImageX>? images;
  String? name;
  String? price;
  String? regularPrice;
  String? salePrice;
  String? slug;

  UpsellId({this.id, this.images, this.name, this.price, this.regularPrice, this.salePrice, this.slug});

  factory UpsellId.fromJson(Map<String, dynamic> json) {
    return UpsellId(
      id: json['id'],
      images: json['images'] != null ? (json['images'] as List).map((i) => ImageX.fromJson(i)).toList() : null,
      name: json['name'],
      price: json['price'],
      regularPrice: json['regular_price'],
      salePrice: json['sale_price'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['price'] = price;
    data['regular_price'] = regularPrice;
    data['sale_price'] = salePrice;
    data['slug'] = slug;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ImageX {
  String? alt;
  String? dateCreated;
  String? dateModified;
  int? id;
  String? name;
  int? position;
  String? src;

  ImageX({this.alt, this.dateCreated, this.dateModified, this.id, this.name, this.position, this.src});

  factory ImageX.fromJson(Map<String, dynamic> json) {
    return ImageX(
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

