import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/exercise_meta_normalizer.dart';
import 'package:gymaipro/models/muscle_targets.dart';

/// تولید متادیتای تمرین اختصاصی مربی با AI — شناسایی + هستهٔ کاربردی + هیت‌مپ.
class AIExerciseMetadataService {
  AIExerciseMetadataService({OpenAIService? openAI})
      : _openAI = openAI ?? OpenAIService();

  static const String _model = AppConfig.aiDefaultModel;
  static const Duration _requestTimeout = Duration(seconds: 45);

  static List<String> get _mainMuscles => ExerciseMetaNormalizer.mainMuscles;
  static List<String> get _movementPatterns =>
      ExerciseMetaNormalizer.movementPatterns;
  static List<String> get _bodyEngagements =>
      ExerciseMetaNormalizer.bodyEngagements;
  static List<String> get _mechanicsTypes =>
      ExerciseMetaNormalizer.mechanicsTypes;
  static List<String> get _forceTypes => ExerciseMetaNormalizer.forceTypes;

  static const List<String> _equipments = [
    'بدون تجهیزات',
    'هالتر',
    'دمبل',
    'دستگاه',
    'کابل',
    'کتل‌بل',
    'کش',
  ];

  final OpenAIService _openAI;

  bool get isAvailable => AiEngineConfig.canAttemptOpenAi;

  /// سه تفسیر احتمالی از تمرین — مربی یکی را انتخاب می‌کند.
  Future<List<ExerciseIdentityOption>> identifyExerciseOptions({
    required String title,
    required String name,
    String? hint,
  }) async {
    if (!isAvailable) {
      throw const OpenAIException(
        'هوش مصنوعی در دسترس نیست. اطلاعات را دستی وارد کنید.',
      );
    }

    final prompt = '''
مربی یک تمرین اختصاصی ثبت می‌کند. ممکن است اسم عجیب، فارسی/انگلیسی مخلوط، یا اختصاری باشد.
با توجه به عنوان، نام و راهنمای کوتاه (اگر هست)، دقیقاً ۳ تفسیر **متفاوت** از این تمرین بده.
هر تفسیر باید یک حرکت/واریانت مشخص باشد (نه سه توضیح از یک حرکت).

عنوان مربی: $title
نام مربی: $name
راهنمای کوتاه: ${hint?.trim().isEmpty ?? true ? '(ندارد)' : hint!.trim()}

خروجی JSON با این ساختار:
{
  "options": [
    {
      "id": "1",
      "standard_name_fa": "نام فارسی استاندارد",
      "standard_name_en": "English name",
      "summary": "یک جمله — این حرکت دقیقاً چیست",
      "main_muscle_group": "یکی از: ${_mainMuscles.join('، ')}",
      "equipment_hint": "یکی از: ${_equipments.join('، ')}"
    }
  ]
}
''';

    final raw = await _completionJson(
      system: _systemPrompt,
      user: prompt,
      maxTokens: 1200,
    );

    final list = raw['options'];
    if (list is! List || list.isEmpty) {
      throw const OpenAIException('پاسخ نامعتبر از هوش مصنوعی');
    }

    final parsed = <ExerciseIdentityOption>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        parsed.add(ExerciseIdentityOption.fromJson(item));
      } else if (item is Map) {
        parsed.add(ExerciseIdentityOption.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    if (parsed.isEmpty) {
      throw const OpenAIException('گزینه‌ای برای تمرین پیدا نشد');
    }

    return parsed.take(3).toList();
  }

  /// هستهٔ کاربردی (MET/RPE/pattern/...) + نقشه عضلانی — بدون توضیحات/نکات.
  Future<GeneratedMuscleProfile> generateMuscleProfile({
    required String title,
    required String name,
    required ExerciseIdentityOption selectedOption,
    String? hint,
  }) async {
    if (!isAvailable) {
      throw const OpenAIException(
        'هوش مصنوعی در دسترس نیست. عضله اصلی را دستی انتخاب کنید.',
      );
    }

    final muscleKeysDoc = MuscleTargets.allKeys
        .map((k) => '$k (${MuscleTargets.label(k)})')
        .join(', ');

    final prompt = '''
مربی تمرین اختصاصی ثبت می‌کند. هستهٔ متای تمرینی + نقشه عضلانی لازم است
(مثل کاتالوگ استاندارد اپ). توضیحات و نکات لازم نیست.

عنوان: $title
نام: $name
${hint != null && hint.trim().isNotEmpty ? 'راهنمای کوتاه: ${hint.trim()}' : ''}

تفسیر تأییدشده:
- ${selectedOption.standardNameFa} / ${selectedOption.standardNameEn}
- ${selectedOption.summary}
- عضله: ${selectedOption.mainMuscleGroup}
- تجهیزات: ${selectedOption.equipmentHint}

قوانین:
- main_muscle یکی از: ${_mainMuscles.join('، ')}
- muscle_targets: کلیدهای مجاز (0-100): $muscleKeysDoc
- secondary_muscles: نام فارسی عضلات فرعی با کاما
- حداقل ۲ و حداکثر ۶ عضله در muscle_targets با مقدار > 0
- movement_pattern یکی از: ${_movementPatterns.join(', ')}
- body_engagement یکی از: ${_bodyEngagements.join(', ')}
- mechanics_type یکی از: ${_mechanicsTypes.join(', ')}
- force_type یکی از: ${_forceTypes.join(', ')}
- met: عدد اعشاری منطقی (مثلاً ایزوله ~3-4، اسکوات/کمپاند ~5-7، کاردیو سنگین‌تر)
- typical_rpe: بین 5 و 9.5
- calories_per_1000kg: عدد صحیح تقریبی کالری به‌ازای ۱۰۰۰ کیلوگرم جابه‌جایی (مثلاً 20-80)

خروجی JSON:
{
  "main_muscle": "...",
  "secondary_muscles": "...",
  "muscle_targets": {"chest_middle": 90, "triceps": 40},
  "met": 5.0,
  "typical_rpe": 7.5,
  "movement_pattern": "horizontal_push",
  "body_engagement": "compound",
  "mechanics_type": "compound",
  "force_type": "push",
  "calories_per_1000kg": 35
}
''';

    final raw = await _completionJson(
      system: _systemPrompt,
      user: prompt,
      maxTokens: 1200,
    );

    return _normalizeMuscleProfile(GeneratedMuscleProfile.fromJson(raw));
  }

  GeneratedMuscleProfile _normalizeMuscleProfile(GeneratedMuscleProfile meta) {
    return ExerciseMetaNormalizer.normalizeProfile(meta);
  }

  Future<Map<String, dynamic>> _completionJson({
    required String system,
    required String user,
    required int maxTokens,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final content = await _openAI.sendCompletion(
          messages: [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
          model: _model,
          temperature: attempt == 0 ? 0.4 : 0.2,
          maxTokens: maxTokens,
          responseFormat: const {'type': 'json_object'},
          requestTimeout: _requestTimeout,
        );

        final decoded = jsonDecode(content.trim());
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('AIExerciseMetadataService attempt ${attempt + 1}: $e');
        }
      }
    }

    if (lastError is OpenAIException) {
      throw lastError;
    }
    throw OpenAIException('خطا در تولید اطلاعات: $lastError');
  }

  static const String _systemPrompt = '''
شما متخصص علوم ورزشی هستید که برای اپ بدنسازی، هستهٔ متای تمرین
(MET، RPE، الگوی حرکت، engagement، mechanics، force، کالری تقریبی)
و نقشه عضلانی را مثل کاتالوگ استاندارد پر می‌کنید.
همیشه JSON معتبر برگردانید. فقط JSON — بدون markdown.
برای movement_pattern / body_engagement / mechanics_type / force_type / main_muscle
فقط و فقط از کلیدهای انگلیسی/فارسی مجاز فهرست‌شده در پیام کاربر استفاده کنید.
هرگز عبارت آزاد مثل "shoulder abduction" ننویسید؛ معادل canonical بدهید
(مثلاً shoulder_abduction برای نشر جانب).
''';
}
