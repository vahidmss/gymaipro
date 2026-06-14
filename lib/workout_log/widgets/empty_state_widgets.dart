import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
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

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heroHeader(context, isDark),
          SizedBox(height: 16.h),
          if (onStarterProgramTap != null)
            _starterProgramCard(
              context: context,
              isDark: isDark,
              onTap: onStarterProgramTap,
              isLoading: isInstallingStarter,
              alreadyInstalled: hasStarterProgram,
              needsUpgrade: needsStarterUpgrade,
            ),
          if (onStarterProgramTap != null) SizedBox(height: 20.h),
          Text(
            'یا از این مسیرها برنامه بگیرید',
            style: WorkoutLogTypography.dialogMuted(context).copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          _buildOptionCard(
            context: context,
            isDark: isDark,
            icon: LucideIcons.listChecks,
            title: 'برنامه‌های من',
            description: 'برنامه‌های ذخیره‌شده را ببینید و فعال کنید',
            accentColor: isDark ? AppTheme.goldColor : AppTheme.lightTextColor,
            onTap: () => Navigator.pushNamed(
              context,
              '/my-club',
              arguments: {'initialTab': 0},
            ),
          ),
          SizedBox(height: 10.h),
          _buildOptionCard(
            context: context,
            isDark: isDark,
            icon: LucideIcons.messageCircle,
            title: 'درخواست برنامه از مربی',
            description: 'برنامه اختصاصی با نظارت مربی حرفه‌ای',
            accentColor: const Color(0xFF2196F3),
            onTap: () => Navigator.pushNamed(context, '/trainer-ranking'),
          ),
          SizedBox(height: 10.h),
          _buildOptionCard(
            context: context,
            isDark: isDark,
            icon: LucideIcons.bot,
            title: 'ساخت با هوش مصنوعی',
            description: 'برنامه شخصی‌سازی‌شده بر اساس اطلاعات شما',
            accentColor: const Color(0xFF9C27B0),
            onTap: () => Navigator.pushNamed(context, '/ai-programs'),
          ),
        ],
      ),
    );
  }

  static Widget _heroHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppTheme.goldColor.withValues(alpha: 0.18),
                  AppTheme.darkCardColor,
                ]
              : [
                  AppTheme.goldColor.withValues(alpha: 0.22),
                  AppTheme.lightCardColor,
                ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.45),
                width: 1.5.w,
              ),
            ),
            child: Icon(
              LucideIcons.clipboardList,
              color: WorkoutLogColors.iconOnSurface(context),
              size: 30.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'هنوز برنامهٔ فعالی ندارید',
            style: WorkoutLogTypography.sectionTitle(context).copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'برای ثبت تمرین، ابتدا یک برنامه را فعال کنید.\n۳ جلسهٔ رایگان مبتدی دارید — هر بار یک جلسه را انتخاب کنید.',
            style: WorkoutLogTypography.dialogMuted(context).copyWith(
              fontSize: 13.sp,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _starterProgramCard({
    required BuildContext context,
    required bool isDark,
    required VoidCallback onTap,
    required bool isLoading,
    required bool alreadyInstalled,
    bool needsUpgrade = false,
  }) {
    const accent = Color(0xFF2E7D32);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      accent.withValues(alpha: 0.35),
                      accent.withValues(alpha: 0.15),
                    ]
                  : [
                      accent.withValues(alpha: 0.12),
                      accent.withValues(alpha: 0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: EdgeInsets.all(10.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: accent,
                          ),
                        )
                      : Icon(
                          LucideIcons.gift,
                          color: accent,
                          size: 22.sp,
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'رایگان',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: accent,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'شروع باشگاه',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        needsUpgrade
                            ? 'نسخهٔ جدید برنامه آماده است — یک‌بار بزنید تا به‌روز شود\n۲ ست هفتهٔ اول · حرکت‌های ساده‌تر'
                            : alreadyInstalled
                            ? 'برنامهٔ مبتدی شما آماده است — فعال کنید و یک جلسه را بزنید'
                            : '۳ جلسه · حرکات دستگاه · بدون محدودیت زمانی\nپیشنهاد تازه‌واردها: حدود ۴ هفته، ۳ بار در هفته',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? context.textColor.withValues(alpha: 0.75)
                              : AppTheme.lightTextSecondary,
                          fontSize: 11.5.sp,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        needsUpgrade
                            ? 'به‌روزرسانی برنامه'
                            : alreadyInstalled
                            ? 'فعال‌سازی و شروع ثبت تمرین'
                            : 'دریافت و شروع فوری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: accent,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.arrowLeft, color: accent, size: 18.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildOptionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? context.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.22 : 0.18),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: accentColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WorkoutLogTypography.sectionTitle(context).copyWith(
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      description,
                      style: WorkoutLogTypography.dialogMuted(context).copyWith(
                        fontSize: 11.sp,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronLeft, color: accentColor, size: 18.sp),
            ],
          ),
        ),
      ),
    );
  }

  static Widget noSessionSelected() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.08)
                  : AppTheme.goldColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.28),
                width: 1.w,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.hand,
                  color: AppTheme.goldColor.withValues(alpha: 0.85),
                  size: 28.sp,
                ),
                SizedBox(height: 10.h),
                Text(
                  'یک جلسه از برنامه را انتخاب کنید',
                  style: WorkoutLogTypography.sectionTitle(context).copyWith(
                    fontSize: 15.5.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'روی «جلسه ۱»، «جلسه ۲» یا «جلسه ۳» در بالا بزنید — هر بار که به باشگاه می‌آیید یکی را انتخاب کنید.',
                  style: WorkoutLogTypography.caption(context).copyWith(
                    fontSize: 12.5.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget noExercisesInSession() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                        style: WorkoutLogTypography.sectionTitle(context),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'از بخش «برنامه‌های من» تمرین به این روز اضافه کنید یا برنامهٔ دیگری را فعال کنید.',
                        style: WorkoutLogTypography.dialogMuted(context).copyWith(
                          fontSize: 12.sp,
                          height: 1.45,
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
