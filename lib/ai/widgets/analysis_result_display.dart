import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/widgets/ai_hub_ui.dart';
import 'package:gymaipro/ai/widgets/progress_analysis_ui.dart';
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
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark
            ? context.backgroundColor.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: kProgressAccent.withValues(alpha: 0.14),
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

      if (trimmed.startsWith('##') ||
          (trimmed.startsWith('**') &&
              trimmed.endsWith('**') &&
              trimmed.length < 100)) {
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
      } else if (trimmed.startsWith('-') ||
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
      } else if (RegExp(r'^\d+[\.\)]\s').hasMatch(trimmed)) {
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
      } else {
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

    if (currentSection != null) {
      if (currentItems.isNotEmpty) {
        currentSection = currentSection.copyWith(items: currentItems);
      }
      sections.add(currentSection);
    }

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
    final style = _headingStyle(title);

    return Padding(
      padding: EdgeInsets.only(top: 14.h, bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AiHubIconBadge(
            icon: style.icon,
            gradientColors: aiHubAccentGradient(style.color),
            size: 34.w,
            iconSize: 16.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _HeadingStyle _headingStyle(String title) {
    if (title.contains('قوت') || title.contains('موفقیت')) {
      return _HeadingStyle(LucideIcons.trendingUp, AppTheme.proteinColor);
    }
    if (title.contains('بهبود') || title.contains('ضعف')) {
      return _HeadingStyle(LucideIcons.target, AppTheme.fatColor);
    }
    if (title.contains('راهکار') || title.contains('پیشنهاد')) {
      return _HeadingStyle(LucideIcons.lightbulb, AppTheme.carbsColor);
    }
    if (title.contains('انگیزه') || title.contains('تشویق')) {
      return _HeadingStyle(LucideIcons.heart, Colors.pink.shade400);
    }
    return _HeadingStyle(LucideIcons.sparkles, kProgressAccent);
  }

  Widget _buildList(
    BuildContext context,
    List<String> items,
    bool isDark, {
    required bool isBullet,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, right: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 8.w, top: 5.h),
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    color: kProgressAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isBullet ? '•' : '${index + 1}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: isBullet ? 12.sp : 10.sp,
                      fontWeight: FontWeight.w800,
                      color: kProgressAccent,
                      height: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    text: _buildRichText(context, item, isDark),
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
        final isImportant =
            para.contains('!') ||
            para.contains('مهم') ||
            para.contains('توجه') ||
            para.contains('نکته') ||
            para.contains('⚠️') ||
            para.contains('💡') ||
            para.contains('توصیه');

        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              if (isImportant)
                Padding(
                  padding: EdgeInsets.only(left: 8.w, top: 2.h),
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
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*|\d+[\.\)]?\s|\d+%|✅|✓|⚠️|💪|📊|⚖️|📈|📏|💡|🎯|🔥|⭐)',
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        if (beforeText.isNotEmpty) {
          spans.add(_plainSpan(context, beforeText));
        }
      }

      final matched = match.group(0) ?? '';

      if (matched.startsWith('**') && matched.endsWith('**')) {
        final boldText = matched.substring(2, matched.length - 2);
        spans.add(
          TextSpan(
            text: boldText,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: kProgressAccent,
              height: 1.55,
            ),
          ),
        );
      } else if (RegExp(r'^\d+').hasMatch(matched)) {
        spans.add(
          TextSpan(
            text: matched,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: kProgressAccent,
              height: 1.55,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: matched,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.5.sp,
              height: 1.55,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(_plainSpan(context, text.substring(lastIndex)));
    }

    if (spans.isEmpty) {
      return _plainSpan(context, text);
    }

    return TextSpan(children: spans);
  }

  TextSpan _plainSpan(BuildContext context, String text) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w400,
        color: context.textColor,
        height: 1.55,
      ),
    );
  }
}

class _HeadingStyle {
  const _HeadingStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
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
