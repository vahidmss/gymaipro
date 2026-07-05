import 'package:flutter/foundation.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/payment/services/commission_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// وضعیت‌های چرخه عمر درآمد مربی (Escrow)
enum TrainerEarningsEscrowStatus {
  inPlatform,
  editWindow,
  hold,
  withdrawable,
  frozen,
  paidOut;

  String get dbValue {
    switch (this) {
      case TrainerEarningsEscrowStatus.inPlatform:
        return 'in_platform';
      case TrainerEarningsEscrowStatus.editWindow:
        return 'edit_window';
      case TrainerEarningsEscrowStatus.hold:
        return 'hold';
      case TrainerEarningsEscrowStatus.withdrawable:
        return 'withdrawable';
      case TrainerEarningsEscrowStatus.frozen:
        return 'frozen';
      case TrainerEarningsEscrowStatus.paidOut:
        return 'paid_out';
    }
  }

  static TrainerEarningsEscrowStatus? fromDb(String? value) {
    switch (value) {
      case 'in_platform':
        return TrainerEarningsEscrowStatus.inPlatform;
      case 'edit_window':
        return TrainerEarningsEscrowStatus.editWindow;
      case 'hold':
        return TrainerEarningsEscrowStatus.hold;
      case 'withdrawable':
        return TrainerEarningsEscrowStatus.withdrawable;
      case 'frozen':
        return TrainerEarningsEscrowStatus.frozen;
      case 'paid_out':
        return TrainerEarningsEscrowStatus.paidOut;
      default:
        return null;
    }
  }

  String get labelFa {
    switch (this) {
      case TrainerEarningsEscrowStatus.inPlatform:
        return 'در اختیار پلتفرم';
      case TrainerEarningsEscrowStatus.editWindow:
        return 'فرصت ادیت برنامه';
      case TrainerEarningsEscrowStatus.hold:
        return 'در انتظار آزادسازی';
      case TrainerEarningsEscrowStatus.withdrawable:
        return 'قابل برداشت';
      case TrainerEarningsEscrowStatus.frozen:
        return 'مسدود شده';
      case TrainerEarningsEscrowStatus.paidOut:
        return 'پرداخت شده';
    }
  }
}

/// سرویس مرکزی Escrow درآمد مربی
///
/// روال:
/// 1. پرداخت شاگرد → کمیسیون ثبت، سهم مربی در escrow (مربی نمی‌بیند)
/// 2. ارسال برنامه → ۳ روز فرصت ادیت (مربی هنوز نمی‌بیند)
/// 3. پایان فرصت ادیت → hold_days شروع، مربی «در انتظار» می‌بیند
/// 4. پایان hold → قابل برداشت
class TrainerEscrowService {
  factory TrainerEscrowService() => _instance;
  TrainerEscrowService._internal();
  static final TrainerEscrowService _instance = TrainerEscrowService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final CommissionService _commissionService = CommissionService();

  static const int defaultEditWindowDays = 3;

  /// ثبت escrow هنگام پرداخت موفق
  Future<void> recordPaymentEscrow({
    required String subscriptionId,
    required String trainerId,
    required String transactionId,
    required int finalAmountRial,
  }) async {
    try {
      final commission = await _commissionService.calculateCommission(
        finalAmountRial,
      );
      final platformAmount = commission['platform_revenue'] ?? 0;
      final trainerShare = commission['trainer_earnings'] ?? finalAmountRial;

      final settings = await _commissionService.getActiveSettings();
      final commissionPct = settings?.commissionPercentage ?? 0.0;

      try {
        await _commissionService.recordPlatformRevenue(
          transactionId: transactionId,
          subscriptionId: subscriptionId,
          trainerId: trainerId,
          amount: platformAmount,
          commissionPercentage: commissionPct,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'TrainerEscrowService.recordPaymentEscrow: platform_revenue skipped: $e',
          );
        }
      }

      await _client.from('trainer_subscriptions').update({
        'trainer_share_amount': trainerShare,
        'platform_commission_amount': platformAmount,
        'earnings_escrow_status':
            TrainerEarningsEscrowStatus.inPlatform.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', subscriptionId);

      if (kDebugMode) {
        debugPrint(
          'Escrow ثبت شد - اشتراک: $subscriptionId, '
          'کمیسیون: $platformAmount, سهم مربی: $trainerShare',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TrainerEscrowService.recordPaymentEscrow error: $e');
      }
    }
  }

  /// هنگام ارسال برنامه توسط مربی
  Future<void> onProgramSent({
    required String subscriptionId,
    required DateTime sentAt,
    DateTime? editableUntil,
  }) async {
    try {
      final settings = await _commissionService.getActiveSettings();
      final editDays = settings?.editWindowDays ?? defaultEditWindowDays;
      final holdDays = settings?.holdDays ?? 3;

      final editUntil =
          editableUntil ?? sentAt.add(Duration(days: editDays));
      final holdStart = editUntil;
      final withdrawableAt = holdStart.add(Duration(days: holdDays));

      await _client.from('trainer_subscriptions').update({
        'program_registration_date': sentAt.toIso8601String(),
        'program_edit_until': editUntil.toIso8601String(),
        'earnings_hold_start_at': holdStart.toIso8601String(),
        'earnings_withdrawable_at': withdrawableAt.toIso8601String(),
        'earnings_escrow_status':
            TrainerEarningsEscrowStatus.editWindow.dbValue,
        'program_status': 'in_progress',
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', subscriptionId);

      await refreshEscrowStatuses(subscriptionId: subscriptionId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TrainerEscrowService.onProgramSent error: $e');
      }
    }
  }

  /// به‌روزرسانی وضعیت escrow بر اساس زمان فعلی
  Future<void> refreshEscrowStatuses({String? subscriptionId}) async {
    try {
      var query = _client
          .from('trainer_subscriptions')
          .select(
            'id, earnings_frozen, earnings_early_released, '
            'program_registration_date, program_edit_until, '
            'earnings_hold_start_at, earnings_withdrawable_at, '
            'earnings_escrow_status',
          );

      if (subscriptionId != null) {
        query = query.eq('id', subscriptionId);
      } else {
        query = query.not('trainer_share_amount', 'is', null);
      }

      final rows = await query;
      final now = DateTime.now();

      for (final raw in (rows as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final subId = row['id'] as String;
        if (row['earnings_escrow_status'] == 'paid_out') continue;

        final isFrozen = row['earnings_frozen'] == true;
        if (isFrozen) {
          if (row['earnings_escrow_status'] != 'frozen') {
            await _client.from('trainer_subscriptions').update({
              'earnings_escrow_status': 'frozen',
              'updated_at': now.toIso8601String(),
            }).eq('id', subId);
          }
          continue;
        }

        final earlyReleased = row['earnings_early_released'] == true;
        if (earlyReleased) {
          if (row['earnings_escrow_status'] != 'withdrawable') {
            await _client.from('trainer_subscriptions').update({
              'earnings_escrow_status': 'withdrawable',
              'updated_at': now.toIso8601String(),
            }).eq('id', subId);
          }
          continue;
        }

        final regDateStr = row['program_registration_date'] as String?;
        if (regDateStr == null) {
          if (row['earnings_escrow_status'] != 'in_platform') {
            await _client.from('trainer_subscriptions').update({
              'earnings_escrow_status': 'in_platform',
              'updated_at': now.toIso8601String(),
            }).eq('id', subId);
          }
          continue;
        }

        final editUntil = _parseDate(row['program_edit_until'] as String?) ??
            _parseDate(regDateStr)?.add(const Duration(days: 3));
        final holdStart =
            _parseDate(row['earnings_hold_start_at'] as String?) ?? editUntil;
        final withdrawableAt =
            _parseDate(row['earnings_withdrawable_at'] as String?) ??
            holdStart?.add(const Duration(days: 3));

        String newStatus;
        if (editUntil != null && now.isBefore(editUntil)) {
          newStatus = TrainerEarningsEscrowStatus.editWindow.dbValue;
        } else if (withdrawableAt != null && now.isBefore(withdrawableAt)) {
          newStatus = TrainerEarningsEscrowStatus.hold.dbValue;
        } else {
          newStatus = TrainerEarningsEscrowStatus.withdrawable.dbValue;
        }

        if (row['earnings_escrow_status'] != newStatus) {
          await _client.from('trainer_subscriptions').update({
            'earnings_escrow_status': newStatus,
            'updated_at': now.toIso8601String(),
          }).eq('id', subId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TrainerEscrowService.refreshEscrowStatuses error: $e');
      }
    }
  }

  /// موجودی قابل مشاهده برای مربی (فقط hold + withdrawable)
  Future<Map<String, dynamic>> getTrainerVisibleBalances(
    String trainerId,
  ) async {
    await refreshEscrowStatuses();

    final rawRows = await _client
        .from('trainer_subscriptions')
        .select(
          'id, trainer_share_amount, earnings_escrow_status, '
          'earnings_withdrawable_at, earnings_hold_start_at, '
          'program_edit_until, earnings_frozen, payment_transaction_id, '
          'final_amount, user_id, service_type, created_at',
        )
        .eq('trainer_id', trainerId)
        .not('trainer_share_amount', 'is', null)
        .order('created_at', ascending: false);

    final rows = (rawRows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
    final profilesById = await _loadProfilesForSubscriptionRows(rows);
    _attachBuyerProfiles(rows, profilesById);

    final txById = await _loadTransactions(
      (rows as List)
          .map((r) => r['payment_transaction_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList(),
    );

    int onHold = 0;
    int withdrawable = 0;
    int totalVisible = 0;
    final visibleEarnings = <Map<String, dynamic>>[];

    for (final row in rows) {
      final status = row['earnings_escrow_status'] as String? ?? 'in_platform';

      // مربی فقط hold و withdrawable را می‌بیند
      if (status == 'in_platform' ||
          status == 'edit_window' ||
          status == 'paid_out') {
        continue;
      }

      final share = _resolveTrainerShare(row, txById);
      if (share <= 0) continue;

      if (status == 'frozen') {
        onHold += share;
        totalVisible += share;
        visibleEarnings.add(_mapEarningRow(row, share, status));
        continue;
      }

      if (status == 'withdrawable') {
        withdrawable += share;
        totalVisible += share;
      } else if (status == 'hold') {
        onHold += share;
        totalVisible += share;
      }

      visibleEarnings.add(_mapEarningRow(row, share, status));
    }

    // کسر برداشت‌های در جریان
    final pendingPayouts = await _getPendingPayoutTotal(trainerId);
    withdrawable = (withdrawable - pendingPayouts).clamp(0, withdrawable);

    return {
      'onHold': onHold,
      'withdrawable': withdrawable,
      'total': totalVisible,
      'visibleEarnings': visibleEarnings,
    };
  }

  /// محاسبه مبلغ قابل برداشت
  Future<int> getWithdrawableAmount(String trainerId) async {
    final balances = await getTrainerVisibleBalances(trainerId);
    return balances['withdrawable'] as int? ?? 0;
  }

  /// آیا مربی مجاز به درخواست برداشت است؟
  Future<Map<String, dynamic>> checkPayoutAllowed(String trainerId) async {
    final wallet = await _client
        .from('wallets')
        .select('payout_blocked, payout_blocked_reason')
        .eq('user_id', trainerId)
        .maybeSingle();

    if (wallet != null && wallet['payout_blocked'] == true) {
      return {
        'allowed': false,
        'reason':
            wallet['payout_blocked_reason'] as String? ??
            'برداشت توسط ادمین مسدود شده است',
      };
    }
    return {'allowed': true};
  }

  // ==================== ادمین ====================

  Future<Map<String, dynamic>> getAdminEscrowOverview({
    DateTime? startDate,
    DateTime? endDate,
    String? trainerId,
    String? statusFilter,
  }) async {
    await refreshEscrowStatuses();

    var query = _client.from('trainer_subscriptions').select('''
          id, trainer_id, user_id, service_type, final_amount,
          trainer_share_amount, platform_commission_amount,
          earnings_escrow_status, earnings_frozen, earnings_frozen_reason,
          earnings_early_released, earnings_early_released_at,
          program_registration_date, program_edit_until,
          earnings_hold_start_at, earnings_withdrawable_at,
          payment_transaction_id, created_at, purchase_date
        ''');

    if (trainerId != null && trainerId.isNotEmpty) {
      query = query.eq('trainer_id', trainerId);
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('earnings_escrow_status', statusFilter);
    }
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    final rawRows = await query
        .not('trainer_share_amount', 'is', null)
        .order('created_at', ascending: false);

    final rows = (rawRows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
    final profilesById = await _loadProfilesForSubscriptionRows(rows);
    _attachTrainerAndBuyerProfiles(rows, profilesById);

    int totalGross = 0;
    int totalCommission = 0;
    int totalTrainerShare = 0;
    int inPlatform = 0;
    int inEditWindow = 0;
    int inHold = 0;
    int withdrawable = 0;
    int frozen = 0;

    final items = <Map<String, dynamic>>[];

    for (final row in rows) {
      final gross = (row['final_amount'] as num?)?.toInt() ?? 0;
      final commission = (row['platform_commission_amount'] as num?)?.toInt() ?? 0;
      final share = (row['trainer_share_amount'] as num?)?.toInt() ?? 0;
      final status = row['earnings_escrow_status'] as String? ?? 'in_platform';

      totalGross += gross;
      totalCommission += commission;
      totalTrainerShare += share;

      switch (status) {
        case 'in_platform':
          inPlatform += share;
        case 'edit_window':
          inEditWindow += share;
        case 'hold':
          inHold += share;
        case 'withdrawable':
          withdrawable += share;
        case 'frozen':
          frozen += share;
      }

      items.add(Map<String, dynamic>.from(row));
    }

    return {
      'items': items,
      'summary': {
        'total_gross': totalGross,
        'total_commission': totalCommission,
        'total_trainer_share': totalTrainerShare,
        'in_platform': inPlatform,
        'in_edit_window': inEditWindow,
        'in_hold': inHold,
        'withdrawable': withdrawable,
        'frozen': frozen,
        'count': items.length,
      },
    };
  }

  Future<Map<String, dynamic>> freezeEarnings({
    required String subscriptionId,
    required String reason,
  }) async {
    return _adminAction(
      subscriptionId: subscriptionId,
      action: 'freeze',
      reason: reason,
      update: {
        'earnings_frozen': true,
        'earnings_frozen_reason': reason,
        'earnings_escrow_status': 'frozen',
      },
    );
  }

  Future<Map<String, dynamic>> unfreezeEarnings({
    required String subscriptionId,
  }) async {
    final result = await _adminAction(
      subscriptionId: subscriptionId,
      action: 'unfreeze',
      update: {
        'earnings_frozen': false,
        'earnings_frozen_reason': null,
      },
    );
    if (result['success'] == true) {
      await refreshEscrowStatuses(subscriptionId: subscriptionId);
    }
    return result;
  }

  Future<Map<String, dynamic>> earlyReleaseEarnings({
    required String subscriptionId,
    String? reason,
  }) async {
    final now = DateTime.now();
    return _adminAction(
      subscriptionId: subscriptionId,
      action: 'early_release',
      reason: reason,
      update: {
        'earnings_early_released': true,
        'earnings_early_released_at': now.toIso8601String(),
        'earnings_early_released_by': _client.auth.currentUser?.id,
        'earnings_withdrawable_at': now.toIso8601String(),
        'earnings_escrow_status': 'withdrawable',
        'earnings_frozen': false,
      },
    );
  }

  Future<Map<String, dynamic>> blockTrainerPayout({
    required String trainerId,
    required String reason,
  }) async {
    try {
      final isAdmin = await AdminService().isAdmin();
      if (!isAdmin) {
        return {'success': false, 'error': 'دسترسی غیرمجاز'};
      }

      await _client.from('wallets').upsert({
        'user_id': trainerId,
        'payout_blocked': true,
        'payout_blocked_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      await _logAdminAction(
        subscriptionId: null,
        trainerId: trainerId,
        action: 'block_payout',
        reason: reason,
      );

      return {'success': true, 'message': 'برداشت مربی مسدود شد'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  Future<Map<String, dynamic>> unblockTrainerPayout({
    required String trainerId,
  }) async {
    try {
      final isAdmin = await AdminService().isAdmin();
      if (!isAdmin) {
        return {'success': false, 'error': 'دسترسی غیرمجاز'};
      }

      await _client.from('wallets').update({
        'payout_blocked': false,
        'payout_blocked_reason': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', trainerId);

      await _logAdminAction(
        subscriptionId: null,
        trainerId: trainerId,
        action: 'unblock_payout',
      );

      return {'success': true, 'message': 'مسدودیت برداشت برداشته شد'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  Future<Map<String, dynamic>> _adminAction({
    required String subscriptionId,
    required String action,
    required Map<String, dynamic> update,
    String? reason,
  }) async {
    try {
      final isAdmin = await AdminService().isAdmin();
      if (!isAdmin) {
        return {'success': false, 'error': 'دسترسی غیرمجاز'};
      }

      final sub = await _client
          .from('trainer_subscriptions')
          .select('trainer_id')
          .eq('id', subscriptionId)
          .maybeSingle();

      if (sub == null) {
        return {'success': false, 'error': 'اشتراک یافت نشد'};
      }

      await _client.from('trainer_subscriptions').update({
        ...update,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', subscriptionId);

      await _logAdminAction(
        subscriptionId: subscriptionId,
        trainerId: sub['trainer_id'] as String,
        action: action,
        reason: reason,
      );

      return {'success': true, 'message': 'عملیات با موفقیت انجام شد'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  Future<void> _logAdminAction({
    required String? subscriptionId,
    required String trainerId,
    required String action,
    String? reason,
  }) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      if (adminId == null) return;

      await _client.from('trainer_escrow_admin_actions').insert({
        if (subscriptionId != null) 'subscription_id': subscriptionId,
        'trainer_id': trainerId,
        'action': action,
        'reason': reason,
        'admin_id': adminId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TrainerEscrowService._logAdminAction error: $e');
      }
    }
  }

  int _resolveTrainerShare(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> txById,
  ) {
    final stored = (row['trainer_share_amount'] as num?)?.toInt();
    if (stored != null && stored > 0) return stored;

    final rawAmount = (row['final_amount'] as num?)?.toInt() ?? 0;
    final txId = row['payment_transaction_id'] as String?;
    final tx = txId != null ? txById[txId] : null;
    return _normalizeToRial(rawAmount, tx: tx);
  }

  Map<String, dynamic> _mapEarningRow(
    Map<String, dynamic> row,
    int share,
    String status,
  ) {
    return {
      'id': row['id'],
      'amount': share,
      'service_type': row['service_type'],
      'status': status,
      'status_label': TrainerEarningsEscrowStatus.fromDb(status)?.labelFa ??
          status,
      'is_available': status == 'withdrawable',
      'is_frozen': status == 'frozen' || row['earnings_frozen'] == true,
      'hold_until': row['earnings_withdrawable_at'],
      'hold_start': row['earnings_hold_start_at'],
      'created_at': row['created_at'],
      'buyer': row['buyer'],
    };
  }

  Future<int> _getPendingPayoutTotal(String trainerId) async {
    try {
      final reqs = await _client
          .from('payout_requests')
          .select('amount, final_amount')
          .eq('trainer_id', trainerId)
          .or('status.eq.pending,status.eq.approved,status.eq.completed');

      int total = 0;
      for (final req in (reqs as List)) {
        total += (req['final_amount'] as int?) ?? (req['amount'] as int?) ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadTransactions(
    List<String> txIds,
  ) async {
    final txById = <String, Map<String, dynamic>>{};
    if (txIds.isEmpty) return txById;

    try {
      final orExpr = txIds.map((id) => 'id.eq.$id').join(',');
      final txRows = await _client
          .from('payment_transactions')
          .select('id, amount, final_amount, payment_method, gateway')
          .or(orExpr);
      for (final t in (txRows as List)) {
        final id = t['id'] as String?;
        if (id != null) {
          txById[id] = Map<String, dynamic>.from(t as Map);
        }
      }
    } catch (_) {}
    return txById;
  }

  int _normalizeToRial(int raw, {Map<String, dynamic>? tx}) {
    if (tx != null) {
      final txFinal = tx['final_amount'] as int?;
      final txAmt = tx['amount'] as int?;
      final pm = (tx['payment_method'] as String?)?.toLowerCase();
      final gw = (tx['gateway'] as String?)?.toLowerCase();
      final v = txFinal ?? txAmt;
      if (v != null) {
        final isDirect =
            pm == 'direct' || gw == 'zibal' || gw == 'zarinpal';
        return isDirect ? v : (v * 10);
      }
    }
    return raw % 10 == 0 ? raw : (raw * 10);
  }

  DateTime? _parseDate(String? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadProfilesForSubscriptionRows(
    List<Map<String, dynamic>> rows, {
    String columns = 'id, username, first_name, last_name, avatar_url',
  }) async {
    final ids = <String>{};
    for (final row in rows) {
      for (final key in ['trainer_id', 'user_id']) {
        final id = row[key] as String?;
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    if (ids.isEmpty) return {};
    return ProfileRepository.instance.fetchProfilesByIdsMap(
      ids.toList(),
      columns: columns,
    );
  }

  void _attachTrainerAndBuyerProfiles(
    List<Map<String, dynamic>> rows,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    for (final row in rows) {
      final trainerId = row['trainer_id'] as String?;
      final userId = row['user_id'] as String?;
      row['trainer'] = trainerId != null ? profilesById[trainerId] : null;
      row['buyer'] = userId != null ? profilesById[userId] : null;
    }
  }

  void _attachBuyerProfiles(
    List<Map<String, dynamic>> rows,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    for (final row in rows) {
      final userId = row['user_id'] as String?;
      row['buyer'] = userId != null ? profilesById[userId] : null;
    }
  }
}
