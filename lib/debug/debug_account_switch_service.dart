import 'package:flutter/foundation.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/auth/utils/phone_utils.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/debug/debug_test_accounts.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Switches the live Supabase session to a seeded debug test account.
///
/// Only callable when [kDebugMode] is true.
///
/// Critical: does **not** call [enterMainAppAfterAuth] / rebuild `/main`.
/// Recreating the main shell after a heavy cache clear was causing ANRs.
class DebugAccountSwitchService {
  DebugAccountSwitchService({
    AuthStateService? authStateService,
  }) : _authStateService = authStateService ?? AuthStateService();

  final AuthStateService _authStateService;

  Future<void> switchTo(DebugTestAccount account) async {
    assert(kDebugMode, 'DebugAccountSwitchService is debug-only');
    if (!kDebugMode) {
      throw StateError('Account switcher is only available in debug mode');
    }

    final targetPhone = PhoneUtils.normalize(account.phone);
    final previousUserId = Supabase.instance.client.auth.currentUser?.id;

    if (kDebugMode) {
      debugPrint(
        'DEBUG switch v3: → ${account.username} ($targetPhone) '
        'from=$previousUserId',
      );
    }

    if (await _isAlreadyOnAccount(targetPhone)) {
      if (kDebugMode) {
        debugPrint('DEBUG switch v3: already on target — soft reload only');
      }
      SimpleProfileService.invalidateCache();
      await _reloadUi();
      return;
    }

    // 1) Replace session in place (no explicit signOut — GoTrue may still emit
    //    a brief signedOut while swapping users; we avoid a full /main rebuild).
    final session = await _signIn(account, targetPhone);

    // 2) Clear previous user's local caches once, then mark new id so
    //    saveAuthState does not clear again.
    await LogoutCacheClearService.clearAllUserData(
      previousUserId: previousUserId,
    );
    SimpleProfileService.invalidateCache();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_in_user_id', session.user.id);
    } catch (_) {}

    await _authStateService.saveAuthState(
      session,
      phoneNumber: targetPhone,
    );
    SimpleProfileService.invalidateCache();

    if (kDebugMode) {
      debugPrint(
        'DEBUG switch v3: session ok user=${session.user.id} — soft reload',
      );
    }

    // 3) Soft reload shell tabs (no pushNamedAndRemoveUntil).
    await _reloadUi();
  }

  Future<Session> _signIn(
    DebugTestAccount account,
    String targetPhone,
  ) async {
    final email = account.email;
    final passwords = <String>{
      targetPhone,
      targetPhone.replaceFirst(RegExp('^0+'), ''),
    }.where((p) => p.isNotEmpty);

    Object? lastError;
    for (final password in passwords) {
      try {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final session = res.session;
        if (session != null) return session;
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('DEBUG switch v3: signIn attempt failed for $email: $e');
        }
      }
    }

    throw Exception(
      'ورود به اکانت تستی ${account.username} ناموفق بود '
      '(email=$email). اسکریپت seed را اجرا کرده‌اید؟ '
      'lastError=$lastError',
    );
  }

  Future<bool> _isAlreadyOnAccount(String targetPhone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPhone = prefs.getString('last_logged_in_phone_number');
      if (lastPhone != null &&
          PhoneUtils.normalize(lastPhone) == targetPhone) {
        return true;
      }
    } catch (_) {}

    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email != null && email.toLowerCase() == '${targetPhone.replaceFirst(RegExp('^0+'), '')}@gym.ai') {
      return true;
    }
    return false;
  }

  Future<void> _reloadUi() async {
    popRootNavigatorOverlays();
    final reloaded = await MainNavigationScreen.reloadAfterAccountSwitch();
    if (reloaded) return;

    // Shell not mounted (rare) — last resort.
    if (kDebugMode) {
      debugPrint('DEBUG switch v3: shell inactive — enterMainAppAfterAuth');
    }
    enterMainAppAfterAuth();
  }
}
