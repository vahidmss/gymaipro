import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgramDeliveryStats {
  const ProgramDeliveryStats({
    required this.medianHours,
    required this.sampleCount,
  });

  final double medianHours;
  final int sampleCount;
}

typedef TrainerProgramDeliveryStats = ProgramDeliveryStats;

class CustomExercisesByVisibility {
  const CustomExercisesByVisibility({
    required this.privateCount,
    required this.publicCount,
  });

  final int privateCount;
  final int publicCount;
}

class TrainerKpis {
  const TrainerKpis({
    required this.trainerId,
    required this.totalWorkoutPrograms,
    required this.activeWorkoutPrograms,
    required this.totalCustomExercises,
    required this.totalCustomMusics,
    required this.publicCustomMusics,
    required this.totalStudents,
    required this.activeStudents,
    required this.totalReviews,
    required this.positiveReviews,
    required this.satisfactionRate,
  });

  final String trainerId;

  /// تعداد کل برنامه‌های تمرینی ساخته‌شده توسط مربی (از جدول `workout_programs`)
  final int totalWorkoutPrograms;

  /// تعداد برنامه‌های تمرینی فعال (ارسال شده به شاگردان - sent_at != null)
  final int activeWorkoutPrograms;

  /// تعداد کل تمرین‌های ثبت‌شده توسط مربی (اختصاصی + عمومی از جدول `custom_exercises`)
  final int totalCustomExercises;

  /// تعداد موزیک‌های اختصاصی اضافه‌شده توسط مربی (از جدول `custom_music`)
  final int totalCustomMusics;
  final int publicCustomMusics;

  /// تعداد کل شاگردها (از جدول `trainer_clients`)
  final int totalStudents;
  
  /// تعداد شاگردان فعال (از جدول `trainer_clients` با status = 'active')
  final int activeStudents;

  /// رضایت‌ها (از جدول `trainer_reviews`)
  final int totalReviews;
  final int positiveReviews;

  /// نسبت رضایت بین 0 تا 1 (مثلاً 0.92)
  final double satisfactionRate;

  int get satisfactionPercent => (satisfactionRate * 100).round().clamp(0, 100);
}

/// KPIهای مربی برای نمایش در پروفایل + ورودی‌های رنکینگ مربیان
class TrainerKpiService {
  TrainerKpiService();

  final SupabaseClient _client = Supabase.instance.client;

  Future<TrainerKpis> getTrainerKpis(String trainerId) async {
    if (trainerId.trim().isEmpty) {
      throw Exception('trainerId is empty');
    }

    try {
      final (totalPrograms, activePrograms) = await _countWorkoutPrograms(trainerId);
      final totalExercises = await _countCustomExercises(trainerId);
      final (totalMusics, publicMusics) = await _countCustomMusics(trainerId);
      final (totalStudents, activeStudents) = await _countStudents(trainerId);
      final (totalReviews, positiveReviews) = await _countReviews(trainerId);

      final satisfactionRate = totalReviews > 0
          ? (positiveReviews / totalReviews).clamp(0.0, 1.0)
          : 0.0;

      return TrainerKpis(
        trainerId: trainerId,
        totalWorkoutPrograms: totalPrograms,
        activeWorkoutPrograms: activePrograms,
        totalCustomExercises: totalExercises,
        totalCustomMusics: totalMusics,
        publicCustomMusics: publicMusics,
        totalStudents: totalStudents,
        activeStudents: activeStudents,
        totalReviews: totalReviews,
        positiveReviews: positiveReviews,
        satisfactionRate: satisfactionRate,
      );
    } catch (e) {
      debugPrint('TrainerKpiService.getTrainerKpis error: $e');
      rethrow;
    }
  }

  Future<(int total, int active)> _countWorkoutPrograms(String trainerId) async {
    try {
      // تعداد کل برنامه‌های تمرینی (حذف نشده)
      final totalRes = await _client
          .from('workout_programs')
          .select('id')
          .eq('trainer_id', trainerId)
          .eq('is_deleted', false)
          .count();
      
      final totalCount = totalRes.count;
      
      // تعداد برنامه‌های فعال (ارسال شده - sent_at != null)
      int activeCount = totalCount; // پیش‌فرض: همه برنامه‌ها فعال
      try {
        final activeRes = await _client
            .from('workout_programs')
            .select('id')
            .eq('trainer_id', trainerId)
            .eq('is_deleted', false)
            .not('sent_at', 'is', null)
            .count();
        activeCount = activeRes.count;
      } catch (_) {
        // اگر ستون sent_at وجود نداشت، همه برنامه‌ها را فعال در نظر می‌گیریم
        // activeCount قبلاً برابر totalCount تنظیم شده
      }
      
      return (totalCount, activeCount);
    } catch (e) {
      debugPrint('Error counting workout programs: $e');
      return (0, 0);
    }
  }

  /// تعداد تمرین‌های ثبت‌شده توسط مربی (اختصاصی + عمومی از custom_exercises)
  Future<int> _countCustomExercises(String trainerId) async {
    try {
      final res = await _client
          .from('custom_exercises')
          .select('id')
          .eq('created_by', trainerId)
          .count();
      return res.count;
    } catch (e) {
      debugPrint('Error counting custom exercises: $e');
      return 0;
    }
  }

  /// شمارش موزیک‌های مربی. برای نمایش در پروفایل/رنکینگ بهتر است RLS روی custom_music
  /// اجازه SELECT برای ردیف‌های visibility='public' را بدهد تا تعداد موزیک عمومی درست نمایش داده شود.
  Future<(int total, int publicCount)> _countCustomMusics(
    String trainerId,
  ) async {
    try {
      final totalRes = await _client
          .from('custom_music')
          .select('id')
          .eq('created_by', trainerId)
          .count();
      final publicRes = await _client
          .from('custom_music')
          .select('id')
          .eq('created_by', trainerId)
          .eq('visibility', 'public')
          .count();
      return (
        totalRes.count,
        publicRes.count,
      );
    } catch (e) {
      debugPrint('Error counting custom musics: $e');
      return (0, 0);
    }
  }

  Future<(int total, int active)> _countStudents(String trainerId) async {
    try {
      final totalRes = await _client
          .from('trainer_clients')
          .select('client_id')
          .eq('trainer_id', trainerId)
          .count();
      final activeRes = await _client
          .from('trainer_clients')
          .select('client_id')
          .eq('trainer_id', trainerId)
          .eq('status', 'active')
          .count();
      return (
        totalRes.count,
        activeRes.count,
      );
    } catch (e) {
      debugPrint('Error counting students: $e');
      return (0, 0);
    }
  }

  Future<ProgramDeliveryStats> getProgramDeliveryStats(String trainerId) async {
    try {
      final rows = await _client
          .from('workout_programs')
          .select('created_at, sent_at')
          .eq('trainer_id', trainerId)
          .eq('is_deleted', false)
          .not('sent_at', 'is', null);

      final hours = <double>[];
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final created = DateTime.tryParse(map['created_at']?.toString() ?? '');
        final sent = DateTime.tryParse(map['sent_at']?.toString() ?? '');
        if (created == null || sent == null) continue;
        final diff = sent.difference(created).inMinutes / 60.0;
        if (diff >= 0) hours.add(diff);
      }

      if (hours.isEmpty) {
        return const ProgramDeliveryStats(
          medianHours: double.nan,
          sampleCount: 0,
        );
      }

      hours.sort();
      final mid = hours.length ~/ 2;
      final median = hours.length.isOdd
          ? hours[mid]
          : (hours[mid - 1] + hours[mid]) / 2;

      return ProgramDeliveryStats(
        medianHours: median,
        sampleCount: hours.length,
      );
    } catch (e) {
      debugPrint('TrainerKpiService.getProgramDeliveryStats error: $e');
      return const ProgramDeliveryStats(
        medianHours: double.nan,
        sampleCount: 0,
      );
    }
  }

  Future<int> sumReviewStarPoints(String trainerId) async {
    try {
      final rows = await _client
          .from('trainer_reviews')
          .select('rating')
          .eq('trainer_id', trainerId);

      var sum = 0;
      for (final row in rows as List<dynamic>) {
        final rating = row['rating'];
        if (rating is int) {
          sum += rating;
        } else if (rating is num) sum += rating.round();
      }
      return sum;
    } catch (e) {
      debugPrint('TrainerKpiService.sumReviewStarPoints error: $e');
      return 0;
    }
  }

  Future<CustomExercisesByVisibility> countCustomExercisesByVisibility(
    String trainerId,
  ) async {
    try {
      final rows = await _client
          .from('custom_exercises')
          .select('visibility')
          .eq('created_by', trainerId);

      var privateCount = 0;
      var publicCount = 0;
      for (final row in rows as List<dynamic>) {
        final visibility = row['visibility']?.toString() ?? 'private';
        if (visibility == 'public') {
          publicCount++;
        } else {
          privateCount++;
        }
      }
      return CustomExercisesByVisibility(
        privateCount: privateCount,
        publicCount: publicCount,
      );
    } catch (e) {
      debugPrint('TrainerKpiService.countCustomExercisesByVisibility error: $e');
      return const CustomExercisesByVisibility(
        privateCount: 0,
        publicCount: 0,
      );
    }
  }

  Future<(int total, int positive)> _countReviews(String trainerId) async {
    try {
      final totalRes = await _client
          .from('trainer_reviews')
          .select('id')
          .eq('trainer_id', trainerId)
          .count();
      final positiveRes = await _client
          .from('trainer_reviews')
          .select('id')
          .eq('trainer_id', trainerId)
          .gte('rating', 4)
          .count();
      return (
        totalRes.count,
        positiveRes.count,
      );
    } catch (e) {
      debugPrint('Error counting reviews: $e');
      return (0, 0);
    }
  }
}

