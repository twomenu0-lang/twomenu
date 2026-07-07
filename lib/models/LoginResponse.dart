class LoginResponse {
  String? token;
  String? userEmail;
  String? userNicename;
  String? userDisplayName;
  String? firstName;
  String? lastName;
  Billing? billing;
  Shipping? shipping;
  List<String>? userRole;
  int? userId;
  String? avatar;
  String? profileImage;

  LoginResponse(
      {this.token,
        this.userEmail,
        this.userNicename,
        this.userDisplayName,
        this.firstName,
        this.lastName,
        this.billing,
        this.shipping,
        this.userRole,
        this.userId,
        this.avatar,
        this.profileImage});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    userEmail = json['user_email'];
    userNicename = json['user_nicename'];
    userDisplayName = json['user_display_name'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    billing =
    json['billing'] != null ? Billing.fromJson(json['billing']) : null;
    shipping = json['shipping'] != null
        ? Shipping.fromJson(json['shipping'])
        : null;
    userRole = json['user_role'].cast<String>();
    userId = json['user_id'];
    avatar = json['avatar'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    data['user_email'] = userEmail;
    data['user_nicename'] = userNicename;
    data['user_display_name'] = userDisplayName;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    if (billing != null) {
      data['billing'] = billing!.toJson();
    }
    if (shipping != null) {
      data['shipping'] = shipping!.toJson();
    }
    data['user_role'] = userRole;
    data['user_id'] = userId;
    data['avatar'] = avatar;
    data['profile_image'] = profileImage;
    return data;
  }
}

class Billing {
  String? firstName;
  String? lastName;
  String? company;
  String? address1;
  String? address2;
  String? city;
  String? postcode;
  String? country;
  String? state;
  String? email;
  String? phone;

  Billing(
      {this.firstName,
        this.lastName,
        this.company,
        this.address1,
        this.address2,
        this.city,
        this.postcode,
        this.country,
        this.state,
        this.email,
        this.phone});

  Billing.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    lastName = json['last_name'];
    company = json['company'];
    address1 = json['address_1'];
    address2 = json['address_2'];
    city = json['city'];
    postcode = json['postcode'];
    country = json['country'];
    state = json['state'];
    email = json['email'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['company'] = company;
    data['address_1'] = address1;
    data['address_2'] = address2;
    data['city'] = city;
    data['postcode'] = postcode;
    data['country'] = country;
    data['state'] = state;
    data['email'] = email;
    data['phone'] = phone;
    return data;
  }
}

class Shipping {
  String? firstName;
  String? lastName;
  String? company;
  String? address1;
  String? address2;
  String? city;
  String? postcode;
  String? country;
  String? state;

  Shipping(
      {this.firstName,
        this.lastName,
        this.company,
        this.address1,
        this.address2,
        this.city,
        this.postcode,
        this.country,
        this.state});

  Shipping.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    lastName = json['last_name'];
    company = json['company'];
    address1 = json['address_1'];
    address2 = json['address_2'];
    city = json['city'];
    postcode = json['postcode'];
    country = json['country'];
    state = json['state'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['company'] = company;
    data['address_1'] = address1;
    data['address_2'] = address2;
    data['city'] = city;
    data['postcode'] = postcode;
    data['country'] = country;
    data['state'] = state;
    return data;
  }
}

