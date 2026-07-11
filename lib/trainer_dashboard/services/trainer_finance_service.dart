import 'package:gymaipro/payment/services/commission_service.dart';
import 'package:gymaipro/payment/services/trainer_escrow_service.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerFinanceService {
  factory TrainerFinanceService() => _instance;
  TrainerFinanceService._internal();
  static final TrainerFinanceService _instance =
      TrainerFinanceService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final TrainerEscrowService _escrowService = TrainerEscrowService();
  final CommissionService _commissionService = CommissionService();

  static const _paidStatuses = {'paid', 'active', 'completed'};

  /// موجودی قابل مشاهده مربی (فقط پس از ارسال برنامه + پایان فرصت ادیت)
  Future<Map<String, dynamic>> getTrainerBalances(String trainerId) async {
    try {
      final visible = await _escrowService.getTrainerVisibleBalances(trainerId);
      return {
        'available': visible['withdrawable'] as int? ?? 0,
        'onHold': visible['onHold'] as int? ?? 0,
        'frozen': visible['frozen'] as int? ?? 0,
        'total': visible['total'] as int? ?? 0,
        'withdrawable': visible['withdrawable'] as int? ?? 0,
        'pendingProgram': visible['pendingProgram'] as int? ?? 0,
        'pendingProgramCount': visible['pendingProgramCount'] as int? ?? 0,
        'inEditWindow': visible['inEditWindow'] as int? ?? 0,
        'inEditWindowCount': visible['inEditWindowCount'] as int? ?? 0,
        'pendingPayouts': visible['pendingPayouts'] as int? ?? 0,
        'holdDays': visible['holdDays'] as int? ?? 3,
        'editWindowDays': visible['editWindowDays'] as int? ?? 3,
        'commissionPercentage':
            (visible['commissionPercentage'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (_) {
      return _emptyBalances();
    }
  }

  Map<String, dynamic> _emptyBalances() => {
        'available': 0,
        'onHold': 0,
        'frozen': 0,
        'total': 0,
        'withdrawable': 0,
        'pendingProgram': 0,
        'pendingProgramCount': 0,
        'inEditWindow': 0,
        'inEditWindowCount': 0,
        'pendingPayouts': 0,
        'holdDays': 3,
        'editWindowDays': 3,
        'commissionPercentage': 0.0,
      };

  /// نمای کامل مالی برای تب مالی مربی
  Future<Map<String, dynamic>> getTrainerFinanceOverview(
    String trainerId,
  ) async {
    try {
      final visible = await _escrowService.getTrainerVisibleBalances(trainerId);
      final stats = await getTrainerStats(trainerId);

      final allEarnings =
          (visible['allEarnings'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      return {
        ...getTrainerBalancesFromSnapshot(visible),
        'lifetimeNetEarnings': stats['netEarnings'] as int? ?? 0,
        'lifetimeRevenue': stats['totalRevenue'] as int? ?? 0,
        'lifetimeCommission': stats['totalCommission'] as int? ?? 0,
        'monthly': Map<String, int>.from(
          (stats['monthly'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
              ) ??
              {},
        ),
        'monthlySubscriptions': Map<String, int>.from(
          (stats['monthlySubscriptions'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
              ) ??
              {},
        ),
        'allEarnings': allEarnings,
      };
    } catch (_) {
      return {
        ..._emptyBalances(),
        'lifetimeNetEarnings': 0,
        'lifetimeRevenue': 0,
        'lifetimeCommission': 0,
        'monthly': <String, int>{},
        'monthlySubscriptions': <String, int>{},
        'allEarnings': <Map<String, dynamic>>[],
      };
    }
  }

  Map<String, dynamic> getTrainerBalancesFromSnapshot(
    Map<String, dynamic> visible,
  ) {
    return {
      'available': visible['withdrawable'] as int? ?? 0,
      'onHold': visible['onHold'] as int? ?? 0,
      'frozen': visible['frozen'] as int? ?? 0,
      'total': visible['total'] as int? ?? 0,
      'withdrawable': visible['withdrawable'] as int? ?? 0,
      'pendingProgram': visible['pendingProgram'] as int? ?? 0,
      'pendingProgramCount': visible['pendingProgramCount'] as int? ?? 0,
      'inEditWindow': visible['inEditWindow'] as int? ?? 0,
      'inEditWindowCount': visible['inEditWindowCount'] as int? ?? 0,
      'pendingPayouts': visible['pendingPayouts'] as int? ?? 0,
      'holdDays': visible['holdDays'] as int? ?? 3,
      'editWindowDays': visible['editWindowDays'] as int? ?? 3,
      'commissionPercentage':
          (visible['commissionPercentage'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// درآمدهای اخیر قابل مشاهده برای مربی
  Future<List<Map<String, dynamic>>> getRecentEarnings(
    String trainerId, {
    int limit = 25,
  }) async {
    try {
      final visible = await _escrowService.getTrainerVisibleBalances(trainerId);
      final list =
          (visible['visibleEarnings'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  /// آمار کامل مربی
  Future<Map<String, dynamic>> getTrainerStats(String trainerId) async {
    try {
      final now = DateTime.now();
      final visible = await _escrowService.getTrainerVisibleBalances(trainerId);
      final commissionSettings = await _commissionService.getActiveSettings();
      final commissionPct = commissionSettings?.commissionPercentage ?? 0.0;

      final subscriptionsResponse = await _client
          .from('trainer_subscriptions')
          .select('''
            id,
            user_id,
            service_type,
            status,
            final_amount,
            trainer_share_amount,
            platform_commission_amount,
            program_registration_date,
            program_response_time,
            program_status,
            earnings_escrow_status,
            created_at,
            purchase_date,
            expiry_date,
            payment_transaction_id
          ''')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      final subscriptions = (subscriptionsResponse as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

      final platformRevenueBySub = await _loadPlatformRevenueBySubscription(
        subscriptions,
      );
      final txById = await _loadTransactions(subscriptions);

      final uniqueClientIds = <String>{};
      final activeClientIds = <String>{};

      for (final sub in subscriptions) {
        final userId = sub['user_id'] as String?;
        if (userId == null) continue;

        if (_isPaidSubscription(sub)) {
          uniqueClientIds.add(userId);
        }
        if (_isActiveSubscription(sub, now)) {
          activeClientIds.add(userId);
        }
      }

      var totalCommission = 0;
      var totalRevenue = 0;
      var netEarnings = 0;
      final byService = <String, int>{};
      final byServiceCommission = <String, int>{};
      final byServiceRevenue = <String, int>{};
      final byServiceCount = <String, int>{};
      final monthly = <String, int>{};
      final monthlyRevenue = <String, int>{};
      final monthlyCommission = <String, int>{};
      final monthlySubscriptions = <String, int>{};

      var subscriptionsWithProgram = 0;
      var subscriptionsWithoutProgram = 0;
      var activeSubscriptions = 0;
      var completedSubscriptions = 0;
      var delayedSubscriptions = 0;
      var totalResponseTimeSeconds = 0;
      var programsWithResponseTime = 0;
      var paidSubscriptions = 0;

      for (final sub in subscriptions) {
        final programStatus =
            (sub['program_status'] as String?) ?? 'not_started';
        final registrationDateStr = sub['program_registration_date'] as String?;
        final isPaid = _isPaidSubscription(sub);

        if (_isActiveSubscription(sub, now)) {
          activeSubscriptions++;
        }
        if (programStatus == 'completed') {
          completedSubscriptions++;
        }
        if (programStatus == 'delayed') {
          delayedSubscriptions++;
        }

        if (!isPaid) continue;

        paidSubscriptions++;

        final txId = sub['payment_transaction_id'] as String?;
        final tx = txId != null ? txById[txId] : null;
        final amountInRial = _amountInRial(
          (sub['final_amount'] as num?)?.toInt() ?? 0,
          tx: tx,
        );
        final platformRevenue = _resolvePlatformCommission(
          sub: sub,
          amountInRial: amountInRial,
          platformRevenueBySub: platformRevenueBySub,
          commissionPct: commissionPct,
        );
        final trainerEarning = _resolveTrainerShare(
          sub: sub,
          amountInRial: amountInRial,
          platformRevenue: platformRevenue,
        );

        totalRevenue += amountInRial;
        totalCommission += platformRevenue;
        netEarnings += trainerEarning;

        if (registrationDateStr != null) {
          subscriptionsWithProgram++;
          final responseTime = sub['program_response_time'] as int?;
          if (responseTime != null && responseTime > 0) {
            totalResponseTimeSeconds += responseTime;
            programsWithResponseTime++;
          }
        } else {
          subscriptionsWithoutProgram++;
        }

        final service = (sub['service_type'] as String?) ?? 'unknown';
        byService[service] = (byService[service] ?? 0) + trainerEarning;
        byServiceRevenue[service] =
            (byServiceRevenue[service] ?? 0) + amountInRial;
        byServiceCommission[service] =
            (byServiceCommission[service] ?? 0) + platformRevenue;
        byServiceCount[service] = (byServiceCount[service] ?? 0) + 1;

        final monthAnchor = _resolvePurchaseDate(sub);
        if (monthAnchor != null) {
          final key = _jalaliMonthKey(monthAnchor);
          monthly[key] = (monthly[key] ?? 0) + trainerEarning;
          monthlyRevenue[key] = (monthlyRevenue[key] ?? 0) + amountInRial;
          monthlyCommission[key] =
              (monthlyCommission[key] ?? 0) + platformRevenue;
          monthlySubscriptions[key] = (monthlySubscriptions[key] ?? 0) + 1;
        }
      }

      final withdrawable = visible['withdrawable'] as int? ?? 0;
      final onHold = visible['onHold'] as int? ?? 0;

      final responseRate = paidSubscriptions > 0
          ? (subscriptionsWithProgram / paidSubscriptions * 100)
          : 0.0;
      final averageResponseTimeHours = programsWithResponseTime > 0
          ? (totalResponseTimeSeconds / programsWithResponseTime / 3600)
          : 0.0;

      return {
        'totalRevenue': totalRevenue,
        'totalCommission': totalCommission,
        'netEarnings': netEarnings,
        'withdrawable': withdrawable,
        'onHold': onHold,
        'commissionPercentage': commissionPct,
        'byService': byService,
        'byServiceRevenue': byServiceRevenue,
        'byServiceCommission': byServiceCommission,
        'byServiceCount': byServiceCount,
        'monthly': monthly,
        'monthlyRevenue': monthlyRevenue,
        'monthlyCommission': monthlyCommission,
        'monthlySubscriptions': monthlySubscriptions,
        'totalClients': uniqueClientIds.length,
        'activeClients': activeClientIds.length,
        'totalSubscriptions': subscriptions.length,
        'paidSubscriptions': paidSubscriptions,
        'activeSubscriptions': activeSubscriptions,
        'subscriptionsWithProgram': subscriptionsWithProgram,
        'subscriptionsWithoutProgram': subscriptionsWithoutProgram,
        'completedSubscriptions': completedSubscriptions,
        'delayedSubscriptions': delayedSubscriptions,
        'responseRate': responseRate,
        'averageResponseTimeHours': averageResponseTimeHours,
        'averageResponseTimeDays': averageResponseTimeHours / 24,
        'onTimeDeliveryRate': subscriptionsWithProgram > 0
            ? ((subscriptionsWithProgram - delayedSubscriptions) /
                  subscriptionsWithProgram *
                  100)
            : 0.0,
      };
    } catch (_) {
      return _emptyStats();
    }
  }

  Map<String, dynamic> _emptyStats() {
    return {
      'totalRevenue': 0,
      'totalCommission': 0,
      'netEarnings': 0,
      'withdrawable': 0,
      'onHold': 0,
      'commissionPercentage': 0.0,
      'byService': <String, int>{},
      'byServiceRevenue': <String, int>{},
      'byServiceCommission': <String, int>{},
      'byServiceCount': <String, int>{},
      'monthly': <String, int>{},
      'monthlyRevenue': <String, int>{},
      'monthlyCommission': <String, int>{},
      'monthlySubscriptions': <String, int>{},
      'totalClients': 0,
      'activeClients': 0,
      'totalSubscriptions': 0,
      'paidSubscriptions': 0,
      'activeSubscriptions': 0,
      'subscriptionsWithProgram': 0,
      'subscriptionsWithoutProgram': 0,
      'completedSubscriptions': 0,
      'delayedSubscriptions': 0,
      'responseRate': 0.0,
      'averageResponseTimeHours': 0.0,
      'averageResponseTimeDays': 0.0,
      'onTimeDeliveryRate': 0.0,
    };
  }

  bool _isPaidSubscription(Map<String, dynamic> sub) {
    final status = (sub['status'] as String?) ?? 'pending';
    if (!_paidStatuses.contains(status)) return false;
    final txId = sub['payment_transaction_id'] as String?;
    return txId != null && txId.isNotEmpty;
  }

  bool _isActiveSubscription(Map<String, dynamic> sub, DateTime now) {
    if (!_isPaidSubscription(sub)) return false;
    final expiryDateStr = sub['expiry_date'] as String?;
    if (expiryDateStr == null) return true;
    try {
      return now.isBefore(DateTime.parse(expiryDateStr));
    } catch (_) {
      return false;
    }
  }

  int _amountInRial(int rawAmount, {Map<String, dynamic>? tx}) {
    if (rawAmount <= 0) return 0;

    if (tx != null) {
      final txFinal = (tx['final_amount'] as num?)?.toInt();
      final txAmount = (tx['amount'] as num?)?.toInt();
      final value = txFinal ?? txAmount;
      if (value != null && value > 0) return value;
    }

    // جریان فعلی پرداخت: مبالغ در ریال ذخیره می‌شوند.
    return rawAmount;
  }

  int _resolvePlatformCommission({
    required Map<String, dynamic> sub,
    required int amountInRial,
    required Map<String, int> platformRevenueBySub,
    required double commissionPct,
  }) {
    final stored = (sub['platform_commission_amount'] as num?)?.toInt();
    if (stored != null && stored > 0) return stored;

    final subId = sub['id'] as String?;
    if (subId != null) {
      final fromLedger = platformRevenueBySub[subId];
      if (fromLedger != null && fromLedger > 0) return fromLedger;
    }

    if (amountInRial <= 0) return 0;
    return (amountInRial * commissionPct / 100).round();
  }

  int _resolveTrainerShare({
    required Map<String, dynamic> sub,
    required int amountInRial,
    required int platformRevenue,
  }) {
    final stored = (sub['trainer_share_amount'] as num?)?.toInt();
    if (stored != null && stored > 0) return stored;
    return (amountInRial - platformRevenue).clamp(0, amountInRial);
  }

  DateTime? _resolvePurchaseDate(Map<String, dynamic> sub) {
    for (final key in ['purchase_date', 'created_at']) {
      final raw = sub[key] as String?;
      if (raw == null) continue;
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return null;
  }

  String _jalaliMonthKey(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    return '${j.year}-${j.month.toString().padLeft(2, '0')}';
  }

  Future<Map<String, int>> _loadPlatformRevenueBySubscription(
    List<Map<String, dynamic>> subscriptions,
  ) async {
    final ids = subscriptions
        .map((s) => s['id'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return {};

    try {
      final orExpr = ids.map((id) => 'subscription_id.eq.$id').join(',');
      final rows = await _client
          .from('platform_revenue')
          .select('subscription_id, amount')
          .or(orExpr);

      final map = <String, int>{};
      for (final row in (rows as List)) {
        final subId = row['subscription_id'] as String?;
        final amount = (row['amount'] as num?)?.toInt() ?? 0;
        if (subId != null && amount > 0) {
          map[subId] = amount;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadTransactions(
    List<Map<String, dynamic>> subscriptions,
  ) async {
    final txIds = subscriptions
        .map((s) => s['payment_transaction_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    if (txIds.isEmpty) return {};

    try {
      final orExpr = txIds.map((id) => 'id.eq.$id').join(',');
      final rows = await _client
          .from('payment_transactions')
          .select('id, amount, final_amount, payment_method, gateway, status')
          .or(orExpr);

      final map = <String, Map<String, dynamic>>{};
      for (final row in (rows as List)) {
        final id = row['id'] as String?;
        if (id != null) {
          map[id] = Map<String, dynamic>.from(row as Map);
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
