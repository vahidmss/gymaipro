import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/services/trainer_escrow_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// پنل مدیریت Escrow درآمد مربیان (فقط ادمین)
class AdminTrainerEscrowScreen extends StatefulWidget {
  const AdminTrainerEscrowScreen({super.key});

  @override
  State<AdminTrainerEscrowScreen> createState() =>
      _AdminTrainerEscrowScreenState();
}

class _AdminTrainerEscrowScreenState extends State<AdminTrainerEscrowScreen> {
  final TrainerEscrowService _escrowService = TrainerEscrowService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _escrowService.getAdminEscrowOverview(
        statusFilter: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _summary = data['summary'] as Map<String, dynamic>? ?? {};
        _items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('خطا در بارگذاری: $e', isError: true);
      }
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _items.where((item) {
        if (q.isEmpty) return true;
        final trainer = item['trainer'] as Map<String, dynamic>?;
        final buyer = item['buyer'] as Map<String, dynamic>?;
        final trainerName = _profileName(trainer).toLowerCase();
        final buyerName = _profileName(buyer).toLowerCase();
        final id = (item['id'] as String? ?? '').toLowerCase();
        return trainerName.contains(q) ||
            buyerName.contains(q) ||
            id.contains(q);
      }).toList();
    });
  }

  String _profileName(Map<String, dynamic>? p) {
    if (p == null) return '';
    final first = (p['first_name'] as String?)?.trim() ?? '';
    final last = (p['last_name'] as String?)?.trim() ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : (p['username'] as String? ?? '');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppTheme.successColor,
      ),
    );
  }

  Future<void> _showItemActions(Map<String, dynamic> item) async {
    final status = item['earnings_escrow_status'] as String? ?? '';
    final subId = item['id'] as String;
    final trainerId = item['trainer_id'] as String?;
    final isFrozen = item['earnings_frozen'] == true;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkCardColor
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'عملیات Escrow',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'سهم مربی: ${PaymentConstants.formatAmount((item['trainer_share_amount'] as num?)?.toInt() ?? 0)}',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey),
              ),
              SizedBox(height: 16.h),
              if (status != 'withdrawable' && !isFrozen)
                ListTile(
                  leading: const Icon(LucideIcons.zap, color: AppTheme.goldColor),
                  title: const Text('آزادسازی زودتر از موعد'),
                  subtitle: const Text('مبلغ فوراً قابل برداشت می‌شود'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _earlyRelease(subId);
                  },
                ),
              if (!isFrozen)
                ListTile(
                  leading: const Icon(LucideIcons.lock, color: Colors.red),
                  title: const Text('مسدود کردن این درآمد'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _freeze(subId);
                  },
                ),
              if (isFrozen)
                ListTile(
                  leading: const Icon(LucideIcons.unlock, color: AppTheme.successColor),
                  title: const Text('رفع مسدودیت'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final r = await _escrowService.unfreezeEarnings(
                      subscriptionId: subId,
                    );
                    if (r['success'] == true) {
                      _showSnack('مسدودیت برداشته شد');
                      _load();
                    } else {
                      _showSnack(r['error'] as String? ?? 'خطا', isError: true);
                    }
                  },
                ),
              if (trainerId != null) ...[
                const Divider(),
                ListTile(
                  leading: Icon(LucideIcons.ban, color: Colors.red.shade700),
                  title: const Text('مسدود کردن برداشت کل مربی'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _blockTrainerPayout(trainerId);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.circleCheck, color: AppTheme.successColor),
                  title: const Text('رفع مسدودیت برداشت مربی'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final r = await _escrowService.unblockTrainerPayout(
                      trainerId: trainerId,
                    );
                    if (r['success'] == true) {
                      _showSnack('مسدودیت برداشت مربی برداشته شد');
                    } else {
                      _showSnack(r['error'] as String? ?? 'خطا', isError: true);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _earlyRelease(String subId) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('آزادسازی زودتر'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'دلیل (اختیاری)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تایید')),
        ],
      ),
    );
    if (ok != true) return;

    final r = await _escrowService.earlyReleaseEarnings(
      subscriptionId: subId,
      reason: reasonController.text.trim().isEmpty
          ? null
          : reasonController.text.trim(),
    );
    if (r['success'] == true) {
      _showSnack('آزادسازی زودتر انجام شد');
      _load();
    } else {
      _showSnack(r['error'] as String? ?? 'خطا', isError: true);
    }
  }

  Future<void> _freeze(String subId) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسدود کردن درآمد'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'دلیل مسدودیت',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مسدود'),
          ),
        ],
      ),
    );
    if (ok != true || reasonController.text.trim().isEmpty) {
      if (ok ?? false) _showSnack('دلیل الزامی است', isError: true);
      return;
    }

    final r = await _escrowService.freezeEarnings(
      subscriptionId: subId,
      reason: reasonController.text.trim(),
    );
    if (r['success'] == true) {
      _showSnack('درآمد مسدود شد');
      _load();
    } else {
      _showSnack(r['error'] as String? ?? 'خطا', isError: true);
    }
  }

  Future<void> _blockTrainerPayout(String trainerId) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسدود کردن برداشت مربی'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'دلیل',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مسدود'),
          ),
        ],
      ),
    );
    if (ok != true || reasonController.text.trim().isEmpty) return;

    final r = await _escrowService.blockTrainerPayout(
      trainerId: trainerId,
      reason: reasonController.text.trim(),
    );
    if (r['success'] == true) {
      _showSnack('برداشت مربی مسدود شد');
    } else {
      _showSnack(r['error'] as String? ?? 'خطا', isError: true);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'withdrawable':
        return AppTheme.successColor;
      case 'hold':
        return AppTheme.fatColor;
      case 'frozen':
        return Colors.red;
      case 'edit_window':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    return TrainerEarningsEscrowStatus.fromDb(status)?.labelFa ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'جستجو مربی، شاگرد یا شناسه...',
                  prefixIcon: const Icon(LucideIcons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  isDense: true,
                ),
              ),
              SizedBox(height: 8.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('همه', null),
                    _filterChip('در پلتفرم', 'in_platform'),
                    _filterChip('فرصت ادیت', 'edit_window'),
                    _filterChip('در انتظار', 'hold'),
                    _filterChip('قابل برداشت', 'withdrawable'),
                    _filterChip('مسدود', 'frozen'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!_loading)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _summaryChip(
                  'کل درآمد',
                  _summary['total_gross'] as int? ?? 0,
                  LucideIcons.banknote,
                  Colors.green,
                ),
                _summaryChip(
                  'کمیسیون',
                  _summary['total_commission'] as int? ?? 0,
                  LucideIcons.percent,
                  Colors.orange,
                ),
                _summaryChip(
                  'سهم مربیان',
                  _summary['total_trainer_share'] as int? ?? 0,
                  LucideIcons.users,
                  Colors.blue,
                ),
                _summaryChip(
                  'در پلتفرم',
                  _summary['in_platform'] as int? ?? 0,
                  LucideIcons.shield,
                  Colors.purple,
                ),
                _summaryChip(
                  'قابل برداشت',
                  _summary['withdrawable'] as int? ?? 0,
                  LucideIcons.checkCircle,
                  AppTheme.successColor,
                ),
              ],
            ),
          ),
        SizedBox(height: 8.h),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.goldColor,
                  child: _filtered.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 80.h),
                            Center(
                              child: Text(
                                'موردی یافت نشد',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final item = _filtered[i];
                            final status =
                                item['earnings_escrow_status'] as String? ??
                                'in_platform';
                            final trainer =
                                item['trainer'] as Map<String, dynamic>?;
                            final buyer =
                                item['buyer'] as Map<String, dynamic>?;

                            return Card(
                              margin: EdgeInsets.only(bottom: 10.h),
                              child: ListTile(
                                onTap: () => _showItemActions(item),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _statusColor(status).withValues(alpha: 0.15),
                                  child: Icon(
                                    LucideIcons.wallet,
                                    color: _statusColor(status),
                                    size: 20.sp,
                                  ),
                                ),
                                title: Text(
                                  '${_profileName(trainer)} ← ${_profileName(buyer)}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4.h),
                                    Text(
                                      _statusLabel(status),
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item['earnings_frozen'] == true &&
                                        item['earnings_frozen_reason'] != null)
                                      Text(
                                        item['earnings_frozen_reason']
                                            as String,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      PaymentConstants.formatAmount(
                                        (item['trainer_share_amount'] as num?)
                                                ?.toInt() ??
                                            0,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                    Text(
                                      'کمیسیون: ${PaymentConstants.formatAmount((item['platform_commission_amount'] as num?)?.toInt() ?? 0)}',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: EdgeInsets.only(left: 6.w),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = status);
          _load();
        },
        selectedColor: AppTheme.goldColor.withValues(alpha: 0.25),
        checkmarkColor: AppTheme.goldColor,
      ),
    );
  }

  Widget _summaryChip(
    String label,
    int amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
              Text(
                PaymentConstants.formatAmount(amount),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
