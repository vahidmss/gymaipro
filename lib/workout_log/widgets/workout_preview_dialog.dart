import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutPreviewDialog extends StatelessWidget {
  const WorkoutPreviewDialog({
    required this.viewModel,
    required this.dateTime,
    super.key,
  });

  final WorkoutLogViewModel viewModel;
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateString = MealLogUtils.getPersianFormattedDate(dateTime);
    final previewData = _getPreviewData(context);

    if (previewData.isEmpty) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.25 : 0.2),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 24.r,
                offset: Offset(0.w, 8.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'پیش‌نمایش تمرین',
                style: WorkoutLogTypography.dialogTitle(context),
              ),
              SizedBox(height: 12.h),
              Text(
                'هنوز داده‌ای وارد نشده است',
                style: WorkoutLogTypography.dialogMuted(context),
              ),
              SizedBox(height: 20.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                ),
                child: Text(
                  'بستن',
                  style: WorkoutLogTypography.chip(context, selected: true),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.25 : 0.2),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24.r,
              offset: Offset(0.w, 8.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - مینیمال
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'پیش‌نمایش تمرین',
                          style: WorkoutLogTypography.dialogTitle(context),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          dateString,
                          style: WorkoutLogTypography.dialogMuted(context).copyWith(
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          LucideIcons.x,
                          color: WorkoutLogColors.secondaryText(context),
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content - مینیمال
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (viewModel.selectedSession != null) ...[
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          'روز: ${viewModel.selectedSession!.day}',
                          style: WorkoutLogTypography.sectionTitle(context).copyWith(
                            fontSize: 13.sp,
                            color: WorkoutLogColors.primaryText(context),
                          ),
                        ),
                      ),
                    ],
                    ...previewData,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getPreviewData(BuildContext context) {
    final widgets = <Widget>[];
    final controllers = viewModel.exerciseControllers;
    final exerciseDetails = viewModel.exerciseDetails;
    final selectedSession = viewModel.selectedSession;

    if (selectedSession == null) return widgets;

    for (final exercise in selectedSession.exercises) {
      if (exercise is NormalExercise) {
        final exerciseId = exercise.exerciseId.toString();
        final exerciseData = controllers[exerciseId];
        final exerciseDetail = exerciseDetails[exercise.exerciseId];

        if (exerciseData == null) continue;

        final hasData = exerciseData.any((setControllers) {
          final weight = setControllers['weight']?.text.trim() ?? '';
          final reps = setControllers['reps']?.text.trim() ?? '';
          final time = setControllers['time']?.text.trim() ?? '';
          return weight.isNotEmpty || reps.isNotEmpty || time.isNotEmpty;
        });

        if (!hasData) continue;

        widgets.add(
          _buildExercisePreview(
            context,
            exerciseDetail?.name ??
                (exercise.tag.isNotEmpty ? exercise.tag : 'تمرین'),
            exercise,
            exerciseData,
          ),
        );
      } else if (exercise is SupersetExercise) {
        for (final item in exercise.exercises) {
          final itemId = '${exercise.id}_${item.exerciseId}';
          final itemData = controllers[itemId];
          final itemDetail = exerciseDetails[item.exerciseId];

          if (itemData == null) continue;

          final hasData = itemData.any((setControllers) {
            final weight = setControllers['weight']?.text.trim() ?? '';
            final reps = setControllers['reps']?.text.trim() ?? '';
            final time = setControllers['time']?.text.trim() ?? '';
            return weight.isNotEmpty || reps.isNotEmpty || time.isNotEmpty;
          });

          if (!hasData) continue;

          widgets.add(
            _buildExercisePreview(
              context,
              itemDetail?.name ??
                  (exercise.tag.isNotEmpty ? exercise.tag : 'تمرین'),
              item,
              itemData,
              isSuperset: true,
            ),
          );
        }
      }
    }

    return widgets;
  }

  Widget _buildExercisePreview(
    BuildContext context,
    String exerciseName,
    dynamic exercise,
    List<Map<String, TextEditingController>> exerciseData, {
    bool isSuperset = false,
  }) {
    final sets = <Widget>[];
    final exerciseSets = exercise is NormalExercise
        ? exercise.sets
        : exercise is SupersetExercise
        ? exercise.exercises.first.sets
        : (exercise as SupersetItem).sets;

    for (int i = 0; i < exerciseData.length && i < exerciseSets.length; i++) {
      final setControllers = exerciseData[i];
      final weight = setControllers['weight']?.text.trim() ?? '';
      final reps = setControllers['reps']?.text.trim() ?? '';
      final time = setControllers['time']?.text.trim() ?? '';

      if (weight.isEmpty && reps.isEmpty && time.isEmpty) continue;

      final style = exercise.style;
      sets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // شماره ست - مینیمال
              Container(
                width: 24.w,
                height: 24.h,
                margin: EdgeInsets.only(top: 2.h),
                decoration: BoxDecoration(
                  color: WorkoutLogColors.chipFill(context, selected: true),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: WorkoutLogTypography.caption(
                      context,
                      color: WorkoutLogColors.primaryText(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (style == ExerciseStyle.setsReps) ...[
                      if (reps.isNotEmpty) ...[
                        Expanded(child: _buildDataItem(context, 'تکرار', reps)),
                      ],
                      if (weight.isNotEmpty) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDataItem(context, 'وزن', '$weight کیلو'),
                        ),
                      ],
                    ] else if (style == ExerciseStyle.setsTime) ...[
                      if (time.isNotEmpty) ...[
                        Expanded(
                          child: _buildDataItem(context, 'زمان', '$time ثانیه'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (sets.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نام تمرین - دست‌نویس شیک
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(
              exerciseName,
              style: WorkoutLogTypography.exerciseTitle(context),
            ),
          ),
          // ست‌ها
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Column(children: sets),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkoutLogTypography.fieldLabel(context),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: WorkoutLogTypography.inputValue(context).copyWith(
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}
