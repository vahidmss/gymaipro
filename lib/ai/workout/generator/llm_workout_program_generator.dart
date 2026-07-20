import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/services/ai_chat_availability.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/ai/workout/generator/llm_iran_gym_style.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_catalog_curator.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_program_sanitizer.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_program_validator.dart';
import 'package:gymaipro/ai/workout/labels/workout_session_labels.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:uuid/uuid.dart';

/// User-facing copy only — never leak validator/repair internals.
const String llmWorkoutProgramUserFailureMessage =
    'ساخت برنامه ممکن نشد. لطفاً دوباره تلاش کنید.';

class LlmWorkoutProgramOutcome {
  const LlmWorkoutProgramOutcome.success(this.program) : errorMessage = null;

  const LlmWorkoutProgramOutcome.failure(this.errorMessage) : program = null;

  final WorkoutProgram? program;
  final String? errorMessage;

  bool get isSuccess => program != null;
}

/// LLM decides the program; local engines only curate catalog and validate.
class LlmWorkoutProgramGenerator {
  LlmWorkoutProgramGenerator({OpenAIService? openAi})
    : _openAi = openAi ?? OpenAIService();

  final OpenAIService _openAi;
  static const _uuid = Uuid();
  static const int _maxTokens = 4096;
  static const Duration _timeout = Duration(seconds: 90);

  Future<LlmWorkoutProgramOutcome> generate({
    required CoachContext context,
    required String userId,
    required List<Exercise> catalog,
  }) async {
    if (!AiEngineConfig.canAttemptOpenAi) {
      return const LlmWorkoutProgramOutcome.failure(
        gymAiModelsUnavailableMessage,
      );
    }

    final daysPerWeek = _daysPerWeek(context);
    final curated = LlmWorkoutCatalogCurator.curate(
      catalog,
      equipment: context.equipment,
      restrictions: context.restrictions,
    );
    if (curated.isEmpty) {
      return const LlmWorkoutProgramOutcome.failure(
        llmWorkoutProgramUserFailureMessage,
      );
    }

    final byId = <int, Exercise>{
      for (final exercise in curated) exercise.id: exercise,
    };
    final allowedIds = byId.keys.toSet();
    final curatedList = curated.toList(growable: false);

    try {
      var prompt = _buildPrompt(context: context, curated: curatedList);
      final program = await _requestAndParse(
        prompt: prompt,
        userId: userId,
        context: context,
        byId: byId,
        daysPerWeek: daysPerWeek,
      );

      if (program == null) {
        return const LlmWorkoutProgramOutcome.failure(
          llmWorkoutProgramUserFailureMessage,
        );
      }

      var current = _sanitize(
        program,
        curated: curatedList,
      );
      var issues = LlmWorkoutProgramValidator.validate(
        current,
        allowedExerciseIds: allowedIds,
        expectedDaysPerWeek: daysPerWeek,
      );

      // Up to two repair rounds — then sanitize again before final validate.
      for (var attempt = 0; attempt < 2 && issues.isNotEmpty; attempt++) {
        if (kDebugMode) {
          debugPrint(
            '[LlmWorkoutGen] validation issues (repair ${attempt + 1}): '
            '$issues',
          );
        }
        prompt = _buildRepairPrompt(
          originalPrompt: prompt,
          issues: issues,
          previousJson: jsonEncode(_compactProgramJson(current)),
        );
        final repaired = await _requestAndParse(
          prompt: prompt,
          userId: userId,
          context: context,
          byId: byId,
          daysPerWeek: daysPerWeek,
        );
        if (repaired == null) {
          // Keep last sanitized attempt; try local sanitize-only pass below.
          break;
        }
        current = _sanitize(repaired, curated: curatedList);
        issues = LlmWorkoutProgramValidator.validate(
          current,
          allowedExerciseIds: allowedIds,
          expectedDaysPerWeek: daysPerWeek,
        );
      }

      if (issues.isNotEmpty) {
        // Final silent fix pass (no more LLM) — strip/fill from catalog.
        current = _sanitize(current, curated: curatedList);
        issues = LlmWorkoutProgramValidator.validate(
          current,
          allowedExerciseIds: allowedIds,
          expectedDaysPerWeek: daysPerWeek,
        );
      }

      // One more local pass if only leftover focus noise remains.
      if (issues.isNotEmpty) {
        current = _sanitize(current, curated: curatedList);
        issues = LlmWorkoutProgramValidator.validate(
          current,
          allowedExerciseIds: allowedIds,
          expectedDaysPerWeek: daysPerWeek,
        );
      }

      if (issues.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[LlmWorkoutGen] still invalid after repairs: $issues');
        }
        return const LlmWorkoutProgramOutcome.failure(
          llmWorkoutProgramUserFailureMessage,
        );
      }

      return LlmWorkoutProgramOutcome.success(current);
    } on OpenAIException catch (e) {
      if (kDebugMode) {
        debugPrint('[LlmWorkoutGen] OpenAIException: $e');
      }
      return const LlmWorkoutProgramOutcome.failure(
        gymAiModelsUnavailableMessage,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LlmWorkoutGen] failed: $e\n$st');
      }
      return const LlmWorkoutProgramOutcome.failure(
        gymAiModelsUnavailableMessage,
      );
    }
  }

  WorkoutProgram _sanitize(
    WorkoutProgram program, {
    required List<Exercise> curated,
  }) {
    final used = <int>{};
    return LlmWorkoutProgramSanitizer.sanitize(
      program,
      curatedCatalog: curated,
      usedAcrossProgram: used,
    );
  }

  Future<WorkoutProgram?> _requestAndParse({
    required String prompt,
    required String userId,
    required CoachContext context,
    required Map<int, Exercise> byId,
    required int daysPerWeek,
  }) async {
    final content = await _openAi.sendCompletion(
      messages: <Map<String, String>>[
        {
          'role': 'system',
          'content':
              'تو مربی حرفه‌ای بدنسازی هستی. فقط JSON معتبر برمی‌گردانی. '
              'برنامه باید خلاقانه، متنوع و شخصی‌سازی‌شده باشد.',
        },
        {'role': 'user', 'content': prompt},
      ],
      model: AppConfig.aiDefaultModel,
      temperature: 0.7,
      maxTokens: _maxTokens,
      responseFormat: const <String, dynamic>{'type': 'json_object'},
      requestTimeout: _timeout,
    );

    return _parseProgram(
      content,
      userId: userId,
      context: context,
      byId: byId,
      daysPerWeek: daysPerWeek,
    );
  }

  String _buildPrompt({
    required CoachContext context,
    required List<Exercise> curated,
  }) {
    final days = _daysPerWeek(context);
    final experience = _experience(context);
    final goals = context.goals.isEmpty
        ? <String>['عمومی']
        : context.goals;
    final sessionMinutes = _sessionMinutes(context);
    final intensity = context.preferences['desired_intensity']?.toString() ??
        context.preferences['intensity']?.toString() ??
        'متوسط';

    final catalogLines = curated
        .map((e) {
          final popular = LlmIranGymPopularity.score(e) >= 12 ? '★رایج|' : '';
          return '$popular${e.id}|${e.name}|${e.mainMuscle}|${e.equipment}';
        })
        .join('\n');

    final styleGuide = LlmIranGymStyleGuide.splitGuidance(
      daysPerWeek: days,
      experience: experience,
      goals: goals,
    );

    return '''
تو مربی باشگاه ایران هستی. برنامه‌ای بده که کاربر ایرانی در باشگاه معمولی بفهمد و دوست داشته باشد — شبیه برنامه‌های رایگان محبوب، نه حرکات غریب آزمایشگاهی.

### کاربر
- سن: ${context.profile['age'] ?? 'نامشخص'}
- قد: ${context.profile['height'] ?? 'نامشخص'}
- وزن: ${context.profile['weight'] ?? 'نامشخص'}
- جنسیت: ${context.profile['gender'] ?? 'نامشخص'}
- سطح تجربه: $experience
- اهداف: ${goals.join('، ')}
- تجهیزات: ${context.equipment.join('، ')}
- محدودیت‌ها/آسیب‌ها: ${context.restrictions.isEmpty ? 'ندارد' : context.restrictions.join('، ')}
- روز در هفته: $days
- مدت هر جلسه (دقیقه): $sessionMinutes
- شدت مطلوب: $intensity
- ترجیحات: ${context.preferences.entries.map((e) => '${e.key}=${e.value}').join(' | ')}

### سبک رایج در ایران (الگوی ذهنی — برنامه را از کاتالوگ بساز)
$styleGuide

### فهرست تمرینات مجاز (فقط از این‌ها)
فرمت: [★رایج|]id|نام|عضله اصلی|تجهیزات
حرکات ★رایج را در اولویت بگذار مگر محدودیت آسیب/تجهیزات مانع شود.
$catalogLines

### الزامات کیفیت
1. نام برنامه: کوتاه و طبیعی مثل مربی باشگاه (مثلاً «چربی‌سوز ۳روزه باشگاهی»).
   ممنوع: «حرکات آشنا»، «با حرکات پایه»، «جذاب با …»، توضیح متا داخل اسم، قالب «برنامه X — N روزه».
2. دقیقاً $days جلسه با نام یکتا و فارسی. قالب اجباری: «روز N — نقش».
   برای $days روز از این الگوی نام‌گذاری استفاده کن:
${_sessionNamingGuide(days)}
   ممنوع: دو جلسه با نام یکسان (مثلاً دو تا فقط «فشار»).
   اگر نقش تکراری است شماره بگذار: بالاتنه ۱ / بالاتنه ۲ یا فشار ۱ / فشار ۲.
3. هر جلسه قدرتی حداقل ۵ حرکت.
4. ترتیب هر روز: عضله‌ها را پشت‌سرهم نگه دار (سینه→سینه، بعد سرشانه، بعد پشت‌بازو). شکم/زمان‌دار همیشه آخر. بین عضله‌ها نپر.
5. روز فشار: حداکثر ۲ سینه + حداکثر ۲ سرشانه فشاری؛ حتماً ۱ پشت‌بازو؛ ممنوع زیربغل/پا/جلوبازو. پنج پرس پشت‌سرهم ممنوع.
6. روز کشش: پشت/زیربغل با هم، بعد جلوبازو، شکم آخر؛ ممنوع اسکوات/پا/سینه/پشت‌بازو.
7. روز پا: چهارسر با هم → همسترینگ/باسن → ساق → شکم آخر؛ ممنوع سینه/زیربغل/سرشانه.
8. ست‌ها معمولاً ۳ ست؛ تکرار متناسب هدف — همه را یکسان نکن.
9. فقط exercise_id از فهرست؛ بین روزها حرکت تکراری نگذار.
10. حرکات ★رایج را ترجیح بده وقتی موجودند.

### JSON خروجی (فقط همین)
{
  "program_name": "نام کوتاه طبیعی فارسی",
  "sessions": [
    {
      "name": "برچسب روز",
      "notes": "یادداشت کوتاه اختیاری",
      "exercises": [
        {
          "exercise_id": 1234,
          "name": "نام دقیق از فهرست",
          "style": "sets_reps",
          "sets": [{"reps": 10}, {"reps": 10}, {"reps": 8}]
        }
      ]
    }
  ]
}

برای کاردیو از style=sets_time و sets با time_seconds استفاده کن.
فقط JSON برگردان.
''';
  }

  String _buildRepairPrompt({
    required String originalPrompt,
    required List<String> issues,
    required String previousJson,
  }) {
    return '''
$originalPrompt

### اصلاح اجباری
برنامه قبلی این ایرادها را داشت — همان را اصلاح کن و JSON کامل جدید بده:
${issues.map((i) => '- $i').join('\n')}

برنامه قبلی:
$previousJson
''';
  }

  WorkoutProgram? _parseProgram(
    String raw, {
    required String userId,
    required CoachContext context,
    required Map<int, Exercise> byId,
    required int daysPerWeek,
  }) {
    final data = _decodeJsonObject(raw);
    if (data == null) return null;

    final sessionsRaw = data['sessions'];
    if (sessionsRaw is! List || sessionsRaw.isEmpty) return null;

    final nameByNormalized = <String, Exercise>{
      for (final exercise in byId.values)
        _normalizeName(exercise.name): exercise,
    };

    final days = <WorkoutDay>[];
    var dayIndex = 0;
    for (final item in sessionsRaw) {
      if (item is! Map) continue;
      final session = Map<String, dynamic>.from(item);
      final label = (session['name'] ?? session['day'] ?? 'روز ${dayIndex + 1}')
          .toString()
          .trim();
      final exercisesRaw = session['exercises'];
      if (exercisesRaw is! List) continue;

      final exercises = <WorkoutExercise>[];
      var order = 0;
      for (final exItem in exercisesRaw) {
        if (exItem is! Map) continue;
        final ex = Map<String, dynamic>.from(exItem);
        final providedId =
            int.tryParse(ex['exercise_id']?.toString() ?? '') ?? 0;
        final providedName =
            (ex['name'] ?? ex['tag'] ?? '').toString().trim();

        Exercise? catalogExercise = byId[providedId];
        if (catalogExercise == null && providedName.isNotEmpty) {
          catalogExercise = nameByNormalized[_normalizeName(providedName)];
        }
        if (catalogExercise == null) continue;

        final style = (ex['style']?.toString() ?? 'sets_reps').toLowerCase();
        final sets = _parseSets(ex, preferTime: style.contains('time'));
        exercises.add(
          WorkoutExercise(
            id: _uuid.v4(),
            catalogExerciseId: catalogExercise.id,
            name: catalogExercise.name,
            primaryMuscle: catalogExercise.mainMuscle,
            secondaryMuscles: catalogExercise.secondaryMuscles
                .split(RegExp('[,،/|]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(growable: false),
            equipment: catalogExercise.equipment,
            difficulty: catalogExercise.difficulty,
            order: order,
            sets: sets,
          ),
        );
        order++;
      }

      if (exercises.isEmpty) continue;
      days.add(
        WorkoutDay(
          id: _uuid.v4(),
          dayIndex: dayIndex,
          label: label.isEmpty ? 'روز ${dayIndex + 1}' : label,
          exercises: exercises,
        ),
      );
      dayIndex++;
    }

    if (days.isEmpty) return null;

    final uniqueLabels = WorkoutSessionLabels.normalizeParsed(
      days.map((d) => d.label).toList(growable: false),
    );
    final normalizedDays = <WorkoutDay>[
      for (var i = 0; i < days.length; i++)
        WorkoutDay(
          id: days[i].id,
          dayIndex: i,
          label: uniqueLabels[i],
          notes: days[i].notes,
          exercises: days[i].exercises,
        ),
    ];

    final now = DateTime.now();
    final programName =
        (data['program_name'] ?? data['name'] ?? '').toString().trim();

    return WorkoutProgram(
      id: _uuid.v4(),
      userId: userId,
      name: programName.isEmpty ? 'برنامه اختصاصی جیم‌آی' : programName,
      goal: _goalFromContext(context),
      experienceLevel: _experience(context),
      daysPerWeek: daysPerWeek > 0 ? daysPerWeek : normalizedDays.length,
      sessionDurationMinutes: _sessionMinutes(context),
      weeks: <WorkoutWeek>[
        WorkoutWeek(id: _uuid.v4(), weekIndex: 0, days: normalizedDays),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  String _sessionNamingGuide(int days) {
    final labels = WorkoutSessionLabels.forDaysPerWeek(days);
    return labels.map((l) => '   - $l').join('\n');
  }

  List<WorkoutSet> _parseSets(
    Map<String, dynamic> exerciseData, {
    required bool preferTime,
  }) {
    final raw = exerciseData['sets'] ?? exerciseData['sets_details'];
    if (raw is! List || raw.isEmpty) {
      return List<WorkoutSet>.generate(
        3,
        (i) => WorkoutSet(
          id: _uuid.v4(),
          order: i,
          type: WorkoutSetType.reps,
          reps: 10,
        ),
      );
    }

    final sets = <WorkoutSet>[];
    var order = 0;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final time =
          int.tryParse(
            (map['time_seconds'] ?? map['timeSeconds'] ?? '').toString(),
          );
      final reps = int.tryParse((map['reps'] ?? '').toString());
      if (preferTime || (time != null && time > 0 && reps == null)) {
        sets.add(
          WorkoutSet(
            id: _uuid.v4(),
            order: order,
            type: WorkoutSetType.time,
            timeSeconds: time ?? 600,
          ),
        );
      } else {
        sets.add(
          WorkoutSet(
            id: _uuid.v4(),
            order: order,
            type: WorkoutSetType.reps,
            reps: reps ?? 10,
          ),
        );
      }
      order++;
    }
    return sets.isEmpty
        ? <WorkoutSet>[
            WorkoutSet(
              id: _uuid.v4(),
              order: 0,
              type: WorkoutSetType.reps,
              reps: 10,
            ),
          ]
        : sets;
  }

  Map<String, dynamic>? _decodeJsonObject(String raw) {
    var clean = raw.trim();
    if (clean.contains('```')) {
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start >= 0 && end > start) {
        clean = clean.substring(start, end + 1);
      }
    }
    try {
      final decoded = jsonDecode(clean);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          final decoded = jsonDecode(clean.substring(start, end + 1));
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  Map<String, Object?> _compactProgramJson(WorkoutProgram program) {
    return <String, Object?>{
      'program_name': program.name,
      'sessions': program.allDays
          .map(
            (day) => <String, Object?>{
              'name': day.label,
              'exercises': day.exercises
                  .map(
                    (e) => <String, Object?>{
                      'exercise_id': e.catalogExerciseId,
                      'name': e.name,
                      'sets': e.sets
                          .map(
                            (s) => s.type == WorkoutSetType.time
                                ? <String, Object?>{
                                    'time_seconds': s.timeSeconds,
                                  }
                                : <String, Object?>{'reps': s.reps},
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }

  int _daysPerWeek(CoachContext context) {
    final prefs = context.preferences;
    final raw =
        prefs['workout_days'] ??
        prefs['days_per_week'] ??
        prefs['training_days'] ??
        context.profile['days_per_week'] ??
        context.profile['bb_days_per_week'] ??
        context.profile['preferred_training_days'];
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed != null && parsed >= 2 && parsed <= 7) return parsed;
    return 3;
  }

  int _sessionMinutes(CoachContext context) {
    final raw =
        context.preferences['session_minutes'] ??
        context.preferences['session_duration'] ??
        context.profile['session_minutes'];
    return int.tryParse(raw?.toString() ?? '') ?? 60;
  }

  String _experience(CoachContext context) {
    final raw =
        context.profile['experience_level'] ??
        context.preferences['experience'] ??
        context.profile['experience'];
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? 'متوسط' : text;
  }

  TrainingGoal _goalFromContext(CoachContext context) {
    final text = context.goals.join(' ').toLowerCase();
    if (text.contains('چربی') || text.contains('fat')) {
      return TrainingGoal.fatLoss;
    }
    if (text.contains('حجم') || text.contains('hypertrophy')) {
      return TrainingGoal.hypertrophy;
    }
    if (text.contains('قدرت') || text.contains('strength')) {
      return TrainingGoal.strength;
    }
    if (text.contains('استقامت') || text.contains('endurance')) {
      return TrainingGoal.endurance;
    }
    return TrainingGoal.general;
  }

  String _normalizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک');
  }
}
