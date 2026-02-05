import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(
                        widget.achievement.tier.colorValue,
                      ).withValues(alpha: 0.15),
                      context.cardColor,
                      Color(
                        widget.achievement.tier.colorValue,
                      ).withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  )
                : isDark
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.goldGradientColors[0].withValues(alpha: 0.08),
                      context.cardColor,
                      context.goldGradientColors[1].withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
            color: isUnlocked ? null : (isDark ? context.cardColor : null),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isUnlocked
                  ? Color(
                      widget.achievement.tier.colorValue,
                    ).withValues(alpha: 0.35)
                  : AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? Color(
                        widget.achievement.tier.colorValue,
                      ).withValues(alpha: isDark ? 0.18 : 0.22)
                    : AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.12 : 0.25,
                      ),
                blurRadius: 24.r,
                offset: Offset(0.w, 6.h),
                spreadRadius: 0.r,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 16.r,
                offset: Offset(0.w, 3.h),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: Stack(
              children: [
                // نوار پیشرفت در پس‌زمینه
                if (!isUnlocked)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(18.r),
                        bottomRight: Radius.circular(18.r),
                      ),
                      child: Container(
                        height: 5.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(
                                widget.achievement.tier.colorValue,
                              ).withValues(alpha: 0.5),
                              Color(
                                widget.achievement.tier.colorValue,
                              ).withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: widget.achievement.progress,
                          alignment: Alignment.centerRight,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(widget.achievement.tier.colorValue),
                                  Color(
                                    widget.achievement.tier.colorValue,
                                  ).withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                                color: isUnlocked
                                    ? (isDark
                                          ? AppTheme.darkTextColor
                                          : AppTheme.lightTextColor)
                                    : (isDark
                                          ? AppTheme.darkTextColor.withValues(
                                              alpha: 0.7,
                                            )
                                          : AppTheme.lightTextSecondary),
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

                // افکت درخشش برای دستاوردهای unlock شده
                if (isUnlocked) _buildShineEffect(),
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
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(widget.achievement.tier.colorValue),
                  Color(
                    widget.achievement.tier.colorValue,
                  ).withValues(alpha: 0.8),
                  Color(
                    widget.achievement.tier.colorValue,
                  ).withValues(alpha: 0.65),
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppTheme.darkGreySeparator,
                        AppTheme.darkGreySeparator.withValues(alpha: 0.75),
                      ]
                    : [
                        AppTheme.lightDividerColor,
                        AppTheme.lightDividerColor.withValues(alpha: 0.65),
                      ],
              ),
        border: isUnlocked
            ? Border.all(
                color: Color(
                  widget.achievement.tier.colorValue,
                ).withValues(alpha: 0.3),
                width: 1.5.w,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? Color(
                    widget.achievement.tier.colorValue,
                  ).withValues(alpha: 0.35)
                : AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.18),
            blurRadius: 14.r,
            offset: Offset(0.w, 3.h),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 10.r,
            offset: Offset(0.w, 2.h),
            spreadRadius: -1.r,
          ),
        ],
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
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(
                    widget.achievement.tier.colorValue,
                  ).withValues(alpha: 0.22),
                  Color(
                    widget.achievement.tier.colorValue,
                  ).withValues(alpha: 0.12),
                ],
              )
            : null,
        color: isUnlocked
            ? null
            : (isDark
                  ? AppTheme.darkGreySeparator
                  : AppTheme.lightDividerColor),
        borderRadius: BorderRadius.circular(9.r),
        border: isUnlocked
            ? Border.all(
                color: Color(
                  widget.achievement.tier.colorValue,
                ).withValues(alpha: 0.25),
                width: 1.w,
              )
            : null,
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: Color(
                    widget.achievement.tier.colorValue,
                  ).withValues(alpha: 0.15),
                  blurRadius: 8.r,
                  offset: Offset(0.w, 2.h),
                ),
              ]
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
                    ? AppTheme.darkTextColor.withValues(alpha: 0.6)
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
                  color: isDark
                      ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                      : AppTheme.lightTextSecondary,
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
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.55)
                  : AppTheme.lightTextSecondary.withValues(alpha: 0.75),
            ),
          ),
      ],
    );
  }

  Widget _buildShineEffect() {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return CustomPaint(
            painter: ShinePainter(
              progress: value,
              color: Color(widget.achievement.tier.colorValue),
            ),
          );
        },
      ),
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

class ShinePainter extends CustomPainter {
  ShinePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.3 || progress > 0.7) return;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final offset = size.width * (progress - 0.3) * 2.5;

    path.moveTo(offset - 50, 0);
    path.lineTo(offset, 0);
    path.lineTo(offset - 50, size.height);
    path.lineTo(offset - 100, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ShinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
