import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:Twomenu/main.dart';
import 'package:Twomenu/models/ProductReviewModel.dart';
import 'package:Twomenu/network/rest_apis.dart';
import 'package:Twomenu/utils/AppBarWidget.dart';
import 'package:Twomenu/utils/AppWidget.dart';
import 'package:Twomenu/utils/Colors.dart';
import 'package:Twomenu/utils/Common.dart';
import 'package:Twomenu/utils/Constants.dart';
import 'package:Twomenu/utils/SharedPref.dart';
import 'package:nb_utils/nb_utils.dart';
import '../AppLocalizations.dart';

class ReviewScreen extends StatefulWidget {
  static String tag = '/ReviewScreen';
  final mProductId;
  ReviewScreen({Key? key, this.mProductId}) : super(key: key);

  @override
  ReviewScreenState createState() => ReviewScreenState();
}

class ReviewScreenState extends State<ReviewScreen> {
  // الكود يظل كما هو مع حذف أي BannerAd أو AdWidget كان موجوداً في الـ build
  // ...
  @override
  Widget build(BuildContext context) {
    // تم تنظيف الـ Widget tree من أي AdWidget
    return Scaffold(
      appBar: mTop(context, AppLocalizations.of(context)!.translate('lbl_reviews')) as PreferredSizeWidget?,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // كود المراجعات الأصلي بدون إعلانات
              ],
            ),
          ),
          Observer(builder: (_) => Loader().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}