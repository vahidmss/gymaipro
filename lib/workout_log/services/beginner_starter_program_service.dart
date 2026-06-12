import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// نتیجهٔ فعال‌سازی برنامهٔ مبتدی + ثبت شاگردی زیر نظارت GymAI.
class StarterProgramActivationResult {
  const StarterProgramActivationResult({
    required this.program,
    required this.trainerDisplayName,
    this.isNewAiStudent = false,
    this.upgradedFromVersion,
    this.rebuiltProgram = false,
  });

  final WorkoutProgram program;
  final String trainerDisplayName;
  final bool isNewAiStudent;
  /// اگر برنامهٔ قدیمی حذف و نسخهٔ جدید ساخته شد.
  final int? upgradedFromVersion;
  final bool rebuiltProgram;
}

/// برنامهٔ رایگان شروع باشگاه — تمام‌بدن ۳ روز در هفته، فقط تازه‌وارد.
///
/// بر پایهٔ الگوی رایج «Full Body ×3» (ماشین/اسمیت) و توصیه ACSM:
/// تمرین منظم همه گروه‌های عضلانی، ۴۸س فاصله بین جلسات، ۳ست×۱۰–۱۲
/// با ۲–۳ تکرار ذخیره (بدون رسیدن به ناتوانی).
class BeginnerStarterProgramService {
  BeginnerStarterProgramService({
    WorkoutProgramService? programService,
    ActiveProgramService? activeProgramService,
    ExerciseService? exerciseService,
    TrainerClientService? trainerClientService,
  }) : _programs = programService ?? WorkoutProgramService(),
       _active = activeProgramService ?? ActiveProgramService(),
       _exercises = exerciseService ?? ExerciseService(),
       _trainerClients = trainerClientService ?? TrainerClientService();

  static const String programDisplayName = 'برنامه شروع باشگاه (مبتدی)';
  static const String generatedByKey = 'gymai_starter';
  static const int recommendedWeeks = 4;
  static const int week1Sets = 2;
  static const int defaultSets = 3;

  /// نسخهٔ محتوای برنامه — ID ثابت از کاتالوگ + ۲ ست هفتهٔ اول.
  static const int programVersion = 5;

  final WorkoutProgramService _programs;
  final ActiveProgramService _active;
  final ExerciseService _exercises;
  final TrainerClientService _trainerClients;

  /// آیا دادهٔ JSON این برنامه، برنامهٔ مبتدی رایگان است؟
  static bool isStarterProgramData(dynamic dataRaw) {
    if (dataRaw == null) return false;
    try {
      final Map<String, dynamic> decoded = dataRaw is String
          ? Map<String, dynamic>.from(jsonDecode(dataRaw) as Map)
          : Map<String, dynamic>.from(dataRaw as Map);
      return decoded['generated_by'] == generatedByKey;
    } catch (_) {
      return false;
    }
  }

  static int? starterVersionFromData(dynamic dataRaw) {
    if (dataRaw == null) return null;
    try {
      final Map<String, dynamic> decoded = dataRaw is String
          ? Map<String, dynamic>.from(jsonDecode(dataRaw) as Map)
          : Map<String, dynamic>.from(dataRaw as Map);
      final v = decoded['starter_version'];
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasStarterProgram() async {
    final p = await _programs.findStarterProgram();
    return p != null;
  }

  /// برنامهٔ مبتدی نصب شده ولی نسخهٔ قدیمی‌تر از [programVersion] است.
  Future<bool> needsStarterUpgrade() async {
    final v = await _installedStarterVersion();
    return v != null && v < programVersion;
  }

  /// نصب (در صورت نبود یا قدیمی بودن) + فعال‌سازی + ثبت شاگردی.
  Future<StarterProgramActivationResult> installAndActivate() async {
    int? upgradedFrom;
    var rebuilt = false;

    final existing = await _programs.findStarterProgram();
    if (existing != null) {
      final version = await _installedStarterVersion();
      if (version != null && version >= programVersion) {
        await _active.setActiveProgram(existing.id);
        return _completeAiTrainerEnrollment(existing);
      }
      upgradedFrom = version ?? 1;
      rebuilt = true;
      if (kDebugMode) {
        debugPrint(
          '[StarterProgram] ارتقا از v$upgradedFrom به v$programVersion…',
        );
      }
      await _programs.deleteProgram(existing.id);
    }

    final allExercises = await _exercises.getExercises();
    if (allExercises.isEmpty) {
      throw Exception('لیست تمرین‌ها در دسترس نیست. اتصال اینترنت را بررسی کنید.');
    }

    if (kDebugMode) {
      debugPrint('[StarterProgram] کاتالوگ: ${allExercises.length} حرکت');
    }

    final built = _buildProgram(allExercises);
    final program = built.program;
    final weakSession = program.sessions.where((s) => s.exercises.length < 4);
    if (weakSession.isNotEmpty || program.sessions.isEmpty) {
      final missing = built.missingSlots.join('، ');
      if (kDebugMode) {
        debugPrint('[StarterProgram] اسلات خالی: $missing');
      }
      throw Exception(
        missing.isEmpty
            ? 'امکان ساخت برنامه مبتدی وجود ندارد. لطفاً بعداً تلاش کنید.'
            : 'برنامه کامل نشد — این موارد در دیتابیس پیدا نشد: $missing',
      );
    }

    final aiTrainerId = await AITrainerService.resolveTrainerIdForAiPrograms();

    final saved = await _programs.createProgram(
      program,
      trainerId: aiTrainerId,
      autoSend: true,
      starterProgram: true,
    );
    await _active.setActiveProgram(saved.id);
    if (kDebugMode) {
      debugPrint('[StarterProgram] نصب v$programVersion: ${saved.id}');
    }
    return _completeAiTrainerEnrollment(
      saved,
      upgradedFromVersion: upgradedFrom,
      rebuiltProgram: rebuilt,
    );
  }

  Future<int?> _installedStarterVersion() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return null;

      final List<dynamic> response = await Supabase.instance.client
          .from('workout_programs')
          .select('data')
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      for (final row in response) {
        final map = Map<String, dynamic>.from(row as Map);
        if (!isStarterProgramData(map['data'])) continue;
        return starterVersionFromData(map['data']) ?? 1;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StarterProgram] خطا در خواندن نسخه: $e');
      }
      return null;
    }
  }

  /// اگر برنامهٔ فعال‌شده همان برنامهٔ مبتدی است، رابطهٔ شاگرد–مربی AI را تضمین می‌کند.
  Future<StarterProgramActivationResult?> enrollIfStarterProgram(
    String programId,
  ) async {
    final starter = await _programs.findStarterProgram();
    if (starter == null || starter.id != programId) return null;
    return _completeAiTrainerEnrollment(starter);
  }

  Future<StarterProgramActivationResult> _completeAiTrainerEnrollment(
    WorkoutProgram program, {
    int? upgradedFromVersion,
    bool rebuiltProgram = false,
  }) async {
    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) {
      throw Exception('برای استفاده از برنامه باید وارد حساب شوید.');
    }

    final aiTrainerId = await AITrainerService.resolveTrainerIdForAiPrograms();
    final profile = await AITrainerService.getDisplayProfile();
    final trainerName = AITrainerService.displayNameFromProfile(profile);

    if (aiTrainerId != null) {
      await _ensureProgramTrainerId(program.id, aiTrainerId);
      program.trainerId = aiTrainerId;
      program.isSelfServiceAi = true;
    }

    var isNewStudent = false;
    if (aiTrainerId != null) {
      isNewStudent = await _trainerClients.ensureActiveRelationship(
        trainerId: aiTrainerId,
        clientId: userId,
      );
      await AITrainerService.syncActiveStudentCount();
    } else if (kDebugMode) {
      debugPrint(
        '[StarterProgram] پروفایل gymai_trainer یافت نشد — شاگردی ثبت نشد.',
      );
    }

    return StarterProgramActivationResult(
      program: program,
      trainerDisplayName: trainerName,
      isNewAiStudent: isNewStudent,
      upgradedFromVersion: upgradedFromVersion,
      rebuiltProgram: rebuiltProgram,
    );
  }

  Future<void> _ensureProgramTrainerId(String programId, String trainerId) async {
    try {
      await Supabase.instance.client
          .from('workout_programs')
          .update({
            'trainer_id': trainerId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', programId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StarterProgram] خطا در ست trainer_id: $e');
      }
    }
  }

  _StarterBuildResult _buildProgram(List<Exercise> all) {
    final usedIds = <int>{};
    final missingSlots = <String>[];

    final sessions = _sessionTemplates.map((tpl) {
      final exercises = <WorkoutExercise>[];
      for (final spec in tpl.exercises) {
        final ex = _resolveExercise(all, spec, usedIds: usedIds);
        if (ex == null) {
          final idHint = spec.preferredIds.isNotEmpty
              ? ' (id: ${spec.preferredIds.first})'
              : '';
          missingSlots.add('${tpl.day} / ${spec.tag}$idHint');
          continue;
        }
        usedIds.add(ex.id);
        final setCount = spec.sets;
        exercises.add(
          NormalExercise(
            exerciseId: ex.id,
            tag: spec.tag,
            style: spec.timeSeconds != null
                ? ExerciseStyle.setsTime
                : ExerciseStyle.setsReps,
            sets: List.generate(setCount, (_) {
              if (spec.timeSeconds != null) {
                return ExerciseSet(timeSeconds: spec.timeSeconds);
              }
              return ExerciseSet(reps: spec.reps);
            }),
            note: spec.note,
          ),
        );
      }
      return WorkoutSession(
        day: tpl.day,
        notes: tpl.notes,
        exercises: exercises,
      );
    }).toList();

    return _StarterBuildResult(
      program: WorkoutProgram(
        name: programDisplayName,
        isSelfServiceAi: true,
        sessions: sessions,
      ),
      missingSlots: missingSlots,
    );
  }

  Exercise? _resolveExercise(
    List<Exercise> all,
    _ExerciseSpec spec, {
    Set<int>? usedIds,
  }) {
    final byId = {for (final e in all) e.id: e};

    for (final id in spec.preferredIds) {
      final hit = byId[id];
      if (hit == null) continue;
      if (usedIds != null && usedIds.contains(hit.id)) continue;
      final blob = _searchBlob(hit);
      final exclude = spec.excludePatterns.map((p) => p.toLowerCase()).toList();
      if (exclude.any(blob.contains)) continue;
      if (_looksComplexForNewcomer(blob)) continue;
      return hit;
    }

    final lowerPatterns = spec.patterns.map((p) => p.toLowerCase()).toList();
    final exclude = spec.excludePatterns.map((p) => p.toLowerCase()).toList();

    if (spec.slugs.isNotEmpty) {
      for (final slug in spec.slugs) {
        final hit = _findBySlug(all, slug, exclude: exclude, usedIds: usedIds);
        if (hit != null) return hit;
      }
    }

    final matches = all.where((e) {
      final blob = _searchBlob(e);
      if (exclude.any(blob.contains)) return false;
      if (lowerPatterns.any(blob.contains)) return true;
      if (spec.preferredMainMuscles.isNotEmpty) {
        final muscle = e.mainMuscle.toLowerCase();
        if (spec.preferredMainMuscles.any((m) => muscle == m.toLowerCase())) {
          return true;
        }
      }
      return false;
    }).toList();

    if (matches.isEmpty) return null;

    int score(Exercise e) {
      var s = 0;
      final blob = _searchBlob(e);
      final d = e.difficulty.toLowerCase();
      final eq = e.equipment.toLowerCase();
      final muscle = e.mainMuscle.toLowerCase();
      final movement = e.movementPattern.toLowerCase();

      if (_isBeginnerDifficulty(d)) s += 22;
      if (d.contains('intermediate') || d.contains('متوسط')) s += 6;
      if (d.contains('advanced') ||
          d.contains('expert') ||
          d.contains('پیشرفته') ||
          d.contains('حرفه')) {
        s -= 40;
      }
      if (!_isBeginnerDifficulty(d)) s -= 28;

      if (_looksComplexForNewcomer(blob)) s -= 35;

      if (spec.preferMachine && _isStableEquipment(blob, eq)) s += 14;
      if (spec.preferMachine &&
          (blob.contains('هالتر') || blob.contains('barbell'))) {
        s -= 12;
      }
      if (spec.preferCable &&
          (blob.contains('سیمکش') ||
              blob.contains('کابل') ||
              eq.contains('cable'))) {
        s += 8;
      }

      final type = e.exerciseType.toLowerCase();
      if (type.contains('cardio') || blob.contains('بورپی')) s -= 25;

      for (final m in spec.preferredMainMuscles) {
        if (muscle == m.toLowerCase()) s += 12;
      }
      for (final mv in spec.preferredMovements) {
        if (movement == mv.toLowerCase()) s += 10;
      }

      for (final p in lowerPatterns) {
        if (blob == p) {
          s += 14;
        } else if (blob.contains(p)) {
          s += 7;
        }
      }
      if (spec.slugs.any((s) => _slugOf(e) == _normalizeSlug(s))) s += 40;

      if (usedIds != null && usedIds.contains(e.id)) s -= 18;

      return s;
    }

    matches.sort((a, b) => score(b).compareTo(score(a)));

    Exercise pickBest() {
      final beginners = matches
          .where((e) => _isBeginnerDifficulty(e.difficulty.toLowerCase()))
          .toList();
      if (beginners.isNotEmpty) {
        beginners.sort((a, b) => score(b).compareTo(score(a)));
        return beginners.first;
      }
      return matches.first;
    }

    final best = pickBest();
    if (score(best) < 0) return null;
    return best;
  }

  /// حرکت‌هایی که برای هفته‌های اول باشگاه زود است.
  static bool _looksComplexForNewcomer(String blob) {
    const hard = [
      'تک بازو',
      'تک‌بازو',
      'single arm',
      'یک دست',
      'اینکلاین',
      'incline',
      'لانج',
      'lunge',
      'دیپ',
      'dip',
      'بارفیکس',
      'pull-up',
      'pull up',
      'chin-up',
      'بورپی',
      'burpee',
      'پالوف',
      'pallof',
      'مکث',
      'pause squat',
      'هاک',
      'hack squat',
      'ددلیفت',
      'deadlift',
      'هالتر',
      'barbell',
      'پشت سر',
      'overhead',
    ];
    return hard.any(blob.contains);
  }

  static Exercise? _findBySlug(
    List<Exercise> all,
    String slug, {
    required List<String> exclude,
    Set<int>? usedIds,
  }) {
    final want = _normalizeSlug(slug);
    if (want.isEmpty) return null;

    final candidates = all.where((e) {
      if (usedIds != null && usedIds.contains(e.id)) return false;
      final blob = _searchBlob(e);
      if (exclude.any(blob.contains)) return false;
      return _slugOf(e) == want;
    }).toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final da = _isBeginnerDifficulty(a.difficulty.toLowerCase()) ? 1 : 0;
      final db = _isBeginnerDifficulty(b.difficulty.toLowerCase()) ? 1 : 0;
      return db.compareTo(da);
    });
    return candidates.first;
  }

  static String _slugOf(Exercise e) {
    final raw = e.richMeta.webSlug.trim();
    if (raw.isEmpty) return '';
    final decoded = raw.contains('%') ? Uri.decodeComponent(raw) : raw;
    return _normalizeSlug(decoded);
  }

  static String _normalizeSlug(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('‌', '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp('-+'), '-');
  }

  static String _searchBlob(Exercise e) {
    final parts = <String>[
      e.name,
      e.title,
      ...e.otherNames,
      e.mainMuscle,
      e.movementPattern,
      e.targetArea,
      ExerciseDisplayLabels.muscle(e.mainMuscle),
      ExerciseDisplayLabels.movement(e.movementPattern),
      ExerciseDisplayLabels.equipmentLabel(e.equipment),
    ];
    return parts
        .where((s) => s.trim().isNotEmpty)
        .join(' ')
        .toLowerCase()
        .replaceAll('‌', '');
  }

  static bool _isBeginnerDifficulty(String d) {
    return d == 'beginner' || d.contains('مبتدی') || d.contains('beginner');
  }

  static bool _isStableEquipment(String blob, String equipment) {
    return equipment.contains('machine') ||
        equipment.contains('دستگاه') ||
        blob.contains('دستگاه') ||
        blob.contains('اسمیت') ||
        blob.contains('لگ پرس') ||
        blob.contains('leg press');
  }

  /// متن دیالوگ اطلاع‌رسانی شاگردی زیر نظارت GymAI.
  static String enrollmentDialogMessage({
    required String trainerName,
    required bool isNewAiStudent,
    int? upgradedFromVersion,
    bool rebuiltProgram = false,
  }) {
    final coach = trainerName.trim().isEmpty
        ? AppConfig.gymAiDisplayName
        : trainerName;

    final upgradeBlock = rebuiltProgram && upgradedFromVersion != null
        ? 'برنامهٔ شما به نسخهٔ جدید ($programVersion) به‌روز شد '
            '(قبلاً نسخه $upgradedFromVersion).\n'
            'هفتهٔ اول: ۲ ست؛ از هفتهٔ ۲ ست سوم را اضافه کنید.\n\n'
        : 'برنامهٔ شروع باشگاه فعال شد.\n'
            'هفتهٔ اول: ۲ ست برای هر حرکت؛ از هفتهٔ ۲ ست سوم.\n\n';

    if (isNewAiStudent) {
      return '$upgradeBlockاز این پس به‌عنوان شاگرد $coach '
          '(مربی هوشمند ${AppConfig.gymAiDisplayName}) ثبت می‌شوید.';
    }
    return '$upgradeBlockشما زیر نظارت $coach '
        '(مربی هوشمند ${AppConfig.gymAiDisplayName}) هستید.';
  }
}

class _StarterBuildResult {
  const _StarterBuildResult({
    required this.program,
    required this.missingSlots,
  });

  final WorkoutProgram program;
  final List<String> missingSlots;
}

class _SessionTemplate {
  const _SessionTemplate({
    required this.day,
    required this.notes,
    required this.exercises,
  });

  final String day;
  final String notes;
  final List<_ExerciseSpec> exercises;
}

class _ExerciseSpec {
  const _ExerciseSpec({
    required this.patterns,
    required this.tag,
    this.sets = 3,
    this.preferredIds = const [],
    this.slugs = const [],
    this.reps = 10,
    this.timeSeconds,
    this.note,
    this.preferMachine = true,
    this.preferCable = false,
    this.preferredMainMuscles = const [],
    this.preferredMovements = const [],
    this.excludePatterns = _defaultExcludePatterns,
  });

  /// حرکت‌های نامناسب برای تازه‌وارد — همیشه حذف می‌شوند.
  static const List<String> _defaultExcludePatterns = <String>[
    'هالتر',
    'barbell',
    'دیپ',
    'بارفیکس',
    'ددلیفت',
    'بورپی',
    'تک بازو',
    'تک‌بازو',
    'single arm',
    'یک دست',
    'لانج',
    'lunge',
    'پالوف',
    'pallof',
    'دیپ',
    'incline',
    'اینکلاین',
    'مکث',
    'هاک',
  ];

  /// شناسهٔ ثابت از `ai_exercises` — اولویت اول (کاتالوگ ۲۱۴ تایی).
  final List<int> preferredIds;
  final List<String> patterns;
  final List<String> slugs;
  final String tag;
  final int sets;
  final int reps;
  final int? timeSeconds;
  final String? note;
  final bool preferMachine;
  final bool preferCable;
  final List<String> preferredMainMuscles;
  final List<String> preferredMovements;
  final List<String> excludePatterns;
}

const _warmupChecklist =
    '☐ گرم‌کردن ۵ دقیقه (راه‌رفت / دوچرخه + مفصل) انجام شد';

const _programIntro =
    'تمام‌بدن برای تازه‌وارد — ۳ جلسه در هفته.\n'
    '• بین جلسات حداقل ۱ روز استراحت\n'
    '• هفته ۱: ۲ ست × ۱۰–۱۲ | از هفته ۲: ست سوم اضافه کنید\n'
    '• اگر ۱۲ تکرار راحت بود → هفته بعد کمی وزنه+ | اگر فرم خراب شد → وزنه−\n'
    '• بعد از ۴ هفته: برنامه شخصی‌سازی‌شده یا پرسشنامه GymAI';

/// هر جلسه: پا + سینه + پشت + شکم — ۴ حرکت، حدود ۳۵–۴۵ دقیقه.
/// منبع ساختار: ACSM 2026 (تمرین منظم گروه‌های اصلی)، Gold's Gym beginner machine full-body.
const _sessionTemplates = <_SessionTemplate>[
  _SessionTemplate(
    day: 'جلسه ۱',
    notes:
        '$_programIntro\n\n'
        'جلسه ۱ — یادگیری مسیر حرکت\n'
        '$_warmupChecklist\n'
        '• ترتیب حرکت‌ها را رعایت کنید؛ بین ست‌ها ۶۰–۹۰ ثانیه\n'
        '• درد تیز = توقف',
    exercises: [
      _ExerciseSpec(
        preferredIds: [4008],
        slugs: ['لگ-پرس'],
        patterns: ['لگ پرس', 'leg press'],
        tag: 'پا',
        reps: 12,
        preferredMainMuscles: ['quads'],
        preferredMovements: ['knee_dominant_press'],
        note: 'پا روی پد؛ پایین رفتن کنترل‌شده؛ زانو قفل کامل نکنید',
      ),
      _ExerciseSpec(
        preferredIds: [4007, 3832],
        slugs: ['پرس-سینه-اسمیت', 'پرس-سینه-دستگاه'],
        patterns: ['پرس سینه اسمیت', 'پرس سینه دستگاه'],
        tag: 'سینه',
        reps: 12,
        preferredMainMuscles: ['chest'],
        preferredMovements: ['horizontal_push'],
        excludePatterns: [
          ..._ExerciseSpec._defaultExcludePatterns,
          'دمبل',
          'تک',
        ],
        note: 'کتف روی نیمکت؛ وزنه سبک تا فرم درست ثابت بماند',
      ),
      _ExerciseSpec(
        preferredIds: [4021],
        slugs: ['زیربغل-نشسته-سیمکش'],
        patterns: ['زیربغل نشسته', 'رویینگ'],
        tag: 'پشت',
        reps: 12,
        preferCable: true,
        preferredMainMuscles: ['back_lat'],
        preferredMovements: ['horizontal_pull'],
        note: 'سینه بالا؛ کتف را به عقب ببرید؛ آرنج کنار بدن',
      ),
      _ExerciseSpec(
        preferredIds: [4012, 3928],
        slugs: ['کرانچ-سیمکش', 'کرانچ'],
        patterns: ['کرانچ سیمکش', 'کرانچ'],
        tag: 'شکم',
        reps: 12,
        preferCable: true,
        preferredMainMuscles: ['abs'],
        note: 'شکم را جمع کنید؛ گردن خنثی؛ بدون کشش گردن',
      ),
    ],
  ),
  _SessionTemplate(
    day: 'جلسه ۲',
    notes:
        'جلسه ۲ — تنوع سبک (کشش عمودی + سینه ایزوله)\n'
        '$_warmupChecklist\n'
        '• بین جلسه ۱ و ۲ حداقل یک روز استراحت',
    exercises: [
      _ExerciseSpec(
        preferredIds: [4008],
        slugs: ['لگ-پرس'],
        patterns: ['لگ پرس', 'leg press'],
        tag: 'پا',
        reps: 12,
        preferredMainMuscles: ['quads'],
        preferredMovements: ['knee_dominant_press'],
        note: 'همان حرکت جلسه قبل — تمرکز روی تکرار با کیفیت',
      ),
      _ExerciseSpec(
        preferredIds: [4014],
        slugs: ['فلای-پک-دستگاه'],
        patterns: ['فلای پک', 'pec deck', 'پک دک'],
        tag: 'سینه',
        reps: 12,
        preferredMainMuscles: ['chest'],
        preferredMovements: ['horizontal_adduction'],
        note: 'آرام باز و بسته کنید؛ احساس کشش وسط سینه',
      ),
      _ExerciseSpec(
        preferredIds: [3969, 3844],
        slugs: ['زیربغل-دست-جمع', 'زیربغل-سیمکش-دست-باز', 'زیربغل-سیمکش'],
        patterns: ['زیربغل دست جمع', 'لت پول', 'pulldown', 'زیربغل سیمکش'],
        tag: 'پشت',
        reps: 12,
        preferCable: true,
        preferredMainMuscles: ['back_lat'],
        preferredMovements: ['vertical_pull'],
        excludePatterns: [
          ..._ExerciseSpec._defaultExcludePatterns,
          'نشسته',
          'تک بازو',
        ],
        note: 'سیم‌کش جمع؛ سینه ثابت؛ آرنج به پایین',
      ),
      _ExerciseSpec(
        preferredIds: [4025, 3906],
        slugs: ['وال-سیت', 'پلانک'],
        patterns: ['وال سیت', 'wall sit', 'پلانک'],
        tag: 'شکم / پا',
        reps: 0,
        timeSeconds: 30,
        preferMachine: false,
        preferredMainMuscles: ['quads'],
        preferredMovements: ['isometric_hold'],
        note: 'پشت به دیوار؛ زانو ۹۰ درجه؛ ۳۰ ثانیه نگه دارید',
      ),
    ],
  ),
  _SessionTemplate(
    day: 'جلسه ۳',
    notes:
        'جلسه ۳ — تثبیت عادت تمرین\n'
        '$_warmupChecklist\n'
        '• ۳ دقیقه کشش سبک بعد از جلسه',
    exercises: [
      _ExerciseSpec(
        preferredIds: [4008],
        slugs: ['لگ-پرس'],
        patterns: ['لگ پرس', 'leg press'],
        tag: 'پا',
        reps: 12,
        preferredMainMuscles: ['quads'],
        preferredMovements: ['knee_dominant_press'],
        note: 'آخرین هفته می‌توانید کمی وزنه اضافه کنید',
      ),
      _ExerciseSpec(
        preferredIds: [4007, 3832],
        slugs: ['پرس-سینه-اسمیت'],
        patterns: ['پرس سینه اسمیت', 'پرس سینه دستگاه'],
        tag: 'سینه',
        reps: 12,
        preferredMainMuscles: ['chest'],
        preferredMovements: ['horizontal_push'],
        excludePatterns: [
          ..._ExerciseSpec._defaultExcludePatterns,
          'دمبل',
          'تک',
        ],
        note: 'سعی کنید یک تکرار بیشتر از هفته قبل',
      ),
      _ExerciseSpec(
        preferredIds: [3831, 4053],
        slugs: ['پرس-سرشانه-دستگاه'],
        patterns: ['پرس سرشانه دستگاه', 'نشر از جلو دستگاه'],
        tag: 'سرشانه',
        reps: 12,
        preferredMainMuscles: ['shoulder', 'shoulder_anterior'],
        preferredMovements: ['vertical_push'],
        excludePatterns: [
          ..._ExerciseSpec._defaultExcludePatterns,
          'هالتر',
          'دمبل',
        ],
        note: 'کتف پایین؛ آرنج جلو؛ وزنه سبک',
      ),
      _ExerciseSpec(
        preferredIds: [4012, 4018],
        slugs: ['کرانچ-سیمکش', 'ددباگ'],
        patterns: ['کرانچ سیمکش', 'کرانچ', 'ددباگ'],
        tag: 'شکم',
        reps: 12,
        preferCable: true,
        preferredMainMuscles: ['abs'],
        excludePatterns: [
          ..._ExerciseSpec._defaultExcludePatterns,
          'دوچرخه',
          'رول',
        ],
        note: 'حرکت آهسته؛ هر تکرار کنترل‌شده',
      ),
    ],
  ),
];
