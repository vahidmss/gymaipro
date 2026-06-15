import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileStatsWidgets {
  static Widget buildStatsGrid(Map<String, dynamic> profileData) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [context.backgroundColor, context.backgroundColor]
                  : [
                      context.goldGradientColors[0].withValues(alpha: 0.15),
                      context.cardColor,
                      context.goldGradientColors[1].withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.5),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.15 : 0.35,
                ),
                blurRadius: 16.r,
                offset: Offset(0.w, 6.h),
                spreadRadius: 1.r,
              ),
              BoxShadow(
                color: isDark
                    ? context.backgroundColor.withValues(alpha: 0.3)
                    : AppTheme.lightTextColor.withValues(alpha: 0.08),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [context.textColor, AppTheme.goldColor]
                          : [context.textColor, AppTheme.goldColor],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'آمار پروفایل',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.4, // کاهش برای فضای بیشتر در ارتفاع
                  children: [
                    buildStatCard(
                      'قد',
                      profileData['height']?.toString(),
                      'سانتی‌متر',
                      LucideIcons.ruler,
                    ),
                    buildStatCard(
                      'وزن',
                      _getWeightDisplayValue(profileData),
                      'کیلوگرم',
                      LucideIcons.scale,
                    ),
                    // روزهای عضویت
                    buildStatCard(
                      'روزهای عضویت',
                      _getMembershipDays(profileData),
                      'روز',
                      LucideIcons.calendar,
                    ),
                    buildStatCard(
                      'دور بازو',
                      profileData['arm_circumference']?.toString(),
                      'سانتی‌متر',
                      LucideIcons.circle,
                    ),
                    buildStatCard(
                      'دور سینه',
                      profileData['chest_circumference']?.toString(),
                      'سانتی‌متر',
                      LucideIcons.heart,
                    ),
                    buildStatCard(
                      'دور کمر',
                      profileData['waist_circumference']?.toString(),
                      'سانتی‌متر',
                      LucideIcons.circle,
                    ),
                    buildStatCard(
                      'دور باسن',
                      profileData['hip_circumference']?.toString(),
                      'سانتی‌متر',
                      LucideIcons.circle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _getWeightDisplayValue(Map<String, dynamic> profileData) {
    // ابتدا از وزن پروفایل استفاده کن، اگر نبود از آخرین وزن ثبت شده استفاده کن
    double? weightValue;

    // اگر وزن در پروفایل موجود است
    if (profileData['weight'] != null &&
        profileData['weight'].toString().isNotEmpty) {
      weightValue = double.tryParse(profileData['weight'].toString());
    }

    // اگر وزن در پروفایل نبود، از آخرین وزن ثبت شده استفاده کن
    if (weightValue == null && profileData['latest_weight'] != null) {
      weightValue = double.tryParse(profileData['latest_weight'].toString());
    }

    return weightValue != null ? weightValue.toStringAsFixed(1) : '--';
  }

  static String _getMembershipDays(Map<String, dynamic> profileData) {
    try {
      final createdAtRaw = profileData['created_at']?.toString();
      if (createdAtRaw == null || createdAtRaw.isEmpty) return '--';
      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) return '--';
      final days = DateTime.now().difference(createdAt).inDays;
      return days >= 0 ? days.toString() : '--';
    } catch (_) {
      return '--';
    }
  }

  static Widget buildStatCard(
    String title,
    String? value,
    String unit,
    IconData icon,
  ) {
    final displayValue = value != null && value.isNotEmpty ? value : '--';

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 10.h, // کاهش بیشتر vertical padding
          ), // کاهش padding برای فضای بیشتر
          decoration: BoxDecoration(
            color: context.veryDarkBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.05 : 0.1,
                ),
                blurRadius: 4.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // استفاده از FittedBox با scaleDown برای scale کردن محتوا در صورت نیاز
              // این روش طبق استاندارد Flutter است و محتوا را کامل نمایش می‌دهد
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ردیف اول: آیکون و عنوان
                      Row(
                        textDirection: TextDirection.rtl,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: AppTheme.goldColor, size: 16.sp),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textSecondary,
                                fontSize: 10.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // ردیف دوم: مقدار و واحد
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // مقدار - استفاده از Flexible برای جلوگیری از clip
                          Flexible(
                            child: Text(
                              displayValue,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          // واحد - فضای ثابت
                          Text(
                            unit,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textSecondary,
                              fontSize: 9.sp,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
