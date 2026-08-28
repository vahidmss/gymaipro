import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ArticleContent extends StatelessWidget {
  const ArticleContent({
    required this.contentHtml,
    this.stripDuplicateTitle,
    super.key,
  });

  final String contentHtml;

  /// اگر اولین h1/h2 تقریباً همان عنوان صفحه باشد، حذف می‌شود تا تکرار نشود.
  final String? stripDuplicateTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final html = _prepareHtml(contentHtml, stripDuplicateTitle);

    return Html(
      data: html,
      style: {
        'body': Style(
          color: textColor,
          fontSize: FontSize(15.5),
          lineHeight: const LineHeight(1.65),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontFamily: AppTheme.fontFamily,
        ),
        'p': Style(
          margin: Margins.only(top: 0, bottom: 10),
          padding: HtmlPaddings.zero,
        ),
        'ul': Style(
          margin: Margins.only(top: 4, bottom: 10),
          padding: HtmlPaddings.only(right: 14),
        ),
        'ol': Style(
          margin: Margins.only(top: 4, bottom: 10),
          padding: HtmlPaddings.only(right: 14),
        ),
        'li': Style(margin: Margins.only(bottom: 4)),
        'h1': Style(margin: Margins.only(top: 8, bottom: 8)),
        'h2': Style(margin: Margins.only(top: 8, bottom: 8)),
        'h3': Style(margin: Margins.only(top: 8, bottom: 8)),
        'h4': Style(
          color: textColor,
          fontWeight: FontWeight.w700,
          margin: Margins.only(top: 8, bottom: 6),
          padding: HtmlPaddings.zero,
          fontFamily: AppTheme.fontFamily,
        ),
        'h5': Style(
          color: textColor,
          fontWeight: FontWeight.w600,
          margin: Margins.only(top: 6, bottom: 4),
          padding: HtmlPaddings.zero,
          fontFamily: AppTheme.fontFamily,
        ),
        'h6': Style(
          color: textColor,
          fontWeight: FontWeight.w600,
          margin: Margins.only(top: 6, bottom: 4),
          padding: HtmlPaddings.zero,
          fontFamily: AppTheme.fontFamily,
        ),
        'hr': Style(margin: Margins.symmetric(vertical: 12)),
      },
      extensions: [
        TagExtension(
          tagsToExtend: const {'h1', 'h2', 'h3'},
          builder: (ctx) {
            final el = ctx.element;
            final text = el?.text.trim() ?? '';
            final level = el?.localName;
            double fontSize = 18;
            FontWeight weight = FontWeight.w800;
            if (level == 'h2') {
              fontSize = 16.5;
              weight = FontWeight.w700;
            }
            if (level == 'h3') {
              fontSize = 15;
              weight = FontWeight.w700;
            }
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 6.h, top: 4.h),
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.1)
                    : AppTheme.goldColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border(
                  right: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.85),
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: textColor,
                  fontWeight: weight,
                  fontSize: fontSize,
                  height: 1.4,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static String _prepareHtml(String raw, String? title) {
    if (title == null || title.trim().isEmpty) return raw;
    final normalizedTitle = _normalize(title);
    // اولین h1/h2 که متنش نزدیک عنوان صفحه است را حذف کن
    final headingRe = RegExp(
      r'<(h[12])[^>]*>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = headingRe.firstMatch(raw);
    if (match == null) return raw;
    final headingText = _normalize(
      match.group(2)!.replaceAll(RegExp('<[^>]*>'), ''),
    );
    if (headingText.isEmpty) return raw;
    final similar =
        headingText == normalizedTitle ||
        headingText.contains(normalizedTitle) ||
        normalizedTitle.contains(headingText);
    if (!similar) return raw;
    return raw.replaceFirst(match.group(0)!, '');
  }

  static String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[\u200c\u200f\u202a-\u202e]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp('[🏆📲✅⭐️⭐]+'), '')
        .trim()
        .toLowerCase();
  }
}
