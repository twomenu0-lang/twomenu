class AddWalletResponse {
  bool? status;
  String? woocommerceRedirect;

  AddWalletResponse({this.status, this.woocommerceRedirect});

  AddWalletResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    woocommerceRedirect = json['woocommerce_redirect'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['woocommerce_redirect'] = woocommerceRedirect;
    return data;
  }
}

