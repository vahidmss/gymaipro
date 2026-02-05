import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? AppTheme.goldColor : Colors.black87,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'هنوز داده‌ای وارد نشده است',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark
                      ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                      : Colors.black54,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
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
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
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
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark ? AppTheme.goldColor : Colors.black87,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          dateString,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark
                                ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                                : Colors.black54,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
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
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                              : Colors.black54,
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
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.8)
                                : Colors.black87,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.15 : 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? AppTheme.goldColor : Colors.black87,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
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
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.goldColor : Colors.black87,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                height: 1.3,
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark
                ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                : Colors.black54,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? AppTheme.darkTextColor : Colors.black87,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
