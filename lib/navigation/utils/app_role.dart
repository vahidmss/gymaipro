/// Centralized role checks for navigation-only behavior.
abstract final class AppRole {
  static const String athlete = 'athlete';
  static const String trainer = 'trainer';
  static const String admin = 'admin';

  static String normalize(String? role) {
    return switch (role?.trim().toLowerCase()) {
      trainer => trainer,
      admin => admin,
      _ => athlete,
    };
  }

  static bool isAthlete(String? role) => normalize(role) == athlete;

  static bool isTrainer(String? role) => normalize(role) == trainer;

  static bool isAdmin(String? role) => normalize(role) == admin;
}
