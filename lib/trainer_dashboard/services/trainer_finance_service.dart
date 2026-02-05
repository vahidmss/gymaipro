import 'package:gymaipro/payment/services/payout_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerFinanceService {
  factory TrainerFinanceService() => _instance;
  TrainerFinanceService._internal();
  static final TrainerFinanceService _instance =
      TrainerFinanceService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final PayoutService _payoutService = PayoutService();

  // Compute trainer balances: available vs onHold vs withdrawable
  // Funds become available 2 days after program_registration_date
  // Funds become withdrawable 3 days after program_registration_date
  Future<Map<String, dynamic>> getTrainerBalances(String trainerId) async {
    int available = 0;
    int onHold = 0;
    int total = 0;
    int withdrawable = 0;

    try {
      // All purchases for this trainer
      final rows = await _client
          .from('trainer_subscriptions')
          .select(
            'final_amount, program_registration_date, payment_transaction_id',
          )
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      final list = rows as List;

      // Load related transactions to normalize amounts (wallet/direct)
      final txIds = list
          .map((r) => r['payment_transaction_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final Map<String, Map<String, dynamic>> txById = {};
      if (txIds.isNotEmpty) {
        try {
          final orExpr = txIds.map((id) => 'id.eq.$id').join(',');
          final txRows = await _client
              .from('payment_transactions')
              .select('id, amount, final_amount, payment_method, gateway')
              .or(orExpr);
          for (final t in (txRows as List)) {
            final id = t['id'] as String?;
            if (id != null) {
              txById[id] = Map<String, dynamic>.from(
                t as Map<dynamic, dynamic>,
              );
            }
          }
        } catch (_) {}
      }

      int normalizeToToman(int raw, {Map<String, dynamic>? tx}) {
        if (tx != null) {
          final txFinal = tx['final_amount'] as int?;
          final txAmt = tx['amount'] as int?;
          final pm = (tx['payment_method'] as String?)?.toLowerCase();
          final gw = (tx['gateway'] as String?)?.toLowerCase();
          final v = txFinal ?? txAmt;
          if (v != null) {
            final isDirect =
                pm == 'direct' || gw == 'zibal' || gw == 'zarinpal';
            return isDirect ? (v ~/ 10) : v;
          }
        }
        // Fallback heuristic when no tx: if looks Rial, convert
        return raw % 10 == 0 ? raw ~/ 10 : raw;
      }

      for (final r in list) {
        final rawAmount = (r['final_amount'] as int?) ?? 0;
        final txId = r['payment_transaction_id'] as String?;
        final tx = txId != null ? txById[txId] : null;
        final amount = normalizeToToman(rawAmount, tx: tx);

        total += amount;
        final hasProgram = (r['program_registration_date'] as String?) != null;
        if (hasProgram) {
          available += amount;
        } else {
          onHold += amount;
        }
      }
    } catch (_) {}

    // محاسبه موجودی قابل برداشت (بعد از 3 روز)
    try {
      withdrawable = await _payoutService.getTrainerWithdrawable(trainerId);
    } catch (_) {}

    return {
      'available': available,
      'onHold': onHold,
      'total': total,
      'withdrawable': withdrawable,
    };
  }

  // Recent earnings per subscription for a trainer with buyer info and hold status
  Future<List<Map<String, dynamic>>> getRecentEarnings(
    String trainerId, {
    int limit = 25,
  }) async {
    try {
      final rows = await _client
          .from('trainer_subscriptions')
          .select('''
            id,
            user_id,
            service_type,
            status,
            final_amount,
            purchase_date,
            program_registration_date,
            created_at,
            payment_transaction_id,
            buyer:profiles!trainer_subscriptions_user_id_fkey(
              id, username, first_name, last_name, avatar_url
            )
          ''')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false)
          .limit(limit);

      final subs = rows as List;

      // Pull transactions for normalization
      final txIds = subs
          .map((r) => r['payment_transaction_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final Map<String, Map<String, dynamic>> txById = {};
      if (txIds.isNotEmpty) {
        try {
          final orExpr = txIds.map((id) => 'id.eq.$id').join(',');
          final txRows = await _client
              .from('payment_transactions')
              .select('id, amount, final_amount, payment_method, gateway')
              .or(orExpr);
          for (final t in (txRows as List)) {
            final id = t['id'] as String?;
            if (id != null) {
              txById[id] = Map<String, dynamic>.from(
                t as Map<dynamic, dynamic>,
              );
            }
          }
        } catch (_) {}
      }

      int normalizeToToman(int raw, {Map<String, dynamic>? tx}) {
        if (tx != null) {
          final txFinal = tx['final_amount'] as int?;
          final txAmt = tx['amount'] as int?;
          final pm = (tx['payment_method'] as String?)?.toLowerCase();
          final gw = (tx['gateway'] as String?)?.toLowerCase();
          final v = txFinal ?? txAmt;
          if (v != null) {
            final isDirect =
                pm == 'direct' || gw == 'zibal' || gw == 'zarinpal';
            return isDirect ? (v ~/ 10) : v;
          }
        }
        return raw % 10 == 0 ? raw ~/ 10 : raw;
      }

      final list = <Map<String, dynamic>>[];
      for (final r in subs) {
        final txId = r['payment_transaction_id'] as String?;
        final tx = txId != null ? txById[txId] : null;
        final rawAmount = (r['final_amount'] as int?) ?? 0;
        final amount = normalizeToToman(rawAmount, tx: tx);
        final hasProgram = (r['program_registration_date'] as String?) != null;

        list.add({
          'id': r['id'],
          'service_type': r['service_type'],
          'status': r['status'],
          'amount': amount,
          'is_available': hasProgram,
          'created_at': r['created_at'] as String?,
          'buyer': r['buyer'],
        });
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// آمار کامل مربی - بازطراحی شده با محاسبات صحیح و آمارهای جامع
  Future<Map<String, dynamic>> getTrainerStats(String trainerId) async {
    try {
      final now = DateTime.now();
      const int holdDaysForWithdrawable = 3; // بعد از 3 روز قابل برداشت است

      // 2. دریافت تمام اشتراک‌های مربی با اطلاعات کامل
      final subscriptionsResponse = await _client
          .from('trainer_subscriptions')
          .select('''
            id,
            user_id,
            service_type,
            status,
            final_amount,
            program_registration_date,
            program_response_time,
            program_status,
            created_at,
            purchase_date,
            expiry_date,
            payment_transaction_id
          ''')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      final subscriptions = subscriptionsResponse as List;

      // 3. محاسبه آمار مشتریان از اشتراک‌ها
      final Set<String> uniqueClientIds = {};
      final Set<String> activeClientIds = {};

      for (final sub in subscriptions) {
        final userId = sub['user_id'] as String?;
        if (userId != null) {
          uniqueClientIds.add(userId);

          // بررسی اینکه آیا اشتراک فعال است
          final status = (sub['status'] as String?) ?? 'pending';
          final expiryDateStr = sub['expiry_date'] as String?;
          if ((status == 'active' || status == 'paid') &&
              expiryDateStr != null) {
            try {
              final expiryDate = DateTime.parse(expiryDateStr);
              if (now.isBefore(expiryDate)) {
                activeClientIds.add(userId);
              }
            } catch (_) {}
          }
        }
      }

      final int totalClients = uniqueClientIds.length;
      final int activeClients = activeClientIds.length;

      // 4. دریافت platform_revenue برای هر subscription
      final subscriptionIds = subscriptions
          .map((s) => s['id'] as String?)
          .whereType<String>()
          .toList();

      final Map<String, int> platformRevenueBySub = {};
      if (subscriptionIds.isNotEmpty) {
        try {
          final orExpr = subscriptionIds
              .map((id) => 'subscription_id.eq.$id')
              .join(',');
          final revenueRows = await _client
              .from('platform_revenue')
              .select('subscription_id, amount')
              .or(orExpr);
          for (final r in (revenueRows as List)) {
            final subId = r['subscription_id'] as String?;
            final amount = (r['amount'] as num?)?.toInt() ?? 0;
            if (subId != null) {
              platformRevenueBySub[subId] = amount;
            }
          }
        } catch (_) {}
      }

      // 5. دریافت تراکنش‌های پرداخت برای نرمال‌سازی مبالغ
      final txIds = subscriptions
          .map((s) => s['payment_transaction_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> txById = {};
      if (txIds.isNotEmpty) {
        try {
          final orExpr = txIds.map((id) => 'id.eq.$id').join(',');
          final txRows = await _client
              .from('payment_transactions')
              .select('id, amount, final_amount, payment_method, gateway')
              .or(orExpr);
          for (final t in (txRows as List)) {
            final id = t['id'] as String?;
            if (id != null) {
              txById[id] = Map<String, dynamic>.from(
                t as Map<dynamic, dynamic>,
              );
            }
          }
        } catch (_) {}
      }

      // 6. تابع نرمال‌سازی مبلغ به ریال (مثل payout_service)
      int normalizeToRial(int raw, {Map<String, dynamic>? tx}) {
        if (tx != null) {
          final txFinal = tx['final_amount'] as int?;
          final txAmt = tx['amount'] as int?;
          final pm = (tx['payment_method'] as String?)?.toLowerCase();
          final gw = (tx['gateway'] as String?)?.toLowerCase();
          final v = txFinal ?? txAmt;
          if (v != null) {
            // اگر direct payment یا gateway مستقیم است، مبلغ به ریال است
            final isDirect =
                pm == 'direct' || gw == 'zibal' || gw == 'zarinpal';
            return isDirect ? v : (v * 10); // اگر wallet بود، به ریال تبدیل کن
          }
        }
        // Fallback: اگر به نظر ریال است (مضرب 10)، همان را برگردان
        return raw % 10 == 0 ? raw : (raw * 10);
      }

      // 7. محاسبه آمارهای مالی
      int totalCommission = 0;
      int totalRevenue = 0; // کل درآمد (قبل از کمیسیون)
      int netEarnings = 0; // درآمد خالص (بعد از کمیسیون)
      int withdrawable = 0; // قابل برداشت (بعد از 3 روز و بدون برداشت‌های قبلی)
      int onHold = 0; // در انتظار (تا رسیدن به زمان برداشت)
      final byService = <String, int>{};
      final byServiceCommission = <String, int>{};
      final byServiceRevenue = <String, int>{}; // کل درآمد سرویس
      final byServiceCount = <String, int>{};
      final monthly = <String, int>{}; // درآمد خالص ماهانه
      final monthlyRevenue = <String, int>{}; // کل درآمد ماهانه
      final monthlyCommission = <String, int>{}; // کمیسیون ماهانه
      final monthlySubscriptions = <String, int>{}; // تعداد اشتراک ماهانه

      // 8. آمار برنامه‌ها
      int totalSubscriptions = subscriptions.length;
      int subscriptionsWithProgram = 0;
      int subscriptionsWithoutProgram = 0;
      int activeSubscriptions = 0;
      int completedSubscriptions = 0;
      int delayedSubscriptions = 0;
      int totalResponseTimeSeconds = 0;
      int programsWithResponseTime = 0;

      // 9. دریافت مبالغ برداشت شده برای محاسبه withdrawable
      int totalWithdrawn = 0;
      try {
        final processedRequests = await _client
            .from('payout_requests')
            .select('amount, final_amount')
            .eq('trainer_id', trainerId)
            .or('status.eq.completed,status.eq.approved');
        for (final req in (processedRequests as List<dynamic>)) {
          final finalAmount = req['final_amount'] as int?;
          final amount = req['amount'] as int?;
          totalWithdrawn += (finalAmount ?? amount ?? 0);
        }
      } catch (_) {}

      // 10. محاسبه آمار برای هر اشتراک
      for (final sub in subscriptions) {
        final subId = sub['id'] as String?;
        final rawAmount = (sub['final_amount'] as num?)?.toInt() ?? 0;
        final txId = sub['payment_transaction_id'] as String?;
        final tx = txId != null ? txById[txId] : null;
        final amountInRial = normalizeToRial(rawAmount, tx: tx);

        // محاسبه کمیسیون و درآمد مربی
        final platformRevenue = subId != null
            ? (platformRevenueBySub[subId] ?? 0)
            : 0;
        final trainerEarning = amountInRial - platformRevenue;

        // کل درآمد (بدون کمیسیون)
        totalRevenue += amountInRial;
        totalCommission += platformRevenue;
        netEarnings += trainerEarning;

        // بررسی وضعیت برنامه
        final registrationDateStr = sub['program_registration_date'] as String?;
        final status = (sub['status'] as String?) ?? 'pending';
        final programStatus =
            (sub['program_status'] as String?) ?? 'not_started';

        if (registrationDateStr != null) {
          subscriptionsWithProgram++;
          final registrationDate = DateTime.parse(registrationDateStr);
          final daysSinceRegistration = now.difference(registrationDate).inDays;

          // محاسبه withdrawable و onHold بر اساس زمان انتظار
          if (daysSinceRegistration >= holdDaysForWithdrawable) {
            // قابل برداشت است (بعد از 3 روز)
            withdrawable += trainerEarning;
          } else {
            // هنوز در انتظار است
            onHold += trainerEarning;
          }

          // محاسبه زمان پاسخ
          final responseTime = sub['program_response_time'] as int?;
          if (responseTime != null && responseTime > 0) {
            totalResponseTimeSeconds += responseTime;
            programsWithResponseTime++;
          }
        } else {
          subscriptionsWithoutProgram++;
          // اگر برنامه ثبت نشده، همه در انتظار است
          onHold += trainerEarning;
        }

        // آمار وضعیت
        if (status == 'active' || status == 'paid') {
          activeSubscriptions++;
        }
        if (programStatus == 'completed') {
          completedSubscriptions++;
        }
        if (programStatus == 'delayed') {
          delayedSubscriptions++;
        }

        // تفکیک سرویس
        final service = (sub['service_type'] as String?) ?? 'unknown';
        byService[service] =
            (byService[service] ?? 0) + trainerEarning; // درآمد خالص
        byServiceRevenue[service] =
            (byServiceRevenue[service] ?? 0) + amountInRial; // کل درآمد
        byServiceCommission[service] =
            (byServiceCommission[service] ?? 0) + platformRevenue;
        byServiceCount[service] = (byServiceCount[service] ?? 0) + 1;

        // آمار ماهانه
        final createdStr = sub['created_at'] as String?;
        if (createdStr != null) {
          try {
            final dt = DateTime.parse(createdStr);
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            monthly[key] = (monthly[key] ?? 0) + trainerEarning; // درآمد خالص
            monthlyRevenue[key] =
                (monthlyRevenue[key] ?? 0) + amountInRial; // کل درآمد
            monthlyCommission[key] =
                (monthlyCommission[key] ?? 0) + platformRevenue;
            monthlySubscriptions[key] = (monthlySubscriptions[key] ?? 0) + 1;
          } catch (_) {}
        }
      }

      // 11. کسر مبالغ برداشت شده از withdrawable
      withdrawable = (withdrawable - totalWithdrawn).clamp(0, withdrawable);

      // 12. محاسبه نرخ پاسخ و میانگین زمان پاسخ
      final responseRate = totalSubscriptions > 0
          ? (subscriptionsWithProgram / totalSubscriptions * 100)
          : 0.0;
      final averageResponseTimeHours = programsWithResponseTime > 0
          ? (totalResponseTimeSeconds / programsWithResponseTime / 3600)
          : 0.0;
      final averageResponseTimeDays = averageResponseTimeHours / 24;

      // 13. محاسبه نرخ تحویل به موقع
      final onTimeDeliveryRate = subscriptionsWithProgram > 0
          ? ((subscriptionsWithProgram - delayedSubscriptions) /
                subscriptionsWithProgram *
                100)
          : 0.0;

      return {
        // آمارهای مالی
        'totalRevenue':
            totalRevenue, // کل درآمد (قبل از کمیسیون) - همه پول‌های پرداخت شده
        'totalCommission': totalCommission, // کل کمیسیون پلتفرم (ریال)
        'netEarnings': netEarnings, // درآمد خالص (کل درآمد - کمیسیون)
        'withdrawable':
            withdrawable, // قابل برداشت (بعد از 3 روز و بدون برداشت‌های قبلی)
        'onHold': onHold, // در انتظار (تا رسیدن به زمان برداشت)
        // تفکیک سرویس
        'byService': byService, // درآمد خالص مربی بر اساس سرویس (ریال)
        'byServiceRevenue': byServiceRevenue, // کل درآمد بر اساس سرویس (ریال)
        'byServiceCommission':
            byServiceCommission, // کمیسیون بر اساس سرویس (ریال)
        'byServiceCount': byServiceCount, // تعداد اشتراک بر اساس سرویس
        // آمار ماهانه
        'monthly': monthly, // درآمد خالص ماهانه (ریال)
        'monthlyRevenue': monthlyRevenue, // کل درآمد ماهانه (ریال)
        'monthlyCommission': monthlyCommission, // کمیسیون ماهانه (ریال)
        'monthlySubscriptions': monthlySubscriptions, // تعداد اشتراک ماهانه
        // آمار مشتریان
        'totalClients': totalClients, // تعداد کل مشتریان (از اشتراک‌ها)
        'activeClients': activeClients, // تعداد مشتریان فعال
        // آمار اشتراک‌ها
        'totalSubscriptions': totalSubscriptions, // تعداد کل اشتراک‌ها
        'activeSubscriptions': activeSubscriptions, // تعداد اشتراک‌های فعال
        'subscriptionsWithProgram':
            subscriptionsWithProgram, // تعداد اشتراک‌هایی که برنامه دارند
        'subscriptionsWithoutProgram':
            subscriptionsWithoutProgram, // تعداد اشتراک‌هایی که برنامه ندارند
        // آمار برنامه‌ها
        'completedSubscriptions':
            completedSubscriptions, // تعداد برنامه‌های تکمیل شده
        'delayedSubscriptions':
            delayedSubscriptions, // تعداد برنامه‌های تاخیردار
        // آمار عملکرد
        'responseRate': responseRate, // نرخ پاسخ (درصد)
        'averageResponseTimeHours':
            averageResponseTimeHours, // میانگین زمان پاسخ (ساعت)
        'averageResponseTimeDays':
            averageResponseTimeDays, // میانگین زمان پاسخ (روز)
        'onTimeDeliveryRate': onTimeDeliveryRate, // نرخ تحویل به موقع (درصد)
      };
    } catch (e) {
      return {
        'totalRevenue': 0,
        'totalCommission': 0,
        'netEarnings': 0,
        'withdrawable': 0,
        'onHold': 0,
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
  }
}
