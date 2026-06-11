import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '/../models/BlogResponse.dart';
import '/../network/rest_apis.dart';
import '/../screen/WebViewExternalProductScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../utils/AppBarWidget.dart';

class BlogDescriptionScreen extends StatefulWidget {
  static String tag = '/BlogDescriptionScreen';
  final int? mId;

  BlogDescriptionScreen({Key? key, this.mId}) : super(key: key);

  @override
  BlogDescriptionScreenState createState() => BlogDescriptionScreenState();
}

class BlogDescriptionScreenState extends State<BlogDescriptionScreen> {
  BlogResponse? post;

  static const Color _brandBlue   = Color(0xFF343892);
  static const Color _brandBlueBg = Color(0xFFF4F5FC);
  static const Color _textPrimary = Color(0xFF1E1E2A);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _pageBg      = Color(0xFFF9FAFC);

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    afterBuildCreated(() {
      fetchBlogDetail();
    });
  }

  Future fetchBlogDetail() async {
    appStore.setLoading(true);
    await getBlogDetail(widget.mId).then((res) {
      if (!mounted) return;
      appStore.setLoading(false);
      post = BlogResponse.fromJson(res);
      setState(() {});
    }).catchError((error) {
      if (!mounted) return;
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ── فتح رابط بذكاء: متاجر التطبيقات تُفتح مباشرة، غيرها WebView ──
  Future<void> _openUrl(String url, {String title = ""}) async {
    if (url.isEmpty) return;

    final isAppStore = url.contains('play.google.com') ||
        url.contains('apps.apple.com') ||
        url.contains('itunes.apple.com') ||
        url.startsWith('intent://') ||
        url.startsWith('market://');

    if (isAppStore) {
      // روابط المتاجر: نفتحها بالـ url_launcher مباشرة
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // باقي الروابط: WebView داخل التطبيق
      WebViewExternalProductScreen(
        mExternal_URL: url,
        title: title,
      ).launch(context);
    }
  }

  // ── التحقق من رابط CTA ──────────────────────────────────────
  bool _isCTALink(String text, String href) {
    if (href.isEmpty || text.isEmpty) return false;
    final trimmed = text.trim();
    return trimmed.startsWith('🚀') ||
        trimmed.startsWith('🛒') ||
        trimmed.startsWith('🌿') ||
        trimmed.startsWith('💊') ||
        trimmed.startsWith('📲');
  }

  // ── تنظيف المحتوى من العناصر غير المرغوبة ─────────────────
  String _cleanContent(String raw) {
    String cleaned = raw;

    cleaned = cleaned.replaceAll(
      RegExp(
        r'<div[^>]*class="[^"]*hero-section[^"]*"[^>]*>.*?</div>',
        dotAll: true,
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<div[^>]*class="[^"]*article-layout[^"]*"[^>]*>',
          caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<div[^>]*class="[^"]*main-content[^"]*"[^>]*>',
          caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<div[^>]*class="[^"]*post-content[^"]*"[^>]*>',
          caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<div[^>]*class="[^"]*twomenu-article[^"]*"[^>]*>',
          caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<aside[^>]*>.*?</aside>',
          dotAll: true, caseSensitive: false),
      '',
    );

    final classPatterns = [
      'table-of-contents',
      'related-posts',
      'related-grid',
      'sidebar',
      'toc-container',
      'meta-data',
      'featured-image',
      'hero-section',
    ];
    for (final cls in classPatterns) {
      cleaned = cleaned.replaceAll(
        RegExp(
          '<div[^>]*class="[^"]*$cls[^"]*"[^>]*>.*?</div>',
          dotAll: true,
          caseSensitive: false,
        ),
        '',
      );
    }

    cleaned = cleaned.replaceAll(
      RegExp(r'<h1[^>]*>.*?</h1>', dotAll: true, caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        r'<[^>]+>\s*(📑|📰|فهرس المحتويات|مقالات ذات صلة)[^<]*</[^>]+>',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>',
          dotAll: true, caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>',
          dotAll: true, caseSensitive: false),
      '',
    );

    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: mTop(
        context,
        post != null ? post!.postTitle.validate() : "",
        showBack: true,
        actions: [
          post != null
              ? IconButton(
              icon: Icon(Icons.share_rounded, color: white),
              onPressed: () {
                _openUrl(
                  post!.shareUrl ?? '',
                  title: post!.postTitle.validate(),
                );
              })
              : SizedBox()
        ],
      ) as PreferredSizeWidget?,
      body: Observer(
        builder: (context) => BodyCornerWidget(
          child: Stack(
            children: [
              post != null
                  ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    16.height,

                    // ── العنوان ──────────────────────────────
                    Text(
                      post!.postTitle.validate(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        height: 1.4,
                        fontFamily: 'Cairo',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    20.height,

                    // ── بطاقة المحتوى ────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(20),
                      child: Html(
                        data: _cleanContent(
                            post!.postContent.validate()),
                        style: {
                          "body": Style(
                            fontSize: FontSize(15.5),
                            lineHeight: LineHeight(1.75),
                            color: _textPrimary,
                            fontFamily: 'Cairo',
                            textAlign: TextAlign.right,
                            direction: TextDirection.rtl,
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          "h2": Style(
                            fontSize: FontSize(20),
                            fontWeight: FontWeight.bold,
                            color: _brandBlue,
                            margin: Margins.only(top: 28, bottom: 10),
                            lineHeight: LineHeight(1.4),
                            border: Border(
                              right: BorderSide(
                                  color: _brandBlue, width: 4),
                            ),
                            padding: HtmlPaddings.only(right: 12),
                          ),
                          "h3": Style(
                            fontSize: FontSize(17),
                            fontWeight: FontWeight.bold,
                            color: _brandBlue,
                            margin: Margins.only(top: 20, bottom: 6),
                            lineHeight: LineHeight(1.4),
                          ),
                          "h1": Style(
                            fontSize: FontSize(22),
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            margin: Margins.only(top: 24, bottom: 10),
                            lineHeight: LineHeight(1.4),
                          ),
                          "p": Style(
                            margin: Margins.only(bottom: 16),
                            lineHeight: LineHeight(1.75),
                            fontSize: FontSize(15.5),
                          ),
                          "strong": Style(
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                          "b": Style(
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                          "blockquote": Style(
                            margin: Margins.symmetric(vertical: 20),
                            padding: HtmlPaddings.only(
                              right: 18,
                              left: 12,
                              top: 14,
                              bottom: 14,
                            ),
                            backgroundColor: _brandBlueBg,
                            border: Border(
                              right: BorderSide(
                                  color: _brandBlue, width: 4),
                            ),
                            fontStyle: FontStyle.italic,
                            fontSize: FontSize(15),
                            color: _textPrimary,
                            lineHeight: LineHeight(1.8),
                          ),
                          "ol": Style(
                            margin: Margins.only(
                                bottom: 16, right: 0, top: 8),
                            padding: HtmlPaddings.only(right: 4),
                          ),
                          "ul": Style(
                            margin: Margins.only(
                                bottom: 16, right: 4, top: 4),
                            padding: HtmlPaddings.only(right: 20),
                          ),
                          "ol li": Style(
                            margin: Margins.only(bottom: 4, top: 4),
                            lineHeight: LineHeight(1.6),
                            fontSize: FontSize(15),
                          ),
                          "li": Style(
                            margin: Margins.only(bottom: 8),
                            lineHeight: LineHeight(1.7),
                            fontSize: FontSize(15),
                          ),
                          "a": Style(
                            color: _brandBlue,
                            textDecoration: TextDecoration.underline,
                          ),
                          "hr": Style(
                            margin: Margins.symmetric(vertical: 20),
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE9ECF5),
                                width: 1,
                              ),
                            ),
                          ),
                          "aside": Style(display: Display.none),
                          "nav": Style(display: Display.none),
                        },
                        extensions: [
                          // ── صور ──────────────────────────────
                          TagExtension(
                            tagsToExtend: {"img"},
                            builder: (extensionContext) {
                              final src =
                                  extensionContext.attributes['src'] ??
                                      '';
                              if (src.isEmpty) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                  child: Image.network(
                                    src,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child,
                                        loadingProgress) {
                                      if (loadingProgress == null)
                                        return child;
                                      return Container(
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: _brandBlueBg,
                                          borderRadius:
                                          BorderRadius.circular(16),
                                        ),
                                        child: Center(
                                          child:
                                          CircularProgressIndicator(
                                              color: _brandBlue),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) =>
                                    const SizedBox(),
                                  ),
                                ),
                              );
                            },
                          ),

                          // ── روابط CTA ─────────────────────────
                          TagExtension(
                            tagsToExtend: {"a"},
                            builder: (extensionContext) {
                              final cls =
                                  extensionContext.attributes['class'] ??
                                      '';
                              final href =
                                  extensionContext.attributes['href'] ??
                                      '';
                              final text =
                                  extensionContext.element?.text.trim() ??
                                      '';

                              final isCTAClass =
                              cls.contains('cta-block');
                              final isCTAEmoji = _isCTALink(text, href);

                              if (!isCTAClass && !isCTAEmoji) {
                                return const SizedBox.shrink();
                              }
                              if (href.isEmpty || text.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                child: GestureDetector(
                                  onTap: () => _openUrl(href),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _brandBlue,
                                      borderRadius:
                                      BorderRadius.circular(60),
                                    ),
                                    child: Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],

                        // ── onLinkTap: كل الروابط العادية ────────
                        onLinkTap: (url, attributes, element) {
                          if (url != null) {
                            _openUrl(url);
                          }
                        },
                      ),
                    ),
                    32.height,
                  ],
                ).paddingOnly(left: 16, right: 16, bottom: 16),
              ).visible(!appStore.isLoading)
                  : SizedBox(),
              mProgress().center().visible(appStore.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}