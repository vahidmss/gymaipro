import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/services/ai_chat_availability.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_program_generator.dart';
import 'package:gymaipro/features/workout_program_request/application/ai_to_stored_workout_program_mapper.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_gap_fill_service.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_token_service.dart';
import 'package:gymaipro/features/workout_program_request/domain/workout_program_gap_answers.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/ai_exercise_read_service.dart';
import 'package:gymaipro/services/ai_trainer_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:gymaipro/workout_plan_builder/utils/workout_program_name_uniquifier.dart';

class WorkoutProgramGenerationOutcome {
  const WorkoutProgramGenerationOutcome.success(this.program)
    : errorMessage = null;

  const WorkoutProgramGenerationOutcome.failure(this.errorMessage)
    : program = null;

  final WorkoutProgram? program;
  final String? errorMessage;

  bool get isSuccess => program != null;
}

/// End-to-end: persist gap answers → LLM generate → map → save → activate.
class WorkoutProgramGenerationService {
  WorkoutProgramGenerationService({
    WorkoutProgramGapFillService? gapFillService,
    LlmWorkoutProgramGenerator? llmGenerator,
    AiToStoredWorkoutProgramMapper? mapper,
    WorkoutProgramService? programService,
    ActiveProgramService? activeProgramService,
    AIExerciseReadService? aiExerciseReadService,
    ExerciseService? exerciseService,
    WorkoutProgramTokenService? tokenService,
  }) : _gapFill = gapFillService ?? WorkoutProgramGapFillService(),
       _llm = llmGenerator ?? LlmWorkoutProgramGenerator(),
       _mapper = mapper ?? const AiToStoredWorkoutProgramMapper(),
       _programs = programService ?? WorkoutProgramService(),
       _active = activeProgramService ?? ActiveProgramService(),
       _aiExercises = aiExerciseReadService ?? AIExerciseReadService(),
       _exercises = exerciseService ?? ExerciseService(),
       _tokens = tokenService ?? WorkoutProgramTokenService();

  final WorkoutProgramGapFillService _gapFill;
  final LlmWorkoutProgramGenerator _llm;
  final AiToStoredWorkoutProgramMapper _mapper;
  final WorkoutProgramService _programs;
  final ActiveProgramService _active;
  final AIExerciseReadService _aiExercises;
  final ExerciseService _exercises;
  final WorkoutProgramTokenService _tokens;

  Future<WorkoutProgramGenerationOutcome> generateAndActivate(
    WorkoutProgramGapAnswers answers,
  ) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        return const WorkoutProgramGenerationOutcome.failure(
          'کاربر وارد سیستم نشده است',
        );
      }

      final access = await _tokens.checkAccess(userId: userId);
      if (!access.canBuild) {
        return WorkoutProgramGenerationOutcome.failure(
          access.message ??
              'برای ساخت برنامه به اشتراک و توکن اجرا نیاز داری.',
        );
      }

      await _gapFill.persistAnswers(answers);

      final base = await _gapFill.loadContext();
      final context = _gapFill.contextForGeneration(base, answers);

      if (kDebugMode) {
        debugPrint(
          '[ProgramGen] equipment=${context.equipment} '
          'age=${context.profile['age']} height=${context.profile['height']} '
          'weight=${context.profile['weight']} goals=${context.goals}',
        );
      }

      final catalogExercises = await _loadCatalog();
      if (catalogExercises.isEmpty) {
        return const WorkoutProgramGenerationOutcome.failure(
          'کاتالوگ تمرین‌ها خالی است. لطفاً بعداً دوباره تلاش کنید.',
        );
      }

      final result = await _llm.generate(
        context: context,
        userId: userId,
        catalog: catalogExercises,
      );

      if (kDebugMode) {
        debugPrint(
          '[ProgramGen] llmSuccess=${result.isSuccess} '
          'msg=${result.errorMessage}',
        );
      }

      if (!result.isSuccess || result.program == null) {
        final raw = result.errorMessage;
        final safe = raw == gymAiModelsUnavailableMessage
            ? gymAiModelsUnavailableMessage
            : llmWorkoutProgramUserFailureMessage;
        return WorkoutProgramGenerationOutcome.failure(safe);
      }

      final aiTrainerId = await AITrainerService.ensureAITrainerExists();
      final stored = _mapper.map(
        result.program!,
        userId: userId,
        trainerId: aiTrainerId,
      );

      stored.name = ensureUniqueWorkoutProgramName(
        stored.name,
        (await _programs.getPrograms()).map((p) => p.name),
      );

      final saved = await _programs.createProgram(
        stored,
        trainerId: aiTrainerId,
        autoSend: true,
      );
      await _programs.sendProgram(saved.id);
      await _active.setActiveProgram(saved.id);

      final consumed = await _tokens.consumeToken(userId: userId);
      if (kDebugMode) {
        debugPrint(
          '[ProgramGen] saved+activated ${saved.id} '
          '(${saved.sessions.length} sessions, tokenConsumed=$consumed)',
        );
      }

      return WorkoutProgramGenerationOutcome.success(saved);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProgramGen] failed: $e\n$st');
      }
      final raw = e.toString();
      if (raw.contains('قبلاً ثبت شده')) {
        return const WorkoutProgramGenerationOutcome.failure(
          'نام برنامه تکراری بود. لطفاً دوباره تلاش کنید.',
        );
      }
      return const WorkoutProgramGenerationOutcome.failure(
        gymAiModelsUnavailableMessage,
      );
    }
  }

  /// Prefer AI exercise table (same as legacy generator), fallback to main catalog.
  Future<List<Exercise>> _loadCatalog() async {
    final aiCatalog = await _aiExercises.getExercisesForAI(limit: 800);
    if (aiCatalog.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[ProgramGen] AI catalog size=${aiCatalog.length}');
      }
      return aiCatalog;
    }

    final fallback = await _exercises.getExercises();
    if (kDebugMode) {
      debugPrint('[ProgramGen] fallback catalog size=${fallback.length}');
    }
    return fallback;
  }
}
