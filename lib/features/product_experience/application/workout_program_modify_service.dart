import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_exercise.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_program.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_set.dart' as ai;
import 'package:gymaipro/ai/workout/models/workout_week.dart' as ai;
import 'package:gymaipro/ai/workout_modify/models/workout_modification.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_result.dart';
import 'package:gymaipro/ai/workout_modify/runtime/workout_modify_runtime.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/application/program_modify_ai_advisor.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_coach_voice.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_options.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart'
    as stored;
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:uuid/uuid.dart';

class ProgramModifyProposal {
  const ProgramModifyProposal({
    required this.accepted,
    required this.title,
    required this.message,
    required this.changeLines,
    required this.canApply,
    this.storedProgram,
    this.engineResult,
    this.refusalLines = const <String>[],
    this.coachHeard,
    this.coachTips = const <String>[],
    this.suggestedGoals = const <ProgramModifyGoal>[],
    this.aiAdvice,
    this.softRefused = false,
  });

  final bool accepted;
  final String title;
  final String message;
  final List<String> changeLines;
  final bool canApply;
  final stored.WorkoutProgram? storedProgram;
  final WorkoutModificationResult? engineResult;
  final List<String> refusalLines;
  final String? coachHeard;
  final List<String> coachTips;
  final List<ProgramModifyGoal> suggestedGoals;
  final String? aiAdvice;
  final bool softRefused;
}

/// Unified «اصلاح برنامه»: propose via modify engine, persist to full program.
class WorkoutProgramModifyService {
  WorkoutProgramModifyService({
    WorkoutProgramService? programService,
    ActiveProgramCatalogService? programCatalog,
    ActiveWorkoutSessionService? sessionService,
    ExerciseService? exerciseService,
    CoachPreviewSeedProvider? seedLoader,
    WorkoutModifyRuntime? modifyRuntime,
    LiveWorkoutSessionStore? draftStore,
    ExerciseProfileMapper? profileMapper,
    ProgramModifyAiAdvisor? aiAdvisor,
    bool enableAiAdvice = true,
  }) : _programs = programService ?? WorkoutProgramService(),
       _catalog = programCatalog ?? ActiveProgramCatalogService(),
       _sessions = sessionService ?? ActiveWorkoutSessionService(),
       _exercises = exerciseService ?? ExerciseService(),
       _seedLoader = seedLoader,
       _modifyRuntime =
           modifyRuntime ??
           const WorkoutModifyRuntime(enforceCoachV2Gate: false),
       _draftStore = draftStore ?? LiveWorkoutSessionStore(),
       _profileMapper = profileMapper ?? const ExerciseProfileMapper(),
       _aiAdvisor = aiAdvisor ?? ProgramModifyAiAdvisor(),
       _enableAiAdvice = enableAiAdvice;

  final WorkoutProgramService _programs;
  final ActiveProgramCatalogService _catalog;
  final ActiveWorkoutSessionService _sessions;
  final ExerciseService _exercises;
  final CoachPreviewSeedProvider? _seedLoader;
  final WorkoutModifyRuntime _modifyRuntime;
  final LiveWorkoutSessionStore _draftStore;
  final ExerciseProfileMapper _profileMapper;
  final ProgramModifyAiAdvisor _aiAdvisor;
  final bool _enableAiAdvice;

  Future<ProgramModifyContext?> loadContext({
    String? programId,
    String? sessionDay,
  }) async {
    final active = await _catalog.getActiveProgramOption();
    final effectiveProgramId = (programId != null && programId.isNotEmpty)
        ? programId
        : active?.id;
    if (effectiveProgramId == null || effectiveProgramId.isEmpty) return null;

    final storedProgram = await _programs.getProgramById(effectiveProgramId);
    if (storedProgram == null || storedProgram.sessions.isEmpty) return null;

    final catalog = await _exercises.getExercises();
    final catalogById = <int, Exercise>{
      for (final exercise in catalog) exercise.id: exercise,
    };

    final sessionContext = await _sessions.loadContext(
      programId: effectiveProgramId,
    );
    final preferredDay = (sessionDay != null && sessionDay.isNotEmpty)
        ? sessionDay
        : sessionContext.selectedSessionDay;

    final sessions = <ProgramModifySessionOption>[];
    for (final session in storedProgram.sessions) {
      if (session.exercises.isEmpty) continue;
      final exercises = <ProgramModifyExerciseOption>[];
      for (final block in session.exercises) {
        if (block is stored.NormalExercise) {
          exercises.add(
            _exerciseOption(block.exerciseId, catalogById, block.sets.length),
          );
        } else if (block is stored.SupersetExercise) {
          for (final item in block.exercises) {
            exercises.add(
              _exerciseOption(item.exerciseId, catalogById, item.sets.length),
            );
          }
        }
      }
      if (exercises.isEmpty) continue;
      sessions.add(
        ProgramModifySessionOption(day: session.day, exercises: exercises),
      );
    }
    if (sessions.isEmpty) return null;

    final selected = sessions.any((s) => s.day == preferredDay)
        ? preferredDay
        : sessions.first.day;

    return ProgramModifyContext(
      programId: effectiveProgramId,
      programName: storedProgram.name,
      sessions: sessions,
      selectedDay: selected,
    );
  }

  Future<ProgramModifyProposal> proposeFromSelection({
    required ProgramModifyGoal goal,
    String? programId,
    String? sessionDay,
    int? catalogExerciseId,
    String? exerciseName,
    String? reasonId,
    String? reasonLabel,
  }) async {
    if (goal.needsExercise &&
        (catalogExerciseId == null || catalogExerciseId <= 0)) {
      return const ProgramModifyProposal(
        accepted: false,
        title: 'حرکت را انتخاب کن',
        message: 'اول مشخص کن کدام حرکت را می‌خواهی تغییر بدهیم تا دقیق بررسی‌ش کنم.',
        changeLines: <String>[],
        canApply: false,
      );
    }

    final active = await _catalog.getActiveProgramOption();
    final effectiveProgramId = (programId != null && programId.isNotEmpty)
        ? programId
        : active?.id;
    final programName = active?.title ?? 'برنامه‌ات';

    final heard = ProgramModifyCoachVoice.requestSummary(
      goal: goal,
      sessionDay: sessionDay,
      exerciseName: exerciseName,
      reasonLabel: reasonLabel,
    );

    // Soft coach pushback before engine — key lifts need a real reason.
    if (goal == ProgramModifyGoal.removeExercise) {
      final soft = ProgramModifyCoachVoice.softRefuseRemove(
        exerciseName: exerciseName,
        reasonId: reasonId,
      );
      if (soft != null) {
        final ai = await _maybeAiAdvice(
          goal: goal,
          programName: programName,
          exerciseName: exerciseName,
          reasonLabel: reasonLabel,
          softRefused: true,
          outcomeSummary: soft.message,
        );
        return ProgramModifyProposal(
          accepted: false,
          title: soft.title,
          message: soft.message,
          changeLines: const <String>[],
          canApply: false,
          coachHeard: heard,
          coachTips: soft.tips,
          suggestedGoals: soft.suggestedGoals,
          aiAdvice: _stripNonPersianNoise(ai),
          softRefused: true,
          refusalLines: soft.tips,
        );
      }
    }

    if (goal == ProgramModifyGoal.replaceExercise) {
      final soft = ProgramModifyCoachVoice.softRefuseWeakReplace(
        exerciseName: exerciseName,
        reasonId: reasonId,
      );
      if (soft != null) {
        final ai = await _maybeAiAdvice(
          goal: goal,
          programName: programName,
          exerciseName: exerciseName,
          reasonLabel: reasonLabel,
          softRefused: true,
          outcomeSummary: soft.message,
        );
        return ProgramModifyProposal(
          accepted: false,
          title: soft.title,
          message: soft.message,
          changeLines: const <String>[],
          canApply: false,
          coachHeard: heard,
          coachTips: soft.tips,
          suggestedGoals: soft.suggestedGoals,
          aiAdvice: _stripNonPersianNoise(ai),
          softRefused: true,
          refusalLines: soft.tips,
        );
      }
    }

    final request = goal.buildRequestText(
      exerciseName: exerciseName,
      reasonLabel: reasonLabel,
      sessionDay: sessionDay,
    );
    return propose(
      userRequest: request,
      programId: effectiveProgramId,
      sessionDay: sessionDay,
      catalogExerciseId: catalogExerciseId,
      forcedTypes: goal.engineTypes,
      preferLowerJoint: _jointFromReason(
        reasonId: reasonId,
        goal: goal,
        exerciseName: exerciseName,
      ),
      avoidExerciseName: exerciseName,
      goal: goal,
      reasonId: reasonId,
      reasonLabel: reasonLabel,
      exerciseName: exerciseName,
      coachHeard: heard,
      programName: programName,
    );
  }

  Future<ProgramModifyProposal> propose({
    required String userRequest,
    String? programId,
    String? sessionDay,
    int? catalogExerciseId,
    List<WorkoutModificationType>? forcedTypes,
    String? preferLowerJoint,
    String? avoidExerciseName,
    ProgramModifyGoal? goal,
    String? reasonId,
    String? reasonLabel,
    String? exerciseName,
    String? coachHeard,
    String? programName,
  }) async {
    final request = userRequest.trim();
    if (request.isEmpty) {
      return const ProgramModifyProposal(
        accepted: false,
        title: 'درخواست خالی است',
        message: 'یکی از گزینه‌ها را انتخاب کن تا پیشنهاد اصلاح بسازم.',
        changeLines: <String>[],
        canApply: false,
      );
    }

    final hardRefuse = _hardRefuse(request);
    if (hardRefuse != null) {
      return ProgramModifyProposal(
        accepted: false,
        title: 'این درخواست قابل اعمال نیست',
        message: hardRefuse,
        changeLines: const <String>[],
        canApply: false,
        refusalLines: <String>[hardRefuse],
      );
    }

    final active = await _catalog.getActiveProgramOption();
    final effectiveProgramId = (programId != null && programId.isNotEmpty)
        ? programId
        : active?.id;
    if (effectiveProgramId == null || effectiveProgramId.isEmpty) {
      return const ProgramModifyProposal(
        accepted: false,
        title: 'برنامه فعال پیدا نشد',
        message: 'اول یک برنامه فعال انتخاب کن، بعد برای اصلاحش درخواست بده.',
        changeLines: <String>[],
        canApply: false,
      );
    }

    final storedProgram = await _programs.getProgramById(effectiveProgramId);
    if (storedProgram == null || storedProgram.sessions.isEmpty) {
      return const ProgramModifyProposal(
        accepted: false,
        title: 'برنامه پیدا نشد',
        message: 'برنامه ذخیره‌شده در دسترس نیست.',
        changeLines: <String>[],
        canApply: false,
      );
    }

    final sessionContext = await _sessions.loadContext(
      programId: effectiveProgramId,
    );
    final day = (sessionDay != null && sessionDay.isNotEmpty)
        ? sessionDay
        : sessionContext.selectedSessionDay;

    final catalog = await _exercises.getExercises();
    final catalogById = <int, Exercise>{
      for (final exercise in catalog) exercise.id: exercise,
    };
    final profiles = _profileMapper.fromExercises(catalog);

    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: AIIntent.workoutModification,
      message: request,
    );

    final aiProgram = _toFullAiProgram(storedProgram, catalogById);
    final targetExerciseId = _resolveTargetExerciseId(
      aiProgram: aiProgram,
      sessionDay: day,
      catalogExerciseId: catalogExerciseId,
      request: request,
    );

    final types = (forcedTypes != null && forcedTypes.isNotEmpty)
        ? forcedTypes
        : _inferModificationTypes(
            request: request,
            hasTargetExercise: targetExerciseId != null,
          );

    final options = <String, Object?>{
      if (targetExerciseId != null) 'exerciseId': targetExerciseId,
      if (day != null && day.isNotEmpty) 'dayLabel': day,
      if (catalogExerciseId != null) 'catalogExerciseId': catalogExerciseId,
      if (preferLowerJoint != null && preferLowerJoint.isNotEmpty)
        'preferLowerJoint': preferLowerJoint,
      if (avoidExerciseName != null && avoidExerciseName.trim().isNotEmpty)
        'avoidExerciseName': avoidExerciseName.trim(),
    };

    final result = _modifyRuntime.modify(
      program: aiProgram,
      context: seed.context,
      modifications: types,
      catalogProfiles: profiles,
      options: options,
    );

    final applied = result.modifications
        .where((item) => item.status == WorkoutModificationStatus.applied)
        .where(_isSensibleAppliedMod)
        .toList(growable: false);
    final rejected = result.modifications
        .where(
          (item) =>
              item.status == WorkoutModificationStatus.rejected ||
              item.status == WorkoutModificationStatus.skipped,
        )
        .toList(growable: false);

    if (!result.enabled) {
      return ProgramModifyProposal(
        accepted: false,
        title: 'الان نمی‌تونم اصلاح کنم',
        message:
            'موتور اصلاح موقتاً در دسترس نیست. کمی بعد دوباره تلاش کن؛ '
            'درخواستت رو یادم می‌مونه که دوباره بررسی کنیم.',
        changeLines: const <String>[],
        canApply: false,
        coachHeard: coachHeard,
      );
    }

    if (applied.isEmpty) {
      final resolvedGoal = goal ?? ProgramModifyGoal.replaceExercise;
      if (resolvedGoal == ProgramModifyGoal.homeVersion) {
        return ProgramModifyProposal(
          accepted: true,
          title: 'از قبل مناسب خانه است',
          message:
              'حرکت‌های این جلسه برای خانه قابل اجرا هستند '
              '(دمبل / کش / وزن بدن). نیازی به تعویض نبود.',
          changeLines: const <String>['تغییری لازم نبود.'],
          canApply: false,
          coachHeard: coachHeard,
          engineResult: result,
        );
      }
      final refusal = _refusalMessage(request: request, rejected: rejected);
      final tips = ProgramModifyCoachVoice.coachingTips(
        goal: resolvedGoal,
        reasonId: reasonId,
      );
      final ai = await _maybeAiAdvice(
        goal: resolvedGoal,
        programName: programName ?? storedProgram.name,
        exerciseName: exerciseName ?? avoidExerciseName,
        reasonLabel: reasonLabel,
        softRefused: false,
        outcomeSummary: refusal,
      );
      return ProgramModifyProposal(
        accepted: false,
        title: 'این تغییر را این‌طور اعمال نمی‌کنم',
        message: refusal,
        changeLines: const <String>[],
        canApply: false,
        coachHeard: coachHeard,
        coachTips: tips.take(2).toList(growable: false),
        aiAdvice: _stripNonPersianNoise(ai),
        refusalLines: const <String>[],
        engineResult: result,
      );
    }

    final merged = _mergeAiIntoStored(
      original: storedProgram,
      modifiedAi: result.modifiedProgram,
      catalogById: catalogById,
    );

    final lines = _summarizeChanges(applied);
    final resolvedGoal = goal ?? ProgramModifyGoal.replaceExercise;
    final afterName = applied
        .map((m) => m.afterName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .firstOrNull;
    final replaceCount = applied
        .where(
          (m) =>
              (m.beforeName ?? '').isNotEmpty && (m.afterName ?? '').isNotEmpty,
        )
        .length;
    final volumeReduced = applied.any(
      (m) =>
          m.type == WorkoutModificationType.reduceVolume ||
          (m.type == WorkoutModificationType.recoveryAdaptation &&
              (m.afterName == null || m.afterName!.isEmpty)),
    );
    final review = ProgramModifyCoachVoice.decisionMessage(
      goal: resolvedGoal,
      reasonLabel: reasonLabel,
      afterName: afterName,
      replaceCount: replaceCount,
      volumeReduced: volumeReduced,
    );
    final tips = ProgramModifyCoachVoice.coachingTips(
      goal: resolvedGoal,
      reasonId: reasonId,
    );
    final ai = await _maybeAiAdvice(
      goal: resolvedGoal,
      programName: programName ?? storedProgram.name,
      exerciseName: exerciseName ?? avoidExerciseName,
      reasonLabel: reasonLabel,
      softRefused: false,
      outcomeSummary: review,
    );

    return ProgramModifyProposal(
      accepted: true,
      title: 'این کار را می‌کنم',
      message: review,
      changeLines: lines,
      canApply: true,
      storedProgram: merged,
      engineResult: result,
      coachHeard: coachHeard,
      coachTips: tips.take(1).toList(growable: false),
      aiAdvice: _stripNonPersianNoise(ai),
    );
  }

  Future<String?> _maybeAiAdvice({
    required ProgramModifyGoal goal,
    required String programName,
    String? exerciseName,
    String? reasonLabel,
    String? outcomeSummary,
    bool softRefused = false,
  }) async {
    if (!_enableAiAdvice) return null;
    // AI tip for meaningful coaching moments only.
    final worthIt = softRefused ||
        goal == ProgramModifyGoal.replaceExercise ||
        goal == ProgramModifyGoal.removeExercise ||
        goal == ProgramModifyGoal.injuryAdapt ||
        goal == ProgramModifyGoal.tiredAdapt;
    if (!worthIt) return null;
    return _aiAdvisor.advise(
      goal: goal,
      programName: programName,
      exerciseName: exerciseName,
      reasonLabel: reasonLabel,
      outcomeSummary: outcomeSummary,
      softRefused: softRefused,
    );
  }

  Future<String?> apply(ProgramModifyProposal proposal) async {
    final program = proposal.storedProgram;
    if (!proposal.canApply || program == null) {
      return 'پیشنهاد قابل اعمال نیست.';
    }
    await _programs.updateProgram(program);
    final userId = await AuthHelper.getCurrentUserId();
    if (userId != null && userId.isNotEmpty) {
      await _draftStore.clearDraft(userId);
    }
    return null;
  }

  ProgramModifyExerciseOption _exerciseOption(
    int catalogId,
    Map<int, Exercise> catalogById,
    int setCount,
  ) {
    final catalog = catalogById[catalogId];
    final rawName = (catalog?.name.trim().isNotEmpty ?? false)
        ? catalog!.name.trim()
        : (catalog?.title.trim() ?? 'حرکت');
    final name = rawName.trim().isEmpty ? 'حرکت' : rawName.trim();
    return ProgramModifyExerciseOption(
      catalogExerciseId: catalogId,
      name: name,
      meta: setCount > 0 ? '$setCount ست' : null,
    );
  }

  String? _hardRefuse(String request) {
    final lower = request.toLowerCase();
    if (RegExp(r'همه\s*(حرکت|تمرین|روز|سشن).*حذف').hasMatch(request) ||
        lower.contains('delete all') ||
        request.contains('کل برنامه را پاک')) {
      return 'کل برنامه را حذف نمی‌کنم. بگو کدام حرکت یا کدام روز را می‌خواهی اصلاح کنیم.';
    }
    if (RegExp(r'(\d{2,})\s*ست').hasMatch(request)) {
      final match = RegExp(r'(\d{2,})\s*ست').firstMatch(request);
      final n = int.tryParse(match?.group(1) ?? '') ?? 0;
      if (n >= 20) {
        return 'این تعداد ست منطقی نیست و به بدنت آسیب می‌زند. '
            'پیشنهادم ۱–۴ ست برای هر حرکت است؛ اگر بخواهی جلسه را سنگین‌تر کنم بگو.';
      }
    }
    if (request.contains('بدون حرکت') || request.contains('صفر حرکت')) {
      return 'جلسه بدون حرکت نمی‌سازم. اگر خسته‌ای، می‌توانم جلسه را سبک‌تر یا کوتاه‌تر کنم.';
    }
    return null;
  }

  List<WorkoutModificationType> _inferModificationTypes({
    required String request,
    required bool hasTargetExercise,
  }) {
    final types = <WorkoutModificationType>{};
    if (RegExp(r'جایگزین|عوض|نمیتونم|نمی‌تونم|نمیشه|نمی‌شه').hasMatch(request)) {
      types.add(WorkoutModificationType.replaceExercise);
    }
    if (RegExp(r'حذف|بردار').hasMatch(request)) {
      types.add(WorkoutModificationType.removeExercise);
    }
    if (RegExp(r'اضافه|بیشتر کن').hasMatch(request) &&
        !RegExp(r'ست').hasMatch(request)) {
      types.add(WorkoutModificationType.addExercise);
    }
    if (RegExp(r'کم کن.*ست|ست.*کم|حجم.*کم|سبک').hasMatch(request)) {
      types.add(WorkoutModificationType.reduceVolume);
    }
    if (RegExp(r'ست.*بیشتر|حجم.*بیشتر|سنگین‌تر|سنگین تر').hasMatch(request)) {
      types.add(WorkoutModificationType.increaseVolume);
    }
    if (RegExp(r'شدت.*کم|آسون‌تر|آسان‌تر').hasMatch(request)) {
      types.add(WorkoutModificationType.reduceIntensity);
    }
    if (RegExp(r'شدت.*بیشتر|سخت‌تر').hasMatch(request)) {
      types.add(WorkoutModificationType.increaseIntensity);
    }
    if (RegExp(r'کوتاه|زود تموم').hasMatch(request)) {
      types.add(WorkoutModificationType.shortenSession);
    }
    if (RegExp(r'خون[هه‌]|خانه|خانگی').hasMatch(request)) {
      types.add(WorkoutModificationType.homeVersion);
    }
    if (RegExp(r'باشگاه').hasMatch(request)) {
      types.add(WorkoutModificationType.gymVersion);
    }
    if (RegExp(r'آسیب|درد|مصدوم').hasMatch(request)) {
      types.add(WorkoutModificationType.injuryAdaptation);
    }
    if (RegExp(r'تجهیز|دمبل|بارفیکس|کش').hasMatch(request)) {
      types.add(WorkoutModificationType.equipmentAdaptation);
    }
    if (RegExp(r'ریکاور|خسته|آمادگی پایین').hasMatch(request)) {
      types.add(WorkoutModificationType.recoveryAdaptation);
    }

    if (types.isEmpty) {
      types.add(
        hasTargetExercise
            ? WorkoutModificationType.replaceExercise
            : WorkoutModificationType.recoveryAdaptation,
      );
    }
    return types.toList(growable: false);
  }

  String? _resolveTargetExerciseId({
    required ai.WorkoutProgram aiProgram,
    required String? sessionDay,
    required int? catalogExerciseId,
    required String request,
  }) {
    if (catalogExerciseId != null && catalogExerciseId > 0) {
      String? matchInDays({required bool requireDay}) {
        for (final day in aiProgram.allDays) {
          if (requireDay &&
              sessionDay != null &&
              sessionDay.isNotEmpty &&
              !_sameSessionDay(day.label, sessionDay)) {
            continue;
          }
          for (final exercise in day.exercises) {
            if (exercise.catalogExerciseId == catalogExerciseId) {
              return exercise.id;
            }
          }
        }
        return null;
      }

      return matchInDays(requireDay: true) ?? matchInDays(requireDay: false);
    }

    for (final day in aiProgram.allDays) {
      if (sessionDay != null &&
          sessionDay.isNotEmpty &&
          !_sameSessionDay(day.label, sessionDay)) {
        continue;
      }
      for (final exercise in day.exercises) {
        final name = exercise.name.trim();
        if (name.length >= 3 && request.contains(name)) {
          return exercise.id;
        }
      }
    }
    return null;
  }

  bool _sameSessionDay(String a, String b) {
    final left = a.trim();
    final right = b.trim();
    if (left == right) return true;
    final digitsA = left.replaceAll(RegExp(r'[^0-9۰-۹]'), '');
    final digitsB = right.replaceAll(RegExp(r'[^0-9۰-۹]'), '');
    return digitsA.isNotEmpty && digitsA == digitsB;
  }

  String _refusalMessage({
    required String request,
    required List<WorkoutModification> rejected,
  }) {
    final rawReasons = rejected
        .expand((item) => item.reasons)
        .expand((reason) => reason.because)
        .toList(growable: false);

    for (final raw in rawReasons) {
      final mapped = _mapEngineRefuseReason(raw);
      if (mapped != null) return mapped;
    }

    if (RegExp(r'جایگزین').hasMatch(request) ||
        request.contains('عوض')) {
      return 'جایگزین مناسبی پیدا نکردم. '
          'می‌توانی «سبک‌تر کردن جلسه» را امتحان کنی یا حرکت دیگری را انتخاب کنی.';
    }
    if (request.contains('خسته') || request.contains('ریکاور')) {
      return 'الان نتوانستم جلسه را امن سبک کنم. دوباره امتحان کن یا «کم کردن ست/حجم» را بزن.';
    }
    return 'با این انتخاب، تغییر امنی اعمال نشد. گزینه یا دلیل دیگری را امتحان کن.';
  }

  String? _mapEngineRefuseReason(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('no exerciseid') || lower.contains('exercise not found')) {
      return 'حرکت انتخاب‌شده در برنامه پیدا نشد. روز و حرکت را دوباره انتخاب کن.';
    }
    if (lower.contains('no profile')) {
      return 'اطلاعات این حرکت در کاتالوگ کامل نیست؛ حرکت دیگری را انتخاب کن.';
    }
    if (lower.contains('found no candidate') || lower.contains('no candidate')) {
      return 'برای این حرکت جایگزین امنی در کاتالوگ پیدا نکردم. '
          'می‌توانی حذف حرکت یا سبک‌تر کردن جلسه را انتخاب کنی.';
    }
    if (lower.contains('no modifications applied')) {
      return 'موتور اصلاح تغییری اعمال نکرد. گزینه دیگری را امتحان کن.';
    }
    return null;
  }

  String? _jointFromReason({
    required String? reasonId,
    required ProgramModifyGoal goal,
    String? exerciseName,
  }) {
    final byReason = switch (reasonId) {
      'shoulder' => 'shoulder',
      'knee' => 'knee',
      'back' => 'back',
      'wrist' => 'wrist',
      'elbow' => 'elbow',
      _ => null,
    };
    if (byReason != null) return byReason;

    if (reasonId == 'pain' ||
        reasonId == 'cant_do' ||
        reasonId == 'too_hard' ||
        goal == ProgramModifyGoal.injuryAdapt) {
      final name = (exerciseName ?? '').toLowerCase();
      if (name.contains('سرشانه') ||
          name.contains('شانه') ||
          name.contains('shoulder') ||
          name.contains('overhead')) {
        return 'shoulder';
      }
      if (name.contains('زانو') ||
          name.contains('اسکوات') ||
          name.contains('لانج') ||
          name.contains('knee')) {
        return 'knee';
      }
      if (name.contains('کمر') ||
          name.contains('ددلیفت') ||
          name.contains('back')) {
        return 'back';
      }
      if (name.contains('مچ') || name.contains('wrist')) return 'wrist';
      if (name.contains('آرنج') || name.contains('elbow')) return 'elbow';
    }
    return null;
  }

  /// Drops absurd role / equipment swaps from user-facing proposals.
  bool _isSensibleAppliedMod(WorkoutModification mod) {
    final before = (mod.beforeName ?? '').trim();
    final after = (mod.afterName ?? '').trim();
    if (before.isEmpty || after.isEmpty) return true;
    if (_isNonsensicalExerciseSwap(before, after)) return false;
    if (mod.type == WorkoutModificationType.homeVersion &&
        _looksLikeGymOnlyName(after)) {
      return false;
    }
    return true;
  }

  bool _looksLikeGymOnlyName(String name) {
    final text = name.toLowerCase();
    return text.contains('دستگاه') ||
        text.contains('اسمیت') ||
        text.contains('smith') ||
        text.contains('کابل') ||
        text.contains('سیم‌کش') ||
        text.contains('سیمکش') ||
        text.contains('سیم کش') ||
        text.contains('پولی') ||
        text.contains('لگ پرس') ||
        text.contains('machine') ||
        text.contains('cable');
  }

  bool _isNonsensicalExerciseSwap(String before, String after) {
    final beforeRole = _exerciseRoleBucket(before);
    final afterRole = _exerciseRoleBucket(after);
    if (beforeRole == null || afterRole == null) return false;
    return beforeRole != afterRole;
  }

  String? _exerciseRoleBucket(String name) {
    final text = name.toLowerCase();
    if (text.contains('اسکوات') ||
        text.contains('squat') ||
        text.contains('لانج') ||
        text.contains('lunge') ||
        text.contains('لگ پرس') ||
        text.contains('leg press')) {
      return 'legs';
    }
    if (text.contains('ددلیفت') ||
        text.contains('deadlift') ||
        text.contains('هیپ تراست') ||
        text.contains('hip thrust')) {
      return 'hinge';
    }
    if (text.contains('سرشانه') ||
        text.contains('overhead') ||
        text.contains('نشر') ||
        (text.contains('پرس') && text.contains('شانه'))) {
      return 'shoulders';
    }
    if (text.contains('سینه') ||
        text.contains('bench') ||
        text.contains('فلای') ||
        text.contains('push up') ||
        text.contains('شنا')) {
      return 'chest';
    }
    if (text.contains('زیربغل') ||
        text.contains('بارفیکس') ||
        text.contains('لت ') ||
        text.contains('row') ||
        text.contains('pull')) {
      return 'back';
    }
    if (text.contains('جلو بازو') ||
        text.contains('پشت بازو') ||
        text.contains('bicep') ||
        text.contains('tricep')) {
      return 'arms';
    }
    if (text.contains('شکم') || text.contains('پلانک') || text.contains('core')) {
      return 'core';
    }
    return null;
  }

  String _formatChangeLine(WorkoutModification mod) {
    final before = (mod.beforeName ?? '').trim();
    final after = (mod.afterName ?? '').trim();
    switch (mod.type) {
      case WorkoutModificationType.replaceExercise:
      case WorkoutModificationType.recoveryAdaptation:
      case WorkoutModificationType.injuryAdaptation:
      case WorkoutModificationType.equipmentAdaptation:
        if (before.isNotEmpty && after.isNotEmpty) {
          return '«$before» عوض شد به «$after»';
        }
        if (mod.type == WorkoutModificationType.recoveryAdaptation) {
          return 'ست‌های جلسه کم شد تا سبک‌تر شود';
        }
        return '';
      case WorkoutModificationType.removeExercise:
        return 'حذف «${before.isNotEmpty ? before : mod.subject}»';
      case WorkoutModificationType.addExercise:
        return 'اضافه شدن «${after.isNotEmpty ? after : mod.subject}»';
      case WorkoutModificationType.reduceVolume:
        return 'کم شدن ست‌ها / حجم جلسه';
      case WorkoutModificationType.increaseVolume:
        return 'زیاد شدن ست‌ها / حجم جلسه';
      case WorkoutModificationType.reduceIntensity:
        return 'کاهش شدت (تکرار راحت‌تر)';
      case WorkoutModificationType.increaseIntensity:
        return 'افزایش شدت';
      case WorkoutModificationType.shortenSession:
        return 'کوتاه‌تر شدن جلسه';
      case WorkoutModificationType.homeVersion:
        if (before.isNotEmpty && after.isNotEmpty) {
          return '«$before» برای خانه شد «$after»';
        }
        return 'تبدیل حرکات به نسخه خانگی';
      case WorkoutModificationType.gymVersion:
        if (before.isNotEmpty && after.isNotEmpty) {
          return '«$before» برای باشگاه شد «$after»';
        }
        return 'تبدیل به نسخه باشگاهی';
    }
  }

  /// Collapse noisy engine mods into a few Persian bullets.
  List<String> _summarizeChanges(List<WorkoutModification> applied) {
    if (applied.isEmpty) {
      return const <String>['تغییر روی برنامه آماده است.'];
    }

    final lines = <String>[];
    final volumeOnly = applied.where((m) {
      final isVolume = m.type == WorkoutModificationType.reduceVolume ||
          m.type == WorkoutModificationType.increaseVolume;
      final isRecoveryTrim = m.type == WorkoutModificationType.recoveryAdaptation &&
          ((m.beforeName ?? '').isEmpty || (m.afterName ?? '').isEmpty);
      return isVolume || isRecoveryTrim;
    }).toList(growable: false);

    if (volumeOnly.any((m) => m.type == WorkoutModificationType.reduceVolume) ||
        volumeOnly.any(
          (m) => m.type == WorkoutModificationType.recoveryAdaptation,
        )) {
      lines.add('از بیشتر حرکت‌ها حدود ۱ ست کم شد.');
    }
    if (volumeOnly.any((m) => m.type == WorkoutModificationType.increaseVolume)) {
      lines.add('ست‌های جلسه کمی زیاد شد.');
    }

    final replaces = applied
        .where(
          (m) =>
              (m.beforeName ?? '').trim().isNotEmpty &&
              (m.afterName ?? '').trim().isNotEmpty,
        )
        .toList(growable: false);

    // Deduplicate identical before→after pairs.
    final seen = <String>{};
    final uniqueReplaces = <WorkoutModification>[];
    for (final mod in replaces) {
      final key = '${mod.beforeName}|${mod.afterName}';
      if (seen.add(key)) uniqueReplaces.add(mod);
    }

    for (final mod in uniqueReplaces.take(4)) {
      final day = mod.dayLabel.trim();
      final dayBit = (day.isNotEmpty && day != 'all') ? ' ($day)' : '';
      lines.add(
        '«${mod.beforeName}»$dayBit عوض شد به «${mod.afterName}»',
      );
    }
    if (uniqueReplaces.length > 3) {
      lines.add('و ${uniqueReplaces.length - 3} حرکت دیگر هم سبک‌تر شد.');
    }

    if (lines.isEmpty) {
      for (final mod in applied.take(3)) {
        final line = _formatChangeLine(mod);
        if (line.isNotEmpty) lines.add(line);
      }
    }
    return lines.isEmpty
        ? const <String>['تغییر روی برنامه آماده است.']
        : lines;
  }

  String? _stripNonPersianNoise(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;
    text = text
        .replaceAll(RegExp(r'\b[A-Za-z][A-Za-z0-9_ .-]{2,}\b'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    final persian = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    final latin = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (persian < 8 || latin > persian) return null;
    return text;
  }

  ai.WorkoutProgram _toFullAiProgram(
    stored.WorkoutProgram program,
    Map<int, Exercise> catalogById,
  ) {
    final days = <ai.WorkoutDay>[];
    for (var dayIndex = 0; dayIndex < program.sessions.length; dayIndex++) {
      final session = program.sessions[dayIndex];
      final exercises = <ai.WorkoutExercise>[];
      var order = 0;
      for (final block in session.exercises) {
        if (block is stored.NormalExercise) {
          exercises.add(
            _aiFromNormal(block, catalogById[block.exerciseId], order++),
          );
        } else if (block is stored.SupersetExercise) {
          for (final item in block.exercises) {
            exercises.add(
              _aiFromSupersetItem(
                item,
                catalogById[item.exerciseId],
                order++,
              ),
            );
          }
        }
      }
      if (exercises.isEmpty) continue;
      days.add(
        ai.WorkoutDay(
          id: session.id,
          dayIndex: dayIndex + 1,
          label: session.day,
          exercises: exercises,
        ),
      );
    }

    return ai.WorkoutProgram(
      id: program.id,
      userId: program.userId,
      name: program.name,
      goal: TrainingGoal.general,
      experienceLevel: 'متوسط',
      daysPerWeek: days.length.clamp(1, 7),
      sessionDurationMinutes: 60,
      weeks: <ai.WorkoutWeek>[
        ai.WorkoutWeek(
          id: '${program.id}_week_1',
          weekIndex: 1,
          days: days,
        ),
      ],
      createdAt: program.createdAt,
      updatedAt: program.updatedAt,
    );
  }

  ai.WorkoutExercise _aiFromNormal(
    stored.NormalExercise exercise,
    Exercise? catalog,
    int order,
  ) {
    return ai.WorkoutExercise(
      id: exercise.id,
      catalogExerciseId: exercise.exerciseId,
      name: (catalog?.name ?? catalog?.title ?? 'حرکت').trim(),
      primaryMuscle: (catalog?.mainMuscle ?? exercise.tag).toString(),
      order: order,
      sets: exercise.sets.isEmpty
          ? <ai.WorkoutSet>[
              ai.WorkoutSet(
                id: '${exercise.id}_set_1',
                order: 1,
                type: ai.WorkoutSetType.reps,
                reps: 10,
              ),
            ]
          : exercise.sets.asMap().entries.map((entry) {
              final set = entry.value;
              return ai.WorkoutSet(
                id: '${exercise.id}_set_${entry.key + 1}',
                order: entry.key + 1,
                type: set.timeSeconds != null
                    ? ai.WorkoutSetType.time
                    : ai.WorkoutSetType.reps,
                reps: set.reps,
                timeSeconds: set.timeSeconds,
                weightKg: set.weight,
              );
            }).toList(growable: false),
    );
  }

  ai.WorkoutExercise _aiFromSupersetItem(
    stored.SupersetItem item,
    Exercise? catalog,
    int order,
  ) {
    final id = '${item.exerciseId}_$order';
    return ai.WorkoutExercise(
      id: id,
      catalogExerciseId: item.exerciseId,
      name: (catalog?.name ?? catalog?.title ?? 'حرکت').trim(),
      primaryMuscle: (catalog?.mainMuscle ?? '').toString(),
      order: order,
      sets: item.sets.isEmpty
          ? <ai.WorkoutSet>[
              ai.WorkoutSet(
                id: '${id}_set_1',
                order: 1,
                type: ai.WorkoutSetType.reps,
                reps: 10,
              ),
            ]
          : item.sets.asMap().entries.map((entry) {
              final set = entry.value;
              return ai.WorkoutSet(
                id: '${id}_set_${entry.key + 1}',
                order: entry.key + 1,
                type: set.timeSeconds != null
                    ? ai.WorkoutSetType.time
                    : ai.WorkoutSetType.reps,
                reps: set.reps,
                timeSeconds: set.timeSeconds,
                weightKg: set.weight,
              );
            }).toList(growable: false),
    );
  }

  stored.WorkoutProgram _mergeAiIntoStored({
    required stored.WorkoutProgram original,
    required ai.WorkoutProgram modifiedAi,
    required Map<int, Exercise> catalogById,
  }) {
    final byId = <String, ai.WorkoutDay>{
      for (final day in modifiedAi.allDays) day.id: day,
    };
    final byLabel = <String, ai.WorkoutDay>{
      for (final day in modifiedAi.allDays) day.label: day,
    };

    final sessions = original.sessions.map((session) {
      final aiDay = byId[session.id] ?? byLabel[session.day];
      if (aiDay == null) return session;
      final exercises = aiDay.exercises
          .where((exercise) => exercise.catalogExerciseId > 0)
          .map((exercise) => _storedFromAi(exercise, catalogById))
          .toList(growable: false);
      if (exercises.isEmpty) return session;
      return stored.WorkoutSession(
        id: session.id,
        day: session.day,
        exercises: exercises,
        notes: session.notes,
      );
    }).toList(growable: false);

    return stored.WorkoutProgram(
      id: original.id,
      name: original.name,
      sessions: sessions,
      userId: original.userId,
      trainerId: original.trainerId,
      isSelfServiceAi: original.isSelfServiceAi,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
      sentAt: original.sentAt,
    );
  }

  stored.NormalExercise _storedFromAi(
    ai.WorkoutExercise exercise,
    Map<int, Exercise> catalogById,
  ) {
    final catalog = catalogById[exercise.catalogExerciseId];
    final style = exercise.sets.any((set) => set.type == ai.WorkoutSetType.time)
        ? stored.ExerciseStyle.setsTime
        : stored.ExerciseStyle.setsReps;
    final sets = exercise.sets.isEmpty
        ? <stored.ExerciseSet>[
            stored.ExerciseSet(reps: 10),
            stored.ExerciseSet(reps: 10),
            stored.ExerciseSet(reps: 10),
          ]
        : exercise.sets
              .map(
                (set) => stored.ExerciseSet(
                  reps: set.reps,
                  timeSeconds: set.timeSeconds,
                  weight: set.weightKg,
                ),
              )
              .toList(growable: false);

    return stored.NormalExercise(
      id: exercise.id.isEmpty ? const Uuid().v4() : exercise.id,
      exerciseId: exercise.catalogExerciseId,
      tag: (catalog?.mainMuscle ?? exercise.primaryMuscle).toString(),
      style: style,
      sets: sets,
    );
  }
}
