import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_reason.dart';

/// A single modification applied, skipped, or rejected on a program.
class WorkoutModification {
  const WorkoutModification({
    required this.type,
    required this.status,
    required this.subject,
    required this.dayLabel,
    required this.reasons,
    this.exerciseId,
    this.beforeName,
    this.afterName,
    this.beforeCatalogId,
    this.afterCatalogId,
  });

  factory WorkoutModification.fromJson(Map<String, Object?> json) {
    return WorkoutModification(
      type: WorkoutModificationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => WorkoutModificationType.replaceExercise,
      ),
      status: WorkoutModificationStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => WorkoutModificationStatus.skipped,
      ),
      subject: (json['subject'] as String?) ?? '',
      dayLabel: (json['dayLabel'] as String?) ?? '',
      exerciseId: json['exerciseId'] as String?,
      beforeName: json['beforeName'] as String?,
      afterName: json['afterName'] as String?,
      beforeCatalogId: json['beforeCatalogId'] as int?,
      afterCatalogId: json['afterCatalogId'] as int?,
      reasons: (json['reasons'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map(WorkoutModificationReason.fromJson)
          .toList(),
    );
  }

  final WorkoutModificationType type;
  final WorkoutModificationStatus status;
  final String subject;
  final String dayLabel;
  final String? exerciseId;
  final String? beforeName;
  final String? afterName;
  final int? beforeCatalogId;
  final int? afterCatalogId;
  final List<WorkoutModificationReason> reasons;

  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.name,
    'status': status.name,
    'subject': subject,
    'dayLabel': dayLabel,
    if (exerciseId != null) 'exerciseId': exerciseId,
    if (beforeName != null) 'beforeName': beforeName,
    if (afterName != null) 'afterName': afterName,
    if (beforeCatalogId != null) 'beforeCatalogId': beforeCatalogId,
    if (afterCatalogId != null) 'afterCatalogId': afterCatalogId,
    'reasons': reasons.map((reason) => reason.toJson()).toList(),
  };

  WorkoutModification copyWith({
    WorkoutModificationType? type,
    WorkoutModificationStatus? status,
    String? subject,
    String? dayLabel,
    String? afterName,
    List<WorkoutModificationReason>? reasons,
  }) {
    return WorkoutModification(
      type: type ?? this.type,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      dayLabel: dayLabel ?? this.dayLabel,
      exerciseId: exerciseId,
      beforeName: beforeName,
      afterName: afterName ?? this.afterName,
      beforeCatalogId: beforeCatalogId,
      afterCatalogId: afterCatalogId,
      reasons: reasons ?? this.reasons,
    );
  }
}
