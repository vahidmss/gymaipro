import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WeightWidgets {
  static String _toPersianNumber(String number) {
    const Map<String, String> persianNumbers = {
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    };

    String result = number;
    persianNumbers.forEach((english, persian) {
      result = result.replaceAll(english, persian);
    });
    return result;
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'امروز';
      } else if (difference == 1) {
        return 'دیروز';
      } else if (difference < 7) {
        return '${_toPersianNumber(difference.toString())} روز پیش';
      } else {
        final persianDate =
            '${_toPersianNumber(date.day.toString())}/${_toPersianNumber(date.month.toString())}/${_toPersianNumber(date.year.toString())}';
        return persianDate;
      }
    } catch (e) {
      return dateString;
    }
  }

  static void showWeightGuidanceDialog(
    BuildContext context,
    void Function(String) onWeightSubmitted,
  ) {
    final weightController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(
                alpha: isDark ? 0.3 : 0.5,
              ),
              width: 1.5,
            ),
          ),
          title: Text(
            'ثبت وزن جدید',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'وزن فعلی خود را وارد کنید:',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'مثال: 75.5',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary.withValues(alpha: 0.6),
                      fontSize: 14.sp,
                    ),
                    filled: true,
                    fillColor: context.veryDarkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: context.separatorColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: context.separatorColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: AppTheme.goldColor,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      LucideIcons.scale,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'انصراف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = weightController.text.trim();
                if (weight.isNotEmpty) {
                  onWeightSubmitted(weight);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'ثبت',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showWeightHistoryDialog(
    BuildContext context,
    List<Map<String, dynamic>> weightHistory,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(
                alpha: isDark ? 0.3 : 0.5,
              ),
              width: 1.5,
            ),
          ),
          title: Text(
            'تاریخچه وزن',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300.h,
            child: weightHistory.isEmpty
                ? Center(
                    child: Text(
                      'هنوز وزنی ثبت نشده است',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 16.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: weightHistory.length,
                    itemBuilder: (context, index) {
                      final record = weightHistory[index];
                      final weight = record['weight']?.toString() ?? '';
                      final date = record['recorded_at']?.toString() ?? '';

                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: context.veryDarkBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Center(
                                child: Text(
                                  _toPersianNumber((index + 1).toString()),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: AppTheme.goldColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_toPersianNumber(weight)}  کیلوگرم',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color: context.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  Text(
                                    _formatDate(date),
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color: context.textSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.lineChart,
                              color: AppTheme.goldColor.withValues(alpha: 0.6),
                              size: 20.sp,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'بستن',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
