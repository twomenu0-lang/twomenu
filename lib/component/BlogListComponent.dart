import 'package:flutter/material.dart';
import '/../models/BlogListResponse.dart';
import '/../screen/BlogDescriptionScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Common.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';

class BlogListComponent extends StatefulWidget {
  static String tag = '/BlogListComponent';
  final List<Blog> mBlogList;

  BlogListComponent(this.mBlogList);

  @override
  BlogListComponentState createState() => BlogListComponentState();
}

class BlogListComponentState extends State<BlogListComponent> {
  static const Color _brandBlue = Color(0xFF343892);

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ── استخراج أول صورة من HTML ──────────────────────────────
  String? _extractFirstImage(String? content) {
    if (content == null || content.isEmpty) return null;

    final matchDouble = RegExp(
      r'<img[^>]+src="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(content);
    if (matchDouble != null) return matchDouble.group(1);

    final matchSingle = RegExp(
      "<img[^>]+src='([^']+)'",
      caseSensitive: false,
    ).firstMatch(content);
    if (matchSingle != null) return matchSingle.group(1);

    return null;
  }

  // ── تنسيق التاريخ ─────────────────────────────────────────
  String _formatDate(Blog blog) {
    if (blog.readableDate != null && blog.readableDate!.isNotEmpty) {
      return blog.readableDate!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // عرض الصورة = ~38% من عرض الشاشة، الارتفاع يتبع نسبة 1920×800 ≈ 2.4:1
    final imgWidth  = screenWidth * 0.38;
    final imgHeight = imgWidth / 2.4;

    List<Blog> mBlogList = widget.mBlogList;
    return AnimatedListView(
      scrollDirection: Axis.vertical,
      itemCount: mBlogList.length,
      padding: EdgeInsets.symmetric(horizontal: 16),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final blog = mBlogList[index];

        final String? imageUrl =
        (blog.image != null && blog.image!.isNotEmpty)
            ? blog.image
            : _extractFirstImage(blog.postContent);

        return GestureDetector(
          onTap: () {
            BlogDescriptionScreen(mId: blog.iD).launch(context);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── الصورة بنسبة أبعاد الصورة الأصلية 1920×800 ──
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: imgWidth,
                    height: imgHeight,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? commonCacheImageWidget(
                      imageUrl,
                      width: imgWidth,
                      height: imgHeight,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      ic_placeholder_logo,
                      width: imgWidth,
                      height: imgHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                12.width,

                // ── النصوص ──────────────────────────────────
                Expanded(
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // العنوان
                        Text(
                          parseHtmlString(blog.postTitle.validate().trim()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _brandBlue,
                            fontFamily: 'Cairo',
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                        ),
                        8.height,

                        // المقتطف
                        Text(
                          parseHtmlString(
                              blog.postExcerpt != null &&
                                  blog.postExcerpt!.isNotEmpty
                                  ? blog.postExcerpt!
                                  : blog.postContent.validate()),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C6F8A),
                            fontFamily: 'Cairo',
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        8.height,

                        // التاريخ
                        if (_formatDate(blog).isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 12, color: Color(0xFF6C6F8A)),
                              4.width,
                              Text(
                                _formatDate(blog),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6C6F8A),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}