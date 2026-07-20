import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_plan_purchase_sheet.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_token_service.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// شیت ارتقا وقتی کاربر بدون اشتراک/توکن روی ساخت برنامه می‌زند.
Future<bool?> showWorkoutProgramAccessSheet(
  BuildContext context, {
  required WorkoutProgramAccess access,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WorkoutProgramAccessSheet(access: access),
  );
}

class WorkoutProgramAccessSheet extends StatelessWidget {
  const WorkoutProgramAccessSheet({required this.access, super.key});

  final WorkoutProgramAccess access;

  static const List<String> _benefits = <String>[
    'ساخت برنامه تمرینی شخصی با هوش مصنوعی',
    'تنظیم بر اساس هدف، تجهیزات و سطح تجربه',
    'فعال‌سازی خودکار در «تمرین امروز»',
    'ویرایش و بازبینی برنامه با مربی هوشمند',
    'تحلیل ریکاوری و گفتگوی مربی',
  ];

  @override
  Widget build(BuildContext context) {
    final isNoTokens = access.reason == WorkoutProgramAccessReason.noTokens;
    final title = isNoTokens
        ? 'توکن ساخت برنامه تموم شده'
        : 'برای ساخت برنامه اشتراک لازم است';
    final subtitle = isNoTokens
        ? 'با هر خرید پلن Coach Pro یا Ultimate AI یک توکن ساخت برنامه می‌گیری — بدون اشتراک رایگان در این بخش.'
        : 'این بخش رایگان نیست. با اشتراک مربی هوشمند، برنامه اختصاصی‌ات ساخته می‌شود و یک توکن اجرا داری.';

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
                      isNoTokens ? LucideIcons.ticket : LucideIcons.sparkles,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.gymTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.gymTextPrimary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: context.gymTextSecondary,
                  ),
                ),
                SizedBox(height: 22.h),
                Text(
                  'با اشتراک چه چیزی می‌گیری؟',
                  style: context.gymTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.gymTextPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                ..._benefits.map((b) => _BenefitRow(text: b)),
                SizedBox(height: 8.h),
                const _PlanHintCard(
                  plan: CoachSubscriptionPlan.coachPro,
                  note: 'شامل ساخت و ویرایش برنامه + بازبینی',
                ),
                SizedBox(height: 8.h),
                const _PlanHintCard(
                  plan: CoachSubscriptionPlan.ultimateAI,
                  note: 'همه قابلیت‌ها + تغذیه و استدلال پیشرفته',
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();
                    final purchased = await showCoachPlanPurchaseSheet(
                      context,
                      currentPlan: access.plan,
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
                    isNoTokens ? 'خرید توکن با پلن' : 'مشاهده پلن‌ها و خرید',
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

class _PlanHintCard extends StatelessWidget {
  const _PlanHintCard({required this.plan, required this.note});

  final CoachSubscriptionPlan plan;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.gymPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.gymPrimary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.crown, size: 16.sp, color: context.gymPrimary),
              SizedBox(width: GymSpacing.sm),
              Text(
                CoachPlanCatalog.persianTitle(plan),
                style: context.gymTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.gymTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '۱ توکن ساخت',
                style: context.gymTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.gymPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            note,
            style: context.gymTextStyle(
              fontSize: 12,
              color: context.gymTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
