import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AIFeatureCard extends StatefulWidget {
  const AIFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    super.key,
    this.isComingSoon = false,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isComingSoon;

  @override
  State<AIFeatureCard> createState() => _AIFeatureCardState();
}

class _AIFeatureCardState extends State<AIFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => _animationController.safeForward(),
      onTapUp: (_) => _animationController.safeReverse(),
      onTapCancel: () => _animationController.safeReverse(),
      onTap: widget.isComingSoon ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.color.withValues(alpha: 0.15),
                            context.cardColor,
                            widget.color.withValues(alpha: 0.1),
                          ],
                        ),
                  color: isDark ? context.cardColor : null,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: widget.color.withValues(alpha: isDark ? 0.3 : 0.5),
                    width: 1.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(
                        alpha: isDark ? 0.15 : 0.35,
                      ),
                      blurRadius: 16.r,
                      offset: Offset(0.w, 6.h),
                      spreadRadius: 1.r,
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.5)
                          : context.textColor.withValues(alpha: 0.08),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.2),
                            blurRadius: 6.r,
                            offset: Offset(0.w, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.isComingSoon)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: AppTheme.goldColor.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'به زودی',
                                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.goldColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.description,
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                              color: context.textSecondary,
                              height: 1.5.h,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      LucideIcons.chevronLeft,
                      color: widget.color.withValues(alpha: 0.6),
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
