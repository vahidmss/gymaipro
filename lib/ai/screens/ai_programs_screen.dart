import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_log/screens/workout_log_screen.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AIProgramsScreen extends StatefulWidget {
  const AIProgramsScreen({super.key});

  @override
  State<AIProgramsScreen> createState() => _AIProgramsScreenState();
}

class _AIProgramsScreenState extends State<AIProgramsScreen> {
  final WorkoutProgramService _programService = WorkoutProgramService();
  List<WorkoutProgram> _aiPrograms = [];
  bool _isLoading = true;
  String? _aiTrainerId;

  @override
  void initState() {
    super.initState();
    _loadAIPrograms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // بارگذاری مجدد برنامه‌ها وقتی صفحه دوباره نمایش داده می‌شود
    // فقط اگر در حال بارگذاری نیستیم
    if (!_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAIPrograms();
        }
      });
    }
  }

  Future<void> _loadAIPrograms() async {
    try {
      debugPrint('\n=== بارگذاری برنامه‌های AI ===');
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);
      }

      // دریافت شناسه AI Trainer
      _aiTrainerId = await AITrainerService.ensureAITrainerExists();
      debugPrint('AI Trainer ID: $_aiTrainerId');

      if (_aiTrainerId != null && mounted) {
        // دریافت برنامه‌های AI
        debugPrint('دریافت برنامه‌های AI از دیتابیس...');
        final programs = await _programService.getProgramsByTrainer(
          _aiTrainerId!,
        );
        debugPrint('تعداد برنامه‌های دریافت شده: ${programs.length}');
        if (programs.isNotEmpty) {
          debugPrint('برنامه‌ها:');
          for (final program in programs) {
            debugPrint('  - ${program.name} (ID: ${program.id})');
          }
        }
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () {
            _aiPrograms = programs;
          });
          debugPrint('برنامه‌ها در state به‌روزرسانی شدند');
        }
      } else {
        debugPrint('⚠️ AI Trainer ID null است یا صفحه unmount شده');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ خطا در بارگذاری برنامه‌های AI: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        debugPrint('بارگذاری کامل شد. تعداد برنامه‌ها: ${_aiPrograms.length}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: context.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
          ),
        ),
        child: DecoratedBox(
          decoration: isDark
              ? const BoxDecoration()
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightGradientStart.withValues(alpha: 0.15),
                      AppTheme.lightCardColor,
                      AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: isDark
                  ? context.backgroundColor
                  : Colors.transparent,
              foregroundColor: isDark ? AppTheme.goldColor : context.textColor,
              elevation: 0,
              title: Text(
                'برنامه‌های جیم‌آی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    LucideIcons.refreshCw,
                    size: 20.sp,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                  ),
                  onPressed: _loadAIPrograms,
                  tooltip: 'بروزرسانی',
                ),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  )
                : _aiPrograms.isEmpty
                ? _buildEmptyState(context, isDark)
                : _buildProgramsList(context, isDark),
            floatingActionButton: _aiPrograms.isEmpty
                ? null
                : Container(
                    margin: EdgeInsets.only(bottom: 60.h),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.goldColor, AppTheme.darkGold],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: FloatingActionButton.extended(
                        onPressed: _requestNewProgram,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        icon: Icon(
                          LucideIcons.sparkles,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        label: Text(
                          'برنامه جدید',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // آیکون جیم‌آی
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                LucideIcons.bot,
                size: 40.sp,
                color: AppTheme.goldColor,
              ),
            ),
            SizedBox(height: 24.h),

            // عنوان
            Text(
              'هنوز برنامه‌ای دریافت نکرده‌اید',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            // توضیحات
            Text(
              'جیم‌آی آماده است تا اولین برنامه تمرینی شخصی‌سازی شده شما را طراحی کند',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // دکمه درخواست برنامه
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.goldColor, AppTheme.darkGold],
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _requestNewProgram,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(LucideIcons.sparkles, size: 16.sp),
                label: Text(
                  'درخواست برنامه',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramsList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _aiPrograms.length,
      itemBuilder: (context, index) {
        final program = _aiPrograms[index];
        return _buildProgramCard(context, isDark, program, index);
      },
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    bool isDark,
    WorkoutProgram program,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.grey[700]!.withValues(alpha: 0.5)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _viewProgram(program),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هدر کارت
                Row(
                  children: [
                    // آیکون جیم‌آی کوچک
                    Container(
                      width: 28.w,
                      height: 28.h,
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        LucideIcons.bot,
                        color: AppTheme.goldColor,
                        size: 14.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // اطلاعات برنامه
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.name,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _formatDate(program.createdAt),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // آمار برنامه (کوچک‌تر)
                Row(
                  children: [
                    _buildStatItem(
                      context,
                      LucideIcons.calendar,
                      '${program.sessions.length}',
                      'جلسه',
                    ),
                    SizedBox(width: 16.w),
                    _buildStatItem(
                      context,
                      LucideIcons.dumbbell,
                      '${_getTotalExercises(program)}',
                      'تمرین',
                    ),
                    SizedBox(width: 16.w),
                    _buildStatItem(
                      context,
                      LucideIcons.clock,
                      '${_getEstimatedDuration(program)}',
                      'دقیقه',
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // دکمه‌های عملیات (کوچک‌تر)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewProgram(program),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.goldColor,
                          side: BorderSide(
                            color: AppTheme.goldColor.withValues(alpha: 0.5),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: Icon(LucideIcons.eye, size: 14.sp),
                        label: Text(
                          'مشاهده',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.goldColor, AppTheme.darkGold],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _startWorkout(program),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          icon: Icon(LucideIcons.play, size: 14.sp),
                          label: Text(
                            'شروع',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14.sp, color: AppTheme.goldColor),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 9.sp,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var output = input;
    for (var i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], persian[i]);
    }
    return output;
  }

  String _formatDate(DateTime date) {
    final j = Jalali.fromDateTime(date);
    final persianMonths = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    return '${_toPersianDigits(j.day.toString())} ${persianMonths[j.month]} ${_toPersianDigits(j.year.toString())}';
  }

  int _getTotalExercises(WorkoutProgram program) {
    int total = 0;
    for (final session in program.sessions) {
      total += session.exercises.length;
    }
    return total;
  }

  int _getEstimatedDuration(WorkoutProgram program) {
    // تخمین مدت زمان بر اساس تعداد تمرینات
    final int totalExercises = _getTotalExercises(program);
    return (totalExercises * 3).clamp(30, 120); // 3 دقیقه برای هر تمرین
  }

  void _requestNewProgram() {
    debugPrint('=== شروع navigation به ProgramTypeSelectionScreen ===');
    Navigator.pushNamed(context, '/program-type-selection').then((_) {
      debugPrint('=== بازگشت از ProgramTypeSelectionScreen ===');
      // بعد از بازگشت، برنامه‌ها را دوباره بارگذاری کن
      if (mounted) {
        _loadAIPrograms();
      }
    });
  }

  void _viewProgram(WorkoutProgram program) {
    // نمایش جزئیات برنامه
    showDialog<void>(
      context: context,
      builder: (context) => _ProgramDetailsDialog(program: program),
    );
  }

  void _startWorkout(WorkoutProgram program) {
    // هدایت به صفحه workout log
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const WorkoutLogScreen()),
    );
  }
}

class _ProgramDetailsDialog extends StatefulWidget {
  const _ProgramDetailsDialog({required this.program});
  final WorkoutProgram program;

  @override
  State<_ProgramDetailsDialog> createState() => _ProgramDetailsDialogState();
}

class _ProgramDetailsDialogState extends State<_ProgramDetailsDialog> {
  final ExerciseService _exerciseService = ExerciseService();
  final Map<int, Exercise> _exerciseDetails = {};
  // نگهداری mapping بین tag و exercise برای تمریناتی که exerciseId ندارند
  final Map<String, Exercise> _tagToExerciseMap = {};

  @override
  void initState() {
    super.initState();
    // استفاده از addPostFrameCallback برای اطمینان از اینکه widget mount شده است
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadExerciseDetails();
      }
    });
  }

  Future<void> _loadExerciseDetails() async {
    if (!mounted) return;

    try {
      debugPrint('=== شروع بارگذاری جزئیات تمرین‌ها ===');
      debugPrint('برنامه: ${widget.program.name}');
      debugPrint('تعداد سشن‌ها: ${widget.program.sessions.length}');

      // جمع‌آوری تمام exerciseId های منحصر به فرد و tag ها
      final exerciseIds = <int>{};
      final exercisesToSearch = <String>{}; // استفاده از Set برای حذف تکراری‌ها
      final allExerciseTags = <String>[]; // برای لاگ
      int totalExercises = 0;

      for (final session in widget.program.sessions) {
        debugPrint(
          'بررسی سشن: ${session.day} با ${session.exercises.length} تمرین',
        );
        totalExercises += session.exercises.length;
        for (final exercise in session.exercises) {
          if (exercise is NormalExercise) {
            debugPrint(
              '  تمرین: exerciseId=${exercise.exerciseId}, tag="${exercise.tag}"',
            );
            allExerciseTags.add(
              'ID:${exercise.exerciseId}, Tag:"${exercise.tag}"',
            );

            if (exercise.exerciseId > 0) {
              exerciseIds.add(exercise.exerciseId);
            }

            // همیشه tag را اضافه کن (حتی اگر exerciseId > 0 باشد) برای fallback
            if (exercise.tag.isNotEmpty) {
              exercisesToSearch.add(exercise.tag);
            } else {
              debugPrint(
                '  ⚠️ تمرین بدون tag! exerciseId=${exercise.exerciseId}',
              );
            }
          }
        }
      }

      debugPrint(
        'جمع‌بندی: $totalExercises تمرین کل، ${exerciseIds.length} با ID، ${exercisesToSearch.length} tag منحصر به فرد',
      );
      debugPrint('تمام tag ها: ${exercisesToSearch.join(", ")}');

      // بارگذاری جزئیات هر تمرین با exerciseId
      for (final exerciseId in exerciseIds) {
        try {
          final exercise = await _exerciseService.getExerciseById(exerciseId);
          if (exercise != null && mounted) {
            setState(() {
              _exerciseDetails[exerciseId] = exercise;
            });
            debugPrint(
              'تمرین بارگذاری شد: ID=$exerciseId, Name=${exercise.name}',
            );
          }
        } catch (e) {
          debugPrint('خطا در بارگذاری تمرین $exerciseId: $e');
        }
      }

      // جستجوی تمرینات با tag برای تمریناتی که exerciseId ندارند
      if (exercisesToSearch.isNotEmpty) {
        try {
          final allExercises = await _exerciseService.getExercises();
          if (allExercises.isEmpty) {
            debugPrint('هیچ تمرینی برای جستجو یافت نشد');
            return;
          }

          debugPrint(
            'جستجوی ${exercisesToSearch.length} تمرین با tag از ${allExercises.length} تمرین موجود',
          );
          debugPrint('Tag های منحصر به فرد: ${exercisesToSearch.join(", ")}');

          for (final tag in exercisesToSearch) {
            if (tag.isEmpty) {
              debugPrint('⚠️ Tag خالی نادیده گرفته شد');
              continue;
            }

            // اگر قبلاً این tag را پیدا کرده‌ایم، از آن استفاده کن
            if (_tagToExerciseMap.containsKey(tag)) {
              debugPrint(
                'Tag "$tag" قبلاً پیدا شده بود: ${_tagToExerciseMap[tag]?.name}',
              );
              continue;
            }

            debugPrint('جستجوی تمرین برای tag: "$tag"');

            // جستجوی تمرین بر اساس نام
            Exercise? foundExercise;
            final tagLower = tag.toLowerCase().trim();

            // جستجوی دقیق
            try {
              foundExercise = allExercises.firstWhere(
                (e) =>
                    e.name.toLowerCase().trim() == tagLower ||
                    e.name.toLowerCase().contains(tagLower) ||
                    e.otherNames.any(
                      (n) =>
                          n.toLowerCase().trim() == tagLower ||
                          n.toLowerCase().contains(tagLower),
                    ),
              );
              debugPrint(
                '✅ تمرین پیدا شد (دقیق) برای tag "$tag": ${foundExercise.name}',
              );
            } catch (e) {
              debugPrint('⚠️ جستجوی دقیق ناموفق برای tag "$tag": $e');
              // اگر پیدا نشد، جستجوی تقریبی با کلمات کلیدی
              try {
                // تقسیم tag به کلمات (با _ یا space)
                final keywords = tagLower
                    .split(RegExp(r'[_\s]+'))
                    .where((w) => w.length > 2)
                    .toList();

                if (keywords.isNotEmpty) {
                  // Mapping کلمات کلیدی انگلیسی به فارسی
                  final keywordMapping = {
                    'bench': ['پرس', 'سینه'],
                    'press': ['پرس'],
                    'incline': ['شیب', 'بالا'],
                    'decline': ['شیب', 'پایین'],
                    'dumbbell': ['دمبل'],
                    'barbell': ['هالتر'],
                    'curl': ['جلو بازو', 'بازو'],
                    'row': ['زیر بغل', 'لت', 'پشت'],
                    'squat': ['اسکوات', 'اسکات'],
                    'deadlift': ['ددلیفت'],
                    'pull': ['زیر بغل', 'لت'],
                    'push': ['پرس'],
                    'raise': ['نشر', 'بالا'],
                    'dip': ['دیپ'],
                    'extension': ['باز', 'کشش'],
                    'tricep': ['پشت بازو'],
                    'bicep': ['جلو بازو'],
                    'chest': ['سینه'],
                    'back': ['پشت', 'زیر بغل'],
                    'shoulder': ['شانه'],
                    'leg': ['پا', 'ران'],
                    'calf': ['ساق'],
                    'lateral': ['جانب'],
                    'cable': ['کابل'],
                    'cross': ['متقاطع'],
                    'over': ['بالا'],
                    'pulldown': ['زیر بغل', 'لت'],
                    'bent': ['خم'],
                    'seated': ['نشسته'],
                    'hammer': ['چکشی'],
                  };

                  int bestScore = 0;
                  Exercise? bestMatch;

                  for (final exercise in allExercises) {
                    int score = 0;
                    final exerciseNameLower = exercise.name.toLowerCase();
                    final exerciseMainMuscleLower = exercise.mainMuscle
                        .toLowerCase();

                    // امتیازدهی بر اساس تطبیق کلمات
                    for (final keyword in keywords) {
                      // جستجو در نام تمرین
                      if (exerciseNameLower.contains(keyword)) {
                        score += 10;
                      }

                      // جستجو در otherNames
                      for (final otherName in exercise.otherNames) {
                        if (otherName.toLowerCase().contains(keyword)) {
                          score += 8;
                        }
                      }

                      // جستجو با mapping
                      if (keywordMapping.containsKey(keyword)) {
                        for (final persianWord in keywordMapping[keyword]!) {
                          if (exerciseNameLower.contains(persianWord)) {
                            score += 15;
                          }
                          if (exerciseMainMuscleLower.contains(persianWord)) {
                            score += 10;
                          }
                        }
                      }
                    }

                    if (score > bestScore) {
                      bestScore = score;
                      bestMatch = exercise;
                    }
                  }

                  if (bestMatch != null && bestScore > 0) {
                    foundExercise = bestMatch;
                    debugPrint(
                      'تمرین پیدا شد (تقریبی) برای tag "$tag": ${bestMatch.name} (Score: $bestScore)',
                    );
                  } else {
                    debugPrint('هیچ تمرینی برای tag "$tag" پیدا نشد');
                  }
                }
              } catch (e) {
                debugPrint('خطا در جستجوی تقریبی برای tag "$tag": $e');
              }
            }

            // ذخیره تمرین پیدا شده در mapping
            if (foundExercise != null) {
              if (mounted) {
                setState(() {
                  _tagToExerciseMap[tag] = foundExercise!;
                });
                debugPrint('✅ Tag "$tag" به ${foundExercise.name} map شد');
              } else {
                debugPrint(
                  '⚠️ Widget unmount شده - نمی‌توان state را به‌روزرسانی کرد',
                );
              }
            } else {
              debugPrint('⚠️ تمرین پیدا نشد برای tag "$tag"');
            }
          }

          debugPrint('=== پایان جستجوی تمرینات با tag ===');
          debugPrint(
            'تعداد تمرینات پیدا شده در mapping: ${_tagToExerciseMap.length}',
          );
        } catch (e) {
          debugPrint('خطا در جستجوی تمرینات با tag: $e');
        }
      }

      if (mounted) {
        setState(() {
          // به‌روزرسانی state برای رندر مجدد UI
        });
        debugPrint('=== پایان بارگذاری جزئیات تمرین‌ها ===');
        debugPrint('تمرینات با ID: ${_exerciseDetails.length}');
        debugPrint('تمرینات با tag: ${_tagToExerciseMap.length}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ خطا در بارگذاری جزئیات تمرین‌ها: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  String _getExerciseName(int exerciseId, {String? fallbackTag}) {
    // اول سعی کن از exerciseId پیدا کنی
    if (exerciseId > 0) {
      final exercise = _exerciseDetails[exerciseId];
      if (exercise != null) {
        return exercise.name;
      }
    }

    // اگر پیدا نشد و tag وجود دارد، از tag mapping استفاده کن
    if (fallbackTag != null && fallbackTag.isNotEmpty) {
      final exerciseFromTag = _tagToExerciseMap[fallbackTag];
      if (exerciseFromTag != null) {
        return exerciseFromTag.name;
      }
      // اگر در mapping هم پیدا نشد، خود tag را برگردان
      // این مهم است چون ممکن است هنوز جستجو کامل نشده باشد
      return fallbackTag;
    }

    // اگر هیچ کدام پیدا نشد
    return 'تمرین';
  }

  void _navigateToExerciseDetail(int exerciseId, {String? tag}) {
    Exercise? exercise;

    if (exerciseId > 0) {
      exercise = _exerciseDetails[exerciseId];
    } else if (tag != null && tag.isNotEmpty) {
      exercise = _tagToExerciseMap[tag];
    }

    if (exercise != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ExerciseDetailScreen(exercise: exercise!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.grey[700]!.withValues(alpha: 0.5)
                : AppTheme.lightDividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 20.r,
              offset: Offset(0.w, 8.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // هدر ساده
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCardColor
                    : AppTheme.goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.dumbbell,
                    color: AppTheme.goldColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      widget.program.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.copy,
                      size: 18.sp,
                      color: context.textSecondary,
                    ),
                    tooltip: 'کپی برنامه',
                    onPressed: () {
                      final text = _buildPlainTextProgram();
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              const Text(
                                'برنامه کپی شد',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 18.sp,
                      color: context.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // محتوا
            Flexible(
              child: Container(
                padding: EdgeInsets.all(16.w),
                child: _buildContentView(context, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اطلاعات کلی برنامه
          Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.3)
                  : AppTheme.goldColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${widget.program.sessions.length} جلسه تمرینی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  LucideIcons.dumbbell,
                  size: 16.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${_getTotalExercises(widget.program)} تمرین',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),

          // لیست جلسات - هر جلسه در یک کارت جداگانه
          ...widget.program.sessions.asMap().entries.map<Widget>((entry) {
            final index = entry.key;
            final session = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : AppTheme.goldColor.withValues(alpha: 0.08),
                    blurRadius: 8.r,
                    offset: Offset(0.w, 2.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // هدر جلسه
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.15),
                          AppTheme.goldColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        // شماره جلسه
                        Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.goldColor, AppTheme.darkGold],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 4.r,
                                offset: Offset(0.w, 2.h),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'جلسه ${index + 1}',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                session.day.replaceFirst(
                                  RegExp(r'^روز\s*\d+\s*-\s*'),
                                  '',
                                ),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.calendar,
                          size: 20.sp,
                          color: AppTheme.goldColor,
                        ),
                      ],
                    ),
                  ),

                  // محتوای جلسه
                  Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // یادداشت جلسه
                        if (session.notes != null &&
                            session.notes!.trim().isNotEmpty) ...[
                          Container(
                            margin: EdgeInsets.only(bottom: 14.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]!.withValues(alpha: 0.3)
                                  : AppTheme.goldColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  LucideIcons.info,
                                  size: 16.sp,
                                  color: AppTheme.goldColor,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    session.notes!,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.sp,
                                      height: 1.5.h,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // عنوان بخش تمرین‌ها
                        Row(
                          children: [
                            Container(
                              width: 3.w,
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'تمرین‌های این جلسه',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${session.exercises.length} تمرین',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // لیست تمرین‌ها
                        ...session.exercises.asMap().entries.map<Widget>((
                          exEntry,
                        ) {
                          final exIndex = exEntry.key;
                          final ex = exEntry.value;
                          if (ex is NormalExercise) {
                            final repsList = ex.sets
                                .map((s) => s.reps?.toString() ?? '-')
                                .toList();

                            // دریافت نام تمرین - همیشه از tag استفاده کن اگر موجود باشد
                            String exerciseName;
                            if (ex.exerciseId > 0 &&
                                _exerciseDetails.containsKey(ex.exerciseId)) {
                              exerciseName =
                                  _exerciseDetails[ex.exerciseId]!.name;
                            } else if (ex.tag.isNotEmpty) {
                              // اول از mapping استفاده کن
                              if (_tagToExerciseMap.containsKey(ex.tag)) {
                                exerciseName = _tagToExerciseMap[ex.tag]!.name;
                              } else {
                                // اگر در mapping نیست، خود tag را نمایش بده
                                // این مهم است چون ممکن است هنوز جستجو کامل نشده باشد
                                exerciseName = ex.tag;
                              }
                            } else {
                              exerciseName = 'تمرین';
                            }

                            // بررسی اینکه آیا تمرین در دیتابیس پیدا شده یا نه
                            final exerciseDetail = ex.exerciseId > 0
                                ? _exerciseDetails[ex.exerciseId]
                                : (ex.tag.isNotEmpty
                                      ? _tagToExerciseMap[ex.tag]
                                      : null);
                            final canNavigate = exerciseDetail != null;

                            return InkWell(
                              onTap: canNavigate
                                  ? () => _navigateToExerciseDetail(
                                      ex.exerciseId,
                                      tag: ex.tag,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(10.r),
                              child: Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[900]!.withValues(alpha: 0.3)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[700]!.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppTheme.lightDividerColor.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // شماره تمرین
                                    Container(
                                      width: 24.w,
                                      height: 24.h,
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${exIndex + 1}',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.goldColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  exerciseName,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: context.textColor,
                                                  ),
                                                ),
                                              ),
                                              if (canNavigate) ...[
                                                SizedBox(width: 8.w),
                                                Icon(
                                                  LucideIcons.chevronLeft,
                                                  size: 16.sp,
                                                  color: AppTheme.goldColor,
                                                ),
                                              ],
                                            ],
                                          ),
                                          SizedBox(height: 6.h),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.goldColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  '${ex.sets.length} ست',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.goldColor,
                                                  ),
                                                ),
                                              ),
                                              if (repsList.isNotEmpty) ...[
                                                SizedBox(width: 8.w),
                                                Text(
                                                  '•',
                                                  style: TextStyle(
                                                    color:
                                                        context.textSecondary,
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  repsList.join('، '),
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontSize: 11.sp,
                                                    color:
                                                        context.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (ex.note != null &&
                                              ex.note!.trim().isNotEmpty) ...[
                                            SizedBox(height: 8.h),
                                            Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.grey[800]!
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                    : AppTheme.goldColor
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(6.r),
                                              ),
                                              child: Text(
                                                ex.note!,
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  fontSize: 11.sp,
                                                  height: 1.4.h,
                                                  color: context.textSecondary,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 8.h),

          // اطلاعات پایین
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.3)
                  : AppTheme.goldColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isDark
                    ? Colors.grey[700]!.withValues(alpha: 0.3)
                    : AppTheme.goldColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.bot, size: 14.sp, color: AppTheme.goldColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'برنامه تولید شده توسط جیم‌آی',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalExercises(WorkoutProgram program) {
    int total = 0;
    for (final session in program.sessions) {
      total += session.exercises.length;
    }
    return total;
  }

  String _buildPlainTextProgram() {
    final buffer = StringBuffer();
    buffer.writeln(widget.program.name);
    buffer.writeln();

    for (int i = 0; i < widget.program.sessions.length; i++) {
      final session = widget.program.sessions[i];
      final title = session.day.isNotEmpty ? session.day : 'روز ${i + 1}';
      buffer.writeln(title);
      if (session.notes != null && session.notes!.trim().isNotEmpty) {
        buffer.writeln('یادداشت: ${session.notes!.trim()}');
      }

      for (final ex in session.exercises) {
        if (ex is NormalExercise) {
          final repsList = ex.sets
              .map((s) => s.reps?.toString() ?? '-')
              .toList();
          final exerciseName = _getExerciseName(
            ex.exerciseId,
            fallbackTag: ex.tag,
          );
          buffer.writeln(
            '- $exerciseName: ${ex.sets.length} ست (${repsList.join(', ')})',
          );
          if (ex.note != null && ex.note!.trim().isNotEmpty) {
            buffer.writeln('  نکته: ${ex.note!.trim()}');
          }
        }
      }

      buffer.writeln();
    }

    return buffer.toString().trim();
  }
}
