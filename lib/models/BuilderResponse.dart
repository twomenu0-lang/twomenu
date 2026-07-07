class BuilderResponse {
  Dashboard? dashboard;
  Appsetup? appsetup;

  BuilderResponse({this.dashboard, this.appsetup});

  BuilderResponse.fromJson(Map<String, dynamic> json) {
    dashboard = json['dashboard'] != null ? Dashboard.fromJson(json['dashboard']) : null;
    appsetup = json['appsetup'] != null ? Appsetup.fromJson(json['appsetup']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (dashboard != null) { data['dashboard'] = dashboard!.toJson(); }
    if (appsetup != null) { data['appsetup'] = appsetup!.toJson(); }
    return data;
  }
}

class Dashboard {
  List<String>? sorting;
  String? layout;
  AppBar? appBar;
  SliderView? sliderView;
  SliderView? category;
  NewProduct? newProduct;
  NewProduct? featureProduct;
  NewProduct? saleProduct;
  NewProduct? dealOfTheDay;
  NewProduct? bestSaleProduct;
  NewProduct? offerProduct;
  NewProduct? suggestionProduct;
  NewProduct? vendor;
  NewProduct? youMayLikeProduct;
  NewProduct? blog;
  SliderView? saleBanner;

  Dashboard({this.sorting, this.layout, this.appBar, this.sliderView, this.category, this.newProduct, this.featureProduct, this.saleProduct, this.dealOfTheDay, this.bestSaleProduct, this.offerProduct, this.suggestionProduct, this.vendor, this.youMayLikeProduct, this.blog, this.saleBanner});

  Dashboard.fromJson(Map<String, dynamic> json) {
    sorting = json['sorting'].cast<String>();
    layout = json['layout'];
    appBar = json['appBar'] != null ? AppBar.fromJson(json['appBar']) : null;
    sliderView = json['sliderView'] != null ? SliderView.fromJson(json['sliderView']) : null;
    category = json['category'] != null ? SliderView.fromJson(json['category']) : null;
    newProduct = json['newProduct'] != null ? NewProduct.fromJson(json['newProduct']) : null;
    featureProduct = json['feature'] != null ? NewProduct.fromJson(json['feature']) : null;
    saleProduct = json['saleProduct'] != null ? NewProduct.fromJson(json['saleProduct']) : null;
    dealOfTheDay = json['dealOfTheDay'] != null ? NewProduct.fromJson(json['dealOfTheDay']) : null;
    bestSaleProduct = json['bestSaleProduct'] != null ? NewProduct.fromJson(json['bestSaleProduct']) : null;
    offerProduct = json['offerProduct'] != null ? NewProduct.fromJson(json['offerProduct']) : null;
    suggestionProduct = json['suggestionProduct'] != null ? NewProduct.fromJson(json['suggestionProduct']) : null;
    vendor = json['vendor'] != null ? NewProduct.fromJson(json['vendor']) : null;
    youMayLikeProduct = json['youMayLikeProduct'] != null ? NewProduct.fromJson(json['youMayLikeProduct']) : null;
    blog = json['blog'] != null ? NewProduct.fromJson(json['blog']) : null;
    saleBanner = json['saleBanner'] != null ? SliderView.fromJson(json['saleBanner']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sorting'] = sorting;
    data['layout'] = layout;
    if (appBar != null) { data['appBar'] = appBar!.toJson(); }
    if (sliderView != null) { data['sliderView'] = sliderView!.toJson(); }
    if (category != null) { data['category'] = category!.toJson(); }
    if (newProduct != null) { data['newProduct'] = newProduct!.toJson(); }
    if (featureProduct != null) { data['feature'] = featureProduct!.toJson(); }
    if (saleProduct != null) { data['saleProduct'] = saleProduct!.toJson(); }
    if (dealOfTheDay != null) { data['dealOfTheDay'] = dealOfTheDay!.toJson(); }
    if (bestSaleProduct != null) { data['bestSaleProduct'] = bestSaleProduct!.toJson(); }
    if (offerProduct != null) { data['offerProduct'] = offerProduct!.toJson(); }
    if (suggestionProduct != null) { data['suggestionProduct'] = suggestionProduct!.toJson(); }
    if (vendor != null) { data['vendor'] = vendor!.toJson(); }
    if (youMayLikeProduct != null) { data['youMayLikeProduct'] = youMayLikeProduct!.toJson(); }
    if (blog != null) { data['blog'] = blog!.toJson(); }
    return data;
  }
}

class AppBar {
  String? title;
  Null appBarIcon;
  Null appBarLayout;

  AppBar({this.title, this.appBarIcon, this.appBarLayout});

  AppBar.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    appBarIcon = json['appBarIcon'];
    appBarLayout = json['appBarLayout'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['appBarIcon'] = appBarIcon;
    data['appBarLayout'] = appBarLayout;
    return data;
  }
}

class SliderView {
  bool? enable;

  SliderView({this.enable});

  SliderView.fromJson(Map<String, dynamic> json) {
    enable = json['enable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enable'] = enable;
    return data;
  }
}

class NewProduct {
  bool? enable;
  String? title;
  String? viewAll;

  NewProduct({this.enable, this.title, this.viewAll});

  NewProduct.fromJson(Map<String, dynamic> json) {
    enable = json['enable'];
    title = json['title'];
    viewAll = json['viewAll'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enable'] = enable;
    data['title'] = title;
    data['viewAll'] = viewAll;
    return data;
  }
}

class Productdetailview {
  String? layout;

  Productdetailview({this.layout});

  Productdetailview.fromJson(Map<String, dynamic> json) {
    layout = json['layout'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['layout'] = layout;
    return data;
  }
}

class Appsetup {
  String? appName;
  String? primaryColor;
  String? secondaryColor;
  String? backgroundColor;
  String? textPrimaryColor;
  String? textSecondaryColor;
  String? consumerKey;
  String? consumerSecret;
  String? appUrl;

  Appsetup({this.appName, this.primaryColor, this.secondaryColor, this.backgroundColor, this.textPrimaryColor, this.textSecondaryColor, this.consumerKey, this.consumerSecret, this.appUrl});

  Appsetup.fromJson(Map<String, dynamic> json) {
    appName = json['appName'];
    primaryColor = json['primaryColor'];
    secondaryColor = json['secondaryColor'];
    backgroundColor = json['backgroundColor'];
    textPrimaryColor = json['textPrimaryColor'];
    textSecondaryColor = json['textSecondaryColor'];
    consumerKey = json['consumerKey'];
    consumerSecret = json['consumerSecret'];
    appUrl = json['appUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appName'] = appName;
    data['primaryColor'] = primaryColor;
    data['secondaryColor'] = secondaryColor;
    data['backgroundColor'] = backgroundColor;
    data['textPrimaryColor'] = textPrimaryColor;
    data['textSecondaryColor'] = textSecondaryColor;
    data['consumerKey'] = consumerKey;
    data['consumerSecret'] = consumerSecret;
    data['appUrl'] = appUrl;
    return data;
  }
}

