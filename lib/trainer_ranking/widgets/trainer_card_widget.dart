import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:gymaipro/widgets/gymai_trainer_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// کارت مربی در لیست کشف — امتیاز واقعی؛ بدون حس سکوی قهرمانی.
class TrainerCardWidget extends StatelessWidget {
  const TrainerCardWidget({
    required this.trainer,
    required this.onTap,
    required this.position,
    super.key,
    this.compact = false,
    this.discoveryMode = false,
    this.emphasizeRecommended = false,
  });

  final UserProfile trainer;
  final VoidCallback onTap;
  final int position;
  final bool compact;
  final bool discoveryMode;
  final bool emphasizeRecommended;

  Color? get _accent {
    if (!discoveryMode) {
      if (position == 1) return const Color(0xFFFFD700);
      if (position == 2) return const Color(0xFFC0C0C0);
      if (position == 3) return const Color(0xFFCD7F32);
      return null;
    }
    if (emphasizeRecommended) {
      return AppTheme.goldColor.withValues(alpha: 0.85);
    }
    return null;
  }

  String get _displayName =>
      trainer.fullName.isNotEmpty ? trainer.fullName : trainer.username;

  String get _heroTag => 'trainer_${trainer.id}_${trainer.username}';

  int get _reviews => trainer.reviewCount ?? 0;
  double get _rating => trainer.rating ?? 0;
  int get _students => trainer.studentCount ?? 0;
  int get _years => trainer.experienceYears ?? 0;

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final bg = accent != null
        ? accent.withValues(alpha: discoveryMode ? 0.08 : 0.12)
        : context.cardColor;
    final border = accent != null
        ? accent.withValues(alpha: discoveryMode ? 0.35 : 0.45)
        : context.separatorColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: border,
                width: accent != null ? 1.3 : 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _IndexBadge(
                  index: position,
                  discoveryMode: discoveryMode,
                  emphasize: emphasizeRecommended,
                ),
                SizedBox(width: 10.w),
                _Avatar(
                  heroTag: _heroTag,
                  trainer: trainer,
                  isOnline: trainer.isEffectivelyOnline,
                  accent: accent ?? AppTheme.goldColor,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              _displayName,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: compact ? 13.sp : 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: context.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          if (trainer.isGymOwner ?? false) ...[
                            SizedBox(width: 6.w),
                            const _MetaChip(
                              label: 'باشگاه',
                              color: AppTheme.goldColor,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 5.h),
                      _RatingLine(
                        rating: _rating,
                        reviews: _reviews,
                      ),
                      if (!compact) ...[
                        SizedBox(height: 6.h),
                        _StatsLine(
                          students: _students,
                          years: _years,
                          specs: trainer.specializations,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      FormatUtils.toPersianDigits(
                        '${trainer.trainerScore ?? 0}',
                      ),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: context.textColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'امتیاز',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4.w),
                Icon(
                  LucideIcons.chevronLeft,
                  size: 16.sp,
                  color: context.textSecondary.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({
    required this.index,
    required this.discoveryMode,
    required this.emphasize,
  });

  final int index;
  final bool discoveryMode;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    if (discoveryMode) {
      return Container(
        width: 36.w,
        height: 36.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: emphasize
              ? AppTheme.goldColor.withValues(alpha: 0.18)
              : context.separatorColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10.r),
          border: emphasize
              ? Border.all(color: AppTheme.goldColor.withValues(alpha: 0.45))
              : null,
        ),
        child: Text(
          FormatUtils.toPersianDigits('$index'),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: emphasize ? AppTheme.goldColor : context.textColor,
          ),
        ),
      );
    }

    final Color bg;
    final Color fg;
    final String? medal;
    if (index == 1) {
      bg = const Color(0xFFFFD700);
      fg = const Color(0xFF1A1A1A);
      medal = '🥇';
    } else if (index == 2) {
      bg = const Color(0xFFC0C0C0);
      fg = const Color(0xFF1A1A1A);
      medal = '🥈';
    } else if (index == 3) {
      bg = const Color(0xFFCD7F32);
      fg = Colors.white;
      medal = '🥉';
    } else {
      bg = context.separatorColor;
      fg = context.textColor;
      medal = null;
    }

    return Container(
      width: 40.w,
      height: 40.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: medal != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(medal, style: TextStyle(fontSize: 11.sp, height: 1)),
                Text(
                  FormatUtils.toPersianDigits('$index'),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: fg,
                    height: 1.1,
                  ),
                ),
              ],
            )
          : Text(
              FormatUtils.toPersianDigits('$index'),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.heroTag,
    required this.trainer,
    required this.isOnline,
    required this.accent,
  });

  final String heroTag;
  final UserProfile trainer;
  final bool isOnline;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final name =
        trainer.fullName.isNotEmpty ? trainer.fullName : trainer.username;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCodes(trimmed.runes.take(1));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
          tag: heroTag,
          child: Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.6),
            ),
            clipBehavior: Clip.antiAlias,
            child: GymaiTrainerAvatar(
              size: 52.w,
              avatarUrl: trainer.avatarUrl,
              userId: trainer.id,
              username: trainer.username,
              firstName: trainer.firstName,
              lastName: trainer.lastName,
              clipOval: false,
              fallback: _Fallback(initial: initial, accent: accent),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 1.h,
            left: 1.w,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: context.cardColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.initial, required this.accent});

  final String initial;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: accent.withValues(alpha: 0.18),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.rating, required this.reviews});

  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews <= 0) {
      return Text(
        'هنوز نظری ثبت نشده',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11.5.sp,
          color: context.textSecondary,
        ),
        textDirection: TextDirection.rtl,
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(LucideIcons.star, size: 13.sp, color: AppTheme.goldColor),
        SizedBox(width: 4.w),
        Text(
          FormatUtils.toPersianDigits(rating.toStringAsFixed(1)),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
            color: AppTheme.goldColor,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          '(${FormatUtils.toPersianDigits('$reviews')} نظر)',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.sp,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatsLine extends StatelessWidget {
  const _StatsLine({
    required this.students,
    required this.years,
    required this.specs,
  });

  final int students;
  final int years;
  final List<String>? specs;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (students > 0) {
      chips.add(
        _MetaChip(
          icon: LucideIcons.users,
          label: '${FormatUtils.toPersianDigits('$students')} شاگرد',
        ),
      );
    }
    if (years > 0) {
      chips.add(
        _MetaChip(
          icon: LucideIcons.clock,
          label: '${FormatUtils.toPersianDigits('$years')} سال',
        ),
      );
    }
    if (specs != null && specs!.isNotEmpty) {
      chips.add(_MetaChip(label: specs!.first));
    }

    if (chips.isEmpty) {
      return Text(
        'پروفایل در حال تکمیل',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11.sp,
          color: context.textSecondary,
        ),
        textDirection: TextDirection.rtl,
      );
    }

    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      textDirection: TextDirection.rtl,
      children: chips,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: (color ?? context.separatorColor).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8.r),
        border: color != null
            ? Border.all(color: color!.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.sp, color: c),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
