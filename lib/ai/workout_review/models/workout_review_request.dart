import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_versions.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Input package for a workout program review.
class WorkoutReviewRequest {
  const WorkoutReviewRequest({
    required this.program,
    required this.context,
    this.catalogProfiles = const <ExerciseProfile>[],
    this.knowledgeResult,
    this.schemaVersion = WorkoutReviewVersions.schemaVersion,
  });

  factory WorkoutReviewRequest.fromJson(Map<String, Object?> json) {
    final contextRaw = json['context'];
    final programRaw = json['program'];
    final profilesRaw = json['catalogProfiles'];
    return WorkoutReviewRequest(
      program: programRaw is Map<String, Object?>
          ? WorkoutProgram.fromJson(programRaw)
          : WorkoutProgram.fromJson(const <String, Object?>{}),
      context: _contextFromJson(
        contextRaw is Map<String, Object?> ? contextRaw : const <String, Object?>{},
      ),
      catalogProfiles: (profilesRaw as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map(ExerciseProfile.fromJson)
          .toList(),
      schemaVersion:
          (json['schemaVersion'] as String?) ?? WorkoutReviewVersions.schemaVersion,
    );
  }

  final WorkoutProgram program;
  final CoachContext context;
  final List<ExerciseProfile> catalogProfiles;
  final CoachKnowledgeResult? knowledgeResult;
  final String schemaVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'program': program.toJson(),
    'context': _contextToJson(context),
    'catalogProfiles': catalogProfiles.map((profile) => profile.toJson()).toList(),
    if (knowledgeResult != null)
      'knowledgeResult': <String, Object?>{
        'selectedNodeId': knowledgeResult!.selectedNode.id,
        'confidence': knowledgeResult!.confidence,
      },
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

  WorkoutReviewRequest copyWith({
    WorkoutProgram? program,
    CoachContext? context,
    List<ExerciseProfile>? catalogProfiles,
    CoachKnowledgeResult? knowledgeResult,
    String? schemaVersion,
  }) {
    return WorkoutReviewRequest(
      program: program ?? this.program,
      context: context ?? this.context,
      catalogProfiles: catalogProfiles ?? this.catalogProfiles,
      knowledgeResult: knowledgeResult ?? this.knowledgeResult,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
