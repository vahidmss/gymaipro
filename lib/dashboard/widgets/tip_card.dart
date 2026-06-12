import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// کارت انگیزشی روزانه - نکته فیتنس با طراحی جذاب
class TipCard extends StatefulWidget {
  const TipCard({super.key});

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  late String _currentTip;
  final Random _random = Random();

  static const List<String> _tips = [
    'نذار تشنگی سرعتتو کم کنه - یه لیوان آب قبل از تمرین فراموش نشه.',
    'گرم کردن قبل از تمرین از آسیب دیدگی جلوگیری می‌کنه.',
    'خواب کافی برای ریکاوری عضلات ضروریه.',
    'پروتئین بعد از تمرین برای ساخت عضله مهمه.',
    'کشش بعد از تمرین انعطاف‌پذیری رو افزایش میده.',
    'تنفس صحیح در حین تمرین عملکرد رو بهتر می‌کنه.',
    'آب خوردن در طول تمرین از کم آبی جلوگیری می‌کنه.',
    'تمرین منظم بهتر از تمرین شدید و نامنظمه.',
    'استراحت بین ست‌ها برای ریکاوری ضروریه.',
    'مکمل‌ها جایگزین تغذیه سالم نمیشن.',
    'گرم کردن عضلات قبل از تمرین سنگین ضروریه.',
    'کشش صبحگاهی انرژی روز رو افزایش میده.',
    'آب خوردن قبل از خواب کیفیت خواب رو بهتر می‌کنه.',
    'تمرین با فرم صحیح از آسیب جلوگیری می‌کنه.',
    'استراحت کافی بین جلسات تمرین مهمه.',
    'تغذیه متعادل کلید موفقیت در فیتنسه.',
    'گرم کردن قبل از دویدن از آسیب جلوگیری می‌کنه.',
    'کشش بعد از تمرین درد عضلانی رو کاهش میده.',
    'آب خوردن در طول روز متابولیسم رو افزایش میده.',
    'تمرین هوازی برای سلامت قلب ضروریه.',
    'قدرت ذهنی به اندازه قدرت بدنی مهمه.',
    'استراحت فعال بهتر از استراحت کامل است.',
    'تغذیه قبل از تمرین انرژی لازم رو تامین می‌کنه.',
    'گرم کردن عضلات قبل از تمرین عملکرد رو بهتر می‌کنه.',
    'کشش منظم انعطاف‌پذیری رو افزایش میده.',
    'آب خوردن بعد از تمرین ریکاوری رو تسریع می‌کنه.',
    'تمرین با وزنه تراکم استخوان رو افزایش میده.',
    'استراحت کافی برای رشد عضلات ضروریه.',
    'تغذیه بعد از تمرین ریکاوری رو بهبود میده.',
    'گرم کردن قبل از تمرین از گرفتگی عضلات جلوگیری می‌کنه.',
  ];

  @override
  void initState() {
    super.initState();
    _currentTip = _tips[_random.nextInt(_tips.length)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      context.veryDarkBackground,
                      AppTheme.darkGold.withValues(alpha: 0.15),
                    ]
                  : [
                      context.goldGradientColors[0].withValues(alpha: 0.35),
                      context.goldGradientColors[1].withValues(alpha: 0.2),
                      context.cardColor,
                    ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.5),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            color: context.textColor,
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'نکته روز',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.sp,
                              color: context.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  _currentTip,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    height: 1.5,
                    color: context.textColor,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: 100.ms)
        .slideX(begin: 0.03, end: 0, duration: 350.ms, delay: 100.ms);
  }
}
