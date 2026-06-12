import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/services/ai_workout_generator_service.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_questionnaire/models/workout_questionnaire_models.dart';
import 'package:gymaipro/workout_questionnaire/services/questionnaire_local_storage_service.dart';
import 'package:gymaipro/workout_questionnaire/services/questionnaire_questions_service.dart';
import 'package:gymaipro/workout_questionnaire/widgets/question_widget.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutQuestionnaireScreen extends StatefulWidget {
  const WorkoutQuestionnaireScreen({super.key});

  @override
  State<WorkoutQuestionnaireScreen> createState() =>
      _WorkoutQuestionnaireScreenState();
}

class _WorkoutQuestionnaireScreenState
    extends State<WorkoutQuestionnaireScreen> {
  final QuestionnaireQuestionsService _questionsService =
      QuestionnaireQuestionsService();
  final QuestionnaireLocalStorageService _localStorage =
      QuestionnaireLocalStorageService();
  bool _isGenerationDialogOpen = false;
  final PageController _pageController = PageController();

  List<WorkoutQuestion> _questions = [];
  Map<String, WorkoutQuestionResponse> _responses = {};
  String? _userId;
  int _currentQuestionIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('=== WorkoutQuestionnaireScreen initState ===');
    // بارگذاری پرسشنامه با تاخیر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('=== شروع بارگذاری پرسشنامه ===');
      _loadQuestionnaire();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // بارگذاری مجدد پاسخ‌ها از SharedPreferences وقتی صفحه دوباره نمایش داده می‌شود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshResponses();
    });
  }

  /// بارگذاری مجدد پاسخ‌ها از SharedPreferences
  Future<void> _refreshResponses() async {
    try {
      if (_userId == null) {
        _userId = await AuthHelper.getCurrentUserId();
      }
      if (_userId == null) {
        return;
      }

      final responses = await _localStorage.getResponses(_userId!);
      SafeSetState.call(this, () {
        _responses = responses;
      });
      debugPrint(
        'پاسخ‌ها از SharedPreferences بارگذاری شدند: ${responses.keys.length} پاسخ',
      );
    } catch (e) {
      debugPrint('خطا در بارگذاری مجدد پاسخ‌ها: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionnaire() async {
    if (!mounted) return;

    SafeSetState.call(this, () => _isLoading = true);

    try {
      // دریافت شناسه کاربر واقعی
      _userId = await AuthHelper.getCurrentUserId();
      if (_userId == null) {
        debugPrint('هیچ کاربری وارد نشده است');
        SafeSetState.call(this, () => _isLoading = false);
        return;
      }

      debugPrint('کاربر واقعی وارد شده: $_userId');
      debugPrint('شروع بارگذاری پرسشنامه برای کاربر: $_userId');

      // دریافت سوالات از فایل JSON محلی
      final questions = await _questionsService.getQuestions(forceReload: true);
      debugPrint('تعداد سوالات دریافت شده: ${questions.length}');

      // دریافت پاسخ‌های ذخیره شده از SharedPreferences
      final savedResponses = await _localStorage.getResponses(_userId!);
      debugPrint('تعداد پاسخ‌های ذخیره شده: ${savedResponses.length}');

      SafeSetState.call(this, () {
        _questions = questions;
        _responses = savedResponses;
      });
    } catch (e) {
      debugPrint('خطا در بارگذاری پرسشنامه: $e');
    } finally {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  void _showError(String message) {
    // فقط در build method استفاده شود
    debugPrint('Error: $message');
    // حذف ScaffoldMessenger برای جلوگیری از ارور
  }

  /// به‌روزرسانی پاسخ در حافظه محلی و ذخیره در SharedPreferences
  Future<void> _updateLocalResponse(
    WorkoutQuestion question,
    dynamic answer,
  ) async {
    if (_userId == null) {
      _userId = await AuthHelper.getCurrentUserId();
      if (_userId == null) return;
    }

    final existingResponse = _responses[question.id];
    final updated = WorkoutQuestionResponse(
      questionId: question.id,
      answerText: answer is String ? answer : existingResponse?.answerText,
      answerNumber: answer is double ? answer : existingResponse?.answerNumber,
      answerChoices: answer is List<String>
          ? answer
          : (existingResponse?.answerChoices ?? []),
    );

    SafeSetState.call(this, () {
      _responses[question.id] = updated;
    });

    // ذخیره در SharedPreferences (بدون await برای سرعت)
    _localStorage.saveSingleResponse(_userId!, question.id, updated);
  }

  // تابع کمکی برای مقایسه لیست‌ها

  Future<void> _nextQuestion() async {
    debugPrint(
      'دکمه بعدی کلیک شد. سوال فعلی: $_currentQuestionIndex از ${_questions.length - 1}',
    );

    // ذخیره پاسخ‌ها در SharedPreferences قبل از رفتن به سوال بعدی
    if (_userId != null && _responses.isNotEmpty) {
      await _localStorage.saveResponses(_userId!, _responses);
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint('آخرین سوال - شروع تکمیل پرسشنامه...');
      _completeQuestionnaire();
    }
  }

  Future<void> _previousQuestion() async {
    if (_currentQuestionIndex > 0) {
      // ذخیره پاسخ‌ها در SharedPreferences قبل از رفتن به سوال قبلی
      if (_userId != null && _responses.isNotEmpty) {
        await _localStorage.saveResponses(_userId!, _responses);
      }

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeQuestionnaire() async {
    debugPrint('\n=== شروع تکمیل پرسشنامه ===');
    debugPrint('تعداد پاسخ‌های جمع‌آوری شده: ${_responses.length}');
    try {
      // ذخیره نهایی همه پاسخ‌ها در SharedPreferences
      if (_userId != null && _responses.isNotEmpty) {
        debugPrint('ذخیره پاسخ‌ها در SharedPreferences...');
        final saved = await _localStorage.saveResponses(_userId!, _responses);
        if (saved) {
          debugPrint('✅ همه پاسخ‌ها در SharedPreferences ذخیره شدند');
          
          // بررسی مجدد برای اطمینان
          final verifyResponses = await _localStorage.getResponses(_userId!);
          debugPrint('تأیید: ${verifyResponses.length} پاسخ در SharedPreferences موجود است');
        } else {
          debugPrint('⚠️ خطا در ذخیره پاسخ‌ها');
        }
      } else {
        debugPrint('⚠️ هشدار: userId یا responses خالی است');
        debugPrint('  userId: $_userId');
        debugPrint('  responses count: ${_responses.length}');
      }

      // نمایش صفحه تولید برنامه
      if (mounted) {
        debugPrint('نمایش دیالوگ تولید برنامه...');
        debugPrint('ارسال ${_responses.length} پاسخ و ${_questions.length} سوال به AI');
        _showWorkoutGenerationDialog();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ خطا در تکمیل پرسشنامه: $e');
      debugPrint('Stack trace: $stackTrace');
      _showError('خطا در تکمیل پرسشنامه: $e');
    }
  }

  /// نمایش دیالوگ تولید برنامه توسط جیم‌آی
  void _showWorkoutGenerationDialog() {
    if (_isGenerationDialogOpen) {
      return;
    }
    _isGenerationDialogOpen = true;
    debugPrint('نمایش دیالوگ تولید برنامه...');
    WidgetSafetyUtils.safeShowDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WorkoutGenerationDialog(
        questions: _questions,
        responses: _responses,
        onComplete: (program) async {
          debugPrint('برنامه تولید شد: ${program?.name}');
          WidgetSafetyUtils.safePop(context); // بستن دیالوگ
          if (program != null) {
            await _navigateToWorkoutBuilder(program);
          } else {
            if (!mounted) return;
            _showError(
              'متاسفانه امکان ساخت برنامه نبود. لطفاً بعداً دوباره تلاش کنید یا با مربی تماس بگیرید.',
            );
          }
          // اجازه نمایش مجدد در دفعات بعدی
          _isGenerationDialogOpen = false;
        },
      ),
    );
  }

  /// انتقال به صفحه Workout Builder
  Future<void> _navigateToWorkoutBuilder(WorkoutProgram program) async {
    try {
      debugPrint('شروع ذخیره برنامه در دیتابیس...');

      // دریافت شناسه AI Trainer (ایجاد در صورت عدم وجود)
      debugPrint('دریافت شناسه AI Trainer...');
      final aiTrainerId = await AITrainerService.ensureAITrainerExists();
      debugPrint('شناسه AI Trainer: $aiTrainerId');

      // ذخیره برنامه در دیتابیس
      debugPrint('ذخیره برنامه در دیتابیس...');
      final savedProgram = await WorkoutProgramService().createProgram(
        program,
        trainerId: aiTrainerId,
      );

      debugPrint('برنامه با موفقیت ذخیره شد: ${savedProgram.name}');

      // پاک کردن پاسخ‌های پرسشنامه از SharedPreferences بعد از تولید موفق برنامه
      if (_userId != null) {
        await _localStorage.clearResponses(_userId!);
        debugPrint('پاسخ‌های پرسشنامه از SharedPreferences پاک شدند');
      }

      // نمایش پیام موفقیت
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'برنامه تمرینی شما آماده و ذخیره شد! 🎉',
          backgroundColor: Colors.green,
        );

        WidgetSafetyUtils.safePop(context);

        // هدایت به صفحه برنامه‌های AI
        WidgetSafetyUtils.safePushReplacementNamed(
          context,
          '/ai-programs',
        );
      }
    } catch (e) {
      debugPrint('خطا در ذخیره برنامه: $e');
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در ذخیره برنامه: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  double get _progress {
    if (_questions.isEmpty) return 0;
    return (_currentQuestionIndex + 1) / _questions.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(scaffoldBackgroundColor: context.backgroundColor),
          child: Container(
            decoration: isDark
                ? null
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
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.goldColor,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
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
          child: Container(
            decoration: isDark
                ? null
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
                foregroundColor: isDark
                    ? AppTheme.goldColor
                    : context.textColor,
                title: Text(
                  'پرسشنامه برنامه تمرینی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              body: Center(
                child: Text(
                  'سوالی یافت نشد',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16.sp,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // مخفی کردن کیبورد هنگام کلیک روی صفحه
        FocusScope.of(context).unfocus();
      },
      child: Directionality(
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
          child: Container(
            decoration: isDark
                ? null
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
                foregroundColor: isDark
                    ? AppTheme.goldColor
                    : context.textColor,
                elevation: 0,
                title: Column(
                  children: [
                    Text(
                      'جیم‌آی مربی هوشمند',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    Text(
                      'برای طراحی برنامه شخصی‌سازی شده',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.8)
                            : context.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                leading: IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                    size: 24.sp,
                  ),
                  onPressed: () => WidgetSafetyUtils.safePop(context),
                ),
              ),
              body: Column(
                children: [
                  // پیام خوش‌آمدگویی از جیم‌آی
                  Container(
                    margin: EdgeInsets.all(16.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.1),
                          AppTheme.goldColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50.w,
                              height: 50.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.goldColor,
                                    AppTheme.darkGold,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 3.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                LucideIcons.bot,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'سلام! من جیم‌آی هستم 🤖',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: context.textColor,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'برای طراحی بهترین برنامه تمرینی، نیاز دارم اطلاعات شما را بدانم. بیایید شروع کنیم!',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14.sp,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // نوار پیشرفت
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'سوال ${_currentQuestionIndex + 1} از ${_questions.length}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14.sp,
                                color: context.textSecondary,
                              ),
                            ),
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14.sp,
                                color: AppTheme.goldColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.goldColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // سوالات
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        SafeSetState.call(this, () {
                          _currentQuestionIndex = index;
                        });
                      },
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        final response = _responses[question.id];

                        return Padding(
                          padding: EdgeInsets.all(16.w),
                          child: QuestionWidget(
                            question: question,
                            initialAnswer: _getInitialAnswer(
                              question,
                              response,
                            ),
                            onAnswerChanged: (answer) =>
                                _updateLocalResponse(question, answer),
                          ),
                        );
                      },
                    ),
                  ),

                  // دکمه‌های نویگیشن
                  Container(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        if (_currentQuestionIndex > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousQuestion,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppTheme.goldColor,
                                side: const BorderSide(
                                  color: AppTheme.goldColor,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'قبلی',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        if (_currentQuestionIndex > 0) SizedBox(width: 16.w),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.goldColor, AppTheme.darkGold],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 6.h),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_currentQuestionIndex ==
                                      _questions.length - 1) ...[
                                    Icon(LucideIcons.sparkles, size: 18.sp),
                                    SizedBox(width: 6.w),
                                  ],
                                  Flexible(
                                    child: Text(
                                      _currentQuestionIndex ==
                                              _questions.length - 1
                                          ? 'تولید برنامه توسط جیم‌آی'
                                          : 'بعدی',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  dynamic _getInitialAnswer(
    WorkoutQuestion question,
    WorkoutQuestionResponse? response,
  ) {
    if (response == null) return null;

    switch (question.questionType) {
      case QuestionType.singleChoice:
        return response.answerText;
      case QuestionType.multipleChoice:
        return response.answerChoices;
      case QuestionType.text:
        return response.answerText;
      case QuestionType.number:
        return response.answerNumber;
      case QuestionType.slider:
        return response.answerNumber;
    }
  }
}

/// دیالوگ تولید برنامه توسط جیم‌آی
class _WorkoutGenerationDialog extends StatefulWidget {
  const _WorkoutGenerationDialog({
    required this.questions,
    required this.responses,
    required this.onComplete,
  });
  final List<WorkoutQuestion> questions;
  final Map<String, WorkoutQuestionResponse> responses;
  final void Function(WorkoutProgram?) onComplete;

  @override
  State<_WorkoutGenerationDialog> createState() =>
      _WorkoutGenerationDialogState();
}

class _WorkoutGenerationDialogState extends State<_WorkoutGenerationDialog> {
  bool _isGenerating = true;
  String _statusMessage = 'جیم‌آی در حال تحلیل اطلاعات شما...';
  WorkoutProgram? _generatedProgram;

  @override
  void initState() {
    super.initState();
    _generateWorkout();
  }

  Future<void> _generateWorkout() async {
    try {
      SafeSetState.call(this, () {
        _statusMessage = 'جیم‌آی در حال تحلیل اطلاعات شما...';
      });

      await Future<void>.delayed(const Duration(seconds: 2));

      SafeSetState.call(this, () {
        _statusMessage = 'طراحی برنامه تمرینی شخصی‌سازی شده...';
      });

      await Future<void>.delayed(const Duration(seconds: 2));

      SafeSetState.call(this, () {
        _statusMessage = 'بهینه‌سازی حرکات و ست‌ها...';
      });

      // تولید برنامه توسط AI
      debugPrint('\n========================================');
      debugPrint('=== شروع تولید برنامه توسط AI ===');
      debugPrint('========================================');
      debugPrint('تعداد پاسخ‌های ارسالی: ${widget.responses.length}');
      debugPrint('تعداد سوالات ارسالی: ${widget.questions.length}');
      
      // لاگ کردن پاسخ‌های ارسالی
      debugPrint('\n--- پاسخ‌های ارسالی به AI ---');
      for (final entry in widget.responses.entries) {
        final response = entry.value;
        debugPrint('  سوال ID: ${entry.key}');
        if (response.answerText != null && response.answerText!.isNotEmpty) {
          debugPrint('    پاسخ متن: ${response.answerText}');
        }
        if (response.answerNumber != null) {
          debugPrint('    پاسخ عدد: ${response.answerNumber}');
        }
        if (response.answerChoices != null && response.answerChoices!.isNotEmpty) {
          debugPrint('    پاسخ انتخاب‌ها: ${response.answerChoices!.join(", ")}');
        }
      }
      
      final program = await AIWorkoutGeneratorService().generateWorkoutProgram(
        responses: widget.responses,
        questions: widget.questions,
      );

      debugPrint('\n--- نتیجه تولید برنامه ---');
      debugPrint('برنامه تولید شد: ${program?.name ?? "null"}');
      if (program != null) {
        debugPrint('✅ برنامه با موفقیت تولید شد و آماده ذخیره است');
        debugPrint('  - نام: ${program.name}');
        debugPrint('  - تعداد جلسات: ${program.sessions.length}');
      } else {
        debugPrint('❌ خطا: برنامه تولید نشد');
      }
      debugPrint('========================================\n');

      await Future<void>.delayed(const Duration(seconds: 1));

      // ذخیره برنامه در متغیر محلی
      _generatedProgram = program;

      SafeSetState.call(this, () {
        _isGenerating = false;
        _statusMessage = program != null
            ? 'برنامه تمرینی شما آماده است! 🎉'
            : 'خطا در تولید برنامه. لطفاً دوباره تلاش کنید.';
      });

      // فراخوانی callback
      if (program != null) {
        debugPrint('فراخوانی callback با برنامه: ${program.name}');
        // اطمینان از اینکه callback فقط یکبار فراخوانی می‌شود
        if (mounted) {
          widget.onComplete(program);
        }
      } else {
        debugPrint('فراخوانی callback با null');
        if (mounted) {
          widget.onComplete(null);
        }
      }
    } catch (e) {
      debugPrint('خطا در تولید برنامه: $e');
      SafeSetState.call(this, () {
        _isGenerating = false;
        _statusMessage = 'خطا در تولید برنامه: $e';
      });

      // فراخوانی callback با null
      debugPrint('فراخوانی callback با null (خطا)');
      if (mounted) {
        widget.onComplete(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // آیکون جیم‌آی
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.goldColor, AppTheme.darkGold],
                ),
                borderRadius: BorderRadius.circular(40.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.bot, color: Colors.white, size: 40),
            ),

            SizedBox(height: 20.h),

            // عنوان
            Text(
              'جیم‌آی در حال کار است',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),

            SizedBox(height: 16.h),

            // پیام وضعیت
            Text(
              _statusMessage,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16.sp,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20.h),

            // انیمیشن لودینگ یا دکمه
            if (_isGenerating) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_generatedProgram != null) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
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
                      child: ElevatedButton(
                        onPressed: () => widget.onComplete(_generatedProgram),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'مشاهده برنامه',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () => widget.onComplete(null),
                    child: Text(
                      'بستن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
