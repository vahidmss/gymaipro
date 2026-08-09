import 'package:flutter/material.dart';
// نوار بالای صفحه ساخت/ویرایش برنامه تمرین
// استفاده در WorkoutProgramBuilderScreen
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutProgramAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const WorkoutProgramAppBar({
    required this.onConfirm,
    this.showConfirmButton = true,
    this.isSent = false,
    super.key,
    this.onBack,
  });
  final VoidCallback onConfirm;
  final bool showConfirmButton;
  final bool isSent;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowRight,
          color: AppTheme.goldColor,
          size: 28.sp,
        ),
        onPressed: onBack ?? () => NavigationService.safePop(context),
      ),
      title: Text(
        'برنامه تمرین',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: isDark ? AppTheme.goldColor : context.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
      actions: [
        if (isSent)
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.circleCheck,
                    color: AppTheme.goldColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'ارسال شده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.goldColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (showConfirmButton)
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.goldColor, AppTheme.darkGold],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.4),
                    blurRadius: 8.r,
                    offset: Offset(0.w, 2.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onConfirm,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.check,
                          color: AppTheme.onGoldColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'ارسال برنامه',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: AppTheme.onGoldColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        SizedBox(width: 8.w),
      ],
    );
  }
}
