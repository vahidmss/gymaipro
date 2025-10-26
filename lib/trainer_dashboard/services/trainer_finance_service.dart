import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerFinanceService {
  factory TrainerFinanceService() => _instance;
  TrainerFinanceService._internal();
  static final TrainerFinanceService _instance =
      TrainerFinanceService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Compute trainer balances: available vs onHold
  // Funds become available 2 days after program_registration_date
  Future<Map<String, dynamic>> getTrainerBalances(String trainerId) async {
    int available = 0;
    int onHold = 0;
    int total = 0;

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

    return {'available': available, 'onHold': onHold, 'total': total};
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

  // Aggregated stats for dashboard
  Future<Map<String, dynamic>> getTrainerStats(String trainerId) async {
    try {
      final rows = await _client
          .from('trainer_subscriptions')
          .select(
            'final_amount, service_type, program_registration_date, created_at',
          )
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      int total = 0;
      int available = 0;
      int onHold = 0;
      final byService = <String, int>{};
      final monthly = <String, int>{}; // yyyy-MM -> sum

      for (final r in (rows as List)) {
        final amount = (r['final_amount'] as int?) ?? 0;
        total += amount;

        final hasProgram = (r['program_registration_date'] as String?) != null;
        if (hasProgram) {
          available += amount;
        } else {
          onHold += amount;
        }

        final service = (r['service_type'] as String?) ?? 'unknown';
        byService[service] = (byService[service] ?? 0) + amount;

        final createdStr = r['created_at'] as String?;
        if (createdStr != null) {
          try {
            final dt = DateTime.parse(createdStr);
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            monthly[key] = (monthly[key] ?? 0) + amount;
          } catch (_) {}
        }
      }

      return {
        'total': total,
        'available': available,
        'onHold': onHold,
        'byService': byService,
        'monthly': monthly,
      };
    } catch (_) {
      return {
        'total': 0,
        'available': 0,
        'onHold': 0,
        'byService': <String, int>{},
        'monthly': <String, int>{},
      };
    }
  }
}
