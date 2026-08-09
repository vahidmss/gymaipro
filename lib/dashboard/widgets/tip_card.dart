import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نکته روز — نوار ساکت، بدون کارت طلایی.
class TipCard extends StatefulWidget {
  const TipCard({super.key});

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  late String _currentTip;

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
    _currentTip = _tips[Random().nextInt(_tips.length)];
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.lightbulb,
              size: 16.sp,
              color: AppTheme.goldColor,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نکته روز',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                      color: context.textSecondary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _currentTip,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      height: 1.45,
                      color: context.textColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
