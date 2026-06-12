import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmptyStateWidgets {
  static Widget noActiveProgram(
    BuildContext context, {
    VoidCallback? onStarterProgramTap,
    bool isInstallingStarter = false,
    bool hasStarterProgram = false,
    bool needsStarterUpgrade = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? context.cardColor
                  : AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.3 : 0.25,
                ),
                width: 1.w,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                      width: 1.5.w,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.dumbbell,
                    color: AppTheme.goldColor,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'برنامه تمرینی فعال ندارید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'یکی از گزینه‌های زیر را انتخاب کنید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.9)
                        : AppTheme.lightTextSecondary,
                    fontSize: 12.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Option Cards - برنامه‌های من اول
          _buildOptionCard(
            context: context,
            isDark: isDark,
            icon: LucideIcons.listChecks,
            title: 'برنامه‌های من',
            description: 'برنامه‌های ذخیره شده را مشاهده و فعال کنید',
            gradientColors: isDark
                ? [
                    AppTheme.goldColor.withValues(alpha: 0.2),
                    AppTheme.darkGold.withValues(alpha: 0.15),
                  ]
                : [
                    AppTheme.goldColor.withValues(alpha: 0.15),
                    AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                  ],
            iconColor: AppTheme.goldColor,
            onTap: () => Navigator.pushNamed(
              context,
              '/my-club',
              arguments: {'initialTab': 0},
            ),
          ),

          SizedBox(height: 12.h),

          _buildOptionCard(
            context: context,
            isDark: isDark,
            icon: LucideIcons.messageCircle,
            title: 'درخواست برنامه از مربی',
            description: 'با مربی‌های حرفه‌ای چت کنید',
            gradientColors: isDark
                ? [
                    const Color(0xFF1E3A5F).withValues(alpha: 0.8),
                    const Color(0xFF2A4A7A).withValues(alpha: 0.6),
                  ]
                : [
                    const Color(0xFFE3F2FD).withValues(alpha: 0.8),
                    const Color(0xFFBBDEFB).withValues(alpha: 0.6),
                  ],
            iconColor: const Color(0xFF2196F3),
            onTap: () => Navigator.pushNamed(context, '/trainer-ranking'),
          ),

          SizedBox(height: 12.h),

          _buildOptionCard(
            context: context,
            isDark: isDark,
            icon: LucideIcons.bot,
            title: 'ساخت با هوش مصنوعی',
            description: 'برنامه تمرینی شخصی‌سازی شده بسازید',
            gradientColors: isDark
                ? [
                    const Color(0xFF4A148C).withValues(alpha: 0.8),
                    const Color(0xFF6A1B9A).withValues(alpha: 0.6),
                  ]
                : [
                    const Color(0xFFF3E5F5).withValues(alpha: 0.8),
                    const Color(0xFFE1BEE7).withValues(alpha: 0.6),
                  ],
            iconColor: const Color(0xFF9C27B0),
            onTap: () => Navigator.pushNamed(context, '/ai-programs'),
          ),
        ],
      ),
    );
  }

  static Widget _buildOptionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.1 : 0.08),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: iconColor.withValues(alpha: isDark ? 0.25 : 0.2),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark
                            ? context.textColor.withValues(alpha: 0.7)
                            : AppTheme.lightTextSecondary,
                        fontSize: 11.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Icon(LucideIcons.arrowLeft, color: iconColor, size: 16.sp),
            ],
          ),
        ),
      ),
    );
  }

  static Widget noSessionSelected() {
    return const SizedBox.shrink();
  }

  static Widget noExercisesInSession() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.3 : 0.25,
                ),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.dumbbell,
                    color: AppTheme.goldColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تمرینی برای این جلسه تعریف نشده',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.darkTextColor
                              : AppTheme.lightTextColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'می‌توانید از بخش ساخت برنامه، تمرین‌ها را اضافه کنید',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                          fontSize: 12.sp,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
