import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ChatSection extends StatelessWidget {
  const ChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = 16.w; // padding از dashboard_screen

        return SizedBox(
          height: 50.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // خط طلایی افقی با gradient
              Positioned(
                top: 25.h, // وسط ارتفاع
                left: -horizontalPadding + 2.w,
                child: Container(
                  width: screenWidth - 4.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.3 : 0.4,
                        ),
                        AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.5 : 0.6,
                        ),
                        AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.3 : 0.4,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // آیکون و متن "ورود به چت روم" در وسط خط
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: GestureDetector(
                    onTap: () {
                      // باز کردن تب همگانی (index 1) به صورت پیش‌فرض
                      Navigator.pushNamed(
                        context,
                        '/chat-main',
                        arguments: 1, // تب همگانی
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.5 : 0.6,
                          ),
                          width: 1.5.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.15 : 0.2,
                            ),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // آیکون چت - دایره طلایی
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: context.goldGradientColors,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: isDark ? 0.4 : 0.5,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'images/chat_icon.png',
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.chat_bubble_outline,
                                    size: 20.sp,
                                    color: AppTheme.onGoldColor,
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // متن "ورود به چت روم"
                          Text(
                            'ورود به چت روم',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                              color: context.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
