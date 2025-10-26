import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseDebugService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// تست اتصال به دیتابیس و بررسی توابع
  static Future<Map<String, dynamic>> runDatabaseDiagnostics() async {
    final results = <String, dynamic>{};

    try {
      developer.log('=== DATABASE DEBUG: Starting diagnostics ===');

      // 1. تست اتصال پایه
      results['basic_connection'] = await _testBasicConnection();

      // 2. تست دسترسی به جدول profiles
      results['profiles_access'] = await _testProfilesAccess();

      // 3. تست توابع database
      results['database_functions'] = await _testDatabaseFunctions();

      // 4. تست RLS policies
      results['rls_policies'] = await _testRLSPolicies();

      // 5. تست ایجاد پروفایل تستی
      results['profile_creation_test'] = await _testProfileCreation();

      developer.log('=== DATABASE DEBUG: Diagnostics completed ===');
      return results;
    } catch (e) {
      developer.log('=== DATABASE DEBUG: Error in diagnostics: $e ===');
      results['error'] = e.toString();
      return results;
    }
  }

  /// تست اتصال پایه
  static Future<Map<String, dynamic>> _testBasicConnection() async {
    try {
      developer.log('=== DATABASE DEBUG: Testing basic connection ===');

      final response = await _client.from('profiles').select('count').limit(1);

      developer.log('=== DATABASE DEBUG: Basic connection successful ===');
      return {
        'success': true,
        'message': 'Basic connection successful',
        'response_type': response.runtimeType.toString(),
      };
    } catch (e) {
      developer.log('=== DATABASE DEBUG: Basic connection failed: $e ===');
      return {
        'success': false,
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
    }
  }

  /// تست دسترسی به جدول profiles
  static Future<Map<String, dynamic>> _testProfilesAccess() async {
    try {
      developer.log('=== DATABASE DEBUG: Testing profiles table access ===');

      // تست SELECT
      await _client.from('profiles').select('id').limit(1);
      developer.log('=== DATABASE DEBUG: SELECT test successful ===');

      // تست INSERT (با rollback)
      final testData = {
        'id': '00000000-0000-0000-0000-000000000000',
        'username': 'test_debug_user',
        'phone_number': '09999999999',
        'role': 'athlete',
      };

      try {
        await _client.from('profiles').insert(testData);
        developer.log('=== DATABASE DEBUG: INSERT test successful ===');

        // حذف داده تستی
        await _client.from('profiles').delete().eq('id', testData['id']!);
        developer.log('=== DATABASE DEBUG: Test data cleaned up ===');

        return {
          'success': true,
          'select_works': true,
          'insert_works': true,
          'message': 'Profiles table access successful',
        };
      } catch (insertError) {
        developer.log(
          '=== DATABASE DEBUG: INSERT test failed: $insertError ===',
        );
        return {
          'success': false,
          'select_works': true,
          'insert_works': false,
          'insert_error': insertError.toString(),
          'message': 'SELECT works but INSERT failed',
        };
      }
    } catch (e) {
      developer.log('=== DATABASE DEBUG: Profiles access test failed: $e ===');
      return {
        'success': false,
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
    }
  }

  /// تست توابع database
  static Future<Map<String, dynamic>> _testDatabaseFunctions() async {
    try {
      developer.log('=== DATABASE DEBUG: Testing database functions ===');

      final results = <String, dynamic>{};

      // تست تابع check_user_exists
      try {
        final checkResult = await _client.rpc<bool>(
          'check_user_exists',
          params: {'phone': '09123456789'},
        );
        results['check_user_exists'] = {'success': true, 'result': checkResult};
        developer.log(
          '=== DATABASE DEBUG: check_user_exists function works ===',
        );
      } catch (e) {
        results['check_user_exists'] = {
          'success': false,
          'error': e.toString(),
        };
        developer.log(
          '=== DATABASE DEBUG: check_user_exists function failed: $e ===',
        );
      }

      // تست تابع check_user_exists_by_phone
      try {
        final checkByPhoneResult = await _client.rpc<bool>(
          'check_user_exists_by_phone',
          params: {'p_phone_number': '09123456789'},
        );
        results['check_user_exists_by_phone'] = {
          'success': true,
          'result': checkByPhoneResult,
        };
        developer.log(
          '=== DATABASE DEBUG: check_user_exists_by_phone function works ===',
        );
      } catch (e) {
        results['check_user_exists_by_phone'] = {
          'success': false,
          'error': e.toString(),
        };
        developer.log(
          '=== DATABASE DEBUG: check_user_exists_by_phone function failed: $e ===',
        );
      }

      return {
        'success': true,
        'functions': results,
        'message': 'Database functions test completed',
      };
    } catch (e) {
      developer.log(
        '=== DATABASE DEBUG: Database functions test failed: $e ===',
      );
      return {
        'success': false,
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
    }
  }

  /// تست RLS policies
  static Future<Map<String, dynamic>> _testRLSPolicies() async {
    try {
      developer.log('=== DATABASE DEBUG: Testing RLS policies ===');

      // بررسی وضعیت RLS
      final rlsResult = await _client.rpc<List<dynamic>>(
        'exec_sql',
        params: {
          'sql': '''
          SELECT 
            schemaname,
            tablename,
            rowsecurity as rls_enabled
          FROM pg_tables 
          WHERE tablename = 'profiles' AND schemaname = 'public'
        ''',
        },
      );

      developer.log('=== DATABASE DEBUG: RLS status: $rlsResult ===');

      return {
        'success': true,
        'rls_status': rlsResult,
        'message': 'RLS policies test completed',
      };
    } catch (e) {
      developer.log('=== DATABASE DEBUG: RLS policies test failed: $e ===');
      return {
        'success': false,
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
    }
  }

  /// تست ایجاد پروفایل
  static Future<Map<String, dynamic>> _testProfileCreation() async {
    try {
      developer.log('=== DATABASE DEBUG: Testing profile creation ===');

      const testUserId = '00000000-0000-0000-0000-000000000001';
      final testUsername =
          'debug_test_user_${DateTime.now().millisecondsSinceEpoch}';
      const testPhone = '09999999998';
      const testEmail = 'debug_test@example.com';

      // تست تابع create_user_profile
      try {
        final createResult = await _client.rpc<Map<String, dynamic>>(
          'create_user_profile',
          params: {
            'user_id': testUserId,
            'p_username': testUsername,
            'p_phone_number': testPhone,
            'p_email': testEmail,
          },
        );

        developer.log(
          '=== DATABASE DEBUG: create_user_profile result: $createResult ===',
        );

        // حذف پروفایل تستی
        try {
          await _client.from('profiles').delete().eq('id', testUserId);
          developer.log('=== DATABASE DEBUG: Test profile cleaned up ===');
        } catch (cleanupError) {
          developer.log(
            '=== DATABASE DEBUG: Cleanup failed: $cleanupError ===',
          );
        }

        return {
          'success': true,
          'create_user_profile_result': createResult,
          'message': 'Profile creation test completed',
        };
      } catch (e) {
        developer.log('=== DATABASE DEBUG: create_user_profile failed: $e ===');
        return {
          'success': false,
          'error': e.toString(),
          'error_type': e.runtimeType.toString(),
        };
      }
    } catch (e) {
      developer.log('=== DATABASE DEBUG: Profile creation test failed: $e ===');
      return {
        'success': false,
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
    }
  }

  /// اجرای تست کامل و نمایش نتایج
  static Future<void> runFullDiagnostics() async {
    developer.log('=== DATABASE DEBUG: Starting full diagnostics ===');

    final results = await runDatabaseDiagnostics();

    developer.log('=== DATABASE DEBUG: Full diagnostics results ===');
    developer.log('Results: $results');

    // نمایش نتایج به صورت ساختاریافته
    for (final entry in results.entries) {
      developer.log('=== DATABASE DEBUG: ${entry.key}: ${entry.value} ===');
    }
  }
}
