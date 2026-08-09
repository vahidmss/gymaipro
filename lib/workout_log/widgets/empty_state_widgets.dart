import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmptyStateWidgets {
  static Widget noActiveProgram(
    BuildContext context, {
    VoidCallback? onStarterProgramTap,
    bool isInstallingStarter = false,
    bool hasStarterProgram = false,
    bool needsStarterUpgrade = false,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StatusHeader(),
          SizedBox(height: 18.h),
          const _FlowSteps(),
          if (onStarterProgramTap != null) ...[
            SizedBox(height: 18.h),
            _PrimaryStarterCard(
              onTap: onStarterProgramTap,
              isLoading: isInstallingStarter,
              alreadyInstalled: hasStarterProgram,
              needsUpgrade: needsStarterUpgrade,
            ),
          ],
          SizedBox(height: 22.h),
          Text(
            'مسیرهای دیگر',
            style: WorkoutLogTypography.caption(
              context,
              color: WorkoutLogColors.mutedText(context),
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          _SecondaryPath(
            icon: LucideIcons.listChecks,
            title: 'برنامه‌های من',
            description: 'اگر برنامه ذخیره دارید، اینجا فعالش کنید',
            onTap: () => Navigator.pushNamed(
              context,
              '/my-club',
              arguments: {'initialTab': 0},
            ),
          ),
          SizedBox(height: 8.h),
          _SecondaryPath(
            icon: LucideIcons.bot,
            title: 'ساخت با هوش مصنوعی',
            description: 'برنامه شخصی بر اساس اطلاعات شما',
            onTap: () => Navigator.pushNamed(context, '/ai-programs'),
          ),
          SizedBox(height: 8.h),
          _SecondaryPath(
            icon: LucideIcons.messageCircle,
            title: 'درخواست از مربی',
            description: 'برنامه اختصاصی با نظارت مربی',
            onTap: () => Navigator.pushNamed(context, '/trainer-ranking'),
          ),
        ],
      ),
    );
  }

  static Widget noSessionSelected() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: Container(
            padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 16.h),
            decoration: BoxDecoration(
              color: WorkoutLogColors.sectionBackground(context),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: WorkoutLogColors.inputBorder(context),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.hand,
                  color: WorkoutLogColors.accent(context),
                  size: 24.sp,
                ),
                SizedBox(height: 10.h),
                Text(
                  'یک جلسه انتخاب کنید',
                  style: WorkoutLogTypography.sectionTitle(context).copyWith(
                    fontSize: 15.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'از بالای صفحه یک جلسه برای این تاریخ انتخاب کنید و ثبت را شروع کنید.',
                  style: WorkoutLogTypography.caption(context).copyWith(
                    fontSize: 12.5.sp,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget noExercisesInSession() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: WorkoutLogColors.sectionBackground(context),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: WorkoutLogColors.inputBorder(context),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: WorkoutLogColors.chipFill(context, selected: false),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    LucideIcons.dumbbell,
                    color: WorkoutLogColors.mutedText(context),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تمرینی در این جلسه نیست',
                        style: WorkoutLogTypography.sectionTitle(context),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'جلسهٔ دیگری را انتخاب کنید یا برنامه را از «برنامه‌های من» ویرایش کنید.',
                        style: WorkoutLogTypography.caption(context).copyWith(
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'برای ثبت تمرین، یک برنامه فعال کنید',
          style: WorkoutLogTypography.sectionTitle(context).copyWith(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'اول برنامه، بعد جلسه، بعد ثبت. مسیر سریع پایین همین صفحه است.',
          style: WorkoutLogTypography.caption(
            context,
            color: WorkoutLogColors.mutedText(context),
          ).copyWith(fontSize: 13.sp, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FlowSteps extends StatelessWidget {
  const _FlowSteps();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: WorkoutLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: WorkoutLogColors.inputBorder(context)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _FlowStep(
              index: '۱',
              label: 'برنامه',
              icon: LucideIcons.clipboardList,
            ),
          ),
          Icon(
            LucideIcons.chevronLeft,
            size: 14.sp,
            color: WorkoutLogColors.mutedText(context),
          ),
          const Expanded(
            child: _FlowStep(
              index: '۲',
              label: 'جلسه',
              icon: LucideIcons.calendarDays,
            ),
          ),
          Icon(
            LucideIcons.chevronLeft,
            size: 14.sp,
            color: WorkoutLogColors.mutedText(context),
          ),
          const Expanded(
            child: _FlowStep(
              index: '۳',
              label: 'ثبت',
              icon: LucideIcons.check,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.index,
    required this.label,
    required this.icon,
  });

  final String index;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: WorkoutLogColors.chipFill(context, selected: true),
            shape: BoxShape.circle,
            border: Border.all(
              color: WorkoutLogColors.accent(context).withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            icon,
            size: 16.sp,
            color: WorkoutLogColors.iconOnSurface(context),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          '$index. $label',
          style: WorkoutLogTypography.caption(
            context,
            fontWeight: FontWeight.w700,
          ).copyWith(fontSize: 11.sp),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PrimaryStarterCard extends StatelessWidget {
  const _PrimaryStarterCard({
    required this.onTap,
    required this.isLoading,
    required this.alreadyInstalled,
    required this.needsUpgrade,
  });

  final VoidCallback onTap;
  final bool isLoading;
  final bool alreadyInstalled;
  final bool needsUpgrade;

  @override
  Widget build(BuildContext context) {
    final accent = WorkoutLogColors.successSolid(context);
    final title = needsUpgrade
        ? 'به‌روزرسانی شروع باشگاه'
        : alreadyInstalled
        ? 'فعال‌سازی شروع باشگاه'
        : 'شروع باشگاه — رایگان';
    final body = needsUpgrade
        ? 'نسخهٔ جدید آماده است. یک‌بار بزنید تا به‌روز شود.'
        : alreadyInstalled
        ? 'برنامهٔ مبتدی آماده‌ست. فعال کنید و جلسه را انتخاب کنید.'
        : 'چرخهٔ ۳ جلسه‌ای قابل تکرار · حرکات دستگاه · مناسب تازه‌واردها';
    final cta = needsUpgrade
        ? 'به‌روزرسانی و ادامه'
        : alreadyInstalled
        ? 'فعال‌سازی و شروع'
        : 'دریافت و شروع فوری';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            color: WorkoutLogColors.successBackground(context),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: WorkoutLogColors.successBorder(context),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: isLoading
                          ? Padding(
                              padding: EdgeInsets.all(10.w),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: accent,
                              ),
                            )
                          : Icon(LucideIcons.gift, color: accent, size: 20.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: WorkoutLogTypography.sectionTitle(
                              context,
                            ).copyWith(fontSize: 15.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            body,
                            style: WorkoutLogTypography.caption(context)
                                .copyWith(fontSize: 12.5.sp, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoChip(label: '۳ جلسه'),
                    _InfoChip(label: 'مبتدی'),
                    _InfoChip(label: 'دستگاه'),
                  ],
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  height: 46.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        cta,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.white,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: WorkoutLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: WorkoutLogColors.successBorder(context).withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        label,
        style: WorkoutLogTypography.caption(
          context,
          color: WorkoutLogColors.successText(context),
          fontWeight: FontWeight.w800,
        ).copyWith(fontSize: 11.sp),
      ),
    );
  }
}

class _SecondaryPath extends StatelessWidget {
  const _SecondaryPath({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          decoration: BoxDecoration(
            color: WorkoutLogColors.sectionBackground(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: WorkoutLogColors.inputBorder(context)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: WorkoutLogColors.chipFill(context, selected: false),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    size: 17.sp,
                    color: WorkoutLogColors.iconOnSurface(context),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: WorkoutLogTypography.sectionTitle(context)
                            .copyWith(fontSize: 13.5.sp),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        description,
                        style: WorkoutLogTypography.caption(context).copyWith(
                          fontSize: 11.5.sp,
                          height: 1.35,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronLeft,
                  size: 16.sp,
                  color: WorkoutLogColors.mutedText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
