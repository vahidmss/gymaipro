import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan/screens/workout_questionnaire_screen.dart';
import 'package:gymaipro/workout_plan/workout_log/screens/workout_log_screen.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/services/workout_program_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  Future<void> _loadAIPrograms() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // دریافت شناسه AI Trainer
      _aiTrainerId = await AITrainerService.ensureAITrainerExists();

      if (_aiTrainerId != null && mounted) {
        // دریافت برنامه‌های AI
        final programs = await _programService.getProgramsByTrainer(
          _aiTrainerId!,
        );
        if (mounted) {
          setState(() {
            _aiPrograms = programs;
          });
        }
      }
    } catch (e) {
      print('خطا در بارگذاری برنامه‌های AI: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'برنامه‌های جیم‌آی',
          style: GoogleFonts.vazirmatn(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadAIPrograms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            )
          : _aiPrograms.isEmpty
          ? _buildEmptyState()
          : _buildProgramsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _requestNewProgram,
        backgroundColor: AppTheme.goldColor,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.sparkles),
        label: Text(
          'درخواست برنامه جدید',
          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // آیکون جیم‌آی
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60.r),
              ),
              child: Icon(
                LucideIcons.bot,
                size: 60.sp,
                color: AppTheme.goldColor,
              ),
            ),
            const SizedBox(height: 32),

            // عنوان
            Text(
              'هنوز برنامه‌ای دریافت نکرده‌اید',
              style: GoogleFonts.vazirmatn(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // توضیحات
            Text(
              'جیم‌آی آماده است تا اولین برنامه تمرینی شخصی‌سازی شده شما را طراحی کند!',
              style: GoogleFonts.vazirmatn(
                fontSize: 16.sp,
                color: AppTheme.textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // دکمه درخواست برنامه
            ElevatedButton.icon(
              onPressed: _requestNewProgram,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: const Icon(LucideIcons.sparkles),
              label: Text(
                'درخواست اولین برنامه',
                style: GoogleFonts.vazirmatn(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramsList() {
    return Column(
      children: [
        // هدر اطلاعات
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              // آیکون جیم‌آی
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppTheme.goldColor,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Icon(LucideIcons.bot, color: Colors.white, size: 30.sp),
              ),
              const SizedBox(height: 16),

              // عنوان
              Text(
                'برنامه‌های جیم‌آی',
                style: GoogleFonts.vazirmatn(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // آمار
              Text(
                '${_aiPrograms.length} برنامه دریافت شده',
                style: GoogleFonts.vazirmatn(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),

        // لیست برنامه‌ها
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _aiPrograms.length,
            itemBuilder: (context, index) {
              final program = _aiPrograms[index];
              return _buildProgramCard(program, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgramCard(WorkoutProgram program, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _viewProgram(program),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هدر کارت
                Row(
                  children: [
                    // شماره برنامه
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // اطلاعات برنامه
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.name,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تاریخ ایجاد: ${_formatDate(program.createdAt)}',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 12.sp,
                              color: AppTheme.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // آیکون جیم‌آی
                    Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        LucideIcons.bot,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // آمار برنامه
                Row(
                  children: [
                    _buildStatItem(
                      LucideIcons.calendar,
                      '${program.sessions.length} روز',
                      'تعداد جلسات',
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      LucideIcons.dumbbell,
                      '${_getTotalExercises(program)} حرکت',
                      'کل تمرینات',
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      LucideIcons.clock,
                      '${_getEstimatedDuration(program)} دقیقه',
                      'مدت زمان',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // دکمه‌های عملیات
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewProgram(program),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: const Icon(LucideIcons.eye, size: 16),
                        label: Text(
                          'مشاهده',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startWorkout(program),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: const Icon(LucideIcons.play, size: 16),
                        label: Text(
                          'شروع تمرین',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
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

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20.sp, color: AppTheme.goldColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.vazirmatn(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.vazirmatn(
              fontSize: 10.sp,
              color: AppTheme.textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final persianMonths = [
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

    return '${date.day} ${persianMonths[date.month - 1]} ${date.year}';
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
    print('=== شروع navigation به WorkoutQuestionnaireScreen ===');
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const WorkoutQuestionnaireScreen(),
      ),
    ).then((_) {
      print('=== بازگشت از WorkoutQuestionnaireScreen ===');
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

class _ProgramDetailsDialog extends StatelessWidget {
  const _ProgramDetailsDialog({required this.program});
  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // رنگ پس‌زمینه دفترچه
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 25.r,
              offset: Offset(0.w, 15.h),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10.r,
              offset: Offset(0.w, 5.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // هدر شبیه جلد دفترچه
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                      ),
                      borderRadius: BorderRadius.circular(25.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.bookOpen,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دفترچه برنامه تمرینی',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.name,
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: IconButton(
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
                                    const SizedBox(width: 8),
                                    const Text('برنامه کپی شد'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            LucideIcons.copy,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            LucideIcons.x,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // محتوا - نمای دفترچه
            Flexible(
              child: Container(
                padding: EdgeInsets.all(20.w),
                child: _buildPaperView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperView() {
    // دفترچه شبیه‌سازی شده با خطوط کاغذ
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE), // رنگ کاغذ طبیعی
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30.r,
            offset: Offset(0.w, 15.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0.w, 5.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3.r,
            offset: Offset(0.w, 1.h),
          ),
        ],
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1.5),
      ),
      child: Stack(
        children: [
          // بافت کاغذ
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFEFEFE),
                  Color(0xFFF8F8F8),
                  Color(0xFFFEFEFE),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // خطوط کاغذ دفترچه
          _buildNotebookLines(),

          // سوراخ‌های دفترچه
          _buildNotebookHoles(),

          // محتوای برنامه
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 40.w, 20.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان برنامه با خط زیر
                  Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFD4AF37), width: 3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          blurRadius: 4.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: Text(
                      program.name,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2.r,
                            offset: Offset(0.w, 1.h),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // بدنه: هر جلسه با عنوان و لیست تمرین‌ها
                  ...program.sessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان روز
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.calendar,
                                  size: 16.sp,
                                  color: const Color(0xFFD4AF37),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'روز ${index + 1}: ',
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2C2C2C),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    session.day.replaceFirst(
                                      RegExp(r'^روز\s*\d+\s*-\s*'),
                                      '',
                                    ),
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // یادداشت جلسه
                          if (session.notes != null &&
                              session.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: const Color(0xFFE9ECEF),
                                ),
                              ),
                              child: Text(
                                session.notes!,
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 13.sp,
                                  height: 1.6.h,
                                  color: const Color(0xFF495057),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // لیست تمرین‌ها
                          ...session.exercises.map((ex) {
                            if (ex is NormalExercise) {
                              final repsList = ex.sets
                                  .map((s) => s.reps?.toString() ?? '-')
                                  .toList();
                              final tag = ex.tag;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: const Color(0xFFE9ECEF),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 2.r,
                                      offset: Offset(0.w, 1.h),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 6.w,
                                          height: 6.h,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD4AF37),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: GoogleFonts.vazirmatn(
                                                fontSize: 14.sp,
                                                color: const Color(0xFF2C2C2C),
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: tag,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const TextSpan(text: ': '),
                                                TextSpan(
                                                  text:
                                                      '${ex.sets.length} ست (${repsList.join('، ')})',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF6C757D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (ex.note != null &&
                                        ex.note!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE9ECEF),
                                            width: 0.5.w,
                                          ),
                                        ),
                                        child: Text(
                                          ex.note!,
                                          style: GoogleFonts.vazirmatn(
                                            fontSize: 12.sp,
                                            color: const Color(0xFF495057),
                                            height: 1.4.h,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // امضا مربی
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.user,
                              size: 16.sp,
                              color: const Color(0xFF6C757D),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'مربی: جیم‌آی (ساخت خودکار)',
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6C757D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تاریخ: ${DateTime.now().toLocal().toString().split(' ').first}',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 11.sp,
                            color: const Color(0xFF6C757D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotebookLines() {
    return Positioned.fill(child: CustomPaint(painter: NotebookLinesPainter()));
  }

  Widget _buildNotebookHoles() {
    return Positioned(
      right: 15.w, // کاهش فاصله از لبه
      top: 0.h,
      bottom: 0.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          8,
          (index) => Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D0D0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB0B0B0), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3.r,
                  offset: Offset(0.w, 1.h),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 1.r,
                  offset: const Offset(0, -0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildPlainTextProgram() {
    final buffer = StringBuffer();
    buffer.writeln(program.name);
    buffer.writeln();

    for (int i = 0; i < program.sessions.length; i++) {
      final session = program.sessions[i];
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
          buffer.writeln(
            '- ${ex.tag}: ${ex.sets.length} ست (${repsList.join(', ')})',
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

/// کلاس برای رسم خطوط کاغذ دفترچه
class NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFE0E0E0) // کمی تیره‌تر
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    // خط قرمز برای حاشیه
    final redPaint = Paint()
      ..color =
          const Color(0xFFE53E3E) // قرمز تیره‌تر و طبیعی‌تر
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // خط قرمز حاشیه سمت راست (برای فارسی)
    canvas.drawLine(
      Offset(size.width - 40, 0),
      Offset(size.width - 40, size.height),
      redPaint,
    );

    // خطوط افقی کاغذ
    for (double y = 50; y < size.height; y += 24) {
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 50, y), // فاصله از حاشیه راست
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
