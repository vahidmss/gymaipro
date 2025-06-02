class TrainerReview {
  final String id;
  final String trainerId;
  final String clientId;
  final int rating; // 1-5
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerReview({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerReview.fromJson(Map<String, dynamic> json) {
    return TrainerReview(
      id: json['id'],
      trainerId: json['trainer_id'],
      clientId: json['client_id'],
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'client_id': clientId,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TrainerReview copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    int? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerReview(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
