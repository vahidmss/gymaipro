import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// کارت دستاورد — یک ردیف واضح: وضعیت، عنوان، پیشرفت، پاداش امتیاز.
class AchievementCard extends StatelessWidget {
  const AchievementCard({required this.achievement, super.key, this.onTap});

  final Achievement achievement;
  final VoidCallback? onTap;

  Color get _tierColor => Color(achievement.tier.colorValue);

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: unlocked
                  ? _tierColor.withValues(alpha: 0.45)
                  : context.separatorColor,
              width: unlocked ? 1.4.w : 1.w,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, unlocked ? 14.h : 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusGlyph(unlocked: unlocked, icon: achievement.icon),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                              height: 1.3,
                              color: context.textColor,
                            ),
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w400,
                              fontSize: 12.sp,
                              height: 1.35,
                              color: context.textSecondary,
                            ),
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _RewardChip(points: achievement.points, unlocked: unlocked),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    _TierChip(
                      label: achievement.tier.displayName,
                      color: _tierColor,
                      unlocked: unlocked,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: unlocked
                          ? Text(
                              achievement.unlockedAt != null
                                  ? 'باز شده · ${_timeAgo(achievement.unlockedAt!)}'
                                  : 'باز شده',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: _tierColor,
                              ),
                              textDirection: TextDirection.rtl,
                            )
                          : Text(
                              '${FormatUtils.toPersianDigits('${achievement.currentValue}')}/${FormatUtils.toPersianDigits('${achievement.targetValue}')} ${achievement.unit}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondary,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                    ),
                    if (!unlocked)
                      Text(
                        '${FormatUtils.toPersianDigits('${achievement.progressPercentage}')}٪',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (!unlocked) ...[
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 4.h,
                      backgroundColor: context.separatorColor,
                      valueColor: AlwaysStoppedAnimation(_tierColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inDays > 30) return '${d.inDays ~/ 30} ماه پیش';
    if (d.inDays > 0) return '${d.inDays} روز پیش';
    if (d.inHours > 0) return '${d.inHours} ساعت پیش';
    if (d.inMinutes > 0) return '${d.inMinutes} دقیقه پیش';
    return 'همین الان';
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.unlocked, required this.icon});

  final bool unlocked;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unlocked
            ? AppTheme.goldColor.withValues(alpha: 0.16)
            : context.separatorColor.withValues(alpha: 0.55),
      ),
      child: Center(
        child: unlocked
            ? Icon(LucideIcons.check, size: 22.sp, color: AppTheme.goldColor)
            : Text(icon, style: TextStyle(fontSize: 22.sp)),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.points, required this.unlocked});

  final int points;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: unlocked ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            GamificationLabels.pointsIcon,
            size: 14.sp,
            color: AppTheme.goldColor,
          ),
          SizedBox(height: 2.h),
          Text(
            '+${FormatUtils.toPersianDigits('$points')}',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 12.sp,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({
    required this.label,
    required this.color,
    required this.unlocked,
  });

  final String label;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: unlocked ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
