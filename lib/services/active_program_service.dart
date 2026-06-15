import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';

class ActiveProgramService {
  ActiveProgramService();

  Future<Map<String, dynamic>?> getActiveProgramState() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return null;

      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return null;

      return {
        'active_program_id': profile['active_program_id'],
        'active_session_date': profile['active_session_date'],
      };
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

      return await SimpleProfileService.updateProfile({
        'active_program_id': programId,
        // تغییر برنامه: تاریخ جلسه فعال پاک می‌شود تا برای امروز دوباره تعیین شود
        'active_session_date': null,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveProgram] setActiveProgram error: $e');
      return false;
    }
  }

  Future<bool> clearActiveProgram() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return false;

      return await SimpleProfileService.updateProfile({
        'active_program_id': null,
        'active_session_date': null,
      });
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

      return await SimpleProfileService.updateProfile({
        'active_session_date': todayDate.toIso8601String().split('T').first,
      });
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
