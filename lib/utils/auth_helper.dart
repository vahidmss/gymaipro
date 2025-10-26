import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthHelper {
  /// فقط کاربر واقعی Supabase؛ اگر نباشد null
  static String? get currentUserIdSync {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  static Future<String?> getCurrentUserId() async {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  static bool get isLoggedInSync {
    return Supabase.instance.client.auth.currentUser != null;
  }

  static Future<bool> isUserLoggedIn() async {
    return Supabase.instance.client.auth.currentUser != null;
  }

  static User? getRealUser() {
    return Supabase.instance.client.auth.currentUser;
  }

  /// لیسن به تغییرات وضعیت احراز هویت (لاگین/لاگ‌اوت/ریفِرش)
  static StreamSubscription<AuthState> onAuthChange(
    void Function(AuthState state) handler,
  ) {
    return Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      handler(data);
    });
  }
}
