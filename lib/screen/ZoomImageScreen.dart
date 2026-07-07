import 'package:flutter/material.dart';
import '/../main.dart';
import '/../models/ProductDetailResponse.dart';
import '/../utils/AppWidget.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:photo_view/photo_view.dart';

import '../utils/AppBarWidget.dart';

class ZoomImageScreen extends StatefulWidget {
  final mProductImage;
  final List<ImageModel>? mImgList;
  final int? ind;

  const ZoomImageScreen({super.key, this.mProductImage, this.mImgList, this.ind});

  @override
  _ZoomImageScreenState createState() => _ZoomImageScreenState();
}

class _ZoomImageScreenState extends State<ZoomImageScreen> {
  List<Widget> productImg = [];
  PageController? pageController;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() {
    log("value+${widget.ind!}");
    pageController = PageController(initialPage: widget.ind!);
    setState(() {});
  }

  Future productDetail() async {
    for (var element in widget.mImgList!) {
      productImg.add(commonCacheImageWidget(element.src.toString(), fit: BoxFit.cover, height: 400, width: double.infinity));
    }
  }

  @override
  void dispose() {
    setStatusBarColor(primaryColor!, statusBarBrightness: Brightness.light);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mTop(context, "", showBack: true) as PreferredSizeWidget?,
      body: BodyCornerWidget(
        child: PageView.builder(
            itemCount: widget.mImgList!.length,
            controller: pageController,
            itemBuilder: (context, i) {
              return PhotoView(imageProvider: NetworkImage(widget.mImgList![i].src!));
            }),
      ),
    );
  }
}

