import 'dart:convert';

import 'package:Twomenu/main.dart';

import '/../models/WishListResponse.dart';
import '/../network/rest_apis.dart';
import '/../utils/Constants.dart';
import '/../utils/SharedPref.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '/../AppLocalizations.dart'; // ✅ الخطوة 1: إضافة الـ import الجديد هنا

part 'WishListStore.g.dart';

class WishListStore = _WishListStore with _$WishListStore;

// ✅ الخطوة 1 المكملة: إضافة الـ helper function للترجمة ديناميكياً عبر الـ navigatorKey
String _tr(String key, String fallback) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return fallback;
  return AppLocalizations.of(ctx)?.translate(key) ?? fallback;
}

abstract class _WishListStore with Store {
  @observable
  List<WishListResponse> wishList = ObservableList<WishListResponse>();

  // ✅ الخطوة 2: استبدال الدالة بالكامل لتدعم الترجمة للمسجلين والزوار وتتجاهل رسائل السيرفر الثابتة
  @action
  Future<void> addToWishList(WishListResponse data) async {
    if (wishList.any((element) => element.proId == data.proId)) {
      if (!await isGuestUser() && await isLoggedIn()) {
        wishList.remove(data);

        await removeWishList({'pro_id': data.proId}).then((value) {
          getWishlistItem();
          toast(_tr('lbl_product_deleted_from_wishlist', 'Product Deleted From Wishlist'));
        }).catchError((e) {
          log(e.toString());
        });
      } else {
        wishList.removeWhere((element) => element.proId == data.proId);
        toast(_tr('lbl_product_deleted_from_wishlist', 'Product Deleted From Wishlist'));
      }
    } else {
      if (!await isGuestUser() && await isLoggedIn()) {
        wishList.add(data);
        var request = {'pro_id': data.proId};
        await addWishList(request).then((value) {
          getWishlistItem();
          toast(_tr('lbl_product_added_to_wishlist', 'Product Successfully Added To Wishlist'));
        }).catchError((e) {
          log(e.toString());
        });
      } else {
        wishList.add(data);
        toast(_tr('lbl_product_added_to_wishlist', 'Product Successfully Added To Wishlist'));
      }
    }
    storeWishlistData();
  }

  bool isItemInWishlist(int id) {
    return wishList.any((element) => element.proId == id);
  }

  @action
  Future<void> storeWishlistData() async {
    if (wishList.isNotEmpty) {
      await setValue(WISHLIST_ITEM_LIST, jsonEncode(wishList));
      log(getStringAsync(WISHLIST_ITEM_LIST));
    } else {
      await setValue(WISHLIST_ITEM_LIST, '');
    }
  }

  @action
  void addAllWishListItem(List<WishListResponse> productList) {
    wishList.addAll(productList);
  }

  @action
  Future<void> getWishlistItem() async {
    appStore.setLoading(true);
    getWishList().then((value) {
      wishList = ObservableList.of(value);
      appStore.setLoading(false);
    }).catchError((e) {
      log("Error" + e.toString());
    });
  }

  @action
  Future<void> clearWishlist() async {
    wishList.clear();
    storeWishlistData();
  }
}