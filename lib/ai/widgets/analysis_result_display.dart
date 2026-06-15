import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ویجت نمایش زیبای نتیجه تحلیل
class AnalysisResultDisplay extends StatelessWidget {
  const AnalysisResultDisplay({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sections = _parseContent(content);

    return Container(
      constraints: const BoxConstraints(),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? context.backgroundColor.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.15),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: sections
            .map((section) => _buildSection(context, section, isDark))
            .toList(),
      ),
    );
  }

  List<ContentSection> _parseContent(String content) {
    final sections = <ContentSection>[];
    final lines = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    ContentSection? currentSection;
    List<String> currentItems = [];

    for (final line in lines) {
      final trimmed = line.trim();

      // تشخیص عنوان‌ها (## یا خطوطی که با ** شروع و تمام می‌شوند)
      if (trimmed.startsWith('##') ||
          (trimmed.startsWith('**') &&
              trimmed.endsWith('**') &&
              trimmed.length < 100)) {
        // ذخیره بخش قبلی
        if (currentSection != null) {
          if (currentItems.isNotEmpty) {
            currentSection = currentSection.copyWith(items: currentItems);
          }
          sections.add(currentSection);
        }
        currentItems = [];
        final title = trimmed
            .replaceAll('##', '')
            .replaceAll('**', '')
            .replaceAll('#', '')
            .trim();
        currentSection = ContentSection(
          type: SectionType.heading,
          title: title,
          items: [],
        );
      }
      // تشخیص لیست‌ها
      else if (trimmed.startsWith('-') ||
          trimmed.startsWith('•') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('✓') ||
          trimmed.startsWith('✅') ||
          trimmed.startsWith('▪') ||
          trimmed.startsWith('▫')) {
        if (currentSection == null ||
            (currentSection.type != SectionType.list &&
                currentSection.type != SectionType.numberedList)) {
          if (currentSection != null && currentItems.isNotEmpty) {
            currentSection = currentSection.copyWith(items: currentItems);
            sections.add(currentSection);
          }
          currentItems = [];
          currentSection = ContentSection(
            type: SectionType.list,
            items: [],
          );
        }
        final item = trimmed.substring(1).trim();
        if (item.isNotEmpty) {
          currentItems.add(item);
        }
      }
      // تشخیص اعداد در ابتدای خط
      else if (RegExp(r'^\d+[\.\)]\s').hasMatch(trimmed)) {
        if (currentSection == null ||
            currentSection.type != SectionType.numberedList) {
          if (currentSection != null && currentItems.isNotEmpty) {
            currentSection = currentSection.copyWith(items: currentItems);
            sections.add(currentSection);
          }
          currentItems = [];
          currentSection = ContentSection(
            type: SectionType.numberedList,
            items: [],
          );
        }
        final item = trimmed.replaceFirst(RegExp(r'^\d+[\.\)]\s'), '').trim();
        if (item.isNotEmpty) {
          currentItems.add(item);
        }
      }
      // متن عادی
      else {
        if (currentSection == null ||
            currentSection.type == SectionType.heading ||
            currentSection.type == SectionType.list ||
            currentSection.type == SectionType.numberedList) {
          if (currentSection != null) {
            if (currentItems.isNotEmpty) {
              currentSection = currentSection.copyWith(items: currentItems);
            }
            sections.add(currentSection);
          }
          currentItems = [];
          currentSection = ContentSection(
            type: SectionType.paragraph,
            items: [],
          );
        }
        currentItems.add(trimmed);
      }
    }

    // اضافه کردن آخرین بخش
    if (currentSection != null) {
      if (currentItems.isNotEmpty) {
        currentSection = currentSection.copyWith(items: currentItems);
      }
      sections.add(currentSection);
    }

    // اگر هیچ بخشی پیدا نشد، کل متن را به عنوان پاراگراف نمایش بده
    if (sections.isEmpty) {
      sections.add(
        ContentSection(
          type: SectionType.paragraph,
          items: [content],
        ),
      );
    }

    return sections;
  }

  Widget _buildSection(
    BuildContext context,
    ContentSection section,
    bool isDark,
  ) {
    switch (section.type) {
      case SectionType.heading:
        return _buildHeading(context, section.title ?? '', isDark);
      case SectionType.list:
        return _buildList(context, section.items, isDark, isBullet: true);
      case SectionType.numberedList:
        return _buildList(context, section.items, isDark, isBullet: false);
      case SectionType.paragraph:
        return _buildParagraph(context, section.items, isDark);
    }
  }

  Widget _buildHeading(BuildContext context, String title, bool isDark) {
    // تشخیص نوع عنوان بر اساس محتوا
    IconData icon = LucideIcons.sparkles;
    Color iconColor = AppTheme.goldColor;

    if (title.contains('قوت') || title.contains('موفقیت')) {
      icon = LucideIcons.trendingUp;
      iconColor = Colors.green;
    } else if (title.contains('بهبود') || title.contains('ضعف')) {
      icon = LucideIcons.target;
      iconColor = Colors.orange;
    } else if (title.contains('راهکار') || title.contains('پیشنهاد')) {
      icon = LucideIcons.lightbulb;
      iconColor = AppTheme.goldColor;
    } else if (title.contains('انگیزه') || title.contains('تشویق')) {
      icon = LucideIcons.heart;
      iconColor = Colors.pink;
    }

    return Container(
      margin: EdgeInsets.only(top: 20.h, bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          right: BorderSide(color: iconColor, width: 3.w),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: context.textColor,
                height: 1.4.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<String> items,
    bool isDark, {
    required bool isBullet,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 10.w, top: 6.h),
                  width: 5.w,
                  height: 5.w,
                  decoration: const BoxDecoration(
                    color: AppTheme.goldColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    text: _buildRichText(
                      context,
                      isBullet ? item : '${index + 1}. $item',
                      isDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParagraph(
    BuildContext context,
    List<String> paragraphs,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        // بررسی وجود نکات مهم
        final isImportant =
            para.contains('!') ||
            para.contains('مهم') ||
            para.contains('توجه') ||
            para.contains('نکته') ||
            para.contains('⚠️') ||
            para.contains('💡') ||
            para.contains('توصیه');

        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              if (isImportant)
                Padding(
                  padding: EdgeInsets.only(left: 10.w, top: 4.h),
                  child: Icon(
                    LucideIcons.star,
                    color: AppTheme.goldColor,
                    size: 14.sp,
                  ),
                ),
              Expanded(
                child: RichText(
                  textDirection: TextDirection.rtl,
                  text: _buildRichText(context, para, isDark),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  TextSpan _buildRichText(BuildContext context, String text, bool isDark) {
    final spans = <TextSpan>[];

    // Pattern برای تشخیص بخش‌های مختلف متن
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*|\d+[\.\)]?\s|\d+%|✅|✓|⚠️|💪|📊|⚖️|📈|📏|💡|🎯|🔥|⭐)',
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      // اضافه کردن متن قبل از match
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        if (beforeText.isNotEmpty) {
          spans.add(
            TextSpan(
              text: beforeText,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: context.textColor,
                height: 1.7.h,
                letterSpacing: 0.2,
              ),
            ),
          );
        }
      }

      final matched = match.group(0) ?? '';

      // تشخیص متن bold
      if (matched.startsWith('**') && matched.endsWith('**')) {
        final boldText = matched.substring(2, matched.length - 2);
        spans.add(
          TextSpan(
            text: boldText,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.goldColor,
              letterSpacing: 0.1,
              height: 1.7.h,
            ),
          ),
        );
      }
      // تشخیص اعداد و درصد
      else if (RegExp(r'^\d+').hasMatch(matched)) {
        spans.add(
          TextSpan(
            text: matched,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.goldColor,
              letterSpacing: 0.2,
              height: 1.7.h,
            ),
          ),
        );
      }
      // ایموجی‌ها
      else {
        spans.add(
          TextSpan(
            text: matched,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.7.h,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    // اضافه کردن باقی متن
    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex);
      spans.add(
        TextSpan(
          text: remaining,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: context.textColor,
            height: 1.7.h,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    // اگر هیچ match پیدا نشد، کل متن را برگردان
    if (spans.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: context.textColor,
          height: 1.7.h,
          letterSpacing: 0.2,
        ),
      );
    }

    return TextSpan(children: spans);
  }
}

class ContentSection {
  ContentSection({required this.type, required this.items, this.title});

  final SectionType type;
  final String? title;
  final List<String> items;

  ContentSection copyWith({
    SectionType? type,
    String? title,
    List<String>? items,
  }) {
    return ContentSection(
      type: type ?? this.type,
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }
}

enum SectionType { heading, list, numberedList, paragraph }
