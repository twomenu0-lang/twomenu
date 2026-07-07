class WalletInitiateResponse {
  String? systemOrderId;
  String? transactionId;
  String? message;

  WalletInitiateResponse({this.systemOrderId, this.transactionId, this.message});

  factory WalletInitiateResponse.fromJson(Map<String, dynamic> json) {
    return WalletInitiateResponse(
      systemOrderId: json['system_order_id']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class WalletStatusResponse {
  String? status; // PENDING / SUCCESS / FAILED

  WalletStatusResponse({this.status});

  factory WalletStatusResponse.fromJson(Map<String, dynamic> json) {
    return WalletStatusResponse(status: json['status']?.toString());
  }

  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';
  bool get isPending => !isSuccess && !isFailed;
}