import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/product_experience/form_guidance/form_exercise_guidance.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/exercise_service.dart';

class FormGuidanceFacadeResult {
  const FormGuidanceFacadeResult({
    required this.session,
    required this.catalog,
    this.initialExerciseId,
  });

  final FormGuidanceSession session;
  final List<FormExerciseGuidance> catalog;
  final int? initialExerciseId;
}

/// Loads session exercises + full catalog form tips (searchable).
class FormGuidanceFacade {
  FormGuidanceFacade({
    ActiveProgramCatalogService? programCatalog,
    ActiveWorkoutSessionService? sessionService,
    CoachProgramResolver? programResolver,
    ExerciseService? exerciseService,
  }) : _programCatalog = programCatalog ?? ActiveProgramCatalogService(),
       _sessionService = sessionService ?? ActiveWorkoutSessionService(),
       _programResolver = programResolver ?? CoachProgramResolver(),
       _exerciseService = exerciseService ?? ExerciseService();

  final ActiveProgramCatalogService _programCatalog;
  final ActiveWorkoutSessionService _sessionService;
  final CoachProgramResolver _programResolver;
  final ExerciseService _exerciseService;

  List<Exercise> _rawCatalog = const <Exercise>[];

  Future<FormGuidanceFacadeResult> load({
    String? sessionDay,
    int? preferredExerciseId,
  }) async {
    _rawCatalog = await _safeGetExercises();
    final catalogById = <int, Exercise>{
      for (final ex in _rawCatalog) ex.id: ex,
    };
    final catalogGuidance = _rawCatalog
        .map(_fromCatalogExercise)
        .toList(growable: false);

    final program = await _programCatalog.getActiveProgramOption();
    if (program == null) {
      return FormGuidanceFacadeResult(
        session: const FormGuidanceSession(
          sessionDay: '',
          exercises: <FormExerciseGuidance>[],
        ),
        catalog: catalogGuidance,
        initialExerciseId: preferredExerciseId,
      );
    }

    final context = await _sessionService.loadContext(programId: program.id);
    final availableDays = context.sessions
        .map((session) => session.day.trim())
        .where((day) => day.isNotEmpty)
        .toList(growable: false);
    final day = (sessionDay != null && sessionDay.trim().isNotEmpty)
        ? sessionDay.trim()
        : (context.selectedSessionDay ??
              (availableDays.isNotEmpty ? availableDays.first : ''));

    if (day.isEmpty) {
      return FormGuidanceFacadeResult(
        session: FormGuidanceSession(
          programTitle: program.title,
          sessionDay: '',
          exercises: const <FormExerciseGuidance>[],
        ),
        catalog: catalogGuidance,
        initialExerciseId: preferredExerciseId,
      );
    }

    final resolved = await _programResolver.resolveStoredProgram(
      program.id,
      sessionDay: day,
    );

    final sessionExercises = <FormExerciseGuidance>[];
    if (resolved != null) {
      for (final item in resolved.exercises) {
        final matched = _matchCatalog(
          catalogById: catalogById,
          exerciseId: item.exerciseId,
          name: item.name,
        );
        final tips = _extractTips(matched);
        sessionExercises.add(
          FormExerciseGuidance(
            name: (matched?.name.trim().isNotEmpty ?? false)
                ? matched!.name.trim()
                : item.name.trim(),
            catalogExerciseId: matched?.id ?? item.exerciseId,
            primaryMuscle: (matched?.mainMuscle.isNotEmpty ?? false)
                ? matched!.mainMuscle
                : item.primaryMuscle,
            tips: tips,
            programNote: item.notes,
          ),
        );
      }
    }

    return FormGuidanceFacadeResult(
      session: FormGuidanceSession(
        programTitle: program.title,
        sessionDay: day,
        exercises: sessionExercises,
      ),
      catalog: catalogGuidance,
      initialExerciseId: preferredExerciseId,
    );
  }

  /// Live search against the loaded catalog (falls back to service search).
  Future<List<FormExerciseGuidance>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (_rawCatalog.isEmpty) {
        _rawCatalog = await _safeGetExercises();
      }
      return _rawCatalog.take(30).map(_fromCatalogExercise).toList();
    }

    final found = await _exerciseService.searchExercises(q);
    return found.take(40).map(_fromCatalogExercise).toList(growable: false);
  }

  FormExerciseGuidance _fromCatalogExercise(Exercise exercise) {
    return FormExerciseGuidance(
      name: exercise.name.trim().isNotEmpty
          ? exercise.name.trim()
          : exercise.title.trim(),
      catalogExerciseId: exercise.id,
      primaryMuscle: exercise.mainMuscle,
      tips: _extractTips(exercise),
    );
  }

  Exercise? _matchCatalog({
    required Map<int, Exercise> catalogById,
    int? exerciseId,
    required String name,
  }) {
    if (exerciseId != null && exerciseId > 0) {
      final byId = catalogById[exerciseId];
      if (byId != null) return byId;
    }

    final target = _normalize(name);
    if (target.isEmpty) return null;

    for (final exercise in catalogById.values) {
      if (_normalize(exercise.name) == target) return exercise;
      if (_normalize(exercise.title) == target) return exercise;
      for (final other in exercise.otherNames) {
        if (_normalize(other) == target) return exercise;
      }
    }

    // Soft contains match when exact name differs slightly.
    for (final exercise in catalogById.values) {
      final n = _normalize(exercise.name);
      if (n.contains(target) || target.contains(n)) return exercise;
    }
    return null;
  }

  List<String> _extractTips(Exercise? exercise) {
    if (exercise == null) return const <String>[];
    final fromField = _cleanTips(exercise.tips);
    if (fromField.isNotEmpty) return fromField;

    // Some catalog rows bury cues in short/detailed description.
    final fromShort = _tipsFromFreeText(exercise.shortDescription);
    if (fromShort.isNotEmpty) return fromShort;
    return _tipsFromFreeText(exercise.detailedDescription);
  }

  List<String> _tipsFromFreeText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const <String>[];
    final lines = text
        .replaceAll(RegExp(r'<[^>]+>'), '\n')
        .split(RegExp(r'[\n\r•\-]+'))
        .map((line) => line.trim())
        .where((line) => line.length >= 12 && line.length <= 180)
        .take(3)
        .toList(growable: false);
    return lines;
  }

  List<String> _cleanTips(List<String> tips) {
    final out = <String>[];
    for (final tip in tips) {
      final cleaned = tip.trim();
      if (cleaned.isEmpty) continue;
      out.add(cleaned);
    }
    return out;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-‌]+'), '')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک');
  }

  Future<List<Exercise>> _safeGetExercises() async {
    try {
      return await _exerciseService.getExercises();
    } on Object {
      return const <Exercise>[];
    }
  }
}
