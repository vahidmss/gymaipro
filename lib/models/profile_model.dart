class Profile {
  final String id;
  final String username;
  final String phoneNumber;
  final double? height;
  final double? weight;
  final double? armCircumference;
  final double? chestCircumference;
  final double? waistCircumference;
  final double? hipCircumference;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.username,
    required this.phoneNumber,
    this.height,
    this.weight,
    this.armCircumference,
    this.chestCircumference,
    this.waistCircumference,
    this.hipCircumference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      phoneNumber: json['phone_number'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      armCircumference: json['arm_circumference']?.toDouble(),
      chestCircumference: json['chest_circumference']?.toDouble(),
      waistCircumference: json['waist_circumference']?.toDouble(),
      hipCircumference: json['hip_circumference']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone_number': phoneNumber,
      'height': height,
      'weight': weight,
      'arm_circumference': armCircumference,
      'chest_circumference': chestCircumference,
      'waist_circumference': waistCircumference,
      'hip_circumference': hipCircumference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
