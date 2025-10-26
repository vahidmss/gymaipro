import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan/workout_log/models/workout_program_log.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class WorkoutLogDetailsScreen extends StatelessWidget {
  // برای حالت مربی

  const WorkoutLogDetailsScreen({required this.log, super.key, this.userName});
  final WorkoutDailyLog log;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    // تاریخ اصلی ثبت تمرین (log_date)
    final date = log.logDate;
    final jalali = Gregorian.fromDateTime(date).toJalali();
    final weekDay = _getPersianWeekDay(date.weekday);
    final persianDate = '$weekDay ${jalali.day}/${jalali.month}/${jalali.year}';
    // ساعت ثبت (createdAt)
    final createdAt = log.createdAt;
    final totalSets = log.sessions.fold<int>(
      0,
      (sum, s) =>
          sum +
          s.exercises.fold<int>(
            0,
            (sum2, e) => e is NormalExerciseLog ? sum2 + e.sets.length : sum2,
          ),
    );
    final totalExercises = log.sessions.fold<int>(
      0,
      (sum, s) => sum + s.exercises.length,
    );
    final totalWeight = log.sessions.fold<double>(
      0,
      (sum, s) =>
          sum +
          s.exercises.fold<double>(
            0,
            (sum2, e) => e is NormalExerciseLog
                ? sum2 +
                      (e.sets.fold<double>(
                        0,
                        (sSum, set) => sSum + (set.weight ?? 0),
                      ))
                : sum2,
          ),
    );
    final totalTime = log.sessions.fold<int>(
      0,
      (sum, s) =>
          sum +
          s.exercises.fold<int>(
            0,
            (sum2, e) => e is NormalExerciseLog
                ? sum2 +
                      (e.sets.fold<int>(
                        0,
                        (sSum, set) => sSum + (set.seconds ?? 0),
                      ))
                : sum2,
          ),
    );

    // پیام الهام‌بخش تصادفی
    final List<String> quotes = [
      'موفقیت حاصل تکرار تلاش‌های کوچک است.',
      'هر روز یک قدم به هدف نزدیک‌تر شو!',
      'بدن قوی، ذهن قوی‌تر!',
      'پیشرفت یعنی بهتر شدن نسبت به دیروز.',
      'هیچ چیز جای استمرار را نمی‌گیرد.',
    ];
    final quote = quotes[date.day % quotes.length];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowRight,
              color: AppTheme.goldColor,
              size: 24.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'جزئیات تمرین',
            style: TextStyle(
              color: AppTheme.goldColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                LucideIcons.share2,
                color: AppTheme.goldColor,
                size: 24.sp,
              ),
              onPressed: () {
                final summary = _buildShareSummary(
                  log,
                  persianDate,
                  totalSets,
                  totalExercises,
                  totalWeight,
                  totalTime,
                );
                Clipboard.setData(ClipboardData(text: summary));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'خلاصه تمرین کپی شد!',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              tooltip: 'کپی خلاصه',
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(persianDate, createdAt),
            SizedBox(height: 12.h),
            _buildSummaryCard(
              totalSets,
              totalExercises,
              totalWeight,
              totalTime,
            ),
            SizedBox(height: 18.h),
            ...log.sessions.map(_buildSessionCard),
            SizedBox(height: 18.h),
            _buildNoteOrQuoteSection(quote),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String persianDate, DateTime createdAt) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.7),
            AppTheme.cardColor,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 16.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.dumbbell, color: AppTheme.goldColor, size: 48),
          SizedBox(height: 10.h),
          Text(
            'تمرین روزانه',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'تاریخ: $persianDate',
            style: TextStyle(color: AppTheme.goldColor, fontSize: 14.sp),
          ),
          Text(
            'ساعت ثبت: ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
          if (userName != null) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.user, color: AppTheme.goldColor, size: 16.sp),
                SizedBox(width: 6.w),
                Text(
                  'کاربر: $userName',
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    int totalSets,
    int totalExercises,
    double totalWeight,
    int totalTime,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        color: AppTheme.cardColor,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'ست',
                totalSets.toString(),
                LucideIcons.listChecks,
              ),
              _buildSummaryItem(
                'حرکت',
                totalExercises.toString(),
                LucideIcons.activity,
              ),
              _buildSummaryItem(
                'وزن',
                totalWeight > 0 ? '${totalWeight.toStringAsFixed(1)}kg' : '-',
                LucideIcons.scale,
              ),
              _buildSummaryItem(
                'زمان',
                totalTime > 0 ? _formatSeconds(totalTime) : '-',
                LucideIcons.timer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppTheme.goldColor, fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _buildSessionCard(WorkoutSessionLog session) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        color: AppTheme.cardColor,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    color: AppTheme.goldColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    session.day,
                    style: TextStyle(
                      color: AppTheme.goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ...session.exercises.map(_buildExerciseCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(dynamic exercise) {
    if (exercise is NormalExerciseLog) {
      return _buildNormalExerciseCard(exercise);
    } else if (exercise is SupersetExerciseLog) {
      return _buildSupersetExerciseCard(exercise);
    }
    return const SizedBox.shrink();
  }

  Widget _buildNormalExerciseCard(NormalExerciseLog exercise) {
    final totalReps = exercise.sets.fold<int>(
      0,
      (sum, s) => sum + (s.reps ?? s.seconds ?? 0),
    );
    final totalWeight = exercise.sets.fold<double>(
      0,
      (sum, s) => sum + (s.weight ?? 0),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        color: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.dumbbell,
                    color: AppTheme.goldColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      exercise.exerciseName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  Text(
                    '${exercise.sets.length} ست',
                    style: TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  if (exercise.style == 'sets_reps')
                    Text(
                      'مجموع تکرار: $totalReps',
                      style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                    ),
                  if (exercise.style == 'sets_time')
                    Text(
                      'مجموع زمان: ${_formatSeconds(totalReps)}',
                      style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                    ),
                  SizedBox(width: 12.w),
                  if (totalWeight > 0)
                    Text(
                      'مجموع وزن: ${totalWeight.toStringAsFixed(1)}kg',
                      style: TextStyle(
                        color: AppTheme.goldColor,
                        fontSize: 11.sp,
                      ),
                    ),
                ],
              ),
              // Display exercise note if available
              if (exercise.note != null && exercise.note!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.messageCircle,
                        color: AppTheme.goldColor,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          exercise.note!,
                          style: TextStyle(
                            color: AppTheme.goldColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...exercise.sets.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final set = entry.value;
                    return _buildSetChip(idx, set, exercise.style);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupersetExerciseCard(SupersetExerciseLog exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        color: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.zap, color: AppTheme.goldColor, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'سوپرست - ${exercise.tag}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  Text(
                    '${exercise.exercises.length} تمرین',
                    style: TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              // Display superset exercise note if available
              if (exercise.note != null && exercise.note!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.messageCircle,
                        color: AppTheme.goldColor,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          exercise.note!,
                          style: TextStyle(
                            color: AppTheme.goldColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              ...exercise.exercises.map(_buildSupersetItemCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupersetItemCard(SupersetItemLog item) {
    final totalReps = item.sets.fold<int>(
      0,
      (sum, s) => sum + (s.reps ?? s.seconds ?? 0),
    );
    final totalWeight = item.sets.fold<double>(
      0,
      (sum, s) => sum + (s.weight ?? 0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.dumbbell,
                color: AppTheme.goldColor,
                size: 14.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  item.exerciseName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Text(
                '${item.sets.length} ست',
                style: TextStyle(color: AppTheme.goldColor, fontSize: 10.sp),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Text(
                'مجموع تکرار: $totalReps',
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
              SizedBox(width: 12.w),
              if (totalWeight > 0)
                Text(
                  'مجموع وزن: ${totalWeight.toStringAsFixed(1)}kg',
                  style: TextStyle(color: AppTheme.goldColor, fontSize: 10.sp),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...item.sets.asMap().entries.map((entry) {
                final idx = entry.key;
                final set = entry.value;
                return _buildSetChip(idx, set, 'sets_reps');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetChip(int idx, ExerciseSetLog set, String style) {
    final int? reps = set.reps;
    final int? seconds = set.seconds;
    final double? weight = set.weight;
    final repsOrSec = style == 'sets_reps'
        ? (reps?.toString() ?? '-')
        : (seconds?.toString() ?? '-');
    final label = style == 'sets_reps' ? 'تکرار' : 'ثانیه';
    final bool isCompleted =
        (reps != null && reps > 0) || (seconds != null && seconds > 0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.1)
            : AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isCompleted
              ? Colors.green
              : AppTheme.goldColor.withValues(alpha: 0.1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? LucideIcons.check : LucideIcons.circle,
            color: isCompleted ? Colors.green : AppTheme.goldColor,
            size: 13.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            'ست ${idx + 1}',
            style: TextStyle(
              color: isCompleted ? Colors.green : AppTheme.goldColor,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            '$label: $repsOrSec',
            style: TextStyle(color: Colors.white, fontSize: 11.sp),
          ),
          if ((weight ?? 0) > 0) ...[
            SizedBox(width: 6.w),
            Text(
              'وزن: $weight',
              style: TextStyle(color: Colors.white70, fontSize: 11.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteOrQuoteSection(String quote) {
    // اگر یادداشت یا حس تمرین داشتی اینجا نمایش بده (در صورت وجود)
    // فعلاً پیام الهام‌بخش تصادفی نمایش داده می‌شود
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12),
      child: Card(
        color: AppTheme.goldColor.withValues(alpha: 0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(18.w),
          child: Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                color: AppTheme.goldColor,
                size: 22.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  '"$quote"',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 13.sp,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min > 0 ? '$min دقیقه ' : ''}${sec > 0 ? '$sec ثانیه' : ''}';
  }

  String _getPersianWeekDay(int weekday) {
    const weekdays = [
      '',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنج‌شنبه',
      'جمعه',
      'شنبه',
      'یکشنبه',
    ];
    return weekdays[weekday];
  }

  String _buildShareSummary(
    WorkoutDailyLog log,
    String persianDate,
    int totalSets,
    int totalExercises,
    double totalWeight,
    int totalTime,
  ) {
    return 'تمرین روزانه\nتاریخ: $persianDate\nست: $totalSets\nحرکت: $totalExercises\nوزن: ${totalWeight.toStringAsFixed(1)}kg\nزمان: ${_formatSeconds(totalTime)}';
  }
}
