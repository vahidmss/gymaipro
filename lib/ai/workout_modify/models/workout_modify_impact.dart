/// Delta metrics comparing original and modified programs.
class WorkoutModificationImpact {
  const WorkoutModificationImpact({
    required this.volumeDelta,
    required this.fatigueDelta,
    required this.recoveryDelta,
    required this.jointStressDelta,
    required this.goalAlignmentDelta,
    this.beforeVolume = 0,
    this.afterVolume = 0,
    this.beforeFatigue = 0,
    this.afterFatigue = 0,
    this.beforeRecovery = 0,
    this.afterRecovery = 0,
    this.beforeJointStress = 0,
    this.afterJointStress = 0,
    this.beforeGoalAlignment = 0,
    this.afterGoalAlignment = 0,
  });

  factory WorkoutModificationImpact.fromJson(Map<String, Object?> json) {
    return WorkoutModificationImpact(
      volumeDelta: _read(json['volumeDelta']),
      fatigueDelta: _read(json['fatigueDelta']),
      recoveryDelta: _read(json['recoveryDelta']),
      jointStressDelta: _read(json['jointStressDelta']),
      goalAlignmentDelta: _read(json['goalAlignmentDelta']),
      beforeVolume: _read(json['beforeVolume']),
      afterVolume: _read(json['afterVolume']),
      beforeFatigue: _read(json['beforeFatigue']),
      afterFatigue: _read(json['afterFatigue']),
      beforeRecovery: _read(json['beforeRecovery']),
      afterRecovery: _read(json['afterRecovery']),
      beforeJointStress: _read(json['beforeJointStress']),
      afterJointStress: _read(json['afterJointStress']),
      beforeGoalAlignment: _read(json['beforeGoalAlignment']),
      afterGoalAlignment: _read(json['afterGoalAlignment']),
    );
  }

  final double volumeDelta;
  final double fatigueDelta;
  final double recoveryDelta;
  final double jointStressDelta;
  final double goalAlignmentDelta;
  final double beforeVolume;
  final double afterVolume;
  final double beforeFatigue;
  final double afterFatigue;
  final double beforeRecovery;
  final double afterRecovery;
  final double beforeJointStress;
  final double afterJointStress;
  final double beforeGoalAlignment;
  final double afterGoalAlignment;

  static double _read(Object? value) =>
      value is num ? value.toDouble() : 0;

  Map<String, Object?> toJson() => <String, Object?>{
    'volumeDelta': volumeDelta,
    'fatigueDelta': fatigueDelta,
    'recoveryDelta': recoveryDelta,
    'jointStressDelta': jointStressDelta,
    'goalAlignmentDelta': goalAlignmentDelta,
    'beforeVolume': beforeVolume,
    'afterVolume': afterVolume,
    'beforeFatigue': beforeFatigue,
    'afterFatigue': afterFatigue,
    'beforeRecovery': beforeRecovery,
    'afterRecovery': afterRecovery,
    'beforeJointStress': beforeJointStress,
    'afterJointStress': afterJointStress,
    'beforeGoalAlignment': beforeGoalAlignment,
    'afterGoalAlignment': afterGoalAlignment,
  };

  WorkoutModificationImpact copyWith({
    double? volumeDelta,
    double? fatigueDelta,
    double? recoveryDelta,
    double? jointStressDelta,
    double? goalAlignmentDelta,
  }) {
    return WorkoutModificationImpact(
      volumeDelta: volumeDelta ?? this.volumeDelta,
      fatigueDelta: fatigueDelta ?? this.fatigueDelta,
      recoveryDelta: recoveryDelta ?? this.recoveryDelta,
      jointStressDelta: jointStressDelta ?? this.jointStressDelta,
      goalAlignmentDelta: goalAlignmentDelta ?? this.goalAlignmentDelta,
      beforeVolume: beforeVolume,
      afterVolume: afterVolume,
      beforeFatigue: beforeFatigue,
      afterFatigue: afterFatigue,
      beforeRecovery: beforeRecovery,
      afterRecovery: afterRecovery,
      beforeJointStress: beforeJointStress,
      afterJointStress: afterJointStress,
      beforeGoalAlignment: beforeGoalAlignment,
      afterGoalAlignment: afterGoalAlignment,
    );
  }
}
