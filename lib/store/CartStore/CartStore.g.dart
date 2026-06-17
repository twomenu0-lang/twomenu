// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CartStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CartStore on _CartStore, Store {
  late final _$cartListAtom =
      Atom(name: '_CartStore.cartList', context: context);

  @override
  List<CartModel> get cartList {
    _$cartListAtom.reportRead();
    return super.cartList;
  }

  @override
  set cartList(List<CartModel> value) {
    _$cartListAtom.reportWrite(value, super.cartList, () {
      super.cartList = value;
    });
  }

  late final _$cartResponseAtom =
      Atom(name: '_CartStore.cartResponse', context: context);

  @override
  CartResponse? get cartResponse {
    _$cartResponseAtom.reportRead();
    return super.cartResponse;
  }

  @override
  set cartResponse(CartResponse? value) {
    _$cartResponseAtom.reportWrite(value, super.cartResponse, () {
      super.cartResponse = value;
    });
  }

  late final _$mLineItemsAtom =
      Atom(name: '_CartStore.mLineItems', context: context);

  @override
  List<LineItems> get mLineItems {
    _$mLineItemsAtom.reportRead();
    return super.mLineItems;
  }

  @override
  set mLineItems(List<LineItems> value) {
    _$mLineItemsAtom.reportWrite(value, super.mLineItems, () {
      super.mLineItems = value;
    });
  }

  late final _$shippingMethodsAtom =
      Atom(name: '_CartStore.shippingMethods', context: context);

  @override
  List<Method> get shippingMethods {
    _$shippingMethodsAtom.reportRead();
    return super.shippingMethods;
  }

  @override
  set shippingMethods(List<Method> value) {
    _$shippingMethodsAtom.reportWrite(value, super.shippingMethods, () {
      super.shippingMethods = value;
    });
  }

  late final _$countryListAtom =
      Atom(name: '_CartStore.countryList', context: context);

  @override
  List<Country> get countryList {
    _$countryListAtom.reportRead();
    return super.countryList;
  }

  @override
  set countryList(List<Country> value) {
    _$countryListAtom.reportWrite(value, super.countryList, () {
      super.countryList = value;
    });
  }

  late final _$shippingAtom =
      Atom(name: '_CartStore.shipping', context: context);

  @override
  Shipping? get shipping {
    _$shippingAtom.reportRead();
    return super.shipping;
  }

  @override
  set shipping(Shipping? value) {
    _$shippingAtom.reportWrite(value, super.shipping, () {
      super.shipping = value;
    });
  }

  late final _$shippingMethodResponseAtom =
      Atom(name: '_CartStore.shippingMethodResponse', context: context);

  @override
  ShippingMethodResponse? get shippingMethodResponse {
    _$shippingMethodResponseAtom.reportRead();
    return super.shippingMethodResponse;
  }

  @override
  set shippingMethodResponse(ShippingMethodResponse? value) {
    _$shippingMethodResponseAtom
        .reportWrite(value, super.shippingMethodResponse, () {
      super.shippingMethodResponse = value;
    });
  }

  late final _$isOutOfStockAtom =
      Atom(name: '_CartStore.isOutOfStock', context: context);

  @override
  bool get isOutOfStock {
    _$isOutOfStockAtom.reportRead();
    return super.isOutOfStock;
  }

  @override
  set isOutOfStock(bool value) {
    _$isOutOfStockAtom.reportWrite(value, super.isOutOfStock, () {
      super.isOutOfStock = value;
    });
  }

  late final _$cartTotalDiscountAtom =
      Atom(name: '_CartStore.cartTotalDiscount', context: context);

  @override
  num get cartTotalDiscount {
    _$cartTotalDiscountAtom.reportRead();
    return super.cartTotalDiscount;
  }

  @override
  set cartTotalDiscount(num value) {
    _$cartTotalDiscountAtom.reportWrite(value, super.cartTotalDiscount, () {
      super.cartTotalDiscount = value;
    });
  }

  late final _$cartTotalAmountAtom =
      Atom(name: '_CartStore.cartTotalAmount', context: context);

  @override
  num get cartTotalAmount {
    _$cartTotalAmountAtom.reportRead();
    return super.cartTotalAmount;
  }

  @override
  set cartTotalAmount(num value) {
    _$cartTotalAmountAtom.reportWrite(value, super.cartTotalAmount, () {
      super.cartTotalAmount = value;
    });
  }

  late final _$cartTotalPayableAmountAtom =
      Atom(name: '_CartStore.cartTotalPayableAmount', context: context);

  @override
  num get cartTotalPayableAmount {
    _$cartTotalPayableAmountAtom.reportRead();
    return super.cartTotalPayableAmount;
  }

  @override
  set cartTotalPayableAmount(num value) {
    _$cartTotalPayableAmountAtom
        .reportWrite(value, super.cartTotalPayableAmount, () {
      super.cartTotalPayableAmount = value;
    });
  }

  late final _$cartSavedAmountAtom =
      Atom(name: '_CartStore.cartSavedAmount', context: context);

  @override
  num get cartSavedAmount {
    _$cartSavedAmountAtom.reportRead();
    return super.cartSavedAmount;
  }

  @override
  set cartSavedAmount(num value) {
    _$cartSavedAmountAtom.reportWrite(value, super.cartSavedAmount, () {
      super.cartSavedAmount = value;
    });
  }

  late final _$cartTotalCountAtom =
      Atom(name: '_CartStore.cartTotalCount', context: context);

  @override
  num get cartTotalCount {
    _$cartTotalCountAtom.reportRead();
    return super.cartTotalCount;
  }

  @override
  set cartTotalCount(num value) {
    _$cartTotalCountAtom.reportWrite(value, super.cartTotalCount, () {
      super.cartTotalCount = value;
    });
  }

  late final _$selectedShipmentAtom =
      Atom(name: '_CartStore.selectedShipment', context: context);

  @override
  int get selectedShipment {
    _$selectedShipmentAtom.reportRead();
    return super.selectedShipment;
  }

  @override
  set selectedShipment(int value) {
    _$selectedShipmentAtom.reportWrite(value, super.selectedShipment, () {
      super.selectedShipment = value;
    });
  }

  late final _$addToMyCartAsyncAction =
      AsyncAction('_CartStore.addToMyCart', context: context);

  @override
  Future<void> addToMyCart(CartModel data) {
    return _$addToMyCartAsyncAction.run(() => super.addToMyCart(data));
  }

  late final _$updateToCartItemAsyncAction =
      AsyncAction('_CartStore.updateToCartItem', context: context);

  @override
  Future<void> updateToCartItem(dynamic req) {
    return _$updateToCartItemAsyncAction.run(() => super.updateToCartItem(req));
  }

  late final _$storeCartDataAsyncAction =
      AsyncAction('_CartStore.storeCartData', context: context);

  @override
  Future<void> storeCartData() {
    return _$storeCartDataAsyncAction.run(() => super.storeCartData());
  }

  late final _$clearCartAsyncAction =
      AsyncAction('_CartStore.clearCart', context: context);

  @override
  Future<void> clearCart() {
    return _$clearCartAsyncAction.run(() => super.clearCart());
  }

  late final _$fetchShipmentDataAsyncAction =
      AsyncAction('_CartStore.fetchShipmentData', context: context);

  @override
  Future<void> fetchShipmentData() {
    return _$fetchShipmentDataAsyncAction.run(() => super.fetchShipmentData());
  }

  late final _$fetchShippingMethodAsyncAction =
      AsyncAction('_CartStore.fetchShippingMethod', context: context);

  @override
  Future fetchShippingMethod(dynamic value) {
    return _$fetchShippingMethodAsyncAction
        .run(() => super.fetchShippingMethod(value));
  }

  late final _$_CartStoreActionController =
      ActionController(name: '_CartStore', context: context);

  @override
  void addAllCartItem(List<CartModel> productList) {
    final _$actionInfo = _$_CartStoreActionController.startAction(
        name: '_CartStore.addAllCartItem');
    try {
      return super.addAllCartItem(productList);
    } finally {
      _$_CartStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void calculateTotal() {
    final _$actionInfo = _$_CartStoreActionController.startAction(
        name: '_CartStore.calculateTotal');
    try {
      return super.calculateTotal();
    } finally {
      _$_CartStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void getCartListData() {
    final _$actionInfo = _$_CartStoreActionController.startAction(
        name: '_CartStore.getCartListData');
    try {
      return super.getCartListData();
    } finally {
      _$_CartStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addToCartList(CartModel val) {
    final _$actionInfo = _$_CartStoreActionController.startAction(
        name: '_CartStore.addToCartList');
    try {
      return super.addToCartList(val);
    } finally {
      _$_CartStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeFromCartList(CartModel val) {
    final _$actionInfo = _$_CartStoreActionController.startAction(
        name: '_CartStore.removeFromCartList');
    try {
      return super.removeFromCartList(val);
    } finally {
      _$_CartStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void getStoreCartList() {
    final _$actionInfo = _$_CartStoreActionController.startAction(
        name: '_CartStore.getStoreCartList');
    try {
      return super.getStoreCartList();
    } finally {
      _$_CartStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  dynamic loadShippingMethod() {
    final _$actionInfo = _$_CartStoreActionController.startAction(
        name: '_CartStore.loadShippingMethod');
    try {
      return super.loadShippingMethod();
    } finally {
      _$_CartStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
cartList: ${cartList},
cartResponse: ${cartResponse},
mLineItems: ${mLineItems},
shippingMethods: ${shippingMethods},
countryList: ${countryList},
shipping: ${shipping},
shippingMethodResponse: ${shippingMethodResponse},
isOutOfStock: ${isOutOfStock},
cartTotalDiscount: ${cartTotalDiscount},
cartTotalAmount: ${cartTotalAmount},
cartTotalPayableAmount: ${cartTotalPayableAmount},
cartSavedAmount: ${cartSavedAmount},
cartTotalCount: ${cartTotalCount},
selectedShipment: ${selectedShipment}
    ''';
  }
}
