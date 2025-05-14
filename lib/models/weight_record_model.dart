class WeightRecord {
  final String id;
  final String profileId;
  final double weight;
  final DateTime recordedAt;
  final DateTime createdAt;

  WeightRecord({
    required this.id,
    required this.profileId,
    required this.weight,
    required this.recordedAt,
    required this.createdAt,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'],
      profileId: json['profile_id'],
      weight: json['weight'].toDouble(),
      recordedAt: DateTime.parse(json['recorded_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'weight': weight,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
