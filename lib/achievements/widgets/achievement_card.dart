import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AchievementCard extends StatefulWidget {
  const AchievementCard({required this.achievement, super.key, this.onTap});
  final Achievement achievement;
  final VoidCallback? onTap;

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = widget.achievement.isUnlocked;

    return GestureDetector(
      onTapDown: (_) => _controller.safeForward(),
      onTapUp: (_) {
        _controller.safeReverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.safeReverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isUnlocked
                  ? Color(widget.achievement.tier.colorValue)
                      .withValues(alpha: 0.35)
                  : AppTheme.lightDividerColor.withValues(
                      alpha: isDark ? 0.7 : 0.5,
                    ),
              width: 1.w,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: Stack(
              children: [
                // نوار پیشرفت مینیمال در پایین کارت
                if (!isUnlocked)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: widget.achievement.progress,
                      minHeight: 3.h,
                      backgroundColor: AppTheme.lightDividerColor.withValues(
                        alpha: isDark ? 0.4 : 0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation(
                        Color(widget.achievement.tier.colorValue),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      // آیکون
                      _buildIcon(isUnlocked, isDark),
                      SizedBox(width: 16.w),

                      // محتوای متنی
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // عنوان
                            Text(
                              widget.achievement.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                height: 1.35,
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 10.h),

                            // پیشرفت یا امتیاز
                            if (!isUnlocked)
                              _buildProgressInfo(isDark)
                            else
                              _buildUnlockedInfo(isDark),
                          ],
                        ),
                      ),

                      // نشان tier
                      _buildTierBadge(isUnlocked, isDark),
                    ],
                  ),
                ),

                // بدون افکت شاین برای سادگی و کارایی بهتر
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isUnlocked, bool isDark) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked
            ? Color(widget.achievement.tier.colorValue).withValues(alpha: 0.2)
            : (isDark
                ? AppTheme.darkGreySeparator.withValues(alpha: 0.7)
                : AppTheme.lightDividerColor.withValues(alpha: 0.7)),
        border: isUnlocked
            ? Border.all(
                color: Color(
                  widget.achievement.tier.colorValue,
                ).withValues(alpha: 0.3),
                width: 1.5.w,
              )
            : null,
      ),
      child: Center(
        child: Text(
          widget.achievement.icon,
          style: TextStyle(
            fontSize: 24.sp,
            shadows: isUnlocked
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4.r,
                      offset: Offset(0.w, 1.h),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTierBadge(bool isUnlocked, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Color(widget.achievement.tier.colorValue)
                .withValues(alpha: 0.15)
            : (isDark
                ? AppTheme.darkGreySeparator
                : AppTheme.lightDividerColor),
        borderRadius: BorderRadius.circular(9.r),
        border: isUnlocked
            ? Border.all(
                color:
                    Color(widget.achievement.tier.colorValue).withValues(alpha: 0.3),
                width: 0.8.w,
              )
            : null,
      ),
      child: Text(
        widget.achievement.tier.displayName,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.25,
          fontFamily: AppTheme.fontFamily,
          color: isUnlocked
              ? Color(widget.achievement.tier.colorValue)
              : (isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.9)
                    : AppTheme.lightTextSecondary),
        ),
      ),
    );
  }

  Widget _buildProgressInfo(bool isDark) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // امتیاز
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.18),
                AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(7.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.25),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.15),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.star, size: 11.5.sp, color: AppTheme.goldColor),
              SizedBox(width: 3.5.w),
              Text(
                '${widget.achievement.points}',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? AppTheme.goldColor : AppTheme.lightTextColor,
                ),
              ),
            ],
          ),
        ),
        // پیشرفت
        Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(
                      widget.achievement.tier.colorValue,
                    ).withValues(alpha: 0.18),
                    Color(
                      widget.achievement.tier.colorValue,
                    ).withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(7.r),
                border: Border.all(
                  color: Color(
                    widget.achievement.tier.colorValue,
                  ).withValues(alpha: 0.2),
                  width: 1.w,
                ),
              ),
              child: Text(
                '${widget.achievement.progressPercentage}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                  fontFamily: AppTheme.fontFamily,
                  color: Color(widget.achievement.tier.colorValue),
                ),
              ),
            ),
            SizedBox(width: 7.w),
            Flexible(
              child: Text(
                '${widget.achievement.currentValue}/${widget.achievement.targetValue} ${widget.achievement.unit}',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                ),
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnlockedInfo(bool isDark) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(
                  widget.achievement.tier.colorValue,
                ).withValues(alpha: 0.18),
                Color(
                  widget.achievement.tier.colorValue,
                ).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(
              color: Color(
                widget.achievement.tier.colorValue,
              ).withValues(alpha: 0.25),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(
                  widget.achievement.tier.colorValue,
                ).withValues(alpha: 0.15),
                blurRadius: 10.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.star, size: 12.sp, color: AppTheme.goldColor),
              SizedBox(width: 4.5.w),
              Text(
                '${widget.achievement.points}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                  fontFamily: AppTheme.fontFamily,
                  color: isDark
                      ? Color(widget.achievement.tier.colorValue)
                      : AppTheme.lightTextColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 7.w),
        if (widget.achievement.unlockedAt != null)
          Text(
            _getUnlockedTimeAgo(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
            ),
          ),
      ],
    );
  }

  String _getUnlockedTimeAgo() {
    if (widget.achievement.unlockedAt == null) return '';

    final difference = DateTime.now().difference(
      widget.achievement.unlockedAt!,
    );

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} ماه پیش';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقیقه پیش';
    } else {
      return 'همین الان';
    }
  }
}
