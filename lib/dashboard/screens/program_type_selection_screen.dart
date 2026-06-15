import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_questionnaire/screens/workout_questionnaire_screen.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه انتخاب نوع برنامه
/// کاربر می‌تواند بین برنامه تمرینی از AI، برنامه رژیمی از AI، یا برنامه از مربی انتخاب کند
class ProgramTypeSelectionScreen extends StatelessWidget {
  const ProgramTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: context.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
          ),
        ),
        child: DecoratedBox(
          decoration: isDark
              ? const BoxDecoration()
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightGradientStart.withValues(alpha: 0.15),
                      AppTheme.lightCardColor,
                      AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: isDark
                  ? context.backgroundColor
                  : Colors.transparent,
              foregroundColor: isDark ? AppTheme.goldColor : context.textColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  LucideIcons.arrowRight,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                ),
                onPressed: () => WidgetSafetyUtils.safePop(context),
              ),
              title: Text(
                'درخواست برنامه',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان و توضیحات
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نوع برنامه را انتخاب کنید',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: context.textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'برنامه‌ای که می‌خواهید دریافت کنید را انتخاب کنید',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                              color: context.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // کارت برنامه تمرینی از AI
                    _buildProgramCard(
                      context: context,
                      isDark: isDark,
                      icon: LucideIcons.dumbbell,
                      iconColor: AppTheme.goldColor,
                      title: 'برنامه تمرینی',
                      subtitle: 'از جیم‌آی',
                      description:
                          'برنامه تمرینی کامل و حرفه‌ای که بر اساس اطلاعات شما طراحی می‌شود',
                      accentColor: AppTheme.goldColor,
                      onTap: () {
                        WidgetSafetyUtils.safeNavigate(
                          context,
                          () => const WorkoutQuestionnaireScreen(),
                        );
                      },
                    ),
                    SizedBox(height: 16.h),

                    // کارت برنامه رژیمی از AI
                    _buildProgramCard(
                      context: context,
                      isDark: isDark,
                      icon: LucideIcons.apple,
                      iconColor: const Color(0xFF4CAF50),
                      title: 'برنامه رژیمی',
                      subtitle: 'از جیم‌آی',
                      description:
                          'برنامه رژیمی کامل با محاسبه کالری و درشت‌مغذی‌ها',
                      accentColor: const Color(0xFF4CAF50),
                      onTap: () {
                        WidgetSafetyUtils.safeShowSnackBar(
                          context,
                          'این قابلیت به زودی اضافه می‌شود',
                          backgroundColor: AppTheme.goldColor,
                        );
                      },
                    ),
                    SizedBox(height: 16.h),

                    // کارت برنامه از مربی
                    _buildProgramCard(
                      context: context,
                      isDark: isDark,
                      icon: LucideIcons.userCheck,
                      iconColor: const Color(0xFF2196F3),
                      title: 'برنامه از مربی',
                      subtitle: 'حرفه‌ای و شخصی',
                      description:
                          'دریافت برنامه تمرینی یا رژیمی از مربیان حرفه‌ای',
                      accentColor: const Color(0xFF2196F3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const TrainerRankingScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),

                    // نکته پایین
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]!.withValues(alpha: 0.2)
                              : AppTheme.goldColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 16.sp,
                              color: AppTheme.goldColor.withValues(alpha: 0.8),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'برنامه‌های جیم‌آی به صورت رایگان و فوری تولید می‌شوند. برای دریافت برنامه از مربی، باید اشتراک تهیه کنید.',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.5.sp,
                                  color: context.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? context.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark
                  ? Colors.grey[700]!.withValues(alpha: 0.3)
                  : AppTheme.lightDividerColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هدر با آیکون و عنوان
                Row(
                  children: [
                    // آیکون مینیمال
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // عنوان و زیرعنوان
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // فلش ظریف
                    Icon(
                      LucideIcons.chevronLeft,
                      color: context.textSecondary.withValues(alpha: 0.5),
                      size: 18.sp,
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                // توضیحات
                Padding(
                  padding: EdgeInsets.only(right: 58.w),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5.sp,
                      color: context.textSecondary,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

