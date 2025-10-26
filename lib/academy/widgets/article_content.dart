import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ArticleContent extends StatelessWidget {
  const ArticleContent({required this.contentHtml, super.key});

  final String contentHtml;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white10),
      ),
      padding: EdgeInsets.all(12.w),
      child: Html(
        data: contentHtml,
        style: {
          'body': Style(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.4),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
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
            color: Colors.white,
            fontWeight: FontWeight.w700,
            margin: Margins.only(top: 2.h, bottom: 2),
            padding: HtmlPaddings.zero,
          ),
          'h5': Style(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            margin: Margins.only(top: 2.h, bottom: 2),
            padding: HtmlPaddings.zero,
          ),
          'h6': Style(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            margin: Margins.only(top: 2.h, bottom: 2),
            padding: HtmlPaddings.zero,
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
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border(
                    right: BorderSide(color: AppTheme.goldColor, width: bar),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontWeight: weight,
                    letterSpacing: 0.2,
                    fontSize: fontSize,
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
