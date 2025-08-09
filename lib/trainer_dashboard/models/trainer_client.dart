class TrainerClient {
  final String id;
  final String trainerId;
  final String clientId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? clientProfile;

  TrainerClient({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.clientProfile,
  });

  factory TrainerClient.fromJson(Map<String, dynamic> json) {
    return TrainerClient(
      id: json['id'],
      trainerId: json['trainer_id'],
      clientId: json['client_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      clientProfile: json['client'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'client_id': clientId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'client': clientProfile,
    };
  }

  TrainerClient copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? clientProfile,
  }) {
    return TrainerClient(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientProfile: clientProfile ?? this.clientProfile,
    );
  }
} 