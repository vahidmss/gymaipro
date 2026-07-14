class LiveWorkoutRestState {
  const LiveWorkoutRestState({
    required this.active,
    required this.paused,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  const LiveWorkoutRestState.idle()
    : active = false,
      paused = false,
      remainingSeconds = 0,
      totalSeconds = 0;

  final bool active;
  final bool paused;
  final int remainingSeconds;
  final int totalSeconds;

  LiveWorkoutRestState copyWith({
    bool? active,
    bool? paused,
    int? remainingSeconds,
    int? totalSeconds,
  }) {
    return LiveWorkoutRestState(
      active: active ?? this.active,
      paused: paused ?? this.paused,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'active': active,
      'paused': paused,
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
    };
  }

  factory LiveWorkoutRestState.fromJson(Map<String, Object?> json) {
    return LiveWorkoutRestState(
      active: json['active'] == true,
      paused: json['paused'] == true,
      remainingSeconds:
          int.tryParse(json['remainingSeconds']?.toString() ?? '') ?? 0,
      totalSeconds: int.tryParse(json['totalSeconds']?.toString() ?? '') ?? 0,
    );
  }
}
