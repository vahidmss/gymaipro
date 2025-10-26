import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerClientService {
  factory TrainerClientService() => _instance;
  TrainerClientService._internal();
  static final TrainerClientService _instance =
      TrainerClientService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ایجاد رابطه مربی-شاگرد (در انتظار تایید)
  Future<void> createTrainerClientRelationship({
    required String trainerId,
    required String clientId,
  }) async {
    try {
      await _client.from('trainer_clients').insert({
        'trainer_id': trainerId,
        'client_id': clientId,
        'status': 'pending', // در انتظار تایید شاگرد
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('خطا در ایجاد رابطه: $e');
    }
  }

  // اطمینان از فعال بودن رابطه مربی-شاگرد (ایجاد یا به‌روزرسانی به active)
  Future<void> ensureActiveRelationship({
    required String trainerId,
    required String clientId,
  }) async {
    try {
      final existing = await _client
          .from('trainer_clients')
          .select('id,status')
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId)
          .maybeSingle();

      if (existing == null) {
        await _client.from('trainer_clients').insert({
          'trainer_id': trainerId,
          'client_id': clientId,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        });
      } else if (existing['status'] != 'active') {
        await _client
            .from('trainer_clients')
            .update({
              'status': 'active',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('trainer_id', trainerId)
            .eq('client_id', clientId);
      }
    } catch (e) {
      throw Exception('خطا در فعال‌سازی رابطه مربی-شاگرد: $e');
    }
  }

  // دریافت لیست شاگردان یک مربی
  Future<List<Map<String, dynamic>>> getTrainerClients(String trainerId) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select('''
            *,
            client:profiles!trainer_clients_client_id_fkey(
              id,
              username,
              first_name,
              last_name,
              avatar_url,
              email,
              bio,
              height,
              weight,
              fitness_goals,
              created_at
            )
          ''')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطا در دریافت لیست شاگردان: $e');
    }
  }

  // دریافت لیست مربیان یک شاگرد
  Future<List<Map<String, dynamic>>> getClientTrainers(String clientId) async {
    try {
      print('در حال دریافت مربی‌ها برای شاگرد: $clientId');

      final response = await _client
          .from('trainer_clients')
          .select('''
            *,
            trainer:profiles!trainer_clients_trainer_id_fkey(
              id, username, first_name, last_name, email, bio, experience_years, 
              specializations, rating, review_count, avatar_url
            )
          ''')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      print('پاسخ دریافت شده از دیتابیس: ${response.length} مربی');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطا در دریافت مربی‌ها: $e');
      throw Exception('خطا در دریافت لیست مربیان: $e');
    }
  }

  // به‌روزرسانی وضعیت رابطه
  Future<void> updateRelationshipStatus({
    required String trainerId,
    required String clientId,
    required String status, // 'active', 'inactive', 'blocked'
  }) async {
    try {
      await _client
          .from('trainer_clients')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId);
    } catch (e) {
      throw Exception('خطا در به‌روزرسانی وضعیت: $e');
    }
  }

  // پایان رابطه
  Future<void> endRelationship({
    required String trainerId,
    required String clientId,
  }) async {
    try {
      await _client
          .from('trainer_clients')
          .delete()
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId);
    } catch (e) {
      throw Exception('خطا در پایان رابطه: $e');
    }
  }

  // دریافت آمار روابط
  Future<Map<String, int>> getRelationshipStats(String trainerId) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select('status')
          .eq('trainer_id', trainerId);

      final stats = <String, int>{
        'active': 0,
        'pending': 0,
        'inactive': 0,
        'blocked': 0,
      };

      for (final item in response) {
        final status = item['status'] as String? ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('خطا در دریافت آمار: $e');
    }
  }

  // بررسی وجود رابطه فعال
  Future<bool> hasActiveRelationship({
    required String trainerId,
    required String clientId,
  }) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select('id')
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId)
          .eq('status', 'active')
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // دریافت اطلاعات شاگرد با پروفایل
  Future<Map<String, dynamic>?> getClientWithProfile({
    required String trainerId,
    required String clientId,
  }) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select('''
            *,
            client:profiles!trainer_clients_client_id_fkey(*)
          ''')
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('خطا در دریافت اطلاعات شاگرد: $e');
    }
  }
}
