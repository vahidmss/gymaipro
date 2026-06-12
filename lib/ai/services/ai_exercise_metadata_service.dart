import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/muscle_targets.dart';

/// تولید متادیتای تمرین اختصاصی مربی با AI — شناسایی + پر کردن فیلدها.
class AIExerciseMetadataService {
  AIExerciseMetadataService({OpenAIService? openAI})
      : _openAI = openAI ?? OpenAIService();

  static const String _model = AppConfig.aiDefaultModel;
  static const Duration _requestTimeout = Duration(seconds: 45);

  static const List<String> _mainMuscles = [
    'سینه',
    'پشت',
    'شانه',
    'پا',
    'بازو',
    'شکم',
    'سرینی',
    'ساعد',
    'کاردیو',
    'کل بدن',
  ];

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

    final options = raw['options'];
    if (options is! List || options.isEmpty) {
      throw const OpenAIException('پاسخ AI نامعتبر بود. دوباره تلاش کنید.');
    }

    final parsed = options
        .whereType<Map<String, dynamic>>()
        .map(ExerciseIdentityOption.fromJson)
        .where((o) => o.summary.isNotEmpty)
        .toList();

    if (parsed.isEmpty) {
      throw const OpenAIException('پاسخ AI نامعتبر بود. دوباره تلاش کنید.');
    }

    return parsed.take(3).toList();
  }

  /// فقط نقشه عضلانی و عضلات — بدون توضیحات/نکات (کاهش هزینه API).
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
مربی تمرین را ثبت می‌کند و فقط **نقشه عضلانی (heatmap)** می‌خواهد.
توضیحات و نکات تمرین لازم نیست — فقط عضلات درگیر.

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

خروجی JSON:
{
  "main_muscle": "...",
  "secondary_muscles": "...",
  "muscle_targets": {"chest_middle": 90, "triceps": 40}
}
''';

    final raw = await _completionJson(
      system: _systemPrompt,
      user: prompt,
      maxTokens: 900,
    );

    return _normalizeMuscleProfile(GeneratedMuscleProfile.fromJson(raw));
  }

  GeneratedMuscleProfile _normalizeMuscleProfile(GeneratedMuscleProfile meta) {
    return GeneratedMuscleProfile(
      mainMuscle:
          _mainMuscles.contains(meta.mainMuscle) ? meta.mainMuscle : 'کل بدن',
      secondaryMuscles: meta.secondaryMuscles,
      muscleTargets: meta.muscleTargets,
    );
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
شما متخصص علوم ورزشی و آناتومی هستید که به مربیان بدنسازی کمک می‌کنید
نقشه عضلانی (heatmap) تمرین اختصاصی‌شان را بسازند.
همیشه JSON معتبر فارسی برگردانید. فقط JSON — بدون markdown.
''';
}
