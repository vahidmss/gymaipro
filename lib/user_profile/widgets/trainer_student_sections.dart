import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// خلاصهٔ عملی شاگرد برای مربی — بدون متریک‌های گیمیفیکیشن مبهم.
class TrainerStudentOverviewCard extends StatelessWidget {
  const TrainerStudentOverviewCard({
    required this.activePrograms,
    required this.totalWorkouts,
    required this.totalMeals,
    required this.currentStreak,
    this.height,
    this.weight,
    this.fitnessGoals,
    this.lastLoginLabel,
    super.key,
  });

  final int activePrograms;
  final int totalWorkouts;
  final int totalMeals;
  final int currentStreak;
  final String? height;
  final String? weight;
  final String? fitnessGoals;
  final String? lastLoginLabel;

  bool get _hasProfileFacts =>
      (height != null && height!.isNotEmpty) ||
      (weight != null && weight!.isNotEmpty) ||
      (fitnessGoals != null && fitnessGoals!.isNotEmpty);

  bool get _hasAnyActivity =>
      activePrograms > 0 ||
      totalWorkouts > 0 ||
      totalMeals > 0 ||
      currentStreak > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'پرونده شاگرد',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          if (_hasProfileFacts) ...[
            SizedBox(height: 14.h),
            _ProfileFactGrid(
              height: height,
              weight: weight,
              fitnessGoals: fitnessGoals,
            ),
          ],
          SizedBox(height: 14.h),
          Text(
            'ثبت فعالیت',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _ActivityStat(
                  label: 'برنامه فعال',
                  value: FormatUtils.formatNumber(activePrograms),
                  icon: LucideIcons.clipboardList,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ActivityStat(
                  label: 'تمرین ثبت‌شده',
                  value: FormatUtils.formatNumber(totalWorkouts),
                  icon: LucideIcons.dumbbell,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ActivityStat(
                  label: 'وعده ثبت‌شده',
                  value: FormatUtils.formatNumber(totalMeals),
                  icon: LucideIcons.utensils,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _EngagementRow(
            currentStreak: currentStreak,
            lastLoginLabel: lastLoginLabel,
          ),
          if (!_hasProfileFacts && !_hasAnyActivity) ...[
            SizedBox(height: 12.h),
            Text(
              'هنوز اطلاعات یا فعالیت ثبت‌شده‌ای برای این شاگرد دیده نمی‌شود.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                color: context.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileFactGrid extends StatelessWidget {
  const _ProfileFactGrid({
    this.height,
    this.weight,
    this.fitnessGoals,
  });

  final String? height;
  final String? weight;
  final String? fitnessGoals;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (height != null || weight != null)
          Row(
            children: [
              if (height != null)
                Expanded(
                  child: _ProfileFactTile(
                    label: 'قد',
                    value: height!,
                    icon: LucideIcons.ruler,
                  ),
                ),
              if (height != null && weight != null) SizedBox(width: 8.w),
              if (weight != null)
                Expanded(
                  child: _ProfileFactTile(
                    label: 'وزن',
                    value: weight!,
                    icon: LucideIcons.scale,
                  ),
                ),
            ],
          ),
        if (fitnessGoals != null && fitnessGoals!.isNotEmpty) ...[
          if (height != null || weight != null) SizedBox(height: 8.h),
          _ProfileFactTile(
            label: 'هدف',
            value: fitnessGoals!,
            icon: LucideIcons.target,
            fullWidth: true,
          ),
        ],
      ],
    );
  }
}

class _ProfileFactTile extends StatelessWidget {
  const _ProfileFactTile({
    required this.label,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: AppTheme.goldColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.sp,
                    color: context.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                    height: 1.3,
                  ),
                  maxLines: fullWidth ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: context.separatorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15.sp, color: context.textSecondary),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9.sp,
              color: context.textSecondary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({
    required this.currentStreak,
    this.lastLoginLabel,
  });

  final int currentStreak;
  final String? lastLoginLabel;

  @override
  Widget build(BuildContext context) {
    final streakText = currentStreak > 0
        ? '${FormatUtils.formatNumber(currentStreak)} روز پشت‌سرهم'
        : 'بدون پیوستگی فعلی';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.flame, size: 15.sp, color: AppTheme.goldColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'پیوستگی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.sp,
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  streakText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          if (lastLoginLabel != null && lastLoginLabel!.isNotEmpty) ...[
            Container(
              width: 1,
              height: 28.h,
              color: context.separatorColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'آخرین ورود',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10.sp,
                      color: context.textSecondary,
                    ),
                  ),
                  Text(
                    lastLoginLabel!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// کارت اطلاعات محرمانه — فشرده وقتی قفل است، غنی وقتی تایید شده.
class TrainerConfidentialSection extends StatelessWidget {
  const TrainerConfidentialSection({
    required this.hasConsented,
    this.confidentialData,
    super.key,
  });

  final bool hasConsented;
  final Map<String, dynamic>? confidentialData;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs =
        (confidentialData?['lifestyle_preferences'] as Map<String, dynamic>?) ??
        {};

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.goldColor.withValues(alpha: 0.12),
                  AppTheme.goldColor.withValues(alpha: 0.04),
                ]
              : [
                  AppTheme.goldColor.withValues(alpha: 0.08),
                  context.cardColor,
                ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  hasConsented ? LucideIcons.shieldCheck : LucideIcons.shield,
                  color: AppTheme.goldColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اطلاعات محرمانه',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      hasConsented
                          ? 'با تایید شاگرد، فقط برای شما قابل مشاهده است.'
                          : 'شاگرد هنوز دسترسی را تایید نکرده.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        color: hasConsented
                            ? AppTheme.goldColor
                            : context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: hasConsented
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                      : context.separatorColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  hasConsented ? 'فعال' : 'در انتظار',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: hasConsented
                        ? const Color(0xFF2E7D32)
                        : context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (!hasConsented) ...[
            SizedBox(height: 12.h),
            Text(
              'سلامت، دارو، آلرژی و جزئیات سبک زندگی بعد از تایید شاگرد اینجا نمایش داده می‌شود.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                color: context.textSecondary,
                height: 1.45,
              ),
            ),
          ] else ...[
            SizedBox(height: 14.h),
            _ConfidentialGroup(
              icon: LucideIcons.heart,
              title: 'سلامت',
              entries: [
                _entry('شرایط پزشکی', prefs['medical_conditions']),
                _entry('داروها', prefs['medications']),
                _entry('آلرژی‌ها', prefs['allergies']),
                _entry('تماس اضطراری', prefs['emergency_contact']),
                _entry('یادداشت', prefs['health_notes']),
              ],
            ),
            SizedBox(height: 10.h),
            _ConfidentialGroup(
              icon: LucideIcons.target,
              title: 'اهداف',
              entries: [
                _entry('اهداف اصلی', prefs['primary_goals']),
                _entry('اهداف فرعی', prefs['secondary_goals']),
                _entry('وزن هدف', prefs['target_weight']),
                _entry('چربی هدف', prefs['target_body_fat']),
                _entry('انگیزه', prefs['motivation']),
              ],
            ),
            SizedBox(height: 10.h),
            _ConfidentialGroup(
              icon: LucideIcons.moon,
              title: 'سبک زندگی',
              entries: [
                _entry('خواب', prefs['sleep_pattern']),
                _entry('شرایط زندگی', prefs['life_conditions']),
                _entry('ترجیحات غذایی', prefs['food_preferences']),
                _entry('سایر', prefs['additional_info']),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static MapEntry<String, String>? _entry(String label, dynamic value) {
    final text = _formatValue(value);
    if (text.isEmpty) return null;
    return MapEntry(label, text);
  }

  static String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join('، ');
    }
    return value.toString().trim();
  }
}

class _ConfidentialGroup extends StatelessWidget {
  const _ConfidentialGroup({
    required this.icon,
    required this.title,
    required this.entries,
  });

  final IconData icon;
  final String title;
  final List<MapEntry<String, String>?> entries;

  @override
  Widget build(BuildContext context) {
    final visible = entries.whereType<MapEntry<String, String>>().toList();
    if (visible.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.cardColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.separatorColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: AppTheme.goldColor),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '$title — ثبت نشده',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: AppTheme.goldColor),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...visible.map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96.w,
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
