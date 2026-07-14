import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_versions.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Input package for a workout program modification run.
class WorkoutModificationRequest {
  const WorkoutModificationRequest({
    required this.program,
    required this.context,
    required this.modifications,
    this.catalogProfiles = const <ExerciseProfile>[],
    this.options = const <String, Object?>{},
    this.schemaVersion = WorkoutModifyVersions.schemaVersion,
  });

  factory WorkoutModificationRequest.fromJson(Map<String, Object?> json) {
    final programRaw = json['program'];
    final contextRaw = json['context'];
    final profilesRaw = json['catalogProfiles'];
    final modsRaw = json['modifications'];
    return WorkoutModificationRequest(
      program: programRaw is Map<String, Object?>
          ? WorkoutProgram.fromJson(programRaw)
          : WorkoutProgram.fromJson(const <String, Object?>{}),
      context: _contextFromJson(
        contextRaw is Map<String, Object?> ? contextRaw : const <String, Object?>{},
      ),
      modifications: (modsRaw as List<Object?>? ?? const <Object?>[])
          .map(
            (item) => WorkoutModificationType.values.firstWhere(
              (value) => value.name == item.toString(),
              orElse: () => WorkoutModificationType.injuryAdaptation,
            ),
          )
          .toList(),
      catalogProfiles: (profilesRaw as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map(ExerciseProfile.fromJson)
          .toList(),
      options: _mapFromJson(json['options']),
      schemaVersion:
          (json['schemaVersion'] as String?) ?? WorkoutModifyVersions.schemaVersion,
    );
  }

  final WorkoutProgram program;
  final CoachContext context;
  final List<WorkoutModificationType> modifications;
  final List<ExerciseProfile> catalogProfiles;
  final Map<String, Object?> options;
  final String schemaVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'program': program.toJson(),
    'context': _contextToJson(context),
    'modifications': modifications.map((item) => item.name).toList(),
    'catalogProfiles': catalogProfiles.map((profile) => profile.toJson()).toList(),
    'options': options,
  };

  static Map<String, Object?> _contextToJson(CoachContext context) =>
      <String, Object?>{
        'intent': context.intent.name,
        'profile': context.profile,
        'goals': context.goals,
        'restrictions': context.restrictions,
        'equipment': context.equipment,
        'preferences': context.preferences,
        'contextVersion': CoachContext.contextVersion,
      };

  static CoachContext _contextFromJson(Map<String, Object?> json) {
    final intentName = json['intent'] as String?;
    final intent = AIIntent.values.firstWhere(
      (value) => value.name == intentName,
      orElse: () => AIIntent.generalChat,
    );
    return CoachContext(
      intent: intent,
      profile: _mapFromJson(json['profile']),
      goals: List<String>.from(
        (json['goals'] as List<Object?>?) ?? const <Object?>[],
      ),
      restrictions: List<String>.from(
        (json['restrictions'] as List<Object?>?) ?? const <Object?>[],
      ),
      equipment: List<String>.from(
        (json['equipment'] as List<Object?>?) ?? const <Object?>[],
      ),
      preferences: _mapFromJson(json['preferences']),
      metadata: CoachContextMetadata(
        buildTime: DateTime.now(),
        sourceCount: 0,
        missingProviders: const {},
        confidence: 0,
        contextVersion:
            (json['contextVersion'] as String?) ?? CoachContext.contextVersion,
      ),
    );
  }

  WorkoutModificationRequest copyWith({
    WorkoutProgram? program,
    CoachContext? context,
    List<WorkoutModificationType>? modifications,
    List<ExerciseProfile>? catalogProfiles,
  }) {
    return WorkoutModificationRequest(
      program: program ?? this.program,
      context: context ?? this.context,
      modifications: modifications ?? this.modifications,
      catalogProfiles: catalogProfiles ?? this.catalogProfiles,
      options: options,
      schemaVersion: schemaVersion,
    );
  }
}
