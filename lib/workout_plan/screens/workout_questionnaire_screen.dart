import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/ai/services/ai_workout_generator_service.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_plan/models/workout_questionnaire_models.dart';
import 'package:gymaipro/workout_plan/services/workout_questionnaire_service.dart';
import 'package:gymaipro/workout_plan/widgets/question_widget.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/services/workout_program_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutQuestionnaireScreen extends StatefulWidget {
  const WorkoutQuestionnaireScreen({super.key});

  @override
  State<WorkoutQuestionnaireScreen> createState() =>
      _WorkoutQuestionnaireScreenState();
}

class _WorkoutQuestionnaireScreenState
    extends State<WorkoutQuestionnaireScreen> {
  final WorkoutQuestionnaireService _service = WorkoutQuestionnaireService();
  bool _isGenerationDialogOpen = false;
  final PageController _pageController = PageController();

  List<WorkoutQuestion> _questions = [];
  Map<String, WorkoutQuestionResponse> _responses = {};
  WorkoutQuestionnaireSession? _session;
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

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
    // بارگذاری مجدد پاسخ‌ها وقتی صفحه دوباره نمایش داده می‌شود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshResponses();
    });
  }

  /// بارگذاری مجدد پاسخ‌ها از دیتابیس
  Future<void> _refreshResponses() async {
    try {
      // دریافت شناسه کاربر واقعی
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        return;
      }

      final responses = await _service.getUserResponses(userId);
      if (mounted) {
        setState(() {
          _responses = responses;
        });
        debugPrint('پاسخ‌ها بارگذاری مجدد شدند: ${responses.keys.length} پاسخ');
      }
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

    setState(() => _isLoading = true);

    try {
      // دریافت شناسه کاربر واقعی
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        debugPrint('هیچ کاربری وارد نشده است');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      debugPrint('کاربر واقعی وارد شده: $userId');

      debugPrint('شروع بارگذاری پرسشنامه برای کاربر: $userId');

      // تست مستقیم دسترسی به سوالات
      try {
        final directTest = await Supabase.instance.client
            .from('workout_questionnaire_questions')
            .select('id, question_text')
            .limit(1);
        debugPrint('تست مستقیم دسترسی: ${directTest.length} سوال');
        if (directTest.isNotEmpty) {
          debugPrint('اولین سوال تست: ${directTest.first['question_text']}');
        }
      } catch (directError) {
        debugPrint('خطا در تست مستقیم: $directError');
        debugPrint('نوع خطا: ${directError.runtimeType}');
        if (directError.toString().contains('RLS')) {
          debugPrint('مشکل RLS: سوالات قابل دسترسی نیستند');
        }
      }

      final questionnaire = await _service.getQuestionnaire(userId);
      if (questionnaire != null) {
        debugPrint(
          'پرسشنامه بارگذاری شد: ${questionnaire.questions.length} سوال، ${questionnaire.responses.length} پاسخ',
        );
        if (mounted) {
          setState(() {
            _questions = questionnaire.questions;
            _responses = questionnaire.responses;
            _session = questionnaire.session;
          });
        }
      } else {
        debugPrint('هیچ پرسشنامه‌ای یافت نشد، ایجاد جلسه جدید');
        // ایجاد جلسه جدید
        final newSession = await _service.createSession(userId);
        if (newSession != null && mounted) {
          setState(() {
            _session = newSession;
          });
          debugPrint('جلسه جدید ایجاد شد: ${newSession.id}');
        }
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری پرسشنامه: $e');
      // فقط در کنسول نمایش دهیم، نه در UI
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    // فقط در build method استفاده شود
    debugPrint('Error: $message');
    // حذف ScaffoldMessenger برای جلوگیری از ارور
  }

  /// به‌روزرسانی پاسخ در حافظه محلی و ذخیره فوری در سرور
  void _updateLocalResponse(WorkoutQuestion question, dynamic answer) {
    final existingResponse = _responses[question.id];
    final updated = WorkoutQuestionResponse(
      questionId: question.id,
      answerText: answer is String ? answer : existingResponse?.answerText,
      answerNumber: answer is double ? answer : existingResponse?.answerNumber,
      answerChoices: answer is List<String>
          ? answer
          : (existingResponse?.answerChoices ?? []),
    );
    setState(() {
      _responses[question.id] = updated;
    });

    // ذخیره فوری پاسخ در سرور
    _saveResponseImmediately(question, updated);
  }

  /// ذخیره فوری پاسخ در سرور
  Future<void> _saveResponseImmediately(
    WorkoutQuestion question,
    WorkoutQuestionResponse response,
  ) async {
    try {
      // دریافت شناسه کاربر واقعی
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return;

      // تعیین نوع پاسخ بر اساس نوع سوال
      dynamic answer;
      switch (question.questionType) {
        case QuestionType.text:
        case QuestionType.singleChoice:
          answer = response.answerText;
        case QuestionType.multipleChoice:
          answer = response.answerChoices;
        case QuestionType.number:
        case QuestionType.slider:
          answer = response.answerNumber;
      }

      debugPrint('ذخیره فوری پاسخ برای سوال: ${question.id}, پاسخ: $answer');

      final success = await _service.saveResponse(
        userId,
        question.id,
        answer,
        sessionId: _session?.id,
      );

      if (success) {
        debugPrint('پاسخ با موفقیت ذخیره شد (فوری): ${question.id}');
      } else {
        debugPrint('خطا در ذخیره فوری پاسخ: ${question.id}');
      }
    } catch (e) {
      debugPrint('خطا در ذخیره فوری پاسخ: $e');
    }
  }

  /// ذخیره اجباری پاسخ بدون بررسی تغییر
  Future<void> _forceSaveResponse(
    WorkoutQuestion question,
    WorkoutQuestionResponse response,
  ) async {
    if (_isSaving) {
      debugPrint('در حال ذخیره، صبر کنید...');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }

      // تعیین نوع پاسخ بر اساس نوع سوال
      dynamic answer;
      switch (question.questionType) {
        case QuestionType.text:
        case QuestionType.singleChoice:
          answer = response.answerText;
        case QuestionType.multipleChoice:
          answer = response.answerChoices;
        case QuestionType.number:
        case QuestionType.slider:
          answer = response.answerNumber;
      }

      // ذخیره اجباری پاسخ
      debugPrint('ذخیره اجباری پاسخ برای سوال: ${question.id}');
      // دریافت شناسه کاربر واقعی
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        debugPrint('هیچ کاربری وارد نشده است');
        return;
      }

      final success = await _service.saveResponse(
        userId,
        question.id,
        answer,
        sessionId: _session?.id,
      );

      if (success) {
        debugPrint('پاسخ با موفقیت ذخیره شد (اجباری): ${question.id}');
      } else {
        debugPrint('خطا در ذخیره اجباری پاسخ: ${question.id}');
      }
    } catch (e) {
      debugPrint('خطا در ذخیره اجباری پاسخ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // تابع کمکی برای مقایسه لیست‌ها

  Future<void> _nextQuestion() async {
    debugPrint(
      'دکمه بعدی کلیک شد. سوال فعلی: $_currentQuestionIndex از ${_questions.length - 1}',
    );

    // ذخیره پاسخ سوال فعلی قبل از رفتن به سوال بعدی
    if (_currentQuestionIndex < _questions.length) {
      final currentQuestion = _questions[_currentQuestionIndex];
      final currentResponse = _responses[currentQuestion.id];

      if (currentResponse != null) {
        // همیشه پاسخ را ذخیره کن، حتی اگر خالی باشد
        debugPrint(
          'ذخیره پاسخ سوال فعلی قبل از رفتن به سوال بعدی: ${currentQuestion.id}',
        );
        await _forceSaveResponse(currentQuestion, currentResponse);
      } else {
        debugPrint('هیچ پاسخی برای سوال ${currentQuestion.id} وجود ندارد');
      }
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
      // ذخیره پاسخ سوال فعلی قبل از رفتن به سوال قبلی
      final currentQuestion = _questions[_currentQuestionIndex];
      final currentResponse = _responses[currentQuestion.id];

      if (currentResponse != null) {
        // همیشه پاسخ را ذخیره کن
        debugPrint(
          'ذخیره پاسخ سوال فعلی قبل از رفتن به سوال قبلی: ${currentQuestion.id}',
        );
        await _forceSaveResponse(currentQuestion, currentResponse);
      }

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeQuestionnaire() async {
    debugPrint('شروع تکمیل پرسشنامه...');
    try {
      setState(() => _isSaving = true);

      // تکمیل جلسه (اگر وجود دارد)
      if (_session != null) {
        debugPrint('تکمیل جلسه: ${_session!.id}');
        await _service.completeSession(_session!.id);
      }

      // نمایش صفحه تولید برنامه
      if (mounted) {
        debugPrint('نمایش دیالوگ تولید برنامه...');
        _showWorkoutGenerationDialog();
      }
    } catch (e) {
      debugPrint('خطا در تکمیل پرسشنامه: $e');
      _showError('خطا در تکمیل پرسشنامه: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// نمایش دیالوگ تولید برنامه توسط جیم‌آی
  void _showWorkoutGenerationDialog() {
    if (_isGenerationDialogOpen) {
      return;
    }
    _isGenerationDialogOpen = true;
    debugPrint('نمایش دیالوگ تولید برنامه...');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WorkoutGenerationDialog(
        questions: _questions,
        responses: _responses,
        onComplete: (program) async {
          debugPrint('برنامه تولید شد: ${program?.name}');
          Navigator.of(context).pop(); // بستن دیالوگ
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

      // نمایش پیام موفقیت
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'برنامه تمرینی شما آماده و ذخیره شد! 🎉',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);

        // هدایت به صفحه برنامه‌های AI
        Navigator.pushReplacementNamed(context, '/ai-programs');
      }
    } catch (e) {
      debugPrint('خطا در ذخیره برنامه: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ذخیره برنامه: $e',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.goldColor,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.goldColor,
          title: Text(
            'پرسشنامه برنامه تمرینی',
            style: GoogleFonts.vazirmatn(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'سوالی یافت نشد',
            style: GoogleFonts.vazirmatn(
              fontSize: 16.sp,
              color: Colors.grey[600],
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
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.goldColor,
          elevation: 0,
          title: Column(
            children: [
              Text(
                'جیم‌آی مربی هوشمند',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              Text(
                'برای طراحی برنامه شخصی‌سازی شده',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(LucideIcons.x, color: Colors.white, size: 24.sp),
            onPressed: () => Navigator.pop(context),
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
                          color: AppTheme.goldColor,
                          borderRadius: BorderRadius.circular(25.r),
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
                              style: GoogleFonts.vazirmatn(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'برای طراحی بهترین برنامه تمرینی، نیاز دارم اطلاعات شما را بدانم. بیایید شروع کنیم!',
                              style: GoogleFonts.vazirmatn(
                                fontSize: 14.sp,
                                color: Colors.grey[700],
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
                        style: GoogleFonts.vazirmatn(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: GoogleFonts.vazirmatn(
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
                    backgroundColor: Colors.grey[300],
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
                  setState(() {
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
                      initialAnswer: _getInitialAnswer(question, response),
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
                      child: ElevatedButton(
                        onPressed: _previousQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppTheme.goldColor,
                          side: const BorderSide(color: AppTheme.goldColor),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: Text(
                          'قبلی',
                          style: GoogleFonts.vazirmatn(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_currentQuestionIndex ==
                                    _questions.length - 1) ...[
                                  Icon(LucideIcons.sparkles, size: 18.sp),
                                  SizedBox(width: 8.w),
                                ],
                                Text(
                                  _currentQuestionIndex == _questions.length - 1
                                      ? 'تولید برنامه توسط جیم‌آی'
                                      : 'بعدی',
                                  style: GoogleFonts.vazirmatn(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      setState(() {
        _statusMessage = 'جیم‌آی در حال تحلیل اطلاعات شما...';
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _statusMessage = 'طراحی برنامه تمرینی شخصی‌سازی شده...';
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _statusMessage = 'بهینه‌سازی حرکات و ست‌ها...';
      });

      // تولید برنامه توسط AI
      debugPrint('شروع تولید برنامه توسط AI...');
      final program = await AIWorkoutGeneratorService().generateWorkoutProgram(
        responses: widget.responses,
        questions: widget.questions,
      );

      debugPrint('برنامه تولید شد: ${program?.name}');
      if (program != null) {
        debugPrint('برنامه با موفقیت تولید شد و آماده ذخیره است');
      } else {
        debugPrint('خطا: برنامه تولید نشد');
      }

      await Future.delayed(const Duration(seconds: 1));

      // ذخیره برنامه در متغیر محلی
      _generatedProgram = program;

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = program != null
              ? 'برنامه تمرینی شما آماده است! 🎉'
              : 'خطا در تولید برنامه. لطفاً دوباره تلاش کنید.';
        });
      }

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
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = 'خطا در تولید برنامه: $e';
        });
      }

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
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // آیکون جیم‌آی
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppTheme.goldColor,
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: const Icon(LucideIcons.bot, color: Colors.white, size: 40),
            ),

            SizedBox(height: 20.h),

            // عنوان
            Text(
              'جیم‌آی در حال کار است',
              style: GoogleFonts.vazirmatn(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 16.h),

            // پیام وضعیت
            Text(
              _statusMessage,
              style: GoogleFonts.vazirmatn(
                fontSize: 16.sp,
                color: Colors.grey[700],
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
                    ElevatedButton(
                      onPressed: () => widget.onComplete(_generatedProgram),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                      ),
                      child: Text(
                        'مشاهده برنامه',
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () => widget.onComplete(null),
                    child: Text(
                      'بستن',
                      style: GoogleFonts.vazirmatn(color: Colors.grey[600]),
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
