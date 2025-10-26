import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_finance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerStatsTab extends StatefulWidget {
  const TrainerStatsTab({super.key});

  @override
  State<TrainerStatsTab> createState() => _TrainerStatsTabState();
}

class _TrainerStatsTabState extends State<TrainerStatsTab> {
  final _finance = TrainerFinanceService();
  bool _loading = true;
  Map<String, dynamic> _stats = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final s = await _finance.getTrainerStats(user.id);
        if (mounted) setState(() => _stats = s);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final int total = _stats['total'] as int? ?? 0;
    final int available = _stats['available'] as int? ?? 0;
    final int onHold = _stats['onHold'] as int? ?? 0;
    final Map<String, dynamic> byService = Map<String, dynamic>.from(
      _stats['byService'] as Map? ?? {},
    );
    final Map<String, dynamic> monthly = Map<String, dynamic>.from(
      _stats['monthly'] as Map? ?? {},
    );

    final serviceNames = {
      'training': 'برنامه تمرینی',
      'diet': 'برنامه غذایی',
      'consulting': 'مشاوره و نظارت',
      'package': 'بسته کامل',
    };

    final monthlyEntries = monthly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _metric('مجموع فروش', total),
          const SizedBox(height: 8),
          _metric('قابل برداشت', available),
          const SizedBox(height: 8),
          _metric('در انتظار', onHold),
          const SizedBox(height: 20),
          const Text('تفکیک سرویس', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          ...byService.entries.map(
            (e) => _row(serviceNames[e.key] ?? e.key, e.value as int? ?? 0),
          ),
          const SizedBox(height: 20),
          const Text('درآمد ماهانه', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          ...monthlyEntries.map((e) => _row(e.key, e.value as int? ?? 0)),
        ],
      ),
    );
  }

  Widget _metric(String title, int amount) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: const Color(0xFF12151C),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            _formatToman(amount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: const Color(0xFF0F131A),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            _formatToman(amount),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatToman(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(',');
    }
    return '${buf.toString().split('').reversed.join()} تومان';
  }
}
