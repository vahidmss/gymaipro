import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({required this.animationController, super.key});
  final AnimationController animationController;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotAnimationController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _dotAnimationController,
          curve: Interval(index * 0.2, 1, curve: Curves.easeInOut),
        ),
      );
    });

    _dotAnimationController.safeRepeat();
  }

  @override
  void dispose() {
    _dotAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(right: 50.w, bottom: 8.h),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // پیام تایپ
          Flexible(
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                        bottomLeft: Radius.circular(4.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.2 : 0.3,
                        ),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.1 : 0.15,
                          ),
                          blurRadius: 6.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: IntrinsicWidth(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            'در حال تایپ',
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              color: context.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          ...List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _dotAnimations[index],
                              builder: (context, child) {
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                                  child: Opacity(
                                    opacity: _dotAnimations[index].value,
                                    child: Container(
                                      width: 6.w,
                                      height: 6.h,
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldColor,
                                        borderRadius: BorderRadius.circular(
                                          3.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // آواتار هوش مصنوعی (بعد از پیام - سمت چپ)
          SizedBox(width: 8.w),
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              ),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
