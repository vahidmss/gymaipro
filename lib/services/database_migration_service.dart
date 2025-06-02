import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseMigrationService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Track migrations that have been run
  static final Set<String> _completedMigrations = <String>{};

  // Run all required migrations
  static Future<void> runMigrations() async {
    try {
      debugPrint('Starting database migrations...');

      // Run individual migrations
      await _addRoleToProfiles();

      debugPrint('All database migrations completed successfully');
    } catch (e) {
      debugPrint('Error running database migrations: $e');
    }
  }

  // Migration to add role to profiles table
  static Future<void> _addRoleToProfiles() async {
    const migrationId = 'add_role_to_profiles';

    if (_completedMigrations.contains(migrationId)) {
      debugPrint('Migration $migrationId already completed, skipping');
      return;
    }

    try {
      debugPrint('Running migration: $migrationId');

      // Check if role column exists
      final roleExists = await _checkColumnExists('profiles', 'role');

      if (!roleExists) {
        debugPrint(
            'Column "role" does not exist in profiles table, running migration');

        // Execute SQL to add role column with default value 'athlete'
        // Note: This requires database admin access and might not work with RLS
        // Alternatively, handle this in the Supabase migrations on the server
        try {
          await _client.rpc('run_migration_add_role_to_profiles');
          debugPrint('Migration SQL executed successfully');
        } catch (e) {
          debugPrint('Error executing migration SQL: $e');
          debugPrint('Attempting to update user profiles programmatically...');

          // Fallback: Update profiles one by one
          try {
            final profiles = await _client.from('profiles').select('id');
            for (final profile in profiles) {
              final id = profile['id'];
              await _client
                  .from('profiles')
                  .update({'role': 'athlete'}).eq('id', id);
            }
            debugPrint('Updated ${profiles.length} profiles with default role');
          } catch (e) {
            debugPrint('Error updating profiles programmatically: $e');
            throw Exception('Failed to add role to profiles: $e');
          }
        }
      } else {
        debugPrint(
            'Column "role" already exists in profiles table, skipping migration');
      }

      _completedMigrations.add(migrationId);
      debugPrint('Migration $migrationId completed successfully');
    } catch (e) {
      debugPrint('Error running migration $migrationId: $e');
      rethrow;
    }
  }

  // Helper method to check if a column exists in a table
  static Future<bool> _checkColumnExists(String table, String column) async {
    try {
      // Query a single row to get column information
      final result = await _client.from(table).select().limit(1);

      // Check if the column exists in the returned data
      if (result.isNotEmpty) {
        final row = result[0];
        return row.containsKey(column);
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if column exists: $e');
      return false;
    }
  }
}
