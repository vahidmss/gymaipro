import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ArticleContent extends StatelessWidget {
  const ArticleContent({required this.contentHtml, super.key});

  final String contentHtml;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: EdgeInsets.zero,
      child: Html(
        data: contentHtml,
        style: {
          'body': Style(
            color: textColor,
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontFamily: AppTheme.fontFamily,
          ),
          'p': Style(
            margin: Margins.only(top: 0.h, bottom: 2),
            padding: HtmlPaddings.zero,
          ),
          'ul': Style(
            margin: Margins.only(top: 2.h, bottom: 4),
            padding: HtmlPaddings.only(right: 12),
          ),
          'ol': Style(
            margin: Margins.only(top: 2.h, bottom: 4),
            padding: HtmlPaddings.only(right: 12),
          ),
          'li': Style(margin: Margins.only(bottom: 1)),
          'h1': Style(margin: Margins.only(top: 2.h, bottom: 2)),
          'h2': Style(margin: Margins.only(top: 2.h, bottom: 2)),
          'h3': Style(margin: Margins.only(top: 2.h, bottom: 2)),
          'h4': Style(
            color: textColor,
            fontWeight: FontWeight.w700,
            margin: Margins.only(top: 2.h, bottom: 2),
            padding: HtmlPaddings.zero,
            fontFamily: AppTheme.fontFamily,
          ),
          'h5': Style(
            color: textColor,
            fontWeight: FontWeight.w600,
            margin: Margins.only(top: 2.h, bottom: 2),
            padding: HtmlPaddings.zero,
            fontFamily: AppTheme.fontFamily,
          ),
          'h6': Style(
            color: textColor,
            fontWeight: FontWeight.w600,
            margin: Margins.only(top: 2.h, bottom: 2),
            padding: HtmlPaddings.zero,
            fontFamily: AppTheme.fontFamily,
          ),
          'hr': Style(margin: Margins.only(top: 6.h, bottom: 6)),
        },
        extensions: [
          TagExtension(
            tagsToExtend: const {'h1', 'h2', 'h3'},
            builder: (ctx) {
              final el = ctx.element;
              final text = el?.text.trim() ?? '';
              final level = el?.localName;
              double bar = 3;
              double fontSize = 20;
              FontWeight weight = FontWeight.w800;
              if (level == 'h2') {
                bar = 2.5;
                fontSize = 18;
                weight = FontWeight.w700;
              }
              if (level == 'h3') {
                bar = 2;
                fontSize = 16;
                weight = FontWeight.w700;
              }
              return Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.15)
                      : AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border(
                    right: BorderSide(color: AppTheme.goldColor, width: bar),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: weight,
                    letterSpacing: 0.2,
                    fontSize: fontSize,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
