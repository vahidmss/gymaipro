import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/utils/exercise_search.dart';

Exercise _ex({
  required int id,
  required String name,
  List<String> otherNames = const [],
  String mainMuscle = 'chest',
}) {
  return Exercise(
    id: id,
    title: name,
    name: name,
    mainMuscle: mainMuscle,
    secondaryMuscles: '',
    tips: const [],
    videoUrl: '',
    imageUrl: '',
    otherNames: otherNames,
    content: '',
  );
}

void main() {
  group('ExerciseSearch', () {
    test('matches alias پرس بالاسینه → پرس سینه شیب دار', () {
      final incline = _ex(
        id: 1,
        name: 'پرس سینه شیب دار',
        otherNames: const ['پرس بالاسینه', 'Incline Bench Press', 'بالاسینه'],
      );
      final flat = _ex(id: 2, name: 'پرس سینه با هالتر');

      expect(ExerciseSearch.matches(incline, 'پرس بالاسینه'), isTrue);
      expect(ExerciseSearch.matches(incline, 'بالاسینه'), isTrue);
      expect(ExerciseSearch.matches(incline, 'بالا سینه'), isTrue);
      expect(ExerciseSearch.matches(flat, 'پرس بالاسینه'), isFalse);
    });

    test('matches alias لت پولداون / لت سیکمش → زیربغل سیمکش', () {
      final lat = _ex(
        id: 3,
        name: 'زیربغل سیمکش',
        mainMuscle: 'back_lat',
        otherNames: const [
          'لت پولداون',
          'لت سیکمش جلو',
          'لت پول',
          'Lat Pulldown',
        ],
      );

      expect(ExerciseSearch.matches(lat, 'لت پولداون'), isTrue);
      expect(ExerciseSearch.matches(lat, 'لت سیکمش'), isTrue);
      expect(ExerciseSearch.matches(lat, 'لت پول'), isTrue);
      expect(ExerciseSearch.matches(lat, 'lat pulldown'), isTrue);
    });

    test('normalizes ZWNJ and arabic ye/kaf', () {
      final lat = _ex(
        id: 4,
        name: 'زیربغل سیم‌کش',
        mainMuscle: 'back_lat',
        otherNames: const ['لت‌پولداون'],
      );
      expect(ExerciseSearch.matches(lat, 'لت پولداون'), isTrue);
      expect(ExerciseSearch.matches(lat, 'زيربغل'), isTrue); // arabic ye
    });

    test('filter ranks alias hit highly', () {
      final incline = _ex(
        id: 1,
        name: 'پرس سینه شیب دار',
        otherNames: const ['پرس بالاسینه'],
      );
      final other = _ex(id: 2, name: 'کرانچ');
      final results = ExerciseSearch.filter([other, incline], 'پرس بالاسینه');
      expect(results, hasLength(1));
      expect(results.first.id, 1);
    });
  });
}
