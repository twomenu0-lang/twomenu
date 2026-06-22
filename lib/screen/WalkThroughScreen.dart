import 'package:flutter/material.dart';
import '/../AppLocalizations.dart'; // ✅ إضافة الـ import الخاص بالترجمة
import '/../main.dart';
import '/../screen/DashBoardScreen.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';

class WalkThroughScreen extends StatefulWidget {
  static String tag = '/WalkThroughScreen';

  @override
  WalkThroughScreenState createState() => WalkThroughScreenState();
}

class WalkThroughScreenState extends State<WalkThroughScreen> {
  var selectedIndex = 0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تم نقل الـ pages هنا مباشرة لتجنب استدعاء setState لانهائي داخل الـ build وتحسين الأداء
    List<Widget> pages = [
      Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(walk_Img1, height: context.height() * 0.4, fit: BoxFit.contain).paddingAll(24),
            20.height,
            Text('أكتر من منيو.. في مكان واحد', style: boldTextStyle(size: 24)).paddingOnly(top: 16, left: 16),
            Text('ليه تشتت نفسك بين كل المحلات  في تومنيو  جمعنالك كل اللي بيتك محتاجه في  مكان واحد ومنظم ', textAlign: TextAlign.center, style: secondaryTextStyle(size: 16)).paddingOnly(right: 24, left: 16, top: 8)
          ],
        ),
      ),
      Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(walk_Img2, height: context.height() * 0.4, fit: BoxFit.contain).paddingAll(24),
            20.height,
            Text('فرحة الافتتاح.. هدايا مابتخلصش', style: boldTextStyle(size: 24)).paddingOnly(top: 16, left: 16),
            Text('احنا مش بس بنفتح مكان احنا بنوزع فرحة. سجل دلوقتي وخليك مستعد لجوائز الافتتاح ', textAlign: TextAlign.center, style: secondaryTextStyle(size: 16)).paddingOnly(right: 24, left: 16, top: 8)
          ],
        ),
      ),
      Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(walk_Img3, height: context.height() * 0.4, fit: BoxFit.contain).paddingAll(24),
            20.height,
            Text('لفينا بدالك.. ونقينا لك الأحسن', style: boldTextStyle(size: 24)).paddingOnly(top: 16, left: 16),
            Text('تومنيو في أمانة بنختار لك كل صنف في المنيو نقاوة كأننا بنشتريه لبيوتنا ', textAlign: TextAlign.center, style: secondaryTextStyle(size: 16)).paddingOnly(right: 24, left: 16, top: 8)
          ],
        ),
      )
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          child: Stack(
            children: [
              PageView(
                  children: pages,
                  controller: _pageController,
                  onPageChanged: (index) {
                    selectedIndex = index;
                    setState(() {});
                  }),
              AnimatedPositioned(duration: Duration(seconds: 1), bottom: 70, left: 0, right: 0, child: DotIndicator(pages: pages, indicatorColor: primaryColor, pageController: _pageController)),
              Positioned(
                  child: AnimatedCrossFade(
                      firstChild:
                      Container(
                        // ✅ تعديل نص زر ابدأ الآن ليدعم الترجمة الديناميكية بناءً على لغة التطبيق
                          child: Text(AppLocalizations.of(context)!.translate('lbl_get_started') ?? 'Get Started', style: boldTextStyle(color: white)),
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: BoxDecoration(color: primaryColor, borderRadius: radius(8))
                      ).onTap(() {
                        DashBoardScreen().launch(context, isNewTask: true);
                      }),
                      secondChild: SizedBox(),
                      duration: Duration(milliseconds: 300),
                      firstCurve: Curves.easeIn,
                      secondCurve: Curves.easeOut,
                      crossFadeState: selectedIndex == (pages.length - 1) ? CrossFadeState.showFirst : CrossFadeState.showSecond),
                  bottom: 20,
                  right: 20),
              Positioned(
                  child: AnimatedContainer(
                      duration: Duration(seconds: 1),
                      // ✅ تعديل نص زر تخطي ليدعم الترجمة الديناميكية بناءً على لغة التطبيق
                      child: Text(AppLocalizations.of(context)!.translate('lbl_skip') ?? 'Skip', style: boldTextStyle(color: primaryColor)),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8)
                  ).onTap(() {
                    DashBoardScreen().launch(context, isNewTask: true);
                  }),
                  right: 8,
                  top: 8)
            ],
          ),
        ),
      ),
    );
  }
}