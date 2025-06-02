class TrainerClient {
  final String id;
  final String trainerId;
  final String clientId;
  final String status; // pending, active, rejected, ended
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerClient({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerClient.fromJson(Map<String, dynamic> json) {
    return TrainerClient(
      id: json['id'],
      trainerId: json['trainer_id'],
      clientId: json['client_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'client_id': clientId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TrainerClient copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerClient(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for status
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isRejected => status == 'rejected';
  bool get isEnded => status == 'ended';
}
