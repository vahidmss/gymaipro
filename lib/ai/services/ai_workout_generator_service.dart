import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/services/ai_chat_availability.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/ai_exercise_read_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_questionnaire/models/workout_questionnaire_models.dart';

/// کلاس تحلیل علمی کاربر
class UserAnalysis {
  const UserAnalysis({
    required this.age,
    required this.experience,
    required this.injuries,
    required this.goals,
    required this.bodyFatPercentage,
    required this.activityLevel,
    required this.sleepHours,
    required this.stressLevel,
    required this.desiredIntensity,
    required this.riskLevel,
    required this.canReceiveOnlineProgram,
    required this.specialNeeds,
    required this.hasInjuries,
  });
  final int age;
  final String experience;
  final List<String> injuries;
  final List<String> goals;
  final String bodyFatPercentage;
  final String activityLevel;
  final String sleepHours;
  final String stressLevel;
  final String desiredIntensity; // سبک/شدت مطلوب: سنگین/متوسط/سبک
  final String riskLevel;
  final bool canReceiveOnlineProgram;
  final List<String> specialNeeds;
  final bool hasInjuries;
}

// حذف کلاس CardioExercise - به جای آن از NormalExercise استفاده می‌کنیم

class AIWorkoutGeneratorService {
  factory AIWorkoutGeneratorService() => _instance;
  AIWorkoutGeneratorService._internal();
  static final AIWorkoutGeneratorService _instance =
      AIWorkoutGeneratorService._internal();

  // gpt-4o-mini سریع‌تر است و کمتر 504 می‌دهد؛ برای کیفیت بالاتر: gpt-4o
  static const String _model = AppConfig.aiDefaultModel;
  static const int _workoutMaxTokens = 4096;
  static const Duration _workoutRequestTimeout = Duration(seconds: 60);

  // ذخیره آخرین پروفایل کاربر برای بهبود نام‌گذاری و پس‌پردازش خروجی
  Map<String, dynamic>? _lastUserProfile;

  // ذخیره آخرین تحلیل علمی کاربر (برای debug و logging)
  late UserAnalysis _lastUserAnalysis;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void print(Object? message) {
    _log('${message ?? ''}');
  }

  /// سوالات اجباری بدون پاسخ معتبر
  static List<WorkoutQuestion> findUnansweredRequired(
    Map<String, WorkoutQuestionResponse> responses,
    List<WorkoutQuestion> questions,
  ) {
    final missing = <WorkoutQuestion>[];
    for (final question in questions) {
      if (!question.isRequired) continue;
      final response = responses[question.id];
      if (response == null || !response.hasAnswer) {
        missing.add(question);
      }
    }
    return missing;
  }

  /// تولید برنامه تمرینی بر اساس پاسخ‌های پرسشنامه
  Future<WorkoutProgram?> generateWorkoutProgram({
    required Map<String, WorkoutQuestionResponse> responses,
    required List<WorkoutQuestion> questions,
  }) async {
    try {
      final missingRequired = findUnansweredRequired(responses, questions);
      if (missingRequired.isNotEmpty) {
        print(
          '❌ پرسشنامه ناقص است — ${missingRequired.length} سوال اجباری بدون پاسخ',
        );
        for (final q in missingRequired) {
          print('  - ${q.questionText}');
        }
        return null;
      }

      print('\n========================================');
      print('=== شروع تولید برنامه تمرینی حرفه‌ای ===');
      print('========================================');
      print('تعداد پاسخ‌ها: ${responses.length}');
      print('تعداد سوالات: ${questions.length}');
      print(
        'موتور AI: mode=${AiEngineConfig.mode.name}, '
        'openAi=${AiEngineConfig.canAttemptOpenAi}, '
        'deviceDirect=${AiEngineConfig.usesDeviceDirectRoute}, '
        'model=$_model',
      );

      // لاگ کردن پاسخ‌های دریافتی
      print('\n--- پاسخ‌های دریافتی ---');
      for (final entry in responses.entries) {
        final response = entry.value;
        print('  سوال ID: ${entry.key}');
        if (response.answerText != null) {
          print('    متن: ${response.answerText}');
        }
        if (response.answerNumber != null) {
          print('    عدد: ${response.answerNumber}');
        }
        if (response.answerChoices != null &&
            response.answerChoices!.isNotEmpty) {
          print('    انتخاب‌ها: ${response.answerChoices!.join(", ")}');
        }
      }

      // تبدیل پاسخ‌ها به پروفایل جامع
      final userProfile = _buildUserProfile(responses, questions);
      _lastUserProfile = userProfile;
      print('\n--- پروفایل کاربر ساخته شد ---');
      print('تعداد فیلدها: ${userProfile.keys.length}');

      // تحلیل علمی و پزشکی عمیق پاسخ‌های کاربر
      print('\n--- شروع تحلیل علمی کاربر ---');
      final analysis = _performUserAnalysis(userProfile);
      _lastUserAnalysis = analysis;
      print('تحلیل کامل شد:');
      print('  - سن: ${analysis.age} سال');
      print('  - سطح تجربه: ${analysis.experience}');
      print(
        '  - آسیب‌ها: ${analysis.injuries.isEmpty ? "ندارد" : analysis.injuries.join(", ")}',
      );
      print('  - اهداف: ${analysis.goals.join(", ")}');
      print('  - درصد چربی: ${analysis.bodyFatPercentage}');
      print('  - خواب: ${analysis.sleepHours}');
      print('  - شدت مطلوب: ${analysis.desiredIntensity}');
      print('  - سطح خطر: ${analysis.riskLevel}');
      print('  - امکان برنامه آنلاین: ${analysis.canReceiveOnlineProgram}');
      _lastUserAnalysis = analysis; // ذخیره برای استفاده در logging

      // بررسی امکان ارائه برنامه آنلاین
      if (!analysis.canReceiveOnlineProgram) {
        print(
          '\n⚠️ کاربر به دلیل مشکلات پزشکی نمی‌تواند برنامه آنلاین دریافت کند',
        );
        print('  - آسیب‌ها: ${analysis.injuries.join(", ")}');
        print('  - سطح خطر: ${analysis.riskLevel}');
        return _createMedicalReferralProgram(analysis);
      }

      // دریافت تمرینات مناسب از Supabase (جدول ai_exercises)
      print('\n--- دریافت تمرینات از دیتابیس ---');
      final availableExercises = await AIExerciseReadService()
          .getExercisesForAI();
      final exercisePool = availableExercises.whereType<Exercise>().toList();
      print('تعداد تمرینات دریافت شده: ${exercisePool.length}');
      if (exercisePool.isEmpty) {
        print('❌ هیچ تمرینی از Supabase دریافت نشد - عدم امکان تولید برنامه');
        return null;
      }

      // فیلتر کردن تمرینات بر اساس محدودیت‌های کاربر
      print('\n--- فیلتر کردن تمرینات بر اساس محدودیت‌ها ---');
      final suitableExercises = _filterExercisesByLimitations(
        exercisePool,
        analysis,
      );
      print('تعداد تمرینات مناسب: ${suitableExercises.length}');
      if (suitableExercises.isEmpty) {
        print('❌ هیچ تمرین مناسبی برای محدودیت‌های کاربر پیدا نشد');
        return _createLimitedOptionsProgram();
      }

      if (!AiEngineConfig.canAttemptOpenAi) {
        print(
          '⚠️ مسیر OpenAI غیرفعال است — بدون fallback آفلاین: '
          '$gymAiModelsUnavailableMessage',
        );
        return null;
      }

      print('\n--- ساخت پرامپت و تولید برنامه با OpenAI ---');
      final prompt = await _buildScientificPrompt(
        userProfile,
        analysis,
        suitableExercises,
      );
      print('✅ پرامپت علمی ساخته شد (${prompt.length} کاراکتر)');

      final program = await _generateFromPromptWithRetry(prompt, analysis);
      if (program != null) {
        print('\n========================================');
        print('✅ برنامه (OpenAI) با موفقیت تولید شد!');
        print('  - نام برنامه: ${program.name}');
        print('  - تعداد جلسات: ${program.sessions.length}');
        print('========================================\n');
        return program;
      }

      print(
        '\n❌ OpenAI برنامه نساخت — بدون fallback آفلاین: '
        '$gymAiModelsUnavailableMessage',
      );
      return null;
    } catch (e, stackTrace) {
      print('\n❌❌❌ خطا در تولید برنامه تمرینی ❌❌❌');
      print('خطا: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// درخواست، دریافت و پارس با یک بار ریتری در صورت JSON معیوب
  Future<WorkoutProgram?> _generateFromPromptWithRetry(
    String prompt,
    UserAnalysis analysis,
  ) async {
    print('ارسال درخواست به OpenAI...');
    String? response = await _sendRequestToOpenAI(prompt);

    if (response != null) {
      print('پاسخ از OpenAI دریافت شد');
      final program = await _parseWorkoutProgram(response, analysis);
      if (program != null) {
        final processed = _scientificPostProcessing(program, analysis);
        print('برنامه علمی تولید شد: ${processed.name}');
        return processed;
      }
      print('JSON معیوب بود؛ تلاش مجدد با دستور سخت‌گیرانه...');
    }

    // تلاش دوم با دستور سخت‌گیرانه و دمای کمتر
    final strictPrompt =
        '$prompt\n\nIMPORTANT: فقط و فقط یک شیء JSON معتبر استاندارد برگردان. هیچ متن اضافه‌ای مجاز نیست.';
    response = await _sendRequestToOpenAI(
      strictPrompt,
      temperature: 0.2,
    );
    if (response != null) {
      final program = await _parseWorkoutProgram(response, analysis);
      if (program != null) {
        final processed = _scientificPostProcessing(program, analysis);
        print('برنامه علمی تولید شد (پس از ریتری): ${processed.name}');
        return processed;
      }
    }
    return null;
  }

  /// ساخت پروفایل کاربر از پاسخ‌ها
  Map<String, dynamic> _buildUserProfile(
    Map<String, WorkoutQuestionResponse> responses,
    List<WorkoutQuestion> questions,
  ) {
    final profile = <String, dynamic>{};

    print('=== ساخت پروفایل کاربر ===');
    print('تعداد سوالات: ${questions.length}');
    print('تعداد پاسخ‌ها: ${responses.length}');

    for (final question in questions) {
      final response = responses[question.id];
      String answer = '';

      if (response == null || !response.hasAnswer) {
        continue;
      }

      switch (question.questionType) {
        case QuestionType.text:
        case QuestionType.singleChoice:
          answer = response.answerText ?? '';
        case QuestionType.multipleChoice:
          answer = response.answerChoices?.join(', ') ?? '';
        case QuestionType.number:
        case QuestionType.slider:
          answer = response.answerNumber?.toString() ?? '';
      }

      // ذخیره هم با متن سوال و هم با ID برای دسترسی بهتر
      if (answer.isNotEmpty) {
        profile[question.questionText] = answer;
        profile[question.id] = answer; // برای دسترسی مستقیم با ID
        print('  سوال: ${question.id} = $answer');
      }
    }

    print('پروفایل ساخته شد با ${profile.length} فیلد');
    return profile;
  }

  /// تحلیل علمی و پزشکی جامع کاربر
  UserAnalysis _performUserAnalysis(Map<String, dynamic> profile) {
    // استخراج اطلاعات پایه
    final age = _extractAge(profile);
    final experience = _extractExperienceLevel(profile);
    final injuries = _extractInjuries(profile);
    final goals = _extractGoals(profile);
    final bodyFat = _extractBodyFatPercentage(profile);
    final activityLevel = _extractActivityLevel(profile);
    final sleepQuality = _extractSleepHours(profile);
    final stressLevel = _extractStressLevel(profile);
    final desiredIntensity = _extractDesiredIntensity(profile);

    // محاسبه سطح خطر
    final riskLevel = _calculateRiskLevel(
      age,
      injuries,
      experience,
      stressLevel,
    );

    // تعیین امکان ارائه برنامه آنلاین
    final canReceiveOnline = _canReceiveOnlineProgram(
      injuries,
      age,
      experience,
      riskLevel,
    );

    // تحلیل نیازهای ویژه
    final specialNeeds = _identifySpecialNeeds(goals, bodyFat, age, experience);

    return UserAnalysis(
      age: age,
      experience: experience,
      injuries: injuries,
      goals: goals,
      bodyFatPercentage: bodyFat,
      activityLevel: activityLevel,
      sleepHours: sleepQuality,
      stressLevel: stressLevel,
      desiredIntensity: desiredIntensity,
      riskLevel: riskLevel,
      canReceiveOnlineProgram: canReceiveOnline,
      specialNeeds: specialNeeds,
      hasInjuries: injuries.isNotEmpty,
    );
  }

  /// استخراج سن کاربر
  int _extractAge(Map<String, dynamic> profile) {
    try {
      // اول با ID سوال جستجو کن
      if (profile.containsKey('bb_age')) {
        final ageValue = profile['bb_age'];
        final age = _parseIntFromProfileValue(ageValue, fallback: 25);
        print('سن استخراج شد (با ID): $age');
        return age;
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('سن') || e.key.toLowerCase().contains('age'),
        orElse: () => const MapEntry('', '25'),
      );
      final age = int.tryParse(entry.value.toString()) ?? 25;
      print('سن استخراج شد (با متن): $age');
      return age;
    } catch (e) {
      print('خطا در استخراج سن: $e');
      return 25;
    }
  }

  /// استخراج سطح تجربه
  String _extractExperienceLevel(Map<String, dynamic> profile) {
    try {
      // اول با ID سوال جستجو کن
      if (profile.containsKey('bb_experience_level')) {
        final value = profile['bb_experience_level'].toString();
        print('سطح تجربه استخراج شد (با ID): $value');
        return _mapExperienceLabel(value);
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('تجربه') || e.key.contains('سطح'),
        orElse: () => const MapEntry('', 'متوسط'),
      );
      final value = entry.value.toString();
      print('سطح تجربه استخراج شد (با متن): $value');

      return _mapExperienceLabel(value);
    } catch (e) {
      print('خطا در استخراج سطح تجربه: $e');
      return 'متوسط';
    }
  }

  int _parseIntFromProfileValue(Object? value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    final text = value.toString().trim();
    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble.round();
    return fallback;
  }

  String _mapExperienceLabel(String value) {
    if (value.contains('نیمه') && value.contains('مبتدی')) {
      return 'نیمه‌مبتدی';
    }
    if (value.contains('حرفه') ||
        value.contains('پیشرفته') ||
        value.contains('3+ سال')) {
      return 'حرفه‌ای';
    }
    if (value.contains('متوسط') || value.contains('1.5 تا 3')) {
      return 'متوسط';
    }
    if (value.contains('مبتدی') || value.contains('0 تا 6 ماه')) {
      return 'مبتدی';
    }
    return 'متوسط';
  }

  /// استخراج آسیب‌دیدگی‌ها
  List<String> _extractInjuries(Map<String, dynamic> profile) {
    try {
      final injuries = <String>[];

      // اول با ID سوال آسیب‌ها جستجو کن
      if (profile.containsKey('bb_injury_areas')) {
        final value = profile['bb_injury_areas'].toString();
        print('آسیب‌ها استخراج شد (با ID): $value');

        if (value.contains('ندارم') || value.isEmpty) {
          return [];
        }

        // استخراج آسیب‌ها از پاسخ multiple choice
        if (value.contains('شانه')) injuries.add('شانه');
        if (value.contains('آرنج')) injuries.add('آرنج');
        if (value.contains('مچ دست')) injuries.add('مچ');
        if (value.contains('گردن')) injuries.add('گردن');
        if (value.contains('کمر')) injuries.add('کمر');
        if (value.contains('لگن')) injuries.add('لگن');
        if (value.contains('زانو')) injuries.add('زانو');
        if (value.contains('مچ پا')) injuries.add('مچ پا');
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      if (injuries.isEmpty) {
        final entry = profile.entries.firstWhere(
          (e) =>
              e.key.contains('آسیب') ||
              e.key.contains('محدودیت') ||
              e.key.contains('درد'),
          orElse: () => const MapEntry('', 'ندارم'),
        );
        final value = entry.value.toString();
        print('آسیب‌ها استخراج شد (با متن): $value');

        if (value.contains('ندارم') || value.contains('خیر') || value.isEmpty) {
          return [];
        }

        if (value.contains('کمر')) injuries.add('کمر');
        if (value.contains('زانو')) injuries.add('زانو');
        if (value.contains('شانه')) injuries.add('شانه');
        if (value.contains('آرنج')) injuries.add('آرنج');
        if (value.contains('مچ')) injuries.add('مچ');
        if (value.contains('گردن')) injuries.add('گردن');
        if (value.contains('لگن')) injuries.add('لگن');
      }

      print('آسیب‌های استخراج شده: ${injuries.join(", ")}');
      return injuries;
    } catch (e) {
      print('خطا در استخراج آسیب‌ها: $e');
      return [];
    }
  }

  /// استخراج اهداف کاربر
  List<String> _extractGoals(Map<String, dynamic> profile) {
    try {
      final goals = <String>[];

      // اول با ID سوال هدف جستجو کن
      if (profile.containsKey('bb_goal_primary')) {
        final value = profile['bb_goal_primary'].toString();
        print('هدف استخراج شد (با ID): $value');

        if (value.contains('افزایش حجم') || value.contains('Bulk')) {
          goals.add('حجم‌سازی');
        }
        if (value.contains('کات') ||
            value.contains('کاهش چربی') ||
            value.contains('Cut')) {
          goals.add('چربی‌سوزی');
        }
        if (value.contains('ریکامپ') ||
            value.contains('هم عضله، هم چربی کمتر')) {
          goals
            ..add('ریکامپ')
            ..add('حجم‌سازی')
            ..add('چربی‌سوزی');
        }
        if (value.contains('بهبود فرم') || value.contains('تناسب')) {
          goals.add('تناسب اندام');
        }
        if (value.contains('آماده‌سازی مسابقه') || value.contains('فیزیک')) {
          goals
            ..add('آماده‌سازی مسابقه')
            ..add('چربی‌سوزی');
        }
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      if (goals.isEmpty) {
        final entry = profile.entries.firstWhere(
          (e) => e.key.contains('هدف') || e.key.toLowerCase().contains('goal'),
          orElse: () => const MapEntry('', 'تناسب اندام'),
        );
        final value = entry.value.toString();
        print('هدف استخراج شد (با متن): $value');

        if (value.contains('حجم') ||
            value.contains('Hypertrophy') ||
            value.contains('Bulk')) {
          goals.add('حجم‌سازی');
        }
        if (value.contains('چربی') ||
            value.contains('لاغری') ||
            value.contains('کات') ||
            value.contains('Cut')) {
          goals.add('چربی‌سوزی');
        }
        if (value.contains('قدرت')) {
          goals.add('قدرت');
        }
        if (value.contains('استقامت')) {
          goals.add('استقامت');
        }
        if (value.contains('ریکامپ')) {
          goals
            ..add('ریکامپ')
            ..add('حجم‌سازی')
            ..add('چربی‌سوزی');
        }
      }

      if (goals.isEmpty) {
        goals.add('تناسب اندام');
      }

      print('اهداف استخراج شده: ${goals.join(", ")}');
      return goals;
    } catch (e) {
      print('خطا در استخراج اهداف: $e');
      return ['تناسب اندام'];
    }
  }

  /// استخراج درصد چربی بدن
  String _extractBodyFatPercentage(Map<String, dynamic> profile) {
    try {
      // اول با ID سوال جستجو کن
      if (profile.containsKey('bb_bodyfat_estimate')) {
        final value = profile['bb_bodyfat_estimate'].toString();
        print('درصد چربی استخراج شد (با ID): $value');

        if (value.contains('خیلی کم') || value.contains('10-12%')) {
          return 'خیلی کم';
        }
        if (value.contains('کم') || value.contains('13-15%')) return 'کم';
        if (value.contains('متوسط') || value.contains('16-20%')) return 'متوسط';
        if (value.contains('بالا') || value.contains('21-25%')) return 'زیاد';
        if (value.contains('خیلی بالا') || value.contains('26%+')) {
          return 'خیلی زیاد';
        }
        return 'متوسط';
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      final entry = profile.entries.firstWhere(
        (e) =>
            e.key.contains('چربی') || e.key.toLowerCase().contains('bodyfat'),
        orElse: () => const MapEntry('', 'متوسط'),
      );
      final value = entry.value.toString();
      print('درصد چربی استخراج شد (با متن): $value');

      if (value.contains('خیلی کم') || value.contains('10%')) return 'خیلی کم';
      if (value.contains('کم') || value.contains('13%')) return 'کم';
      if (value.contains('زیاد') ||
          value.contains('21%') ||
          value.contains('20%')) {
        return 'زیاد';
      }
      if (value.contains('خیلی زیاد') ||
          value.contains('26%') ||
          value.contains('30%')) {
        return 'خیلی زیاد';
      }
      return 'متوسط';
    } catch (e) {
      print('خطا در استخراج درصد چربی: $e');
      return 'متوسط';
    }
  }

  /// استخراج سطح فعالیت روزانه
  String _extractActivityLevel(Map<String, dynamic> profile) {
    try {
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('فعالیت روزانه'),
        orElse: () => const MapEntry('', 'متوسط'),
      );
      final value = entry.value.toString();
      if (value.contains('کم') || value.contains('اداری')) return 'کم';
      if (value.contains('زیاد') || value.contains('فیزیکی')) return 'زیاد';
      return 'متوسط';
    } catch (_) {
      return 'متوسط';
    }
  }

  /// استخراج ساعات خواب
  String _extractSleepHours(Map<String, dynamic> profile) {
    try {
      // اول با ID سوال جستجو کن
      if (profile.containsKey('bb_sleep_hours')) {
        final value = profile['bb_sleep_hours'].toString();
        print('ساعات خواب استخراج شد (با ID): $value');

        final hours = double.tryParse(value) ?? 7.0;
        if (hours < 6) return 'کم';
        if (hours > 8) return 'زیاد';
        return 'مناسب';
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('خواب') || e.key.toLowerCase().contains('sleep'),
        orElse: () => const MapEntry('', '7'),
      );
      final value = entry.value.toString();
      print('ساعات خواب استخراج شد (با متن): $value');

      final hours = double.tryParse(value) ?? 7.0;
      if (hours < 6) return 'کم';
      if (hours > 8) return 'زیاد';
      return 'مناسب';
    } catch (e) {
      print('خطا در استخراج ساعات خواب: $e');
      return 'مناسب';
    }
  }

  /// استخراج سطح استرس
  String _extractStressLevel(Map<String, dynamic> profile) {
    try {
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('استرس'),
        orElse: () => const MapEntry('', 'متوسط'),
      );
      final value = entry.value.toString();
      if (value.contains('کم')) return 'کم';
      if (value.contains('زیاد')) return 'زیاد';
      return 'متوسط';
    } catch (_) {
      return 'متوسط';
    }
  }

  /// استخراج شدت/سختی مطلوب کاربر (سنگین/متوسط/سبک)
  String _extractDesiredIntensity(Map<String, dynamic> profile) {
    try {
      // اول با ID سوال جستجو کن
      if (profile.containsKey('bb_effort_level')) {
        final value = profile['bb_effort_level'].toString().toLowerCase();
        print('شدت تمرین استخراج شد (با ID): $value');

        if (value.contains('تقریباً تا ناتوانی') ||
            value.contains('0-1 تکرار در ذخیره')) {
          return 'سنگین';
        }
        if (value.contains('نزدیک ناتوانی') ||
            value.contains('1-2 تکرار در ذخیره')) {
          return 'سنگین';
        }
        if (value.contains('با فاصله') || value.contains('3+ تکرار در ذخیره')) {
          return 'متوسط';
        }
        return 'متوسط';
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      final entry = profile.entries.firstWhere(
        (e) =>
            e.key.contains('شدت') ||
            e.key.contains('سختی') ||
            e.key.contains('فشار') ||
            e.key.contains('ناتوانی') ||
            e.key.toLowerCase().contains('intensity') ||
            e.key.toLowerCase().contains('difficulty') ||
            e.key.toLowerCase().contains('effort'),
        orElse: () => const MapEntry('', 'متوسط'),
      );
      final value = entry.value.toString().toLowerCase();
      print('شدت تمرین استخراج شد (با متن): $value');

      if (value.contains('سنگین') ||
          value.contains('شدید') ||
          value.contains('heavy') ||
          value.contains('پرفشار') ||
          value.contains('ناتوانی') ||
          value.contains('0-1')) {
        return 'سنگین';
      }
      if (value.contains('سبک') ||
          value.contains('light') ||
          value.contains('3+')) {
        return 'سبک';
      }
      return 'متوسط';
    } catch (e) {
      print('خطا در استخراج شدت تمرین: $e');
      return 'متوسط';
    }
  }

  /// محاسبه سطح خطر کلی
  String _calculateRiskLevel(
    int age,
    List<String> injuries,
    String experience,
    String stress,
  ) {
    int riskScore = 0;

    // امتیاز سن
    if (age > 50) {
      riskScore += 2;
    } else if (age > 40) {
      riskScore += 1;
    }

    // امتیاز آسیب‌دیدگی
    riskScore += injuries.length;
    if (injuries.contains('کمر') || injuries.contains('زانو')) riskScore += 2;

    // امتیاز تجربه
    if (experience == 'مبتدی') riskScore += 1;

    // امتیاز استرس
    if (stress == 'زیاد') riskScore += 1;

    if (riskScore >= 5) return 'بالا';
    if (riskScore >= 3) return 'متوسط';
    return 'کم';
  }

  /// تعیین امکان ارائه برنامه آنلاین
  bool _canReceiveOnlineProgram(
    List<String> injuries,
    int age,
    String experience,
    String riskLevel,
  ) {
    // شرایط مانع:
    // 1. آسیب‌های متعدد و شدید
    if (injuries.length >= 3) return false;
    if (injuries.contains('کمر') && injuries.contains('زانو')) return false;

    // 2. سن بالا با آسیب
    if (age > 60 && injuries.isNotEmpty) return false;

    // 3. مبتدی با آسیب‌های شدید
    if (experience == 'مبتدی' &&
        (injuries.contains('کمر') || injuries.contains('شانه'))) {
      return false;
    }

    // 4. سطح خطر بالا
    if (riskLevel == 'بالا') return false;

    return true;
  }

  /// شناسایی نیازهای ویژه کاربر
  List<String> _identifySpecialNeeds(
    List<String> goals,
    String bodyFat,
    int age,
    String experience,
  ) {
    final needs = <String>[];

    if (goals.contains('چربی‌سوزی')) {
      needs
        ..add('کاردیو اجباری')
        ..add('تمرینات مقاومتی با تکرار بالا');
    }

    if (goals.contains('حجم‌سازی')) {
      needs
        ..add('تمرینات چندمفصلی')
        ..add('محدوده هایپرتروفی');
    }

    if (age > 45) {
      needs
        ..add('گرم کردن طولانی‌تر')
        ..add('استراحت بیشتر بین ست‌ها');
    }

    if (experience == 'مبتدی') {
      needs
        ..add('تمرینات ساده و پایه')
        ..add('آموزش فرم صحیح');
    }

    return needs;
  }

  /// فیلتر کردن تمرینات بر اساس محدودیت‌های کاربر
  List<Exercise> _filterExercisesByLimitations(
    List<Exercise> exercises,
    UserAnalysis analysis,
  ) {
    return exercises.where((exercise) {
      final name = exercise.name.toLowerCase();

      // حذف تمرینات خطرناک برای آسیب‌دیدگی‌ها
      for (final injury in analysis.injuries) {
        if (injury == 'کمر') {
          if (name.contains('ددلیفت') ||
              name.contains('اسکوات') ||
              name.contains('زیر بغل') && name.contains('خم')) {
            return false;
          }
        }
        if (injury == 'زانو') {
          if (name.contains('اسکوات') ||
              name.contains('لانج') ||
              name.contains('پرس پا')) {
            return false;
          }
        }
        if (injury == 'شانه') {
          if (name.contains('پرس بالا') ||
              name.contains('پرس سرشانه') ||
              name.contains('نشر جانب')) {
            return false;
          }
        }
      }

      // فیلتر براساس سطح تجربه
      if (analysis.experience == 'مبتدی') {
        // فقط تمرینات ساده
        final difficulty = exercise.difficulty.toLowerCase();
        if (difficulty.contains('سخت') || difficulty.contains('پیشرفته')) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// لیست تمرینات ممنوع برای هر آسیب
  List<String> _getProhibitedExercises(List<String> injuries) {
    final prohibited = <String>{};

    for (final injury in injuries) {
      switch (injury) {
        case 'کمر':
          prohibited.addAll(['ددلیفت', 'اسکوات عمیق', 'زیر بغل خم']);
        case 'زانو':
          prohibited.addAll(['اسکوات', 'لانج', 'پرس پا']);
        case 'شانه':
          prohibited.addAll(['پرس بالای سر', 'نشر جانب', 'پرس پشت گردن']);
        case 'آرنج':
          prohibited.addAll(['دیپ', 'پرس سینه باریک', 'پشت بازو بالای سر']);
        case 'مچ':
          prohibited.addAll(['پرس سینه', 'جلو بازو', 'پلانک']);
      }
    }

    return prohibited.toList();
  }

  /// ساخت prompt علمی و حرفه‌ای برای مربی هوشمند
  Future<String> _buildScientificPrompt(
    Map<String, dynamic> userProfile,
    UserAnalysis analysis,
    List<Exercise> suitableExercises,
  ) async {
    // کاهش حجم پرامپت: فقط لیست نام‌ها و حداکثر 120 مورد
    final List<String> allNames = suitableExercises
        .map<String>((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final List<String> limitedNames = allNames.take(120).toList();
    final String availableExerciseNames = limitedNames.join(', ');
    // حذف اطلاعات تفصیلی برای کاهش طول پرامپت

    // استخراج معلومات کلیدی برای JSON
    final int targetSessions = _extractDaysFromProfile(userProfile);
    print('تعداد جلسات هدف: $targetSessions'); // استفاده برای logging

    // استخراج اطلاعات اضافی از پروفایل
    final equipment = _extractEquipment(userProfile);
    final splitPreference = _extractSplitPreference(userProfile);
    final priorityMuscles = _extractPriorityMuscles(userProfile);
    final compoundMovements = _extractCompoundMovements(userProfile);
    final injuryDetails = _extractInjuryDetails(userProfile);
    final extraNotes = _extractExtraNotes(userProfile);
    final trainingConsistency = _extractTrainingConsistency(userProfile);
    final sex = _extractSex(userProfile);
    final weight = _extractWeight(userProfile);
    final height = _extractHeight(userProfile);
    final stylePreference = _extractStylePreference(userProfile);

    return '''
شما یک مربی بدنسازی خبره و متخصص فیزیوتراپی با 20 سال تجربه در طراحی برنامه‌های تمرینی علمی و حرفه‌ای هستید. وظیفه شما طراحی برنامه‌ای است که هم اهداف کاربر را محقق کند و هم کاملاً ایمن و قابل اجرا باشد.

### اطلاعات کامل کاربر:
${userProfile.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

### تحلیل علمی و حرفه‌ای کاربر:
- **سن**: ${analysis.age} سال
- **جنسیت**: $sex
- **قد**: $height سانتی‌متر
- **وزن**: $weight کیلوگرم
- **سطح تجربه**: ${analysis.experience}
- **تداوم تمرین در 3 ماه اخیر**: $trainingConsistency
- **آسیب‌دیدگی‌ها**: ${analysis.injuries.isEmpty ? 'ندارد' : analysis.injuries.join(', ')}
${injuryDetails.isNotEmpty ? '- **جزئیات آسیب‌ها**: $injuryDetails' : ''}
- **اهداف اصلی**: ${analysis.goals.join(', ')}
- **درصد چربی بدن**: ${analysis.bodyFatPercentage}
- **ساعات خواب شبانه**: ${analysis.sleepHours} (${_extractSleepHoursRaw(userProfile)} ساعت)
- **سطح فعالیت روزانه**: ${analysis.activityLevel}
- **سطح استرس**: ${analysis.stressLevel}
- **شدت مطلوب تمرین**: ${analysis.desiredIntensity}
- **سطح خطر**: ${analysis.riskLevel}
- **نیازهای ویژه**: ${analysis.specialNeeds.join(', ')}

### اطلاعات تمرین:
- **تعداد روزهای تمرین در هفته**: ${_extractDaysFromProfile(userProfile)} روز
- **مدت زمان هر جلسه**: ${_extractSessionDurationRaw(userProfile)} دقیقه
- **دسترسی به تجهیزات**: $equipment
- **ترجیح سبک تمرین**: $stylePreference
- **ترجیح تقسیم‌بندی**: $splitPreference
- **عضلات اولویت**: ${priorityMuscles.isNotEmpty ? priorityMuscles.join(', ') : 'بدون اولویت خاص'}
- **حرکات پایه راحت**: ${compoundMovements.isNotEmpty ? compoundMovements.join(', ') : 'نیاز به آموزش'}
${extraNotes.isNotEmpty ? '- **یادداشت‌های اضافی**: $extraNotes' : ''}

### اصول علمی حتمی (مثل یک مربی 20 ساله):
1. **ایمنی مطلق اولویت اول**: هیچ تمرینی که با آسیب‌دیدگی‌های کاربر تداخل داشته باشد انتخاب نشود. ${analysis.injuries.isNotEmpty ? 'تمرینات جایگزین ایمن برای ${analysis.injuries.join(", ")} استفاده شود.' : ''}
2. **تطبیق دقیق با سطح تجربه**: حجم، پیچیدگی و شدت دقیقاً متناسب با تجربه ${analysis.experience} باشد. ${analysis.experience == 'مبتدی'
        ? 'تمرکز بر آموزش فرم صحیح و حرکات پایه.'
        : analysis.experience == 'حرفه‌ای'
        ? 'استفاده از تکنیک‌های پیشرفته و برنامه‌های پیچیده مجاز است.'
        : 'تعادل بین پایه و پیشرفته.'}
3. **اهداف محور و علمی**: ${analysis.goals.contains('چربی‌سوزی')
        ? 'شامل تمرینات هوازی (15-20 دقیقه در پایان هر جلسه) و مقاومتی با تکرار بالا (12-20 تکرار) برای حداکثر کالری‌سوزی. استراحت کوتاه‌تر (30-60 ثانیه) بین ست‌ها.'
        : analysis.goals.contains('حجم‌سازی')
        ? 'تمرکز بر هایپرتروفی با محدوده 8-12 تکرار. استراحت 2-3 دقیقه بین ست‌ها برای ریکاوری کامل. حجم تمرین بالا.'
        : analysis.goals.contains('ریکامپ')
        ? 'ترکیب هوازی متوسط و مقاومتی با تکرار 8-12. تعادل بین حجم و چربی‌سوزی.'
        : 'متناسب با هدف مشخص شده'}
4. **تدریجی بودن و پیشرفت علمی**: پیشرفت هفتگی کنترل‌شده (افزایش 2.5-5% وزن یا 1-2 تکرار). از افزایش ناگهانی حجم یا شدت پرهیز شود.
5. **بازیابی و ریکاوری مناسب**: ${analysis.stressLevel == 'زیاد' ? 'توجه ویژه به استراحت بیشتر بین ست‌ها و روزهای استراحت. کاهش حجم تمرین.' : 'استراحت استاندارد بین ست‌ها و روزهای استراحت کافی.'} خواب ${analysis.sleepHours} ساعت باید در نظر گرفته شود.
6. **شدت مطلوب کاربر**: کاربر «${analysis.desiredIntensity}» می‌خواهد. شدت واقعی تمرین‌ها، حجم ست/تکرار/زمان، استراحت بین ست‌ها، و انتخاب حرکات باید این را بازتاب دهد.
   - برای «سنگین»: حرکات چندمفصلی بیشتر، محدوده تکرار پایین‌تر (4-8 تکرار) یا ست‌های زمان‌محور با RPE بالا (8-10)، استراحت بلندتر (3-5 دقیقه)، حجم متوسط.
   - برای «متوسط»: محدوده کلاسیک هایپرتروفی (8-12 تکرار)، استراحت متوسط (2-3 دقیقه)، حجم متعادل.
   - برای «سبک»: حجم کمتر، استراحت کوتاه‌تر (60-90 ثانیه)، شدت ذهنی کمتر (RPE 6-7)، تکرار بیشتر (12-15).
7. **تطبیق با تجهیزات**: برنامه باید کاملاً با دسترسی به «$equipment» سازگار باشد.
8. **تقسیم‌بندی مناسب**: استفاده از «$splitPreference» با توجه به ${_extractDaysFromProfile(userProfile)} روز تمرین در هفته.
9. **اولویت عضلات**: ${priorityMuscles.isNotEmpty ? 'تمرکز بیشتر روی ${priorityMuscles.join(", ")} با حجم و تکرار بالاتر.' : 'توزیع متعادل حجم بین همه گروه‌های عضلانی.'}
10. **حرکات پایه**: ${compoundMovements.isNotEmpty ? 'استفاده از ${compoundMovements.join(", ")} در برنامه.' : 'استفاده از حرکات پایه ساده‌تر و آموزش فرم صحیح.'}

### فهرست نام‌های تمرینات (فقط از این نام‌ها استفاده کنید):
$availableExerciseNames

**مهم**: در JSON خروجی، برای هر تمرین باید دقیقاً یکی از نام‌های بالا را در فیلد `tag` یا `name` قرار دهید. از نام‌های انگلیسی یا نام‌های دیگر استفاده نکنید.

### محدودیت‌های اجباری برای این کاربر:
${analysis.injuries.isNotEmpty ? '- تمرینات ممنوع: ${_getProhibitedExercises(analysis.injuries).join(', ')}' : '- محدودیت خاصی ندارد'}
${analysis.riskLevel == 'بالا' ? '- اولویت با تمرینات دستگاهی و کنترل‌شده' : ''}
${analysis.experience == 'مبتدی'
        ? '- حداکثر 4-5 حرکت در هر جلسه'
        : analysis.experience == 'حرفه‌ای'
        ? '- تا 7-8 حرکت مجاز'
        : '- 5-6 حرکت در هر جلسه'}

برنامه تمرینی را در قالب JSON زیر برگردانید. خروجی باید دقیقاً ${_extractDaysFromProfile(userProfile)} جلسه در آرایه sessions داشته باشد (نه کمتر، نه بیشتر). 

**قوانین مهم برای تمرینات:**
1. برای هر تمرین، حتماً از یکی از نام‌های موجود در فهرست بالا استفاده کنید (نام فارسی کامل)
2. فیلد `tag` باید دقیقاً همان نام فارسی تمرین باشد که در فهرست بالا آمده است
3. فیلد `exercise_id` را 0 قرار دهید (سیستم خودش ID را پیدا می‌کند)
4. برای هر تمرین، یکی از دو سبک زیر را الزاماً مشخص کنید:
   - sets_reps: ست‌های تکرارمحور با کلیدهای {"reps": number}
   - sets_time: ست‌های زمان‌محور با کلیدهای {"time_seconds": number}
5. در صورت هدف هوازی/کاردیو، از سبک sets_time با زمان 600 تا 1200 ثانیه استفاده کنید

**مثال صحیح:**
{"type":"normal","tag":"پرس سینه هالتر", "style":"sets_reps","exercise_id":0,"sets":[{"reps":10}]}

**مثال غلط (استفاده نکنید):**
{"type":"normal","tag":"bench_press", "style":"sets_reps","exercise_id":0,"sets":[{"reps":10}]}

{
  "program_name": "برنامه ${analysis.goals.join(' و ')} ${analysis.experience} ${_extractDaysFromProfile(userProfile)}روزه",
  "name": "برنامه تخصصی ${analysis.goals.first} (${analysis.experience})",
  "description": "توضیح کوتاه برنامه",
  "duration": "مدت برنامه (هفته)",
  "frequency": "تعداد جلسات در هفته",
  "sessions": [
    {"name": "روز 1 - گروه عضلانی", "notes": "...", "exercises": [{"type":"normal","tag":"نام فارسی کامل تمرین از فهرست بالا", "style":"sets_reps","exercise_id":0,"sets":[{"reps":10}]}]},
    {"name": "روز 2 - گروه عضلانی", "notes": "...", "exercises": []},
    {"name": "روز 3 - گروه عضلانی", "notes": "...", "exercises": []},
    {"name": "روز 4 - گروه عضلانی", "notes": "...", "exercises": []}
  ],
  "weekly_progression": "نحوه پیشرفت هفتگی (مثال: افزایش 2.5 کیلوگرم به وزنه‌ها یا افزایش یک تکرار)",
  "nutrition_tips": [
    "توصیه تغذیه‌ای 1",
    "توصیه تغذیه‌ای 2"
  ],
  "recovery_tips": [
    "توصیه ریکاوری 1",
    "توصیه ریکاوری 2"
  ]
}

### قوانین حتمی برای این کاربر:
1. **آسیب‌دیدگی‌ها**: ${analysis.injuries.isEmpty ? 'محدودیتی ندارد' : 'مطلقاً از تمرینات ${_getProhibitedExercises(analysis.injuries).join(', ')} استفاده نکنید'}
2. **سطح تجربه ${analysis.experience}**: ${analysis.experience == 'مبتدی'
        ? 'فقط تمرینات پایه و ساده، حداکثر 4 حرکت'
        : analysis.experience == 'حرفه‌ای'
        ? 'تمرینات پیشرفته و ترکیبی مجاز، تا 7-8 حرکت'
        : 'تمرینات متوسط، 5-6 حرکت'}
3. **هدف اصلی**: ${analysis.goals.contains('چربی‌سوزی')
        ? 'حتماً شامل 15-20 دقیقه کاردیو در پایان هر جلسه'
        : analysis.goals.contains('حجم‌سازی')
        ? 'تمرکز بر تمرینات چندمفصلی با 8-12 تکرار'
        : 'متناسب با هدف'}
4. **محدودیت زمان**: هر جلسه ${_extractSessionDuration(userProfile)}
5. **تعداد جلسات**: دقیقاً ${_extractDaysFromProfile(userProfile)} جلسه در هفته
6. **حجم هر جلسه**: ${analysis.experience == 'مبتدی'
        ? '4 حرکت حداکثر'
        : analysis.experience == 'حرفه‌ای'
        ? 'حداکثر 8 حرکت'
        : '5-6 حرکت'}
7. **تکرارات**: ${analysis.goals.contains('قدرت')
        ? '4-6 تکرار'
        : analysis.goals.contains('چربی‌سوزی')
        ? '12-20 تکرار'
        : '8-12 تکرار'}
8. **کاردیو**: ${analysis.goals.contains('چربی‌سوزی')
        ? 'الزامی در پایان هر جلسه (15-20 دقیقه) به سبک sets_time'
        : analysis.goals.contains('حجم‌سازی')
        ? 'اختیاری و کم (5-10 دقیقه گرم کردن) به سبک sets_time'
        : 'متعادل (10 دقیقه) به سبک sets_time'}

### نکات امنیتی حتمی:
- ${analysis.injuries.contains('کمر') ? 'هیچ حرکت خم شدن به جلو یا بار محوری بر ستون فقرات مجاز نیست' : ''}
- ${analysis.injuries.contains('زانو') ? 'اسکوات عمیق و لانج ممنوع - فقط حرکات کم ضربه' : ''}
- ${analysis.injuries.contains('شانه') ? 'حرکات بالای سر و پرس پشت گردن ممنوع' : ''}
- ${analysis.age >= 50 ? 'اولویت با تمرینات کنترل‌شده و دستگاهی' : ''}

فقط JSON معتبر برگردانید، بدون توضیح اضافه یا کد بلاک. پاسخ می‌تواند تا حد نیاز طولانی باشد اما باید کامل و معتبر باشد.
''';
  }

  final OpenAIService _openAIService = OpenAIService();

  /// ارسال درخواست به OpenAI (مستقیم یا پروکسی سرور)
  Future<String?> _sendRequestToOpenAI(
    String prompt, {
    double temperature = 0.6,
    int maxTokens = _workoutMaxTokens,
  }) async {
    try {
      print('ارسال درخواست به OpenAI با مدل: $_model (maxTokens: $maxTokens)');

      final content = await _openAIService.sendCompletion(
        messages: [
          {
            'role': 'system',
            'content':
                'شما یک مربی حرفه‌ای بدنسازی هستید که برنامه‌های تمرینی شخصی‌سازی شده طراحی می‌کنید.',
          },
          {'role': 'user', 'content': prompt},
        ],
        model: _model,
        temperature: temperature,
        maxTokens: maxTokens,
        responseFormat: const {'type': 'json_object'},
        requestTimeout: _workoutRequestTimeout,
      );

      print('محتوای پاسخ دریافت شد، طول: ${content.length} کاراکتر');
      return content;
    } on OpenAIException catch (e) {
      print('خطا در OpenAI: $e');
      return null;
    } catch (e) {
      print('خطا در ارسال درخواست: $e');
      return null;
    }
  }

  /// تبدیل پاسخ JSON به WorkoutProgram
  Future<WorkoutProgram?> _parseWorkoutProgram(
    String jsonResponse,
    UserAnalysis analysis,
  ) async {
    try {
      // پاک کردن markdown code blocks اگر وجود دارد
      String cleanJson = jsonResponse;
      if (cleanJson.contains('```json')) {
        cleanJson = cleanJson.split('```json')[1].split('```')[0];
      } else if (cleanJson.contains('```')) {
        cleanJson = cleanJson.split('```')[1].split('```')[0];
      }

      // بررسی و اصلاح JSON ناقص
      cleanJson = _fixIncompleteJson(cleanJson);

      print(
        'JSON پاکسازی شده: ${cleanJson.substring(0, min(100, cleanJson.length))}...',
      );

      late final Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(cleanJson.trim());
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        } else {
          throw const FormatException('JSON root must be an object');
        }
      } catch (_) {
        // تلاش دوباره با بریدن تا آخرین آکولاد و حذف ویرگول‌های انتهایی
        final trimmed = _stripToJsonObject(cleanJson);
        final deComma = _removeTrailingCommas(trimmed);
        final repaired = _fixIncompleteJson(deComma);
        final decoded = jsonDecode(repaired.trim());
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        } else {
          throw const FormatException('JSON root must be an object');
        }
      }

      // تبدیل به WorkoutProgram با تمرین‌های واقعی از AI
      final sessions = <WorkoutSession>[];

      final sessionsRaw = data['sessions'];
      final sessionItems = sessionsRaw is List
          ? sessionsRaw
          : const <dynamic>[];
      for (final sessionData
          in sessionItems.whereType<Map<String, dynamic>>()) {
        final exercises = <NormalExercise>[];

        final exercisesRaw = sessionData['exercises'];
        final exerciseItems = exercisesRaw is List
            ? exercisesRaw
            : const <dynamic>[];
        for (final exerciseData
            in exerciseItems.whereType<Map<String, dynamic>>()) {
          try {
            // تعیین شناسه و برچسب تمرین
            final providedId =
                int.tryParse(
                  (exerciseData['exercise_id']?.toString() ?? '').trim(),
                ) ??
                0;
            final providedName =
                (exerciseData['name'] ?? exerciseData['tag'] ?? '')
                    .toString()
                    .trim();

            // همیشه سعی کن ID را از نام پیدا کنی (حتی اگر providedId > 0 باشد)
            // چون ممکن است AI ID اشتباه بفرستد
            int resolvedId = providedId;
            if (providedName.isNotEmpty) {
              final foundId = await _getExerciseIdByName(providedName);
              if (foundId > 0) {
                resolvedId = foundId;
                print('ID از نام پیدا شد: "$providedName" -> ID=$foundId');
              } else if (providedId > 0) {
                // اگر از نام پیدا نشد اما providedId > 0 است، از آن استفاده کن
                resolvedId = providedId;
                print(
                  'استفاده از providedId: $providedId برای "$providedName"',
                );
              } else {
                print('⚠️ هیچ ID برای "$providedName" پیدا نشد');
              }
            }

            final tagValue = (exerciseData['tag'] ?? exerciseData['name'] ?? '')
                .toString()
                .trim();
            final style = _parseStyle(exerciseData);
            final noteRaw = exerciseData['note'] ?? exerciseData['notes'];
            final note = noteRaw?.toString();

            print(
              'پارس تمرین: providedId=$providedId, resolvedId=$resolvedId, tag="$tagValue", name="${exerciseData['name']}"',
            );

            final exercise = NormalExercise(
              exerciseId: resolvedId,
              tag: tagValue.isNotEmpty ? tagValue : providedName.trim(),
              style: style,
              sets: _parseSets(
                exerciseData,
                desiredStyle: style,
                desiredIntensity: analysis.desiredIntensity,
              ),
              note: note,
            );

            print(
              'تمرین ایجاد شد: exerciseId=${exercise.exerciseId}, tag="${exercise.tag}"',
            );
            exercises.add(exercise);
          } catch (e) {
            print('خطا در پارس تمرین: $e');
            print('داده تمرین: $exerciseData');
            // ادامه حلقه و رد کردن این تمرین
            continue;
          }
        }

        // اگر هیچ تمرینی پارس نشد، این جلسه را رد کن
        if (exercises.isEmpty) {
          print(
            'هیچ تمرینی برای جلسه ${sessionData['name']} پارس نشد، رد کردن جلسه',
          );
          continue;
        }

        final session = WorkoutSession(
          day: (sessionData['name'] ?? 'روز تمرین').toString(),
          exercises: exercises,
          notes: sessionData['notes']?.toString(),
        );
        sessions.add(session);
      }

      // اگر هیچ جلسه‌ای پارس نشد، null برگردان (بدون fallback)
      if (sessions.isEmpty) {
        print('هیچ جلسه‌ای پارس نشد، عدم امکان تولید برنامه');
        return null;
      }

      final program = WorkoutProgram(
        name:
            (data['program_name'] ??
                    data['name'] ??
                    _generateProgramNameFromProfile(
                      _lastUserProfile ?? const {},
                    ))
                .toString(),
        sessions: sessions,
      );

      // استفاده از پس‌پردازش علمی جدید
      return _scientificPostProcessing(program, _lastUserAnalysis);
    } catch (e) {
      print('خطا در تجزیه JSON: $e');
      print('JSON دریافتی: $jsonResponse');

      // در صورت خطا در پارس، null برگردان
      return null;
    }
  }

  /// اصلاح JSON ناقص
  String _fixIncompleteJson(String json) {
    // بررسی آکولادها و براکت‌های باز و بسته
    int openBraces = 0;
    int closeBraces = 0;
    int openBrackets = 0;
    int closeBrackets = 0;

    for (int i = 0; i < json.length; i++) {
      if (json[i] == '{') openBraces++;
      if (json[i] == '}') closeBraces++;
      if (json[i] == '[') openBrackets++;
      if (json[i] == ']') closeBrackets++;
    }

    // اگر JSON ناقص است، سعی کن آن را تکمیل کنی
    String fixedJson = json.trim();

    // اگر string ناقص پیدا کردیم (مثل "set_number}}}}]]]) آن را اصلاح کن
    fixedJson = _fixBrokenStrings(fixedJson);

    // اگر آخرین کاراکتر : یا , است، آن را اصلاح کن
    if (fixedJson.endsWith(':')) {
      fixedJson = '${fixedJson.substring(0, fixedJson.length - 1)}""}';
    } else if (fixedJson.endsWith(',')) {
      fixedJson = fixedJson.substring(0, fixedJson.lastIndexOf(','));
    }

    // بستن آکولادها و براکت‌های باز
    if (openBraces > closeBraces || openBrackets > closeBrackets) {
      final buffer = StringBuffer(fixedJson);
      while (openBraces > closeBraces) {
        buffer.write('}');
        closeBraces++;
      }

      while (openBrackets > closeBrackets) {
        buffer.write(']');
        closeBrackets++;
      }
      fixedJson = buffer.toString();
    }

    return fixedJson;
  }

  String _fixBrokenStrings(String json) {
    var fixedJson = json;
    // Fix patterns like "set_number}}}}]]]
    final brokenPattern = RegExp(r'"[^"]*}}+\]+$');
    if (brokenPattern.hasMatch(fixedJson)) {
      final match = brokenPattern.firstMatch(fixedJson);
      if (match != null) {
        final brokenPart = match.group(0)!;
        final fixedPart = brokenPart.replaceAll(RegExp(r'[}\]]+$'), '": "1"');
        fixedJson = fixedJson.replaceAll(brokenPart, fixedPart);
      }
    }

    // Fix patterns like "reps": ""}}}}]]]
    final brokenPattern2 = RegExp(r'"[^"]*":\s*"[^"]*"?}}+\]+$');
    if (brokenPattern2.hasMatch(fixedJson)) {
      final match = brokenPattern2.firstMatch(fixedJson);
      if (match != null) {
        final brokenPart = match.group(0)!;
        final fixedPart = brokenPart.replaceAll(RegExp(r'[}\]]+$'), '');
        fixedJson = fixedJson.replaceAll(brokenPart, fixedPart);
      }
    }

    return fixedJson;
  }

  // بریدن امن رشته تا بازه معتبر شیٔ JSON (از اولین '{' تا آخرین '}')
  String _stripToJsonObject(String content) {
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return content.substring(start, end + 1);
    }
    return content;
  }

  // حذف ویرگول‌های اضافه قبل از ']' یا '}' که باعث خطای JSON می‌شوند
  String _removeTrailingCommas(String content) {
    return content.replaceAll(RegExp(',\n?\r?s*(]|})'), r'$1');
  }

  /// استخراج تعداد روزهای تمرین از پروفایل
  int _extractDaysFromProfile(Map<String, dynamic> profile) {
    try {
      // اول با ID سوال جستجو کن
      if (profile.containsKey('bb_days_per_week')) {
        final value = profile['bb_days_per_week'].toString();
        print('تعداد روزهای تمرین استخراج شد (با ID): $value');

        final match = RegExp(r'(\d+)').firstMatch(value);
        if (match != null) {
          final days = int.parse(match.group(1)!);
          print('تعداد روزها: $days');
          return days;
        }
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      final entry = profile.entries.firstWhere(
        (e) =>
            e.key.contains('چند روز') ||
            e.key.contains('چند روز در هفته') ||
            e.key.toLowerCase().contains('days per week'),
        orElse: () => const MapEntry('', '3'),
      );
      final value = entry.value.toString();
      print('تعداد روزهای تمرین استخراج شد (با متن): $value');

      final match = RegExp(r'(\d+)').firstMatch(value);
      if (match != null) {
        final days = int.parse(match.group(1)!);
        print('تعداد روزها: $days');
        return days;
      }
      return 3;
    } catch (e) {
      print('خطا در استخراج تعداد روزها: $e');
      return 3;
    }
  }

  /// استخراج مدت زمان هر جلسه
  String _extractSessionDuration(Map<String, dynamic> profile) {
    try {
      // اول با ID سوال جستجو کن
      if (profile.containsKey('bb_session_minutes')) {
        final value = profile['bb_session_minutes'].toString();
        print('مدت زمان جلسه استخراج شد (با ID): $value');

        final minutes = double.tryParse(value) ?? 60.0;
        if (minutes >= 90) return 'حجم بالاتر مجاز (۵-۶ حرکت)';
        if (minutes >= 60) return 'حجم متوسط (۴-۵ حرکت)';
        if (minutes >= 45) return 'حجم متوسط (۴-۵ حرکت)';
        return 'حجم محدود (۳-۴ حرکت)';
      }

      // اگر پیدا نشد، با متن سوال جستجو کن
      final entry = profile.entries.firstWhere(
        (e) =>
            e.key.contains('مدت زمان') ||
            e.key.contains('زمان دارید') ||
            e.key.toLowerCase().contains('session') ||
            e.key.toLowerCase().contains('minutes'),
        orElse: () => const MapEntry('', '60'),
      );
      final value = entry.value.toString();
      print('مدت زمان جلسه استخراج شد (با متن): $value');

      final minutes = double.tryParse(value) ?? 60.0;
      if (minutes >= 90) return 'حجم بالاتر مجاز (۵-۶ حرکت)';
      if (minutes >= 60) return 'حجم متوسط (۴-۵ حرکت)';
      if (minutes >= 45) return 'حجم متوسط (۴-۵ حرکت)';
      return 'حجم محدود (۳-۴ حرکت)';
    } catch (e) {
      print('خطا در استخراج مدت زمان جلسه: $e');
      return '۴-۶ حرکت';
    }
  }

  /// تولید نام برنامه بر اساس پروفایل
  String _generateProgramNameFromProfile(Map<String, dynamic> profile) {
    final String goal = _extractGoalShort(profile);
    final int days = _extractDaysFromProfile(profile);
    final String level = _extractExperienceShort(profile);
    final String location = _extractLocationShort(profile);
    final String daysPart = days > 0 ? '$daysروزه' : 'چندروزه';
    return '$goal $level $daysPart ($location)';
  }

  /// استخراج هدف کوتاه
  String _extractGoalShort(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_goal_primary')) {
        final value = profile['bb_goal_primary'].toString();
        if (value.contains('حجم') || value.contains('Bulk')) {
          return 'هایپرتروفی';
        }
        if (value.contains('قدرت')) return 'قدرت';
        if (value.contains('چربی') || value.contains('لاغر')) {
          return 'چربی‌سوزی';
        }
        if (value.contains('استقامت')) return 'استقامت';
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('هدف') || e.key.contains('goals'),
        orElse: () => const MapEntry('', ''),
      );
      final value = entry.value.toString();
      if (value.contains('حجم') || value.contains('Hypertrophy')) {
        return 'هایپرتروفی';
      }
      if (value.contains('قدرت')) return 'قدرت';
      if (value.contains('چربی') || value.contains('لاغری')) return 'چربی‌سوزی';
      if (value.contains('استقامت')) return 'استقامت';
      return 'فیتنس';
    } catch (_) {
      return 'فیتنس';
    }
  }

  /// استخراج سطح تجربه کوتاه
  String _extractExperienceShort(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_experience_level')) {
        return _mapExperienceLabel(profile['bb_experience_level'].toString());
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('تجربه') || e.key.contains('سطح'),
        orElse: () => const MapEntry('', ''),
      );
      return _mapExperienceLabel(entry.value.toString());
    } catch (_) {
      return 'سطح متوسط';
    }
  }

  /// استخراج مکان تمرین کوتاه
  String _extractLocationShort(Map<String, dynamic> profile) {
    try {
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('محل تمرین') || e.key.contains('کجاست'),
        orElse: () => const MapEntry('', ''),
      );
      final value = entry.value.toString();
      if (value.contains('باشگاه')) return 'باشگاه کامل';
      if (value.contains('خانه')) return 'تمرین در خانه';
      if (value.contains('پارک') || value.contains('وزن بدن')) return 'وزن بدن';
      return 'باشگاه';
    } catch (_) {
      return 'باشگاه';
    }
  }

  /// ایجاد برنامه ارجاع پزشکی برای کاربران با مشکلات شدید
  WorkoutProgram _createMedicalReferralProgram(UserAnalysis analysis) {
    return WorkoutProgram(
      name: 'ارجاع به متخصص - عدم امکان ارائه برنامه آنلاین',
      sessions: [
        WorkoutSession(
          day: 'توصیه پزشکی',
          exercises: [],
          notes:
              '''
با توجه به شرایط سلامتی شما:
- آسیب‌دیدگی‌ها: ${analysis.injuries.join(', ')}
- سن: ${analysis.age} سال
- سطح خطر: ${analysis.riskLevel}

توصیه می‌شود قبل از شروع هر برنامه تمرینی، حتماً با پزشک متخصص طب ورزشی یا فیزیوتراپیست مشورت کنید.

ارائه برنامه تمرینی آنلاین برای شما ایمن نیست.''',
        ),
      ],
    );
  }

  /// ایجاد برنامه محدود برای کاربرانی که گزینه‌های کمی دارند
  WorkoutProgram _createLimitedOptionsProgram() {
    return WorkoutProgram(
      name: 'برنامه محدود - تمرینات ایمن',
      sessions: [
        WorkoutSession(
          day: 'روز 1 - تمرینات ایمن',
          exercises: [],
          notes:
              'متاسفانه با توجه به محدودیت‌های شما، تمرینات مناسبی در دیتابیس یافت نشد. لطفاً با مربی حضوری مشورت کنید.',
        ),
      ],
    );
  }

  /// پس‌پردازش علمی برنامه
  WorkoutProgram _scientificPostProcessing(
    WorkoutProgram program,
    UserAnalysis analysis,
  ) {
    // اعمال قوانین علمی و تطبیق دقیق با نیازها
    final processedSessions = <WorkoutSession>[];

    for (final session in program.sessions) {
      final processedExercises = <WorkoutExercise>[];

      // پردازش هر تمرین و اضافه کردن نکات شخصی‌سازی شده
      for (final exercise in session.exercises) {
        final enhancedExercise = _enhanceExerciseNotes(exercise, analysis);
        processedExercises.add(enhancedExercise);
      }

      processedSessions.add(
        session.copyWith(
          exercises: processedExercises,
          notes: _enhanceSessionNotes(session.notes, analysis),
        ),
      );
    }

    // Keep LLM program name; only enrich session notes for safety UX.
    return program.copyWith(sessions: processedSessions);
  }

  /// بهبود توضیحات جلسات بر اساس تحلیل کاربر
  String _enhanceSessionNotes(String? originalNotes, UserAnalysis analysis) {
    final enhanced = StringBuffer();

    if (originalNotes != null && originalNotes.isNotEmpty) {
      enhanced.writeln(originalNotes);
    }

    // بررسی اینکه آیا قبلاً "نکات ویژه" اضافه شده یا خیر
    if (originalNotes != null &&
        originalNotes.contains('--- نکات ویژه برای شما ---')) {
      return originalNotes; // اگر قبلاً اضافه شده، همان را برگردان
    }

    enhanced.writeln('\n--- نکات ویژه برای شما ---');

    if (analysis.hasInjuries) {
      enhanced.writeln(
        '⚠️ توجه: به دلیل آسیب‌دیدگی ${analysis.injuries.join(', ')}, از حرکات پرخطر پرهیز شده است.',
      );
    }

    if (analysis.experience == 'مبتدی') {
      enhanced.writeln(
        '🔰 مبتدی: روی فرم صحیح تمرکز کنید، وزن را آرام افزایش دهید.',
      );
    }

    // نمایش شدت مطلوب در یادداشت‌ها برای شفافیت کاربر
    enhanced.writeln('🎯 شدت مدنظر شما: ${analysis.desiredIntensity}.');

    if (analysis.age > 45) {
      enhanced.writeln('🧘 سن: گرم کردن دقیق‌تر و استراحت بیشتر بین ست‌ها.');
    }

    if (analysis.stressLevel == 'زیاد') {
      enhanced.writeln('😌 استرس بالا: به استراحت کافی توجه کنید.');
    }

    return enhanced.toString();
  }

  /// بهبود نکات تمرین‌ها بر اساس تحلیل کاربر و نوع تمرین
  WorkoutExercise _enhanceExerciseNotes(
    WorkoutExercise exercise,
    UserAnalysis analysis,
  ) {
    String? currentNote;

    // تشخیص نوع تمرین و دریافت نکات فعلی
    if (exercise is NormalExercise) {
      currentNote = exercise.note;
    } else if (exercise is SupersetExercise) {
      currentNote = exercise.note;
    }

    // اگر قبلاً نکات ویژه اضافه شده، تغییر نده
    if (currentNote != null &&
        currentNote.contains('--- نکات ویژه برای شما ---')) {
      return exercise;
    }

    // تولید نکات شخصی‌سازی شده برای این تمرین خاص
    final personalizedNotes = _generatePersonalizedExerciseNotes(
      exercise,
      analysis,
    );

    // بازگرداندن تمرین با نکات بهبود یافته
    if (exercise is NormalExercise) {
      return NormalExercise(
        id: exercise.id,
        exerciseId: exercise.exerciseId,
        tag: exercise.tag,
        style: exercise.style,
        sets: exercise.sets,
        note: personalizedNotes,
      );
    } else if (exercise is SupersetExercise) {
      return SupersetExercise(
        id: exercise.id,
        tag: exercise.tag,
        style: exercise.style,
        exercises: exercise.exercises,
        note: personalizedNotes,
      );
    }

    return exercise;
  }

  /// تولید نکات شخصی‌سازی شده برای هر تمرین
  String _generatePersonalizedExerciseNotes(
    WorkoutExercise exercise,
    UserAnalysis analysis,
  ) {
    final notes = StringBuffer();

    // اضافه کردن نکات اصلی اگر وجود داشته باشد
    String? currentNote;
    if (exercise is NormalExercise) {
      currentNote = exercise.note;
    } else if (exercise is SupersetExercise) {
      currentNote = exercise.note;
    }

    if (currentNote != null && currentNote.isNotEmpty) {
      notes.writeln(currentNote);
    }

    // تولید نکات مخصوص این تمرین
    notes.writeln('\n--- نکات ویژه برای شما ---');

    // نکات بر اساس نوع تمرین و تگ
    _addExerciseSpecificNotes(notes, exercise, analysis);

    // نکات بر اساس شرایط کاربر (فقط یک بار)
    _addUserSpecificNotes(notes, analysis);

    return notes.toString().trim();
  }

  /// اضافه کردن نکات مخصوص هر تمرین
  void _addExerciseSpecificNotes(
    StringBuffer notes,
    WorkoutExercise exercise,
    UserAnalysis analysis,
  ) {
    final tag = exercise.tag.toLowerCase();

    // تولید نکات متنوع بر اساس ترکیب عوامل مختلف
    final random = Random();
    final tips = <String>[];

    // نکات بر اساس نوع تمرین
    if (tag.contains('قدرتی') || tag.contains('سنگین')) {
      tips.addAll([
        '💪 تمرین قدرتی: روی فرم صحیح تمرکز کنید، وزن را کنترل شده افزایش دهید.',
        '💪 تمرین قدرتی: نفس‌گیری صحیح در حین حرکت مهم است.',
        '💪 تمرین قدرتی: استراحت کافی بین ست‌ها برای ریکاوری کاملاً ضروری است.',
      ]);
      if (analysis.experience == 'مبتدی') {
        tips.add('🔰 مبتدی: با وزن سبک شروع کنید و تدریجاً افزایش دهید.');
      }
    } else if (tag.contains('استقامتی') || tag.contains('کاردیو')) {
      tips.addAll([
        '🏃 تمرین استقامتی: ریتم ثابت حفظ کنید، نفس‌گیری منظم داشته باشید.',
        '🏃 تمرین استقامتی: شدت را تدریجاً افزایش دهید، از فشار زیاد پرهیز کنید.',
        '🏃 تمرین استقامتی: آب کافی بنوشید و وضعیت بدن را کنترل کنید.',
      ]);
      if (analysis.goals.contains('کاهش وزن')) {
        tips.add('🔥 چربی‌سوزی: شدت متوسط تا بالا برای حداکثر کالری‌سوزی.');
      }
    } else if (tag.contains('ایزوله')) {
      tips.addAll([
        '🎯 تمرین ایزوله: روی عضله هدف تمرکز کنید، حرکت را آرام و کنترل شده انجام دهید.',
        '🎯 تمرین ایزوله: از وزن مناسب استفاده کنید، کیفیت مهم‌تر از کمیت است.',
        '🎯 تمرین ایزوله: انقباض عضلانی را در نقطه اوج حرکت حفظ کنید.',
      ]);
    } else if (tag.contains('چندمفصلی')) {
      tips.addAll([
        '⚡ تمرین چندمفصلی: هماهنگی بین مفاصل را حفظ کنید، فرم صحیح اولویت دارد.',
        '⚡ تمرین چندمفصلی: بدن را به عنوان یک واحد در نظر بگیرید.',
        '⚡ تمرین چندمفصلی: گرم کردن مفاصل قبل از شروع ضروری است.',
      ]);
    }

    // نکات بر اساس عضله هدف
    if (tag.contains('سینه')) {
      tips.addAll([
        '💪 سینه: قفسه سینه را باز نگه دارید، حرکت را کامل انجام دهید.',
        '💪 سینه: تیغه‌های شانه را به سمت عقب نگه دارید.',
        '💪 سینه: از پایین آوردن بیش از حد وزنه خودداری کنید.',
      ]);
    } else if (tag.contains('پشت')) {
      tips.addAll([
        '🦾 پشت: تیغه‌های شانه را به هم نزدیک کنید، ستون فقرات را صاف نگه دارید.',
        '🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید.',
        '🦾 پشت: فشار را در وسط پشت احساس کنید.',
      ]);
    } else if (tag.contains('شانه')) {
      tips.addAll([
        '🏋️ شانه: از وزن مناسب استفاده کنید، از چرخش ناگهانی پرهیز کنید.',
        '🏋️ شانه: حرکت را در دامنه کامل انجام دهید.',
        '🏋️ شانه: تعادل بین قدرت و انعطاف‌پذیری را حفظ کنید.',
      ]);
    } else if (tag.contains('بازو')) {
      tips.addAll([
        '💪 بازو: حرکت را کامل انجام دهید، از تاب دادن بدن پرهیز کنید.',
        '💪 بازو: آرنج‌ها را نزدیک بدن نگه دارید.',
        '💪 بازو: انقباض را در نقطه اوج احساس کنید.',
      ]);
    } else if (tag.contains('پا')) {
      tips.addAll([
        '🦵 پا: زانوها را در راستای انگشتان پا نگه دارید، حرکت را کنترل شده انجام دهید.',
        '🦵 پا: وزن را روی پاشنه‌ها نگه دارید.',
        '🦵 پا: عضلات مرکزی را درگیر نگه دارید.',
      ]);
    } else if (tag.contains('شکم')) {
      tips.addAll([
        '🔥 شکم: نفس را در حین انقباض نگه دارید، از فشار به گردن پرهیز کنید.',
        '🔥 شکم: حرکت را آرام و کنترل شده انجام دهید.',
        '🔥 شکم: تمرکز روی کیفیت حرکت نه تعداد.',
      ]);
    }

    // انتخاب تصادفی 1-2 نکته از لیست
    if (tips.isNotEmpty) {
      tips.shuffle();
      final selectedTips = tips.take(random.nextInt(2) + 1).toList();
      for (final tip in selectedTips) {
        notes.writeln(tip);
      }
    }
  }

  /// اضافه کردن نکات بر اساس شرایط کاربر
  void _addUserSpecificNotes(StringBuffer notes, UserAnalysis analysis) {
    final random = Random();
    final userTips = <String>[];

    // نکات بر اساس آسیب‌ها (فقط گاهی اوقات)
    if (analysis.hasInjuries && random.nextBool()) {
      final injuryNote = analysis.injuries.contains('کمر')
          ? '⚠️ آسیب کمر: از حرکات فشاری روی کمر پرهیز کنید، در صورت درد متوقف شوید.'
          : '⚠️ آسیب: در صورت درد یا ناراحتی، تمرین را متوقف کنید.';
      userTips.add(injuryNote);
    }

    // نکات بر اساس سن
    if (analysis.age > 45 && random.nextBool()) {
      userTips.add('🧘 سن: گرم کردن کامل قبل از شروع، استراحت کافی بین ست‌ها.');
    }

    // نکات بر اساس سطح استرس
    if (analysis.stressLevel == 'زیاد' && random.nextBool()) {
      userTips.add('😌 استرس بالا: تمرین را آرام انجام دهید، نفس عمیق بکشید.');
    }

    // نکات بر اساس اهداف (فقط یکی و گاهی اوقات)
    if (random.nextBool()) {
      if (analysis.goals.contains('کاهش وزن')) {
        userTips.add(
          '🔥 هدف کاهش وزن: استراحت کوتاه‌تر (30-60 ثانیه) بین ست‌ها.',
        );
      } else if (analysis.goals.contains('افزایش حجم')) {
        userTips.add(
          '💪 هدف افزایش حجم: استراحت 2-3 دقیقه بین ست‌ها برای ریکاوری کامل.',
        );
      } else if (analysis.goals.contains('افزایش قدرت')) {
        userTips.add('⚡ هدف افزایش قدرت: استراحت 3-5 دقیقه بین ست‌ها.');
      }
    }

    // انتخاب تصادفی 0-1 نکته از نکات کاربر
    if (userTips.isNotEmpty) {
      userTips.shuffle();
      final selectedUserTips = userTips.take(random.nextInt(2)).toList();
      for (final tip in selectedUserTips) {
        notes.writeln(tip);
      }
    }
  }

  /// تولید نام علمی برای برنامه (نگه داشته شده برای سازگاری داخلی)
  // ignore: unused_element
  String _generateScientificProgramName(UserAnalysis analysis) {
    final goal = analysis.goals.isNotEmpty ? analysis.goals.first : 'فیتنس';
    final level = analysis.experience;
    final agePart = analysis.age > 0 ? ' • ${analysis.age}سال' : '';
    final injury = analysis.hasInjuries ? ' • محدودیت‌دار' : '';
    return 'برنامه $goal — $level$agePart$injury';
  }

  /// دریافت شناسه تمرین بر اساس نام از API با انتخاب هوشمند
  Future<int> _getExerciseIdByName(String exerciseName) async {
    try {
      final allExercises = await AIExerciseReadService().getExercisesForAI();
      final searchName = exerciseName.trim().toLowerCase();

      // جستجوی دقیق
      for (final exercise in allExercises) {
        if (exercise.name.trim().toLowerCase() == searchName) {
          print(
            'تمرین پیدا شد (دقیق): "$exerciseName" -> ${exercise.name} (ID: ${exercise.id})',
          );
          return exercise.id;
        }
      }

      // جستجوی در otherNames
      for (final exercise in allExercises) {
        for (final otherName in exercise.otherNames) {
          if (otherName.trim().toLowerCase() == searchName) {
            print(
              'تمرین پیدا شد (otherNames): "$exerciseName" -> ${exercise.name} (ID: ${exercise.id})',
            );
            return exercise.id;
          }
        }
      }

      // جستجوی تقریبی بر اساس کلمات کلیدی
      final keywords = searchName
          .split(RegExp(r'[_\s]+'))
          .where((w) => w.length > 2)
          .toList();
      int bestScore = 0;
      int bestId = 0;

      for (final exercise in allExercises) {
        int score = 0;
        final exerciseLower = exercise.name.toLowerCase();
        final exerciseMainMuscle = exercise.mainMuscle.toLowerCase();

        // امتیازدهی بر اساس تطبیق کلمات در نام تمرین
        for (final keyword in keywords) {
          if (exerciseLower.contains(keyword)) score += 10;
          // جستجو در otherNames
          for (final otherName in exercise.otherNames) {
            if (otherName.toLowerCase().contains(keyword)) score += 8;
          }
        }

        // امتیاز اضافی برای تطبیق عضله اصلی
        if (exerciseMainMuscle.isNotEmpty) {
          for (final keyword in keywords) {
            if (exerciseMainMuscle.contains(keyword)) score += 5;
          }
        }

        // امتیاز اضافی برای تطبیق کلمات کلیدی رایج
        final commonMappings = {
          'bench': ['پرس', 'سینه'],
          'press': ['پرس'],
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
        };

        for (final entry in commonMappings.entries) {
          if (searchName.contains(entry.key)) {
            for (final persianWord in entry.value) {
              if (exerciseLower.contains(persianWord)) {
                score += 15; // امتیاز بالا برای تطبیق کلمات کلیدی
              }
            }
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestId = exercise.id;
        }
      }

      if (bestScore > 0) {
        final foundExercise = allExercises.firstWhere((e) => e.id == bestId);
        print(
          'تمرین پیدا شد (تقریبی): "$exerciseName" -> ${foundExercise.name} (ID: $bestId, Score: $bestScore)',
        );
        return bestId;
      }

      print('⚠️ هیچ تمرینی برای "$exerciseName" پیدا نشد');
      // اگر هیچ تطبیقی پیدا نشد، 0 برگردان تا باعث خطا شود
      return 0;
    } catch (e) {
      print('خطا در جستجوی تمرین "$exerciseName": $e');
      // در صورت خطا، 0 برگردان تا تمرین جعلی ساخته نشود
      return 0;
    }
  }

  /// پارس کردن سبک تمرین (sets_reps یا sets_time)
  ExerciseStyle _parseStyle(Map<String, dynamic> exerciseData) {
    final styleStr = (exerciseData['style']?.toString() ?? 'sets_reps')
        .toLowerCase();
    return styleStr == 'sets_time'
        ? ExerciseStyle.setsTime
        : ExerciseStyle.setsReps;
  }

  /// پارس کردن ست‌های تمرین
  List<ExerciseSet> _parseSets(
    Map<String, dynamic> exerciseData, {
    ExerciseStyle? desiredStyle,
    String? desiredIntensity,
  }) {
    final List<ExerciseSet> sets = [];

    try {
      final style = desiredStyle ?? _parseStyle(exerciseData);

      // اگر جزئیات ست‌ها موجود باشد
      if (exerciseData.containsKey('sets_details') &&
          exerciseData['sets_details'] is List) {
        final setDetails = exerciseData['sets_details'] as List;

        for (final setDetail in setDetails) {
          if (setDetail is Map<String, dynamic>) {
            if (style == ExerciseStyle.setsTime) {
              final sec = _parseSeconds(
                setDetail['time_seconds']?.toString() ?? '60',
              );
              sets.add(ExerciseSet(timeSeconds: sec));
            } else {
              sets.add(
                ExerciseSet(
                  reps: _parseReps(setDetail['reps']?.toString() ?? '8-12'),
                ),
              );
            }
          }
        }
      } else {
        // اگر جزئیات ست‌ها موجود نباشد، از تعداد ست استفاده می‌کنیم
        final setsCount = _parseSetsCount(exerciseData);

        // ایجاد ست‌ها با توجه به سبک و شدت مطلوب
        for (int i = 0; i < setsCount; i++) {
          if (style == ExerciseStyle.setsTime) {
            // الگوهای زمان‌محور
            int seconds;
            final intensity = desiredIntensity ?? 'متوسط';
            if (intensity == 'سنگین') {
              // اینتروال سنگین: 45-60 ثانیه
              seconds = i == 0 ? 60 : (i == 1 ? 50 : 45);
            } else if (intensity == 'سبک') {
              // سبک: 60-75 ثانیه
              seconds = i == 0 ? 75 : (i == 1 ? 65 : 60);
            } else {
              // متوسط: 50-70 ثانیه
              seconds = i == 0 ? 70 : (i == 1 ? 60 : 50);
            }
            sets.add(ExerciseSet(timeSeconds: seconds));
          } else {
            // الگوهای تکرارمحور
            String range;
            final intensity = desiredIntensity ?? 'متوسط';
            if (intensity == 'سنگین') {
              range = i == 0 ? '6-8' : (i == 1 ? '6-8' : '5-7');
            } else if (intensity == 'سبک') {
              range = i == 0 ? '12-15' : (i == 1 ? '10-12' : '10-12');
            } else {
              range = i == 0 ? '10-12' : (i == 1 ? '8-10' : '6-8');
            }
            sets.add(ExerciseSet(reps: _parseReps(range)));
          }
        }
      }

      // اگر هیچ ستی ایجاد نشد، حداقل 3 ست پیش‌فرض ایجاد می‌کنیم
      if (sets.isEmpty) {
        if ((desiredStyle ?? ExerciseStyle.setsReps) ==
            ExerciseStyle.setsTime) {
          sets
            ..add(ExerciseSet(timeSeconds: 60))
            ..add(ExerciseSet(timeSeconds: 50))
            ..add(ExerciseSet(timeSeconds: 45));
        } else {
          sets
            ..add(ExerciseSet(reps: _parseReps('10-12')))
            ..add(ExerciseSet(reps: _parseReps('8-10')))
            ..add(ExerciseSet(reps: _parseReps('6-8')));
        }
      }

      return sets;
    } catch (e) {
      print('خطا در پارس ست‌ها: $e');
      // در صورت خطا، 3 ست پیش‌فرض برمی‌گردانیم
      if ((desiredStyle ?? ExerciseStyle.setsReps) == ExerciseStyle.setsTime) {
        return [
          ExerciseSet(timeSeconds: 60),
          ExerciseSet(timeSeconds: 50),
          ExerciseSet(timeSeconds: 45),
        ];
      } else {
        return [
          ExerciseSet(reps: 12),
          ExerciseSet(reps: 10),
          ExerciseSet(reps: 8),
        ];
      }
    }
  }

  /// پارس کردن تعداد ست‌ها
  int _parseSetsCount(Map<String, dynamic> exerciseData) {
    try {
      // ابتدا sets_count را بررسی می‌کنیم
      if (exerciseData.containsKey('sets_count')) {
        final setsCount =
            int.tryParse(exerciseData['sets_count'].toString()) ?? 3;
        return setsCount.clamp(3, 5); // حداقل 3 و حداکثر 5 ست
      }

      // اگر sets موجود باشد
      if (exerciseData.containsKey('sets')) {
        final setsCount = int.tryParse(exerciseData['sets'].toString()) ?? 3;
        return setsCount.clamp(3, 5); // حداقل 3 و حداکثر 5 ست
      }

      // مقدار پیش‌فرض
      return 3;
    } catch (e) {
      return 3; // پیش‌فرض
    }
  }

  /// تبدیل رشته reps به عدد
  int _parseReps(String repsString) {
    try {
      // اگر شامل محدوده است (مثل "8-12")
      if (repsString.contains('-')) {
        final parts = repsString.split('-');
        if (parts.length == 2) {
          final min = int.tryParse(parts[0].trim()) ?? 8;
          final max = int.tryParse(parts[1].trim()) ?? 12;
          return (min + max) ~/ 2; // میانگین
        }
      }

      // اگر عدد ساده است
      return int.tryParse(repsString.trim()) ?? 10;
    } catch (e) {
      return 10; // پیش‌فرض
    }
  }

  /// تبدیل رشته زمان به ثانیه
  int _parseSeconds(String secondsString) {
    try {
      // پشتیبانی از فرمت mm:ss یا عدد ساده ثانیه
      if (secondsString.contains(':')) {
        final parts = secondsString.split(':');
        final mm = int.tryParse(parts[0].trim()) ?? 0;
        final ss = int.tryParse(parts[1].trim()) ?? 0;
        return mm * 60 + ss;
      }
      return int.tryParse(secondsString.trim()) ?? 60;
    } catch (_) {
      return 60;
    }
  }

  /// استخراج تجهیزات در دسترس
  String _extractEquipment(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_equipment_access')) {
        return profile['bb_equipment_access'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) =>
            e.key.contains('تجهیزات') ||
            e.key.contains('محیط') ||
            e.key.toLowerCase().contains('equipment'),
        orElse: () => const MapEntry('', 'باشگاه کامل'),
      );
      return entry.value.toString();
    } catch (_) {
      return 'باشگاه کامل';
    }
  }

  /// استخراج ترجیح تقسیم‌بندی
  String _extractSplitPreference(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_split_preference')) {
        return profile['bb_split_preference'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('تقسیم') || e.key.contains('split'),
        orElse: () => const MapEntry('', 'فرقی ندارد'),
      );
      return entry.value.toString();
    } catch (_) {
      return 'فرقی ندارد';
    }
  }

  /// استخراج عضلات اولویت
  List<String> _extractPriorityMuscles(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_priority_muscles')) {
        final value = profile['bb_priority_muscles'].toString();
        if (value.contains('بدون اولویت')) return [];
        return value.split(', ').where((e) => e.isNotEmpty).toList();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('اولویت') || e.key.contains('عضلات'),
        orElse: () => const MapEntry('', ''),
      );
      final value = entry.value.toString();
      if (value.contains('بدون اولویت')) return [];
      return value.split(', ').where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// استخراج حرکات پایه راحت
  List<String> _extractCompoundMovements(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_compound_comfort')) {
        final value = profile['bb_compound_comfort'].toString();
        if (value.contains('هیچکدام') || value.contains('مطمئن نیستم')) {
          return [];
        }
        return value
            .split(', ')
            .where((e) => e.isNotEmpty && !e.contains('هیچکدام'))
            .toList();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('حرکات پایه') || e.key.contains('راحت'),
        orElse: () => const MapEntry('', ''),
      );
      final value = entry.value.toString();
      if (value.contains('هیچکدام') || value.contains('مطمئن نیستم')) return [];
      return value
          .split(', ')
          .where((e) => e.isNotEmpty && !e.contains('هیچکدام'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// استخراج جزئیات آسیب‌ها
  String _extractInjuryDetails(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_injury_details')) {
        final value = profile['bb_injury_details'].toString();
        return value.isNotEmpty ? value : '';
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('محدودیت') && e.key.contains('دقیقاً'),
        orElse: () => const MapEntry('', ''),
      );
      return entry.value.toString();
    } catch (_) {
      return '';
    }
  }

  /// استخراج یادداشت‌های اضافی
  String _extractExtraNotes(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_extra_notes')) {
        final value = profile['bb_extra_notes'].toString();
        return value.isNotEmpty ? value : '';
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('نکته') || e.key.contains('یادداشت'),
        orElse: () => const MapEntry('', ''),
      );
      return entry.value.toString();
    } catch (_) {
      return '';
    }
  }

  /// استخراج تداوم تمرین
  String _extractTrainingConsistency(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_training_consistency')) {
        return profile['bb_training_consistency'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('چند روز در هفته') && e.key.contains('3 ماه'),
        orElse: () => const MapEntry('', '3 روز'),
      );
      return entry.value.toString();
    } catch (_) {
      return '3 روز';
    }
  }

  /// استخراج جنسیت
  String _extractSex(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_sex')) {
        return profile['bb_sex'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('جنسیت'),
        orElse: () => const MapEntry('', 'مرد'),
      );
      return entry.value.toString();
    } catch (_) {
      return 'مرد';
    }
  }

  /// استخراج وزن
  String _extractWeight(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_weight_kg')) {
        return profile['bb_weight_kg'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('وزن') && e.key.contains('کیلو'),
        orElse: () => const MapEntry('', '70'),
      );
      return entry.value.toString();
    } catch (_) {
      return '70';
    }
  }

  /// استخراج قد
  String _extractHeight(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_height_cm')) {
        return profile['bb_height_cm'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('قد') && e.key.contains('سانتی'),
        orElse: () => const MapEntry('', '175'),
      );
      return entry.value.toString();
    } catch (_) {
      return '175';
    }
  }

  /// استخراج ترجیح سبک تمرین
  String _extractStylePreference(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_style_preference')) {
        return profile['bb_style_preference'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('ترجیح سبک') || e.key.contains('سبک تمرین'),
        orElse: () => const MapEntry('', 'ترکیبی'),
      );
      return entry.value.toString();
    } catch (_) {
      return 'ترکیبی';
    }
  }

  /// استخراج ساعات خواب به صورت عدد
  String _extractSleepHoursRaw(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_sleep_hours')) {
        return profile['bb_sleep_hours'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('خواب'),
        orElse: () => const MapEntry('', '7'),
      );
      return entry.value.toString();
    } catch (_) {
      return '7';
    }
  }

  /// استخراج مدت زمان جلسه به صورت عدد
  String _extractSessionDurationRaw(Map<String, dynamic> profile) {
    try {
      if (profile.containsKey('bb_session_minutes')) {
        return profile['bb_session_minutes'].toString();
      }
      final entry = profile.entries.firstWhere(
        (e) => e.key.contains('زمان دارید') || e.key.contains('مدت زمان'),
        orElse: () => const MapEntry('', '60'),
      );
      return entry.value.toString();
    } catch (_) {
      return '60';
    }
  }
}
