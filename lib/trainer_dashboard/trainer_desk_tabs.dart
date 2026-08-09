/// Named indices for trainer desk tabs.
/// Keep [students] and [requests] stable — notifications deep-link to them.
abstract final class TrainerDeskTabs {
  static const int students = 0;
  static const int requests = 1;
  static const int content = 2;
  static const int services = 3;
  static const int finance = 4;
  static const int activities = 5;
  static const int profile = 6;

  static const int count = 7;
  static const int last = count - 1;
}
