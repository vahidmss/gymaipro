import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }
}
