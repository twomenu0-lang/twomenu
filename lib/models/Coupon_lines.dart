class CouponLines {
  String? code;
  CouponLines({this.code});
  CouponLines.fromJson(Map<String, dynamic> json) {
    code = json['code'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    return data;
  }
}
class Tracking {
   String? status;
   String? message;

  Tracking({this.status, this.message});
  factory Tracking.fromJson(dynamic json) {
    return  Tracking(status:json['status'], message: json['message']);
  }

  @override
  String toString() {
    return '{$status,$message';
  }
}
