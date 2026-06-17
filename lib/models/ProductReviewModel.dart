class ProductReviewModel {
  int? id;
  String? dateCreated;
  String? dateCreatedGmt;
  int? productId;
  String? status;
  String? reviewer;
  String? reviewerEmail;
  String? review;
  int? rating;
  bool? verified;
  ReviewerAvatarUrls? reviewerAvatarUrls;
  ReviewLinks? lLinks;

  ProductReviewModel({
    this.id,
    this.dateCreated,
    this.dateCreatedGmt,
    this.productId,
    this.status,
    this.reviewer,
    this.reviewerEmail,
    this.review,
    this.rating,
    this.verified,
    this.reviewerAvatarUrls,
    this.lLinks,
  });

  /// اسم المراجع
  String? get reviewerName => reviewer;

  /// رابط الصورة الرمزية 96px
  String? get avatarUrl => reviewerAvatarUrls?.s96;

  ProductReviewModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dateCreated = json['date_created'];
    dateCreatedGmt = json['date_created_gmt'];
    productId = json['product_id'];
    status = json['status'];
    reviewer = json['reviewer'];
    reviewerEmail = json['reviewer_email'];
    review = json['review'];
    rating = json['rating'];
    verified = json['verified'];
    reviewerAvatarUrls = json['reviewer_avatar_urls'] != null
        ? ReviewerAvatarUrls.fromJson(json['reviewer_avatar_urls'])
        : null;
    lLinks =
    json['_links'] != null ? ReviewLinks.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['date_created'] = dateCreated;
    data['date_created_gmt'] = dateCreatedGmt;
    data['product_id'] = productId;
    data['status'] = status;
    data['reviewer'] = reviewer;
    data['reviewer_email'] = reviewerEmail;
    data['review'] = review;
    data['rating'] = rating;
    data['verified'] = verified;
    if (reviewerAvatarUrls != null) {
      data['reviewer_avatar_urls'] = reviewerAvatarUrls!.toJson();
    }
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }
}

// ─────────────────────────────────────────
// Reviewer Avatar URLs
// ─────────────────────────────────────────
class ReviewerAvatarUrls {
  String? s24;
  String? s48;
  String? s96;

  ReviewerAvatarUrls({this.s24, this.s48, this.s96});

  ReviewerAvatarUrls.fromJson(Map<String, dynamic> json) {
    s24 = json['24']?.toString();
    s48 = json['48']?.toString();
    s96 = json['96']?.toString();
  }

  Map<String, dynamic> toJson() => {
    '24': s24,
    '48': s48,
    '96': s96,
  };
}

// ─────────────────────────────────────────
// Links  (اسم مختلف لتفادي التعارض مع Links في CategoryData)
// ─────────────────────────────────────────
class ReviewLinks {
  List<ReviewSelf>? self;
  List<ReviewCollection>? collection;
  List<ReviewUp>? up;

  ReviewLinks({this.self, this.collection, this.up});

  ReviewLinks.fromJson(Map<String, dynamic> json) {
    if (json['self'] != null) {
      self = <ReviewSelf>[];
      json['self'].forEach((v) => self!.add(ReviewSelf.fromJson(v)));
    }
    if (json['collection'] != null) {
      collection = <ReviewCollection>[];
      json['collection']
          .forEach((v) => collection!.add(ReviewCollection.fromJson(v)));
    }
    if (json['up'] != null) {
      up = <ReviewUp>[];
      json['up'].forEach((v) => up!.add(ReviewUp.fromJson(v)));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (self != null) data['self'] = self!.map((v) => v.toJson()).toList();
    if (collection != null) {
      data['collection'] = collection!.map((v) => v.toJson()).toList();
    }
    if (up != null) data['up'] = up!.map((v) => v.toJson()).toList();
    return data;
  }
}

class ReviewSelf {
  String? href;
  ReviewSelf({this.href});
  ReviewSelf.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }
  Map<String, dynamic> toJson() => {'href': href};
}

class ReviewCollection {
  String? href;
  ReviewCollection({this.href});
  ReviewCollection.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }
  Map<String, dynamic> toJson() => {'href': href};
}

class ReviewUp {
  String? href;
  ReviewUp({this.href});
  ReviewUp.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }
  Map<String, dynamic> toJson() => {'href': href};
}
