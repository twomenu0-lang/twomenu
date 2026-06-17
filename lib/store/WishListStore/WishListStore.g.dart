// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'WishListStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WishListStore on _WishListStore, Store {
  late final _$wishListAtom =
      Atom(name: '_WishListStore.wishList', context: context);

  @override
  List<WishListResponse> get wishList {
    _$wishListAtom.reportRead();
    return super.wishList;
  }

  @override
  set wishList(List<WishListResponse> value) {
    _$wishListAtom.reportWrite(value, super.wishList, () {
      super.wishList = value;
    });
  }

  late final _$addToWishListAsyncAction =
      AsyncAction('_WishListStore.addToWishList', context: context);

  @override
  Future<void> addToWishList(WishListResponse data) {
    return _$addToWishListAsyncAction.run(() => super.addToWishList(data));
  }

  late final _$storeWishlistDataAsyncAction =
      AsyncAction('_WishListStore.storeWishlistData', context: context);

  @override
  Future<void> storeWishlistData() {
    return _$storeWishlistDataAsyncAction.run(() => super.storeWishlistData());
  }

  late final _$getWishlistItemAsyncAction =
      AsyncAction('_WishListStore.getWishlistItem', context: context);

  @override
  Future<void> getWishlistItem() {
    return _$getWishlistItemAsyncAction.run(() => super.getWishlistItem());
  }

  late final _$clearWishlistAsyncAction =
      AsyncAction('_WishListStore.clearWishlist', context: context);

  @override
  Future<void> clearWishlist() {
    return _$clearWishlistAsyncAction.run(() => super.clearWishlist());
  }

  late final _$_WishListStoreActionController =
      ActionController(name: '_WishListStore', context: context);

  @override
  void addAllWishListItem(List<WishListResponse> productList) {
    final _$actionInfo = _$_WishListStoreActionController.startAction(
        name: '_WishListStore.addAllWishListItem');
    try {
      return super.addAllWishListItem(productList);
    } finally {
      _$_WishListStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
wishList: ${wishList}
    ''';
  }
}
