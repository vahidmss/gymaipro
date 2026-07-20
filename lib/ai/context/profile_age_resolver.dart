/// Derives age from profile fields (`birth_date`, `age`, questionnaire keys).
abstract final class ProfileAgeResolver {
  const ProfileAgeResolver._();

  static int? resolve(Map<String, Object?> profile) {
    final direct = _asInt(profile['age']) ?? _asInt(profile['bb_age']);
    if (direct != null && direct > 0 && direct < 120) return direct;

    final birthRaw =
        profile['birth_date'] ?? profile['birthDate'] ?? profile['birthday'];
    if (birthRaw == null) return null;

    final birthDate = birthRaw is DateTime
        ? birthRaw
        : DateTime.tryParse(birthRaw.toString());
    if (birthDate == null) return null;

    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age -= 1;
    }
    if (age <= 0 || age >= 120) return null;
    return age;
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString().trim());
  }
}
