import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/widgets/ai_hub_ui.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 160),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    final accent = widget.color;
    final borderColor = Color.lerp(context.separatorColor, accent, 0.45)!;

    return GestureDetector(
      onTapDown: widget.isComingSoon ? null : (_) => _animationController.safeForward(),
      onTapUp: widget.isComingSoon ? null : (_) => _animationController.safeReverse(),
      onTapCancel: widget.isComingSoon ? null : () => _animationController.safeReverse(),
      onTap: widget.isComingSoon ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.isComingSoon ? 0.72 : 1,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: borderColor.withValues(alpha: isDark ? 0.75 : 0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.headerShadowColor,
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AiHubIconBadge(
                      icon: widget.icon,
                      gradientColors: aiHubAccentGradient(accent),
                      dimmed: widget.isComingSoon,
                      size: 52.w,
                      iconSize: 24.sp,
                    ),
                    SizedBox(width: 14.w),
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
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: context.textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.isComingSoon) ...[
                                SizedBox(width: 8.w),
                                _ComingSoonChip(),
                              ],
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            widget.description,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.sp,
                              height: 1.5,
                              color: context.textSecondary.withValues(
                                alpha: isDark ? 0.92 : 0.88,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      LucideIcons.chevronLeft,
                      color: widget.isComingSoon
                          ? context.textSecondary.withValues(alpha: 0.35)
                          : accent.withValues(alpha: isDark ? 0.85 : 0.75),
                      size: 22.sp,
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

class _ComingSoonChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        'به‌زودی',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkGold,
        ),
      ),
    );
  }
}
