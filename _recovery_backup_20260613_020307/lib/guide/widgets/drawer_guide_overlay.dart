import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/guide/services/guide_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// راهنمای کوچک برای Drawer
class DrawerGuideOverlay extends StatefulWidget {
  const DrawerGuideOverlay({super.key});

  @override
  State<DrawerGuideOverlay> createState() => _DrawerGuideOverlayState();
}

class _DrawerGuideOverlayState extends State<DrawerGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    final guideService = Provider.of<GuideService>(context, listen: false);
    guideService.skipGuide(dontShowAgain: _dontShowAgain);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // آیکون و عنوان
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.menu,
                      color: AppTheme.goldColor,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      '📱 منوی اصلی',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : AppTheme.lightTextColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.lightTextSecondary,
                    ),
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // توضیحات
              Text(
                'از این منو می‌تونید به تمام بخش‌های اپ دسترسی داشته باشید:\n\n'
                '• پروفایل و اطلاعات شخصی\n'
                '• باشگاه من و برنامه‌ها\n'
                '• کیف پول و تراکنش‌ها\n'
                '• تنظیمات و راهنما\n'
                '• و خیلی چیزهای دیگه!',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppTheme.lightTextSecondary,
                  height: 1.6,
                  fontFamily: AppTheme.fontFamily,
                ),
                textDirection: TextDirection.rtl,
              ),

              SizedBox(height: 16.h),

              // Checkbox "دیگه نشون نده"
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (value) {
                      setState(() {
                        _dontShowAgain = value ?? false;
                      });
                    },
                    activeColor: AppTheme.goldColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    'دیگه نشون نده',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.lightTextSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // دکمه متوجه شدم
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _dismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 1,
                  ),
                  child: Text(
                    'متوجه شدم!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

