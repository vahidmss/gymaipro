class LoggedSupplement {
  LoggedSupplement({
    required this.name,
    required this.supplementType,
    this.amount,
    this.unit,
    this.time,
    this.note,
    this.protein,
    this.carbs,
    this.followedPlan = false,
  });

  factory LoggedSupplement.fromJson(Map<String, dynamic> json) {
    return LoggedSupplement(
      name: (json['name'] as String?) ?? json['name'].toString(),
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      unit: json['unit'] as String?,
      time: json['time'] as String?,
      note: json['note'] as String?,
      supplementType: (json['supplement_type'] as String?) ?? 'مکمل',
      protein: json['protein'] != null
          ? (json['protein'] as num).toDouble()
          : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
      followedPlan: (json['followed_plan'] as bool?) ?? false,
    );
  }
  final String name;
  final double? amount;
  final String? unit;
  final String? time;
  final String? note;
  final String supplementType;
  final double? protein;
  final double? carbs;
  final bool followedPlan;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (time != null) 'time': time,
      if (note != null) 'note': note,
      'supplement_type': supplementType,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      'followed_plan': followedPlan,
    };
  }

  LoggedSupplement copyWith({
    String? name,
    double? amount,
    String? unit,
    String? time,
    String? note,
    String? supplementType,
    double? protein,
    double? carbs,
    bool? followedPlan,
  }) {
    return LoggedSupplement(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      time: time ?? this.time,
      note: note ?? this.note,
      supplementType: supplementType ?? this.supplementType,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      followedPlan: followedPlan ?? this.followedPlan,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoggedSupplement &&
        other.name == name &&
        other.amount == amount &&
        other.unit == unit &&
        other.time == time &&
        other.note == note &&
        other.supplementType == supplementType &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.followedPlan == followedPlan;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        amount.hashCode ^
        unit.hashCode ^
        time.hashCode ^
        note.hashCode ^
        supplementType.hashCode ^
        protein.hashCode ^
        carbs.hashCode ^
        followedPlan.hashCode;
  }

  @override
  String toString() {
    return 'LoggedSupplement(name: $name, amount: $amount, unit: $unit, time: $time, note: $note, supplementType: $supplementType, protein: $protein, carbs: $carbs, followedPlan: $followedPlan)';
  }
}
