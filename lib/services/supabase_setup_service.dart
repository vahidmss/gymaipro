import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSetupService {
  static Future<bool> setupDatabase() async {
    try {
      final client = Supabase.instance.client;
      print('Starting database setup check');

      // Try to get profiles to check if table exists and is accessible
      try {
        final profilesResponse = await client
            .from('profiles')
            .select('id')
            .limit(1);
        print(
          'Profiles table exists, found ${profilesResponse.length} records',
        );
      } catch (e) {
        print('Error accessing profiles table: $e');
        print('This might be due to table not existing or permissions issue');
        // We can't create tables via RLS policies, this would require admin access
        return false;
      }

      // Try to get weight records to check if table exists and is accessible
      try {
        final weightRecordsResponse = await client
            .from('weight_records')
            .select('id')
            .limit(1);
        print(
          'Weight records table exists, found ${weightRecordsResponse.length} records',
        );
      } catch (e) {
        print('Error accessing weight_records table: $e');
        print('This might be due to table not existing or permissions issue');
        // We can't create tables via RLS policies, this would require admin access
        return false;
      }

      print('Database setup check completed successfully');
      return true;
    } catch (e) {
      print('Error during database setup check: $e');
      return false;
    }
  }
}
