import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// removed unused import

/// سرویس مدیریت برنامه‌های مربی
class TrainerProgramService {
  factory TrainerProgramService() => _instance;
  TrainerProgramService._internal();
  static final TrainerProgramService _instance =
      TrainerProgramService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// ثبت برنامه توسط مربی
  Future<bool> registerProgram({
    required String subscriptionId,
    required String trainerId,
    String? programDescription,
    Map<String, dynamic>? programData,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'ثبت برنامه توسط مربی - اشتراک: $subscriptionId, مربی: $trainerId',
        );
      }

      // بررسی اینکه مربی صاحب این اشتراک است
      final subscription = await _client
          .from('trainer_subscriptions')
          .select('trainer_id, status')
          .eq('id', subscriptionId)
          .eq('trainer_id', trainerId)
          .maybeSingle();

      if (subscription == null) {
        if (kDebugMode) {
          print('اشتراک یافت نشد یا مربی مجاز نیست');
        }
        return false;
      }

      if (subscription['status'] != 'active' &&
          subscription['status'] != 'paid') {
        if (kDebugMode) {
          print('اشتراک فعال نیست');
        }
        return false;
      }

      // به‌روزرسانی وضعیت برنامه
      final now = DateTime.now();
      await _client
          .from('trainer_subscriptions')
          .update({
            'program_registration_date': now.toIso8601String(),
            'program_status': 'in_progress',
            'status': 'active',
            'updated_at': now.toIso8601String(),
            'metadata': {
              'program_description': programDescription,
              'program_data': programData,
              'registered_by_trainer': true,
            },
          })
          .eq('id', subscriptionId);

      if (kDebugMode) {
        print('برنامه با موفقیت ثبت شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ثبت برنامه: $e');
      }
      return false;
    }
  }

  /// ثبت اولین استفاده توسط کاربر
  Future<bool> recordFirstUsage({
    required String subscriptionId,
    required String userId,
  }) async {
    try {
      if (kDebugMode) {
        print('ثبت اولین استفاده - اشتراک: $subscriptionId, کاربر: $userId');
      }

      // بررسی اینکه کاربر صاحب این اشتراک است
      final subscription = await _client
          .from('trainer_subscriptions')
          .select('user_id, first_usage_date')
          .eq('id', subscriptionId)
          .eq('user_id', userId)
          .maybeSingle();

      if (subscription == null) {
        if (kDebugMode) {
          print('اشتراک یافت نشد یا کاربر مجاز نیست');
        }
        return false;
      }

      if (subscription['first_usage_date'] != null) {
        if (kDebugMode) {
          print('اولین استفاده قبلاً ثبت شده');
        }
        return true; // قبلاً ثبت شده
      }

      // ثبت اولین استفاده
      final now = DateTime.now();
      await _client
          .from('trainer_subscriptions')
          .update({
            'first_usage_date': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', subscriptionId);

      if (kDebugMode) {
        print('اولین استفاده با موفقیت ثبت شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ثبت اولین استفاده: $e');
      }
      return false;
    }
  }

  /// تکمیل برنامه
  Future<bool> completeProgram({
    required String subscriptionId,
    required String trainerId,
    String? completionNotes,
  }) async {
    try {
      if (kDebugMode) {
        print('تکمیل برنامه - اشتراک: $subscriptionId, مربی: $trainerId');
      }

      // بررسی مجوز مربی
      final subscription = await _client
          .from('trainer_subscriptions')
          .select('trainer_id, program_status')
          .eq('id', subscriptionId)
          .eq('trainer_id', trainerId)
          .maybeSingle();

      if (subscription == null) {
        if (kDebugMode) {
          print('اشتراک یافت نشد یا مربی مجاز نیست');
        }
        return false;
      }

      if (subscription['program_status'] != 'in_progress') {
        if (kDebugMode) {
          print('برنامه در حال انجام نیست');
        }
        return false;
      }

      // تکمیل برنامه
      final now = DateTime.now();
      await _client
          .from('trainer_subscriptions')
          .update({
            'program_status': 'completed',
            'updated_at': now.toIso8601String(),
            'metadata': {
              'completion_notes': completionNotes,
              'completed_at': now.toIso8601String(),
            },
          })
          .eq('id', subscriptionId);

      if (kDebugMode) {
        print('برنامه با موفقیت تکمیل شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تکمیل برنامه: $e');
      }
      return false;
    }
  }

  /// دریافت اشتراک‌های در انتظار برنامه
  Future<List<Map<String, dynamic>>> getPendingPrograms(
    String trainerId,
  ) async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select('''
            id,
            user_id,
            service_type,
            purchase_date,
            program_registration_date,
            program_status,
            trainer_delay_days,
            profiles!trainer_subscriptions_user_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('trainer_id', trainerId)
          .or('status.eq.paid,status.eq.active')
          .or('program_status.eq.not_started,program_status.eq.delayed')
          .order('purchase_date', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت برنامه‌های در انتظار: $e');
      }
      return [];
    }
  }

  /// دریافت آمار برنامه‌های مربی
  Future<Map<String, dynamic>> getTrainerProgramStats(String trainerId) async {
    try {
      final response = await _client
          .from('trainer_subscriptions')
          .select('program_status, created_at, program_registration_date')
          .eq('trainer_id', trainerId);

      final stats = <String, dynamic>{
        'total_programs': response.length,
        'not_started': 0,
        'in_progress': 0,
        'completed': 0,
        'delayed': 0,
        'average_delay_days': 0,
        'on_time_delivery_rate': 0.0,
      };

      int totalDelays = 0;
      int onTimeDeliveries = 0;

      for (final program in response) {
        final status = program['program_status'] as String;
        final createdAt = DateTime.parse(program['created_at'] as String);
        final registrationDate = program['program_registration_date'] != null
            ? DateTime.parse(program['program_registration_date'] as String)
            : null;

        stats[status] = (stats[status] as int) + 1;

        if (registrationDate != null) {
          final expectedDate = createdAt.add(const Duration(days: 1));
          if (registrationDate.isAfter(expectedDate)) {
            final delayDays = registrationDate.difference(expectedDate).inDays;
            totalDelays += delayDays;
          } else {
            onTimeDeliveries++;
          }
        }
      }

      if (response.isNotEmpty) {
        stats['average_delay_days'] = totalDelays / response.length;
        stats['on_time_delivery_rate'] =
            (onTimeDeliveries / response.length) * 100;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت آمار برنامه‌های مربی: $e');
      }
      return {};
    }
  }

  /// بررسی تاخیر برنامه‌ها
  Future<void> checkDelayedPrograms() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // یافتن برنامه‌هایی که بیش از 1 روز از خرید گذشته و هنوز ثبت نشده‌اند
      final delayedPrograms = await _client
          .from('trainer_subscriptions')
          .select('id, trainer_id, user_id, purchase_date')
          .eq('program_status', 'not_started')
          .lt('purchase_date', oneDayAgo.toIso8601String())
          .or('status.eq.paid,status.eq.active');

      for (final program in delayedPrograms) {
        final purchaseDate = DateTime.parse(program['purchase_date'] as String);
        final delayDays = now.difference(purchaseDate).inDays - 1;

        await _client
            .from('trainer_subscriptions')
            .update({
              'program_status': 'delayed',
              'trainer_delay_days': delayDays,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', program['id'] as String);

        if (kDebugMode) {
          print(
            'برنامه تاخیردار شناسایی شد: ${program['id']} - تاخیر: $delayDays روز',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در بررسی برنامه‌های تاخیردار: $e');
      }
    }
  }

  /// دریافت تاریخچه برنامه‌های مربی
  Future<List<Map<String, dynamic>>> getTrainerProgramHistory({
    required String trainerId,
    int? limit,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final base = _client.from('trainer_subscriptions').select('''
            id,
            user_id,
            service_type,
            status,
            program_status,
            purchase_date,
            program_registration_date,
            first_usage_date,
            trainer_delay_days,
            profiles!trainer_subscriptions_user_id_fkey(
              full_name,
              avatar_url
            )
          ''');

      var filter = base.eq('trainer_id', trainerId);

      if (fromDate != null) {
        filter = filter.gte('purchase_date', fromDate.toIso8601String());
      }

      if (toDate != null) {
        filter = filter.lte('purchase_date', toDate.toIso8601String());
      }

      final ordered = filter.order('purchase_date', ascending: false);
      final response = await (limit != null ? ordered.limit(limit) : ordered);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تاریخچه برنامه‌های مربی: $e');
      }
      return [];
    }
  }
}
