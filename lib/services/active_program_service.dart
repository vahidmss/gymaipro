import 'package:flutter/foundation.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActiveProgramService {
  ActiveProgramService();

  final SupabaseClient _db = Supabase.instance.client;

  Future<Map<String, dynamic>?> getActiveProgramState() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return null;

      final row = await _db
          .from('profiles')
          .select('active_program_id, active_session_date')
          .eq('id', userId)
          .maybeSingle();

      return row;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveProgram] getActiveProgramState error: $e');
      }
      return null;
    }
  }

  Future<bool> setActiveProgram(String programId) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return false;

      await _db
          .from('profiles')
          .update({
            'active_program_id': programId,
            // تغییر برنامه: تاریخ جلسه فعال پاک می‌شود تا برای امروز دوباره تعیین شود
            'active_session_date': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveProgram] setActiveProgram error: $e');
      return false;
    }
  }

  Future<bool> clearActiveProgram() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return false;

      await _db
          .from('profiles')
          .update({
            'active_program_id': null,
            'active_session_date': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveProgram] clearActiveProgram error: $e');
      }
      return false;
    }
  }

  Future<bool> lockTodaySessionDate() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return false;
      final today = DateTime.now();
      final todayDate = DateTime.utc(today.year, today.month, today.day);

      await _db
          .from('profiles')
          .update({
            'active_session_date': todayDate.toIso8601String().split('T').first,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveProgram] lockTodaySessionDate error: $e');
      }
      return false;
    }
  }

  Future<bool> canChangeProgramToday() async {
    try {
      final state = await getActiveProgramState();
      if (state == null) return true;
      final String? activeSessionDateStr =
          state['active_session_date'] as String?;
      if (activeSessionDateStr == null) return true;

      final today = DateTime.now();
      final todayStr = DateTime.utc(
        today.year,
        today.month,
        today.day,
      ).toIso8601String().split('T').first;
      return activeSessionDateStr != todayStr;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveProgram] canChangeProgramToday error: $e');
      }
      return true;
    }
  }
}
