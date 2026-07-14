import 'package:gymaipro/models/exercise.dart';

/// Offline exercise catalog fixture for workout generator tests.
class WorkoutExerciseCatalogFixture {
  const WorkoutExerciseCatalogFixture._();

  static List<Exercise> gymCatalog() => <Exercise>[
    _exercise(1, 'پرس سینه هالتر', 'سینه', 'هالتر', 'قدرتی', 'متوسط'),
    _exercise(2, 'پرس سینه دمبل', 'سینه', 'دمبل', 'قدرتی', 'متوسط'),
    _exercise(3, 'فلای سینه', 'سینه', 'دمبل', 'قدرتی', 'آسان'),
    _exercise(4, 'زیربغل هالتر', 'پشت', 'هالتر', 'قدرتی', 'متوسط'),
    _exercise(5, 'لت از جلو', 'پشت', 'دستگاه', 'قدرتی', 'متوسط'),
    _exercise(6, 'پرس سرشانه', 'شانه', 'دمبل', 'قدرتی', 'متوسط'),
    _exercise(7, 'نشر از بغل', 'شانه', 'دمبل', 'قدرتی', 'آسان'),
    _exercise(8, 'اسکوات هالتر', 'ران', 'هالتر', 'قدرتی', 'متوسط'),
    _exercise(9, 'لانج دمبل', 'ران', 'دمبل', 'قدرتی', 'آسان'),
    _exercise(10, 'ددلیفت رومانیایی', 'پشت پا', 'هالتر', 'قدرتی', 'متوسط'),
    _exercise(11, 'پشت ران دستگاه', 'پشت پا', 'دستگاه', 'قدرتی', 'آسان'),
    _exercise(12, 'جلو بازو دمبل', 'دوسر بازو', 'دمبل', 'قدرتی', 'آسان'),
    _exercise(13, 'پشت بازو پولی', 'سه‌سر بازو', 'دستگاه', 'قدرتی', 'آسان'),
    _exercise(14, 'کرانچ', 'شکم', 'بدون تجهیزات', 'قدرتی', 'آسان'),
    _exercise(15, 'پلانک', 'شکم', 'بدون تجهیزات', 'قدرتی', 'آسان'),
    _exercise(16, 'پرس پا دستگاه', 'ران', 'دستگاه', 'قدرتی', 'آسان'),
  ];

  static List<Exercise> homeCatalog() => <Exercise>[
    _exercise(101, 'پرس سینه دمبل', 'سینه', 'دمبل', 'قدرتی', 'متوسط'),
    _exercise(102, 'زیربغل دمبل', 'پشت', 'دمبل', 'قدرتی', 'متوسط'),
    _exercise(103, 'لانج دمبل', 'ران', 'دمبل', 'قدرتی', 'آسان'),
    _exercise(104, 'اسکوات گوبلت', 'ران', 'دمبل', 'قدرتی', 'آسان'),
    _exercise(105, 'جلو بازو دمبل', 'دوسر بازو', 'دمبل', 'قدرتی', 'آسان'),
    _exercise(106, 'کرانچ', 'شکم', 'بدون تجهیزات', 'قدرتی', 'آسان'),
    _exercise(107, 'پلانک', 'شکم', 'بدون تجهیزات', 'قدرتی', 'آسان'),
  ];

  static Exercise _exercise(
    int id,
    String name,
    String muscle,
    String equipment,
    String type,
    String difficulty,
  ) {
    return Exercise(
      id: id,
      title: name,
      name: name,
      mainMuscle: muscle,
      secondaryMuscles: '',
      tips: const <String>['فرم صحیح را حفظ کنید.'],
      videoUrl: '',
      imageUrl: '',
      otherNames: const <String>[],
      content: '',
      difficulty: difficulty,
      equipment: equipment,
      exerciseType: type,
    );
  }
}
