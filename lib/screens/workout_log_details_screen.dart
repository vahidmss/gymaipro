import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/workout_program_log.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

class WorkoutLogDetailsScreen extends StatelessWidget {
  final WorkoutProgramLog log;
  final String? userName; // برای حالت مربی

  const WorkoutLogDetailsScreen({Key? key, required this.log, this.userName})
      : super(key: key);

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
                (sum2, e) =>
                    e is NormalExerciseLog ? sum2 + e.sets.length : sum2));
    final totalExercises =
        log.sessions.fold<int>(0, (sum, s) => sum + s.exercises.length);
    final totalWeight = log.sessions.fold<double>(
        0,
        (sum, s) =>
            sum +
            s.exercises.fold<double>(
                0,
                (sum2, e) => e is NormalExerciseLog
                    ? sum2 +
                        (e.sets.fold<double>(
                            0, (sSum, set) => sSum + (set.weight ?? 0)))
                    : sum2));
    final totalTime = log.sessions.fold<int>(
        0,
        (sum, s) =>
            sum +
            s.exercises.fold<int>(
                0,
                (sum2, e) => e is NormalExerciseLog
                    ? sum2 +
                        (e.sets.fold<int>(
                            0, (sSum, set) => sSum + (set.seconds ?? 0)))
                    : sum2));

    // پیام الهام‌بخش تصادفی
    final List<String> quotes = [
      'موفقیت حاصل تکرار تلاش‌های کوچک است.',
      'هر روز یک قدم به هدف نزدیک‌تر شو!',
      'بدن قوی، ذهن قوی‌تر!',
      'پیشرفت یعنی بهتر شدن نسبت به دیروز.',
      'هیچ چیز جای استمرار را نمی‌گیرد.'
    ];
    final quote = quotes[date.day % quotes.length];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('جزئیات تمرین',
            style: TextStyle(
                color: AppTheme.goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: AppTheme.goldColor),
            onPressed: () {
              final summary = _buildShareSummary(log, persianDate, totalSets,
                  totalExercises, totalWeight, totalTime);
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('خلاصه تمرین کپی شد!'),
                  backgroundColor: Colors.green));
            },
            tooltip: 'کپی خلاصه',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          _buildHeader(persianDate, createdAt),
          const SizedBox(height: 12),
          _buildSummaryCard(totalSets, totalExercises, totalWeight, totalTime),
          const SizedBox(height: 18),
          ...log.sessions.map((session) => _buildSessionCard(session)).toList(),
          const SizedBox(height: 18),
          _buildNoteOrQuoteSection(quote),
        ],
      ),
    );
  }

  Widget _buildHeader(String persianDate, DateTime createdAt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.goldColor.withOpacity(0.7), AppTheme.cardColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(LucideIcons.dumbbell, color: AppTheme.goldColor, size: 48),
          const SizedBox(height: 10),
          Text(
            log.programName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text('تاریخ: $persianDate',
              style: const TextStyle(color: AppTheme.goldColor, fontSize: 14)),
          Text(
              'ساعت ثبت: ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (userName != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.user,
                    color: AppTheme.goldColor, size: 16),
                const SizedBox(width: 6),
                Text('کاربر: $userName',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      int totalSets, int totalExercises, double totalWeight, int totalTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: AppTheme.cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  'ست', totalSets.toString(), LucideIcons.listChecks),
              _buildSummaryItem(
                  'حرکت', totalExercises.toString(), LucideIcons.activity),
              _buildSummaryItem(
                  'وزن',
                  totalWeight > 0 ? '${totalWeight.toStringAsFixed(1)}kg' : '-',
                  LucideIcons.scale),
              _buildSummaryItem(
                  'زمان',
                  totalTime > 0 ? _formatSeconds(totalTime) : '-',
                  LucideIcons.timer),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withOpacity(0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 22),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(color: AppTheme.goldColor, fontSize: 11)),
      ],
    );
  }

  Widget _buildSessionCard(WorkoutSessionLog session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: AppTheme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.calendar,
                      color: AppTheme.goldColor, size: 18),
                  const SizedBox(width: 8),
                  Text(session.day,
                      style: const TextStyle(
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              ...session.exercises
                  .map((exercise) => _buildExerciseCard(exercise))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(dynamic exercise) {
    if (exercise is! NormalExerciseLog) return const SizedBox.shrink();
    final totalReps = exercise.sets
        .fold<int>(0, (sum, s) => sum + (s.reps ?? s.seconds ?? 0));
    final totalWeight =
        exercise.sets.fold<double>(0, (sum, s) => sum + (s.weight ?? 0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Colors.white.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.dumbbell,
                      color: AppTheme.goldColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(exercise.exerciseName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  Text('${exercise.sets.length} ست',
                      style: const TextStyle(
                          color: AppTheme.goldColor, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (exercise.style == 'sets_reps')
                    Text('مجموع تکرار: $totalReps',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  if (exercise.style == 'sets_time')
                    Text('مجموع زمان: ${_formatSeconds(totalReps)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  const SizedBox(width: 12),
                  if (totalWeight > 0)
                    Text('مجموع وزن: ${totalWeight.toStringAsFixed(1)}kg',
                        style: const TextStyle(
                            color: AppTheme.goldColor, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...exercise.sets.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final set = entry.value;
                    return _buildSetChip(idx, set, exercise.style);
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetChip(int idx, dynamic set, String style) {
    final repsOrSec = style == 'sets_reps'
        ? (set.reps?.toString() ?? '-')
        : (set.seconds?.toString() ?? '-');
    final label = style == 'sets_reps' ? 'تکرار' : 'ثانیه';
    final isCompleted = (set.reps != null && set.reps > 0) ||
        (set.seconds != null && set.seconds > 0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.18)
            : AppTheme.goldColor.withOpacity(0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isCompleted
                ? Colors.green
                : AppTheme.goldColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCompleted ? LucideIcons.check : LucideIcons.circle,
              color: isCompleted ? Colors.green : AppTheme.goldColor, size: 13),
          const SizedBox(width: 4),
          Text('ست ${idx + 1}',
              style: TextStyle(
                  color: isCompleted ? Colors.green : AppTheme.goldColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
          const SizedBox(width: 6),
          Text('$label: $repsOrSec',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          if (set.weight != null) ...[
            const SizedBox(width: 6),
            Text('وزن: ${set.weight}',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]
        ],
      ),
    );
  }

  Widget _buildNoteOrQuoteSection(String quote) {
    // اگر یادداشت یا حس تمرین داشتی اینجا نمایش بده (در صورت وجود)
    // فعلاً پیام الهام‌بخش تصادفی نمایش داده می‌شود
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Card(
        color: AppTheme.goldColor.withOpacity(0.09),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles,
                  color: AppTheme.goldColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"$quote"',
                  style: const TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
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
      'یکشنبه'
    ];
    return weekdays[weekday];
  }

  String _buildShareSummary(WorkoutProgramLog log, String persianDate,
      int totalSets, int totalExercises, double totalWeight, int totalTime) {
    return 'برنامه: ${log.programName}\nتاریخ: $persianDate\nست: $totalSets\nحرکت: $totalExercises\nوزن: ${totalWeight.toStringAsFixed(1)}kg\nزمان: ${_formatSeconds(totalTime)}';
  }
}
