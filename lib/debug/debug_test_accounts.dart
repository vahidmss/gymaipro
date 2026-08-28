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
    labelFa: 'ورزشکار ۱',
  );

  static const athlete2 = DebugTestAccount(
    phone: '09129999004',
    username: 'debug_athlete_2',
    role: 'athlete',
    labelFa: 'ورزشکار ۲',
  );

  static const athlete3 = DebugTestAccount(
    phone: '09129999005',
    username: 'debug_athlete_3',
    role: 'athlete',
    labelFa: 'ورزشکار ۳',
  );

  static const athlete4 = DebugTestAccount(
    phone: '09129999006',
    username: 'debug_athlete_4',
    role: 'athlete',
    labelFa: 'ورزشکار ۴',
  );

  static const trainer = DebugTestAccount(
    phone: '09129999002',
    username: 'debug_trainer',
    role: 'trainer',
    labelFa: 'مربی ۱',
  );

  static const trainer2 = DebugTestAccount(
    phone: '09129999007',
    username: 'debug_trainer_2',
    role: 'trainer',
    labelFa: 'مربی ۲',
  );

  static const trainer3 = DebugTestAccount(
    phone: '09129999008',
    username: 'debug_trainer_3',
    role: 'trainer',
    labelFa: 'مربی ۳',
  );

  static const trainer4 = DebugTestAccount(
    phone: '09129999009',
    username: 'debug_trainer_4',
    role: 'trainer',
    labelFa: 'مربی ۴',
  );

  static const admin = DebugTestAccount(
    phone: '09129999003',
    username: 'debug_admin',
    role: 'admin',
    labelFa: 'ادمین',
  );

  static const List<DebugTestAccount> athletes = <DebugTestAccount>[
    athlete,
    athlete2,
    athlete3,
    athlete4,
  ];

  static const List<DebugTestAccount> trainers = <DebugTestAccount>[
    trainer,
    trainer2,
    trainer3,
    trainer4,
  ];

  static const List<DebugTestAccount> all = <DebugTestAccount>[
    ...athletes,
    ...trainers,
    admin,
  ];

  /// Returns null outside debug builds.
  static List<DebugTestAccount>? get ifDebug {
    if (!kDebugMode) return null;
    return all;
  }
}
