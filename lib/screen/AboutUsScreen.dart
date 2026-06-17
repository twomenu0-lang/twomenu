import 'package:flutter/material.dart';
import '/../main.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../AppLocalizations.dart';
import '../utils/AppBarWidget.dart';

class AboutUsScreen extends StatefulWidget {
  static String tag = '/AboutUsScreen';

  @override
  AboutUsScreenState createState() => AboutUsScreenState();
}

class AboutUsScreenState extends State<AboutUsScreen> {
  PackageInfo? package;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    package = await PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: mTop(context, appLocalization.translate('lbl_about'), showBack: true) as PreferredSizeWidget?,
      body: BodyCornerWidget(
        child: Container(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              children: [
                16.height,
                Container(width: 120, height: 120, padding: EdgeInsets.all(8), decoration: boxDecorationRoundedWithShadow(10), child: Image.asset(app_logo)),
                16.height,
                FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (_, snap) {
                      if (snap.hasData) {
                        return Column(
                          children: [
                            Text('${snap.data!.appName.validate()}', style: boldTextStyle(color: primaryColor, size: 20)),
                            8.height,
                            Text('V ${snap.data!.version.validate()}', style: boldTextStyle(color: primaryColor, size: 20)),
                          ],
                        );
                      }
                      return SizedBox();
                    }),
                8.height
              ],
            ).center(),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 150, // تم تقليل الارتفاع لأننا حذفنا الإعلان
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: context.width(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(appLocalization.translate('llb_follow_us')!, style: boldTextStyle()).visible(getStringAsync(WHATSAPP).isNotEmpty),
                  16.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // ... (بقية أيقونات التواصل الاجتماعي تظل كما هي)
                    ],
                  ),
                ],
              ),
            ),
            FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (_, snap) {
                  if (snap.hasData) return Text('V ${snap.data!.version.validate()}', style: secondaryTextStyle());
                  return SizedBox();
                }),
            2.height,
            Text(getStringAsync(COPYRIGHT_TEXT), style: secondaryTextStyle()).visible(getStringAsync(COPYRIGHT_TEXT).isNotEmpty),
            16.height,
            // تم حذف AdWidget من هنا
          ],
        ),
      ),
    );
  }
}
