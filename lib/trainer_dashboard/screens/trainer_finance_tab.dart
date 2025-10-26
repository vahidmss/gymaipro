import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_finance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerFinanceTab extends StatefulWidget {
  const TrainerFinanceTab({super.key});

  @override
  State<TrainerFinanceTab> createState() => _TrainerFinanceTabState();
}

class _TrainerFinanceTabState extends State<TrainerFinanceTab> {
  final _finance = TrainerFinanceService();
  bool _loading = true;
  Map<String, dynamic> _balances = const {};
  List<Map<String, dynamic>> _earnings = const [];

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
        final b = await _finance.getTrainerBalances(user.id);
        final e = await _finance.getRecentEarnings(user.id, limit: 20);
        if (mounted) {
          setState(() {
            _balances = b;
            _earnings = e;
          });
        }
      } else {
        if (mounted) {
          setState(
            () => _balances = const {'available': 0, 'onHold': 0, 'total': 0},
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final int available = _balances['available'] as int? ?? 0;
    final int onHold = _balances['onHold'] as int? ?? 0;
    final int total = _balances['total'] as int? ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Text(
            'خلاصه مالی',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _summaryCard('موجودی کل', total, const [
            Color(0xFF2B2E3A),
            Color(0xFF232736),
          ]),
          const SizedBox(height: 10),
          _summaryCard('قابل برداشت', available, const [
            Color(0xFF1E3A2B),
            Color(0xFF193024),
          ]),
          const SizedBox(height: 10),
          _summaryCard('در انتظار آزادسازی', onHold, const [
            Color(0xFF3A2B2B),
            Color(0xFF2F2323),
          ]),
          const SizedBox(height: 24),
          const Text(
            'توضیح سیاست نگه‌داری',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'مبالغ پس از ثبت برنامه توسط مربی، به مدت ۲ روز نگه‌داری شده و سپس قابل برداشت می‌شوند.',
            style: TextStyle(color: Colors.white60, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text(
            'تراکنش‌های اخیر',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ..._earnings.map(_buildEarningTile),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int amount, List<Color> gradient) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33000000),
            blurRadius: 10.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  _formatToman(amount),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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

  Widget _buildEarningTile(Map<String, dynamic> e) {
    final buyer = e['buyer'] as Map<String, dynamic>?;
    final first = (buyer?['first_name'] as String?)?.trim() ?? '';
    final last = (buyer?['last_name'] as String?)?.trim() ?? '';
    final name = '$first $last'.trim().isNotEmpty
        ? '$first $last'.trim()
        : (buyer?['username'] as String? ?? 'کاربر');
    final amount = e['amount'] as int? ?? 0;
    final available = e['is_available'] == true;
    final holdUntilStr = e['hold_until'] as String?;
    DateTime? holdUntil;
    if (holdUntilStr != null) {
      try {
        holdUntil = DateTime.parse(holdUntilStr);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  available
                      ? 'قابل برداشت'
                      : 'آزادسازی تا ${holdUntil != null ? _formatDate(holdUntil) : '-'}',
                  style: TextStyle(
                    color: available ? Colors.green : Colors.orange,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatToman(amount),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    // ساده: روز/ماه شمسی تقریبی؛ برای دقت بیشتر می‌توان از shamsi_date استفاده کرد
    return '${date.day} ${months[date.month]}';
  }
}
