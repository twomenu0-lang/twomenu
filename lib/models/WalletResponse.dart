class WalletResponse {
  var transactionId;
  var blogId;
  var userId;
  var type;
  var amount;
  var balance;
  var currency;
  var details;
  var createdBy;
  var deleted;
  var date;

  WalletResponse(
      {this.transactionId,
        this.blogId,
        this.userId,
        this.type,
        this.amount,
        this.balance,
        this.currency,
        this.details,
        this.createdBy,
        this.deleted,
        this.date});

  WalletResponse.fromJson(Map<String, dynamic> json) {
    transactionId = json['transaction_id'];
    blogId = json['blog_id'];
    userId = json['user_id'];
    type = json['type'];
    amount = json['amount'];
    balance = json['balance'];
    currency = json['currency'];
    details = json['details'];
    createdBy = json['created_by'];
    deleted = json['deleted'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transaction_id'] = transactionId;
    data['blog_id'] = blogId;
    data['user_id'] = userId;
    data['type'] = type;
    data['amount'] = amount;
    data['balance'] = balance;
    data['currency'] = currency;
    data['details'] = details;
    data['created_by'] = createdBy;
    data['deleted'] = deleted;
    data['date'] = date;
    return data;
  }
}

