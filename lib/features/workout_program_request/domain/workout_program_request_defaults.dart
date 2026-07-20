/// Popular beginner-friendly defaults for AI program generation.
abstract final class WorkoutProgramRequestDefaults {
  const WorkoutProgramRequestDefaults._();

  static const String goal = 'عضله‌سازی';
  static const String equipment = 'باشگاه کامل';
  static const String experience = 'مبتدی';
  static const int daysPerWeek = 3;
  static const int sessionMinutes = 75;
  static const String noInjury = 'ندارم';

  static const List<String> goalOptions = <String>[
    'عضله‌سازی',
    'چربی‌سوزی',
    'قدرت',
    'تناسب اندام',
  ];

  static const List<String> equipmentOptions = <String>[
    'باشگاه کامل',
    'باشگاه معمولی',
    'دمبل در خانه',
    'فقط وزن بدن',
    'کش ورزشی',
  ];

  static const List<String> experienceOptions = <String>[
    'مبتدی',
    'متوسط',
    'پیشرفته',
  ];

  static const List<int> daysPerWeekOptions = <int>[2, 3, 4, 5, 6];

  static const List<int> sessionMinutesOptions = <int>[45, 60, 75, 90];

  static const List<String> injuryOptions = <String>[
    'ندارم',
    'شانه',
    'کمر',
    'زانو',
    'مچ دست',
    'آرنج',
    'گردن',
  ];

  static const List<String> priorityMuscleOptions = <String>[
    'بدون اولویت خاص',
    'سینه',
    'پشت',
    'سرشانه',
    'پا',
    'بازو',
    'شکم',
  ];
}
