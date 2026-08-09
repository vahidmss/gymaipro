import 'package:flutter/foundation.dart';

/// Fixed debug-only test accounts seeded by [sql/seed_debug_test_accounts.sql].
///
/// Never used in release builds — all call sites must gate on [kDebugMode].
class DebugTestAccount {
  const DebugTestAccount({
    required this.phone,
    required this.username,
    required this.role,
    required this.labelFa,
  });

  final String phone;
  final String username;
  final String role;
  final String labelFa;

  String get email {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final local = digits.replaceFirst(RegExp('^0+'), '');
    return '$local@gym.ai';
  }
}

/// Canonical list matching the SQL seed script.
abstract final class DebugTestAccounts {
  static const athlete = DebugTestAccount(
    phone: '09129999001',
    username: 'debug_athlete',
    role: 'athlete',
    labelFa: 'ورزشکار',
  );

  static const trainer = DebugTestAccount(
    phone: '09129999002',
    username: 'debug_trainer',
    role: 'trainer',
    labelFa: 'مربی',
  );

  static const admin = DebugTestAccount(
    phone: '09129999003',
    username: 'debug_admin',
    role: 'admin',
    labelFa: 'ادمین',
  );

  static const List<DebugTestAccount> all = <DebugTestAccount>[
    athlete,
    trainer,
    admin,
  ];

  /// Returns null outside debug builds.
  static List<DebugTestAccount>? get ifDebug {
    if (!kDebugMode) return null;
    return all;
  }
}
