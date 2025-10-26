import 'package:flutter/material.dart';
// نوار بالای صفحه (AppBar) مخصوص صفحه ساخت برنامه غذایی
// استفاده در MealPlanBuilderScreen
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppBarMealPlanBuilder extends StatelessWidget
    implements PreferredSizeWidget {
  const AppBarMealPlanBuilder({
    required this.isSaving,
    required this.onSave,
    required this.onOpenDrawer,
    super.key,
    this.onBack,
  });
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onOpenDrawer;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
            child: Row(
              children: [
                // دکمه بازگشت
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                      width: 1.5.w,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.arrowRight,
                      color: const Color(0xFFD4AF37),
                      size: 20.sp,
                    ),
                    onPressed:
                        onBack ?? () => NavigationService.safePop(context),
                  ),
                ),
                const SizedBox(width: 16),
                // عنوان
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'برنامه غذایی',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'طراحی و مدیریت وعده‌های غذایی',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // دکمه منو
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                      width: 1.5.w,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.menu,
                      color: const Color(0xFFD4AF37),
                      size: 20.sp,
                    ),
                    onPressed: onOpenDrawer,
                    tooltip: 'برنامه‌های ذخیره‌شده',
                  ),
                ),
                const SizedBox(width: 12),
                // دکمه ذخیره
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                      width: 1.5.w,
                    ),
                  ),
                  child: IconButton(
                    icon: isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD4AF37),
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.save,
                            color: const Color(0xFFD4AF37),
                            size: 20.sp,
                          ),
                    onPressed: isSaving ? null : onSave,
                    tooltip: 'ذخیره',
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
