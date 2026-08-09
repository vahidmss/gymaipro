import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// خلاصهٔ سادهٔ ست‌های ثبت‌شدهٔ همین روز — از آیکون دفترچه.
class WorkoutLogSummarySheet extends StatelessWidget {
  const WorkoutLogSummarySheet({
    required this.viewModel,
    required this.dateTime,
    super.key,
  });

  final WorkoutLogViewModel viewModel;
  final DateTime dateTime;

  static Future<void> show(
    BuildContext context, {
    required WorkoutLogViewModel viewModel,
    required DateTime dateTime,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutLogSummarySheet(
        viewModel: viewModel,
        dateTime: dateTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateString = MealLogUtils.getPersianFormattedDate(dateTime);
    final rows = _buildRows(context);
    final sessionDay = viewModel.selectedSession?.day;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16.w,
          0,
          16.w,
          12.h + MediaQuery.paddingOf(context).bottom,
        ),
        child: Material(
          color: WorkoutLogColors.sectionBackground(context),
          borderRadius: BorderRadius.circular(18.r),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 10.w, 10.h),
                  child: Row(
                    children: [
                      Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.notebookText,
                          size: 18.sp,
                          color: AppTheme.goldColor,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خلاصه ثبت',
                              style: WorkoutLogTypography.sectionTitle(context)
                                  .copyWith(fontSize: 15.sp),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              sessionDay != null && sessionDay.isNotEmpty
                                  ? '$dateString · $sessionDay'
                                  : dateString,
                              style: WorkoutLogTypography.caption(
                                context,
                                color: WorkoutLogColors.mutedText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          LucideIcons.x,
                          size: 18.sp,
                          color: WorkoutLogColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: WorkoutLogColors.inputBorder(context),
                ),
                if (rows.isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 32.h),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.circleDashed,
                          size: 28.sp,
                          color: WorkoutLogColors.mutedText(context),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'هنوز ستی ثبت نشده',
                          style: WorkoutLogTypography.sectionTitle(context)
                              .copyWith(fontSize: 14.sp),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'با تیک زدن ست‌ها، خلاصه اینجا می‌آید.',
                          style: WorkoutLogTypography.caption(
                            context,
                            color: WorkoutLogColors.mutedText(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => SizedBox(height: 14.h),
                      itemBuilder: (context, i) => rows[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    final session = viewModel.selectedSession;
    if (session == null) return const [];

    final out = <Widget>[];
    for (final exercise in session.exercises) {
      if (exercise is NormalExercise) {
        final id = exercise.exerciseId.toString();
        final row = _exerciseBlock(
          context,
          name: viewModel.exerciseDetails[exercise.exerciseId]?.name ??
              (exercise.tag.isNotEmpty ? exercise.tag : 'تمرین'),
          style: exercise.style,
          controllers: viewModel.exerciseControllers[id],
          saved: viewModel.setSavedStatus[id],
        );
        if (row != null) out.add(row);
      } else if (exercise is SupersetExercise) {
        for (final item in exercise.exercises) {
          final id = '${exercise.id}_${item.exerciseId}';
          final row = _exerciseBlock(
            context,
            name: viewModel.exerciseDetails[item.exerciseId]?.name ??
                (exercise.tag.isNotEmpty ? exercise.tag : 'تمرین'),
            style: item.style,
            controllers: viewModel.exerciseControllers[id],
            saved: viewModel.setSavedStatus[id],
            badge: 'سوپر',
          );
          if (row != null) out.add(row);
        }
      }
    }
    return out;
  }

  Widget? _exerciseBlock(
    BuildContext context, {
    required String name,
    required ExerciseStyle style,
    required List<Map<String, TextEditingController>>? controllers,
    required List<bool>? saved,
    String? badge,
  }) {
    if (controllers == null || saved == null) return null;

    final lines = <String>[];
    for (var i = 0; i < controllers.length; i++) {
      if (i >= saved.length || !saved[i]) continue;
      final c = controllers[i];
      final reps = c['reps']?.text.trim() ?? '';
      final weight = c['weight']?.text.trim() ?? '';
      final time = c['time']?.text.trim() ?? '';
      final rpe = c['rpe']?.text.trim() ?? '';

      String body;
      if (style == ExerciseStyle.setsTime) {
        if (time.isEmpty) continue;
        body = '$time ث';
      } else {
        if (reps.isEmpty && weight.isEmpty) continue;
        if (weight.isEmpty) {
          body = reps;
        } else if (reps.isEmpty) {
          body = '${_fmtWeight(weight)} کیلو';
        } else {
          body = '\u200E$reps\u00D7${_fmtWeight(weight)}';
        }
      }
      if (rpe.isNotEmpty) body = '$body · RPE $rpe';
      lines.add('${MealLogUtils.convertToPersianNumbers('${i + 1}')}.  $body');
    }
    if (lines.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: WorkoutLogTypography.exerciseTitle(context).copyWith(
                  fontSize: 13.5.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: WorkoutLogColors.chipFill(context, selected: false),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  badge,
                  style: WorkoutLogTypography.caption(
                    context,
                    color: WorkoutLogColors.mutedText(context),
                    fontWeight: FontWeight.w800,
                  ).copyWith(fontSize: 10.sp),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        for (final line in lines)
          Padding(
            padding: EdgeInsets.only(bottom: 3.h),
            child: Text(
              line,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: WorkoutLogColors.secondaryText(context),
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }

  static String _fmtWeight(String raw) {
    final d = double.tryParse(raw);
    if (d == null) return raw;
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toString();
  }
}
