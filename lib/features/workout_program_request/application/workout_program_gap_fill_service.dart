import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/coach/coach_rules.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_engine.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/profile_age_resolver.dart';
import 'package:gymaipro/ai/workout/equipment/workout_equipment_tokens.dart';
import 'package:gymaipro/features/workout_program_request/domain/workout_program_gap_answers.dart';
import 'package:gymaipro/features/workout_program_request/domain/workout_program_request_defaults.dart';
import 'package:gymaipro/my_club/services/confidential_user_info_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';

/// Loads context, finds missing essentials, and persists gap-fill answers.
class WorkoutProgramGapFillService {
  WorkoutProgramGapFillService({
    AIContextEngine? contextEngine,
  }) : _contextEngine = contextEngine ?? AIContextEngine();

  final AIContextEngine _contextEngine;

  Future<CoachContext> loadContext() async {
    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('کاربر وارد سیستم نشده است');
    }

    final context = await _contextEngine.buildCoachContext(
      request: AIContextRequest(
        userId: userId,
        intent: AIIntent.workoutGeneration,
        source: 'workout_program_request',
        currentQuestion: 'درخواست برنامه تمرینی',
      ),
      intent: AIIntent.workoutGeneration,
    );
    return _recoverBodyMetricsFromProfileRow(
      _scrubImplausibleBodyMetrics(_withDerivedAge(context)),
    );
  }

  /// Fields the UI should still ask (age skipped when birth_date exists).
  List<String> missingEssentials(CoachContext context) {
    final normalized = _scrubImplausibleBodyMetrics(_withDerivedAge(context));
    return CoachRules.missingWorkoutGenerationFields(normalized)
        .where((field) => field != 'age' || !_hasBirthDate(normalized.profile))
        .toList(growable: false);
  }

  /// Prefill controllers / chips from existing context + popular defaults.
  WorkoutProgramGapAnswers seedAnswers(CoachContext context) {
    final normalized = _scrubImplausibleBodyMetrics(_withDerivedAge(context));
    final profile = normalized.profile;
    final age = ProfileAgeResolver.resolve(profile);
    final heightRaw =
        _asDouble(profile['height']) ?? _asDouble(profile['bb_height_cm']);
    final height =
        (heightRaw != null && heightRaw >= 100 && heightRaw <= 250)
            ? heightRaw
            : null;
    final weightRaw =
        _asDouble(profile['weight']) ?? _asDouble(profile['bb_weight_kg']);
    // Guard against polluted prefs (e.g. days_per_week written into weight).
    final weight =
        (weightRaw != null && weightRaw >= 30 && weightRaw <= 300)
            ? weightRaw
            : null;
    final goal = normalized.goals.isNotEmpty
        ? normalized.goals.first
        : WorkoutProgramRequestDefaults.goal;
    final equipment = normalized.equipment.isNotEmpty
        ? _closestEquipmentPreset(normalized.equipment.first)
        : WorkoutProgramRequestDefaults.equipment;
    final experience =
        (profile['experience_level'] ?? profile['bb_experience_level'])
            ?.toString()
            .trim();
    final days =
        _asInt(profile['bb_days_per_week'] ?? profile['days_per_week']) ??
        _asInt(normalized.preferences['workout_days']);
    final minutes =
        _asInt(profile['bb_session_minutes'] ?? profile['session_minutes']) ??
        _asInt(normalized.preferences['session_minutes']);

    final injuryRaw = normalized.restrictions;
    final injuries = injuryRaw.where((item) => !_isNoInjury(item)).isEmpty
        ? <String>[WorkoutProgramRequestDefaults.noInjury]
        : injuryRaw.where((item) => !_isNoInjury(item)).toList();

    return WorkoutProgramGapAnswers(
      age: age,
      height: height,
      weight: weight,
      goal: goal,
      equipment: equipment,
      experience: (experience == null || experience.isEmpty)
          ? WorkoutProgramRequestDefaults.experience
          : experience,
      daysPerWeek: days ?? WorkoutProgramRequestDefaults.daysPerWeek,
      sessionMinutes: minutes ?? WorkoutProgramRequestDefaults.sessionMinutes,
      injuries: injuries,
    );
  }

  /// Saves answers to profile + confidential lifestyle so next time we skip them.
  Future<void> persistAnswers(WorkoutProgramGapAnswers answers) async {
    final profileUpdates = <String, dynamic>{};
    // Only columns that exist on `profiles`. Prefer confidential for bb_* keys.
    if (answers.height != null && answers.height! >= 100) {
      profileUpdates['height'] = answers.height;
    }
    if (answers.weight != null && answers.weight! >= 30) {
      profileUpdates['weight'] = answers.weight;
    }
    if (answers.goal != null && answers.goal!.trim().isNotEmpty) {
      profileUpdates['fitness_goals'] = <String>[answers.goal!.trim()];
    }
    if (answers.experience != null && answers.experience!.trim().isNotEmpty) {
      profileUpdates['experience_level'] = answers.experience!.trim();
    }
    // Note: preferred_training_days is a JSON array of weekday labels,
    // not "days per week" count — that belongs in confidential prefs only.

    final meaningfulInjuries = answers.injuries
        .where((item) => !_isNoInjury(item))
        .toList(growable: false);
    if (meaningfulInjuries.isNotEmpty) {
      profileUpdates['medical_conditions'] = meaningfulInjuries;
    }

    if (profileUpdates.isNotEmpty) {
      final ok = await SimpleProfileService.updateProfile(profileUpdates);
      if (!ok && kDebugMode) {
        debugPrint('[GapFill] profile update returned false');
      }
    }

    await _persistConfidential(answers);
  }

  Future<void> _persistConfidential(WorkoutProgramGapAnswers answers) async {
    try {
      final existing = await ConfidentialUserInfoService.loadUserData();
      final prefs = Map<String, dynamic>.from(
        (existing?['lifestyle_preferences'] as Map?) ??
            const <String, dynamic>{},
      );

      var changed = false;
      if (answers.goal != null && answers.goal!.trim().isNotEmpty) {
        prefs['primary_goals'] = answers.goal!.trim();
        prefs['fitness_goal'] = answers.goal!.trim();
        changed = true;
      }
      if (answers.weight != null &&
          answers.weight! >= 30 &&
          answers.weight! <= 300) {
        prefs['weight'] = answers.weight;
        changed = true;
      } else if (prefs['weight'] != null) {
        final bad = _asDouble(prefs['weight']);
        if (bad != null && (bad < 30 || bad > 300)) {
          prefs.remove('weight');
          changed = true;
        }
      }
      if (answers.height != null &&
          answers.height! >= 100 &&
          answers.height! <= 250) {
        prefs['height'] = answers.height;
        changed = true;
      }
      if (answers.age != null) {
        prefs['age'] = answers.age;
        changed = true;
      }
      if (answers.equipment != null && answers.equipment!.trim().isNotEmpty) {
        prefs['equipment'] = answers.equipment!.trim();
        changed = true;
      }
      if (answers.experience != null && answers.experience!.trim().isNotEmpty) {
        prefs['experience_level'] = answers.experience!.trim();
        changed = true;
      }
      if (answers.daysPerWeek != null) {
        prefs['workout_days'] = answers.daysPerWeek;
        changed = true;
      }
      if (answers.sessionMinutes != null) {
        prefs['session_minutes'] = answers.sessionMinutes;
        changed = true;
      }
      if (answers.injuries.isNotEmpty) {
        prefs['injury_areas'] = answers.injuries;
        changed = true;
      }

      if (changed) {
        await ConfidentialUserInfoService.updateLifestylePreferences(prefs);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GapFill] confidential persist skipped: $e');
      }
    }
  }

  /// Overlay answers + popular defaults onto context for the generator.
  CoachContext contextForGeneration(
    CoachContext base,
    WorkoutProgramGapAnswers answers,
  ) {
    final withAge = _withDerivedAge(base);
    final goal = (answers.goal?.trim().isNotEmpty ?? false)
        ? answers.goal!.trim()
        : WorkoutProgramRequestDefaults.goal;
    final equipmentLabel = (answers.equipment?.trim().isNotEmpty ?? false)
        ? answers.equipment!.trim()
        : WorkoutProgramRequestDefaults.equipment;
    final equipmentTokens = WorkoutEquipmentTokens.expand(<String>[
      equipmentLabel,
    ]);
    final experience = (answers.experience?.trim().isNotEmpty ?? false)
        ? answers.experience!.trim()
        : WorkoutProgramRequestDefaults.experience;
    final days =
        answers.daysPerWeek ?? WorkoutProgramRequestDefaults.daysPerWeek;
    final minutes = answers.sessionMinutes ??
        WorkoutProgramRequestDefaults.sessionMinutes;
    final age =
        answers.age ?? ProfileAgeResolver.resolve(withAge.profile);

    final seeded = withAge.withCollectedFields(<String, Object?>{
      if (age != null) 'age': age,
      if (answers.height != null) 'height': answers.height,
      if (answers.weight != null && answers.weight! >= 30) 'weight': answers.weight,
      'goal': goal,
      'equipment': equipmentLabel,
      'experience_level': experience,
    });

    final profile = Map<String, Object?>.from(seeded.profile);
    if (age != null) profile['age'] = age;
    if (answers.height != null && answers.height! >= 100) {
      profile['height'] = answers.height;
    }
    if (answers.weight != null && answers.weight! >= 30) {
      profile['weight'] = answers.weight;
    } else {
      // Drop polluted weight (e.g. 3 from days_per_week mix-up).
      final existing = _asDouble(profile['weight']);
      if (existing != null && (existing < 30 || existing > 300)) {
        profile.remove('weight');
      }
    }
    profile['experience_level'] = experience;
    profile['bb_experience_level'] = experience;
    profile['bb_days_per_week'] = days;
    profile['bb_session_minutes'] = minutes;
    profile['bb_equipment_access'] = equipmentLabel;

    final preferences = Map<String, Object?>.from(seeded.preferences);
    preferences['experience_level'] = experience;
    preferences['workout_days'] = days;
    preferences['session_minutes'] = minutes;
    if (answers.priorityMuscles.isNotEmpty &&
        !answers.priorityMuscles.contains('بدون اولویت خاص')) {
      preferences['bb_priority_muscles'] = answers.priorityMuscles;
      preferences['priority_muscles'] = answers.priorityMuscles;
    }

    final restrictions = answers.injuries
        .where((item) => !_isNoInjury(item))
        .toList(growable: false);

    return CoachContext(
      intent: seeded.intent,
      metadata: seeded.metadata,
      profile: Map<String, Object?>.unmodifiable(profile),
      goals: List<String>.unmodifiable(<String>[goal]),
      restrictions: List<String>.unmodifiable(restrictions),
      equipment: List<String>.unmodifiable(equipmentTokens),
      preferences: Map<String, Object?>.unmodifiable(preferences),
      activeProgram: seeded.activeProgram,
      workoutHistory: seeded.workoutHistory,
      weeklyHeatmap: seeded.weeklyHeatmap,
      memories: seeded.memories,
      apiUsage: seeded.apiUsage,
      currentQuestion: seeded.currentQuestion,
      conversationSummary: seeded.conversationSummary,
    );
  }

  CoachContext _withDerivedAge(CoachContext context) {
    final age = ProfileAgeResolver.resolve(context.profile);
    if (age == null) return context;
    final profile = Map<String, Object?>.from(context.profile);
    profile['age'] = age;
    return CoachContext(
      intent: context.intent,
      metadata: context.metadata,
      profile: Map<String, Object?>.unmodifiable(profile),
      goals: context.goals,
      restrictions: context.restrictions,
      equipment: context.equipment,
      preferences: context.preferences,
      activeProgram: context.activeProgram,
      workoutHistory: context.workoutHistory,
      weeklyHeatmap: context.weeklyHeatmap,
      memories: context.memories,
      apiUsage: context.apiUsage,
      currentQuestion: context.currentQuestion,
      conversationSummary: context.conversationSummary,
    );
  }

  /// Removes body metrics that are clearly not kg/cm (pollution from other fields).
  CoachContext _scrubImplausibleBodyMetrics(CoachContext context) {
    final profile = Map<String, Object?>.from(context.profile);
    var changed = false;

    void scrub(String key, bool Function(double) ok) {
      final n = _asDouble(profile[key]);
      if (n != null && !ok(n)) {
        profile.remove(key);
        changed = true;
      }
    }

    scrub('weight', (n) => n >= 30 && n <= 300);
    scrub('bb_weight_kg', (n) => n >= 30 && n <= 300);
    scrub('height', (n) => n >= 100 && n <= 250);
    scrub('bb_height_cm', (n) => n >= 100 && n <= 250);

    if (!changed) return context;
    return CoachContext(
      intent: context.intent,
      metadata: context.metadata,
      profile: Map<String, Object?>.unmodifiable(profile),
      goals: context.goals,
      restrictions: context.restrictions,
      equipment: context.equipment,
      preferences: context.preferences,
      activeProgram: context.activeProgram,
      workoutHistory: context.workoutHistory,
      weeklyHeatmap: context.weeklyHeatmap,
      memories: context.memories,
      apiUsage: context.apiUsage,
      currentQuestion: context.currentQuestion,
      conversationSummary: context.conversationSummary,
    );
  }

  /// If memory/confidential overwrote weight with junk, restore from profiles row.
  Future<CoachContext> _recoverBodyMetricsFromProfileRow(
    CoachContext context,
  ) async {
    final needsWeight = !CoachRules.hasValidWeight(context.profile['weight']);
    final needsHeight = !CoachRules.hasValidHeight(context.profile['height']);
    if (!needsWeight && !needsHeight) return context;

    try {
      final row = await SimpleProfileService.getCurrentProfile();
      if (row == null) return context;

      final profile = Map<String, Object?>.from(context.profile);
      var changed = false;

      if (needsWeight) {
        final w = _asDouble(row['weight']);
        if (w != null && w >= 30 && w <= 300) {
          profile['weight'] = w;
          changed = true;
        }
      }
      if (needsHeight) {
        final h = _asDouble(row['height']);
        if (h != null && h >= 100 && h <= 250) {
          profile['height'] = h;
          changed = true;
        }
      }

      if (!changed) return context;
      return CoachContext(
        intent: context.intent,
        metadata: context.metadata,
        profile: Map<String, Object?>.unmodifiable(profile),
        goals: context.goals,
        restrictions: context.restrictions,
        equipment: context.equipment,
        preferences: context.preferences,
        activeProgram: context.activeProgram,
        workoutHistory: context.workoutHistory,
        weeklyHeatmap: context.weeklyHeatmap,
        memories: context.memories,
        apiUsage: context.apiUsage,
        currentQuestion: context.currentQuestion,
        conversationSummary: context.conversationSummary,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GapFill] profile metric recovery skipped: $e');
      }
      return context;
    }
  }

  bool _hasBirthDate(Map<String, Object?> profile) {
    final raw = profile['birth_date'] ?? profile['birthDate'];
    if (raw == null) return false;
    if (raw is DateTime) return true;
    return DateTime.tryParse(raw.toString()) != null;
  }

  String _closestEquipmentPreset(String raw) {
    for (final option in WorkoutProgramRequestDefaults.equipmentOptions) {
      if (raw.contains(option) || option.contains(raw)) return option;
    }
    if (raw.contains('باشگاه')) return 'باشگاه کامل';
    if (raw.contains('خانه')) return 'دمبل در خانه';
    if (raw.contains('وزن بدن')) return 'فقط وزن بدن';
    if (raw.contains('کش')) return 'کش ورزشی';
    return WorkoutProgramRequestDefaults.equipment;
  }

  bool _isNoInjury(String value) {
    final text = value.trim().toLowerCase();
    return text.isEmpty ||
        text == 'ندارم' ||
        text == 'هیچکدام' ||
        text == 'هیچ کدام' ||
        text == 'none' ||
        text.contains('ندارم') ||
        text.contains('هیچکدام');
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString().trim());
  }

  double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }
}
