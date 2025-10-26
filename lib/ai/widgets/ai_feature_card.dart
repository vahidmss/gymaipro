import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
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
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
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
                  color: widget.isComingSoon
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: widget.isComingSoon
                        ? Colors.white.withValues(alpha: 0.1)
                        : widget.color.withValues(alpha: 0.1),
                    width: 1.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isComingSoon
                          ? Colors.transparent
                          : widget.color.withValues(alpha: 0.1),
                      blurRadius: 12.r,
                      offset: Offset(0.w, 4.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: widget.isComingSoon
                            ? Colors.white.withValues(alpha: 0.1)
                            : widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.isComingSoon
                            ? Colors.white.withValues(alpha: 0.1)
                            : widget.color,
                        size: 24.sp,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isComingSoon
                                        ? Colors.black.withValues(alpha: 0.1)
                                        : Colors.black,
                                  ),
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
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'به زودی',
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.goldColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.description,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 15.sp,
                              color: widget.isComingSoon
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                              height: 1.4.h,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.chevronLeft,
                      color: widget.isComingSoon
                          ? Colors.white.withValues(alpha: 0.1)
                          : widget.color.withValues(alpha: 0.1),
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
