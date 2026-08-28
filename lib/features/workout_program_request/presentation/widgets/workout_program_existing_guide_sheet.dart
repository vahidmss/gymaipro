import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// What the user chose after we blocked a duplicate program request.
enum WorkoutProgramExistingAction {
  modify,
  today,
  programs,
  buildNew,
  dismiss,
}

/// Shown when the athlete already has a Coach AI workout program.
Future<WorkoutProgramExistingAction?> showWorkoutProgramExistingGuideSheet(
  BuildContext context, {
  required ActiveProgramOption? activeAiProgram,
  required int aiProgramCount,
}) {
  return showModalBottomSheet<WorkoutProgramExistingAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WorkoutProgramExistingGuideSheet(
      activeAiProgram: activeAiProgram,
      aiProgramCount: aiProgramCount,
    ),
  );
}

class WorkoutProgramExistingGuideSheet extends StatelessWidget {
  const WorkoutProgramExistingGuideSheet({
    required this.activeAiProgram,
    required this.aiProgramCount,
    super.key,
  });

  final ActiveProgramOption? activeAiProgram;
  final int aiProgramCount;

  @override
  Widget build(BuildContext context) {
    final title = activeAiProgram?.title;
    final body = title != null && title.isNotEmpty
        ? 'برنامه «$title» برات آماده است. دیگه لازم نیست از اول درخواست بدی — '
            'می‌تونی اصلاحش کنی، تمرین امروزت رو ببینی، یا اگر واقعاً لازم شد برنامهٔ جدید بسازی.'
        : 'برنامه مربی هوشمندت آماده‌ست. دیگه لازم نیست از اول درخواست بدی — '
            'می‌تونی اصلاحش کنی، تمرین امروزت رو ببینی، یا اگر واقعاً لازم شد برنامهٔ جدید بسازی.';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.gymCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 22.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.gymTextSecondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.gymPrimary.withValues(alpha: 0.9),
                          AppTheme.goldColor.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: Icon(
                      LucideIcons.circleCheck,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  ProductCopy.existingAiProgramTitle,
                  textAlign: TextAlign.center,
                  style: context.gymTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.gymTextPrimary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: context.gymTextSecondary,
                  ),
                ),
                if (aiProgramCount > 1) ...[
                  SizedBox(height: 10.h),
                  Text(
                    '$aiProgramCount برنامه هوش مصنوعی داری — می‌تونی بینشون جابه‌جا شی.',
                    textAlign: TextAlign.center,
                    style: context.gymTextStyle(
                      fontSize: 13,
                      color: context.gymTextSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 22.h),
                _GuideActionTile(
                  icon: LucideIcons.pencil,
                  title: ProductCopy.modifyProgramTitle,
                  subtitle: ProductCopy.existingAiProgramModifyHint,
                  emphasized: true,
                  onTap: () => _pop(context, WorkoutProgramExistingAction.modify),
                ),
                SizedBox(height: 10.h),
                _GuideActionTile(
                  icon: LucideIcons.calendarDays,
                  title: ProductCopy.goToTodayWorkout,
                  subtitle: ProductCopy.existingAiProgramTodayHint,
                  onTap: () => _pop(context, WorkoutProgramExistingAction.today),
                ),
                SizedBox(height: 10.h),
                _GuideActionTile(
                  icon: LucideIcons.layoutList,
                  title: ProductCopy.existingAiProgramProgramsCta,
                  subtitle: ProductCopy.existingAiProgramProgramsHint,
                  onTap: () =>
                      _pop(context, WorkoutProgramExistingAction.programs),
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () =>
                      _pop(context, WorkoutProgramExistingAction.buildNew),
                  child: Text(
                    ProductCopy.existingAiProgramBuildNewCta,
                    style: context.gymTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.gymTextSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _pop(context, WorkoutProgramExistingAction.dismiss),
                  child: Text(
                    'باشه',
                    style: context.gymTextStyle(
                      fontSize: 14,
                      color: context.gymTextSecondary,
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

  void _pop(BuildContext context, WorkoutProgramExistingAction action) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(action);
  }
}

class _GuideActionTile extends StatelessWidget {
  const _GuideActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized
          ? context.gymPrimary.withValues(alpha: 0.1)
          : context.gymIsDark
          ? context.gymElevated
          : Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: emphasized
                  ? context.gymPrimary.withValues(alpha: 0.35)
                  : context.gymBorderSubtle,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.gymPrimary.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: context.gymPrimary, size: 20.sp),
              ),
              SizedBox(width: GymSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.gymTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.gymTextPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: context.gymTextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: context.gymTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronLeft,
                size: 18.sp,
                color: context.gymTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
