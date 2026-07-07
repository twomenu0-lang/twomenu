import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/../screen/DashBoardScreen.dart';
import '/../screen/ProductDetail/ProductDetailScreen1.dart';
import '/../utils/Colors.dart';
import '/../utils/Common.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../utils/Constants.dart';
import 'ChristmasWalkThroughScreen.dart';

class ChristmasSplashScreen extends StatefulWidget {
  static String tag = '/HalloweenSplashScreen';

  const ChristmasSplashScreen({super.key});

  @override
  ChristmasSplashScreenState createState() => ChristmasSplashScreenState();
}

class ChristmasSplashScreenState extends State<ChristmasSplashScreen> {
  @override
  void initState() {
    super.initState();

    init();
  }

  init() async {
    setStatusBarColor(transparentColor, statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark);
    await Future.delayed(const Duration(seconds: 2));

    String productId = await getProductIdFromNative();
    print(productId);

    if (productId.isNotEmpty) {
      ProductDetailScreen1(mProId: productId.toInt()).launch(context);
    } else {
      checkFirstSeen();
    }
  }

  Future checkFirstSeen() async {
    bool seen = (getBoolAsync('seen'));
    if (seen) {
      const DashBoardScreen().launch(context, isNewTask: true);
    } else {
      await setValue('seen', true);
      const ChristmasWalkThroughScreen().launch(context, isNewTask: true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          Positioned(right: 0, child: Image.asset(ic_christmas_bg, fit: BoxFit.cover, height: 400)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Merry Christmas",
                style: boldTextStyle(color: mChristmasColor, size: 44, letterSpacing: 2, fontFamily: GoogleFonts.pacifico().fontFamily),
              ),
              Text(
                AppName,
                style: boldTextStyle(color: mChristmasColor, size: 44, letterSpacing: 2, fontFamily: GoogleFonts.pacifico().fontFamily),
              ),
            ],
          ).center(),
          Positioned(bottom: 10, right: 0, child: Image.asset(ic_christmas_santa, height: 250, fit: BoxFit.cover))
        ],
      ),
    );
  }
}

