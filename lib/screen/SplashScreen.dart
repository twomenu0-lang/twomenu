import 'package:flutter/material.dart';
import '/../main.dart';
import '/../screen/DashBoardScreen.dart';
import '/../screen/ProductDetail/ProductDetailScreen1.dart';
import '/../utils/Colors.dart';
import '/../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';

import 'WalkThroughScreen.dart';

class SplashScreen extends StatefulWidget {
  static String tag = '/SplashScreen';

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    // ✅ إعداد Status Bar — سريع جداً (sync تقريباً)
    setStatusBarColor(
      isHalloween ? mChristmasColor : primaryColor!,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    // ─────────────────────────────────────────────────────────────
    // ❌ أُزيل: await Future.delayed(Duration(seconds: 2))
    // كان يضيف ثانيتين إجباريتين حتى لو التطبيق جاهز في 300ms
    //
    // ✅ بدّل بـ: 300ms فقط — كافية لظهور اللوجو بشكل لائق
    // لو حابب تحذفها تماماً، احذف السطر التالي
    // ─────────────────────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 300));

    // ✅ getProductIdFromNative في الخلفية — مش بيحجب الـ UI
    // لو استغرقت وقتاً طويلاً، الـ splash هتظهر وتنتظر بدل ما تكون شاشة سوداء
    final String productId = await getProductIdFromNative();

    if (!mounted) return; // تأكد إن الـ widget لسه موجود

    if (productId.isNotEmpty) {
      ProductDetailScreen1(mProId: productId.toInt()).launch(context);
    } else {
      checkFirstSeen();
    }
  }

  Future checkFirstSeen() async {
    bool seen = getBoolAsync('seen');
    if (seen) {
      DashBoardScreen().launch(context, isNewTask: true);
    } else {
      await setValue('seen', true);
      WalkThroughScreen().launch(context, isNewTask: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            app_logo,
            width: width * 0.70,
            height: 220,
            fit: BoxFit.contain,
          ),
        ],
      ).center(),
    );
  }
}