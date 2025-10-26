import 'package:supabase_flutter/supabase_flutter.dart';

class UserSearchService {
  factory UserSearchService() => _instance;
  UserSearchService._internal();
  static final UserSearchService _instance = UserSearchService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // جستجوی ورزشکاران (برای مربی‌ها)
  Future<List<Map<String, dynamic>>> searchAthletes(String query) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, username, full_name, bio, height, weight, fitness_goals')
          .eq('role', 'athlete')
          .ilike('username', '%$query%')
          .order('username');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطا در جستجوی ورزشکاران: $e');
    }
  }

  // دریافت اطلاعات کامل کاربر بر اساس یوزرنیم
  Future<Map<String, dynamic>?> getUserProfile(String username) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('خطا در دریافت اطلاعات کاربر: $e');
    }
  }

  // بررسی وجود رابطه بین دو کاربر
  Future<bool> hasRelationship({
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

  // بررسی وجود هر نوع رابطه بین دو کاربر (فعال، در انتظار، غیرفعال، مسدود)
  Future<Map<String, dynamic>?> getAnyRelationship({
    required String trainerId,
    required String clientId,
  }) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select('id, status')
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // بررسی وجود درخواست بین دو کاربر
  Future<bool> hasPendingRequest({
    required String trainerId,
    required String clientId,
  }) async {
    try {
      final response = await _client
          .from('trainer_requests')
          .select('id')
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId)
          .eq('status', 'pending')
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
