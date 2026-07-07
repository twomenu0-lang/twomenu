class PaymentGatewayModel {
  String? id;
  String? methodDescription;
  String? methodTitle;

  PaymentGatewayModel({this.id, this.methodDescription, this.methodTitle});

  factory PaymentGatewayModel.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayModel(
      id: json['id'],
      methodDescription: json['method_description'],
      methodTitle: json['method_title'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['method_description'] = methodDescription;
    data['method_title'] = methodTitle;
    return data;
  }
}

