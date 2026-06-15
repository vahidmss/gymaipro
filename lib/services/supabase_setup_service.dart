import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSetupService {
  static Future<bool> setupDatabase() async {
    try {
      final client = Supabase.instance.client;
      debugPrint('Starting database setup check');

      // Try to get profiles to check if table exists and is accessible
      try {
        final profilesResponse = await client
            .from('profiles')
            .select('id')
            .limit(1);
        debugPrint(
          'Profiles table exists, found ${profilesResponse.length} records',
        );
      } catch (e) {
        debugPrint('Error accessing profiles table: $e');
        debugPrint('This might be due to table not existing or permissions issue');
        // We can't create tables via RLS policies, this would require admin access
        return false;
      }

      // Try to get weight records to check if table exists and is accessible
      try {
        final weightRecordsResponse = await client
            .from('weight_records')
            .select('id')
            .limit(1);
        debugPrint(
          'Weight records table exists, found ${weightRecordsResponse.length} records',
        );
      } catch (e) {
        debugPrint('Error accessing weight_records table: $e');
        debugPrint('This might be due to table not existing or permissions issue');
        // We can't create tables via RLS policies, this would require admin access
        return false;
      }

      debugPrint('Database setup check completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error during database setup check: $e');
      return false;
    }
  }
}
