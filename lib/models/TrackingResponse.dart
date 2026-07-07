import '/../models/CategoryData.dart';

class TrackingResponse {
  String? trackingId;
  String? trackingProvider;
  String? trackingLink;
  String? trackingNumber;
  String? dateShipped;
  Links? lLinks;

  TrackingResponse(
      {this.trackingId,
        this.trackingProvider,
        this.trackingLink,
        this.trackingNumber,
        this.dateShipped,
        this.lLinks});

  TrackingResponse.fromJson(Map<String, dynamic> json) {
    trackingId = json['tracking_id'];
    trackingProvider = json['tracking_provider'];
    trackingLink = json['tracking_link'];
    trackingNumber = json['tracking_number'];
    dateShipped = json['date_shipped'];
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tracking_id'] = trackingId;
    data['tracking_provider'] = trackingProvider;
    data['tracking_link'] = trackingLink;
    data['tracking_number'] = trackingNumber;
    data['date_shipped'] = dateShipped;
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }
}

class Links {
  List<Self>? self;
  List<Collection>? collection;
  List<Up>? up;

  Links({this.self, this.collection, this.up});

  Links.fromJson(Map<String, dynamic> json) {
    if (json['self'] != null) {
      self = <Self>[];
      json['self'].forEach((v) {
        self!.add(Self.fromJson(v));
      });
    }
    if (json['collection'] != null) {
      collection = <Collection>[];
      json['collection'].forEach((v) {
        collection!.add(Collection.fromJson(v));
      });
    }
    if (json['up'] != null) {
      up = <Up>[];
      json['up'].forEach((v) {
        up!.add(Up.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (self != null) {
      data['self'] = self!.map((v) => v.toJson()).toList();
    }
    if (collection != null) {
      data['collection'] = collection!.map((v) => v.toJson()).toList();
    }
    if (up != null) {
      data['up'] = up!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Self {
  String? href;

  Self({this.href});

  Self.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}

