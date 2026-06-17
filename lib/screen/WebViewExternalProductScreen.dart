import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/../utils/AppWidget.dart';
import 'package:nb_utils/nb_utils.dart';


import '../utils/AppBarWidget.dart';

// ignore: must_be_immutable
class WebViewExternalProductScreen extends StatefulWidget {
  // ignore: non_constant_identifier_names
  final String? mExternal_URL;
  final String? title;

  // ignore: non_constant_identifier_names
  WebViewExternalProductScreen({Key? key, this.mExternal_URL, this.title}) : super(key: key);

  @override
  _WebViewExternalProductScreenState createState() => _WebViewExternalProductScreenState();
}

class _WebViewExternalProductScreenState extends State<WebViewExternalProductScreen> {

  WebViewController? controller ;
  var mIsError = false;
  @override
  void initState() {
    super.initState();
    log("widget.title${widget.title}");


    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {

            if (mIsError) return;
          },
          onPageFinished: (String url) {
              mIsError = true;

          },
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(widget.mExternal_URL!)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.mExternal_URL!));
  }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: mTopNew(context, widget.title.validate().isNotEmpty ? widget.title.validate() : '', showBack: true) as PreferredSizeWidget?,
        body: BodyCornerWidget(
          child: Builder(
            builder: (context) {
              // var mIsError = false;
              return WebViewWidget(
                controller: controller!
                  // initialUrl: widget.mExternal_URL,
                  // javascriptMode: JavascriptMode.unrestricted,
                  // gestureNavigationEnabled: true,
                  // onPageFinished: (String url) {
                  //   if (mIsError) return;
                  // },
                  // onWebResourceError: (s) {
                  //   mIsError = true;
                  // }
                  );
            },
          ),
        ),
      ),
    );
  }
}

