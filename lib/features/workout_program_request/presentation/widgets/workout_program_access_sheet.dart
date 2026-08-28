import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_plan_purchase_sheet.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_token_service.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// شیت خرید وقتی کاربر بدون پاس فعال روی ساخت برنامه می‌زند.
Future<bool?> showWorkoutProgramAccessSheet(
  BuildContext context, {
  required WorkoutProgramAccess access,
  bool openProgramBuilderOnSuccess = true,
  String? returnTarget,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WorkoutProgramAccessSheet(
      access: access,
      openProgramBuilderOnSuccess: openProgramBuilderOnSuccess,
      returnTarget: returnTarget,
    ),
  );
}

class WorkoutProgramAccessSheet extends StatelessWidget {
  const WorkoutProgramAccessSheet({
    required this.access,
    this.openProgramBuilderOnSuccess = true,
    this.returnTarget,
    super.key,
  });

  final WorkoutProgramAccess access;
  final bool openProgramBuilderOnSuccess;
  final String? returnTarget;

  @override
  Widget build(BuildContext context) {
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
                      LucideIcons.clipboardList,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'پرداخت کن، بعد بساز',
                  textAlign: TextAlign.center,
                  style: context.gymTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.gymTextPrimary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  access.message ?? CoachPlanCatalog.productDescription,
                  textAlign: TextAlign.center,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: context.gymTextSecondary,
                  ),
                ),
                SizedBox(height: 22.h),
                Text(
                  'با خرید چه چیزی می‌گیری؟',
                  style: context.gymTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.gymTextPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                ...CoachPlanCatalog.productFeatures.map(
                  (b) => _BenefitRow(text: b),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: context.gymPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: context.gymPrimary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendarDays,
                        size: 18.sp,
                        color: context.gymPrimary,
                      ),
                      SizedBox(width: GymSpacing.sm),
                      Expanded(
                        child: Text(
                          '${CoachPlanCatalog.defaultValidityDays} روز دسترسی منعطف '
                          '— مثل خرید برنامه از مربی',
                          style: context.gymTextStyle(
                            fontSize: 13,
                            color: context.gymTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();
                    final purchased = await showCoachPlanPurchaseSheet(
                      context,
                      currentPlan: access.plan,
                      openProgramBuilderOnSuccess: openProgramBuilderOnSuccess,
                      returnTarget: returnTarget,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop(purchased ?? false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'خرید برنامه',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'بعداً',
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
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, size: 18.sp, color: context.gymPrimary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: context.gymTextStyle(
                fontSize: 13.5,
                color: context.gymTextPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
