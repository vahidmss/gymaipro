import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/payout_request.dart';
import 'package:gymaipro/payment/services/payout_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحه مدیریت درخواست‌های برداشت
class AdminPayoutRequestsScreen extends StatefulWidget {
  const AdminPayoutRequestsScreen({super.key});

  @override
  State<AdminPayoutRequestsScreen> createState() =>
      _AdminPayoutRequestsScreenState();
}

class _AdminPayoutRequestsScreenState
    extends State<AdminPayoutRequestsScreen> {
  final PayoutService _payoutService = PayoutService();
  final TextEditingController _searchController = TextEditingController();
  List<PayoutRequest> _requests = [];
  List<PayoutRequest> _filteredRequests = [];
  bool _isLoading = false;
  PayoutRequestStatus? _filterStatus;
  String? _selectedTrainerId;
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, Map<String, dynamic>> _trainerProfiles = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRequests);
    _loadRequests();
    _loadTrainerProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainerProfiles() async {
    try {
      final trainerIds = _requests.map((r) => r.trainerId).toSet().toList();
      if (trainerIds.isEmpty) return;

      // استفاده از or برای گرفتن چند profile
      if (trainerIds.length == 1) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('id, username, first_name, last_name')
            .eq('id', trainerIds.first)
            .maybeSingle();
        
        if (profile != null) {
          final id = profile['id'] as String?;
          if (id != null) {
            setState(() {
              _trainerProfiles[id] = Map<String, dynamic>.from(
                profile as Map<dynamic, dynamic>,
              );
            });
          }
        }
      } else {
        // برای چند profile، از or استفاده می‌کنیم
        final orExpr = trainerIds.map((id) => 'id.eq.$id').join(',');
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, username, first_name, last_name')
            .or(orExpr);

        final Map<String, Map<String, dynamic>> profilesMap = {};
        for (final profile in (profiles as List)) {
          final id = profile['id'] as String?;
          if (id != null) {
            profilesMap[id] = Map<String, dynamic>.from(
              profile as Map<dynamic, dynamic>,
            );
          }
        }
        setState(() => _trainerProfiles = profilesMap);
      }
    } catch (e) {
      // خطا در بارگذاری پروفایل‌ها نباید جریان اصلی را متوقف کند
    }
  }

  void _filterRequests() {
    final searchQuery = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredRequests = _requests.where((request) {
        // فیلتر بر اساس وضعیت
        if (_filterStatus != null && request.status != _filterStatus) {
          return false;
        }

        // فیلتر بر اساس مربی
        if (_selectedTrainerId != null &&
            request.trainerId != _selectedTrainerId) {
          return false;
        }

        // فیلتر بر اساس تاریخ
        if (_startDate != null && request.createdAt.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && request.createdAt.isAfter(_endDate!)) {
          return false;
        }

        // جستجو
        if (searchQuery.isNotEmpty) {
          final trainer = _trainerProfiles[request.trainerId];
          final trainerName = trainer != null
              ? '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''} ${trainer['username'] ?? ''}'
                  .toLowerCase()
              : '';
          final cardNumber = request.maskedCardNumber.toLowerCase();
          final cardOwner = request.cardOwnerName.toLowerCase();
          
          if (!trainerName.contains(searchQuery) &&
              !cardNumber.contains(searchQuery) &&
              !cardOwner.contains(searchQuery)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _payoutService.getAllPayoutRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
          _filterRequests();
          _isLoading = false;
        });
        _loadTrainerProfiles();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری درخواست‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveRequest(PayoutRequest request) async {
    final penaltyController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    bool hasPenalty = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تایید درخواست برداشت'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مبلغ درخواستی: ${request.formattedAmount}'),
                SizedBox(height: 16.h),
                CheckboxListTile(
                  value: hasPenalty,
                  onChanged: (value) {
                    setDialogState(() => hasPenalty = value ?? false);
                  },
                  title: const Text('اعمال جریمه'),
                ),
                if (hasPenalty) ...[
                  SizedBox(height: 8.h),
                  TextField(
                    controller: penaltyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'مبلغ جریمه (تومان)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'دلیل جریمه',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'یادداشت (اختیاری)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('تایید'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final penaltyAmount = hasPenalty
          ? (int.tryParse(penaltyController.text) ?? 0) * 10
          : null;

      final approveResult = await _payoutService.approvePayoutRequest(
        requestId: request.id,
        penaltyAmount: penaltyAmount,
        penaltyReason: hasPenalty ? reasonController.text : null,
        adminNotes: notesController.text.isNotEmpty
            ? notesController.text
            : null,
      );

      if (mounted) {
        if (approveResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('درخواست با موفقیت تایید شد'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRequests();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approveResult['error'] as String? ?? 'خطا'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectRequest(PayoutRequest request) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد درخواست برداشت'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'دلیل رد',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('رد'),
          ),
        ],
      ),
    );

    if (result == true) {
      final rejectResult = await _payoutService.rejectPayoutRequest(
        requestId: request.id,
        reason: reasonController.text,
      );

      if (mounted) {
        if (rejectResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('درخواست رد شد'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadRequests();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(rejectResult['error'] as String? ?? 'خطا'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completePayout(PayoutRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تکمیل پرداخت'),
        content: Text(
          'آیا مطمئن هستید که مبلغ ${request.formattedFinalAmount} به حساب مربی واریز شده است؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('تایید'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final completeResult = await _payoutService.completePayout(
        requestId: request.id,
      );

      if (mounted) {
        if (completeResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('پرداخت با موفقیت تکمیل شد'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRequests();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(completeResult['error'] as String? ?? 'خطا'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // فیلترها و جستجو
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Column(
            children: [
              // جستجو
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'جستجو بر اساس نام مربی، شماره کارت...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkBackgroundColor
                      : AppTheme.lightBackgroundColor,
                ),
              ),
              SizedBox(height: 12.h),
              // فیلترها
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<PayoutRequestStatus?>(
                      value: _filterStatus,
                      isExpanded: true,
                      hint: const Text('وضعیت'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('همه وضعیت‌ها'),
                        ),
                        ...PayoutRequestStatus.values.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusText(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _filterStatus = value);
                        _filterRequests();
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final DateTimeRange? picked =
                            await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _startDate != null &&
                                  _endDate != null
                              ? DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                )
                              : null,
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                          _filterRequests();
                        }
                      },
                      icon: const Icon(LucideIcons.calendar),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                            : 'بازه زمانی',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (_startDate != null || _endDate != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        _filterRequests();
                      },
                      icon: const Icon(LucideIcons.x),
                      tooltip: 'حذف فیلتر تاریخ',
                    ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: _loadRequests,
                    icon: const Icon(LucideIcons.refreshCw),
                    tooltip: 'بروزرسانی',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // لیست درخواست‌ها
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                )
              : _filteredRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 64.sp,
                            color: isDark
                                ? AppTheme.darkTextColor.withValues(alpha: 0.3)
                                : AppTheme.lightTextSecondary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'درخواستی یافت نشد',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                  : AppTheme.lightTextSecondary,
                              fontSize: 16.sp,
                            ),
                          ),
                          if (_filterStatus != null ||
                              _startDate != null ||
                              _endDate != null ||
                              _searchController.text.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _filterStatus = null;
                                  _startDate = null;
                                  _endDate = null;
                                  _searchController.clear();
                                });
                                _filterRequests();
                              },
                              child: const Text('حذف فیلترها'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return _buildRequestCard(context, request, isDark);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    PayoutRequest request,
    bool isDark,
  ) {
    final trainer = _trainerProfiles[request.trainerId];
    final trainerName = trainer != null
        ? '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}'.trim()
        : 'مربی ناشناس';
    final trainerUsername = trainer?['username'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Color(int.parse(request.statusColor.replaceFirst('#', '0xFF'))),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مربی: $trainerName${trainerUsername != null ? ' (@$trainerUsername)' : ''}',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                            : AppTheme.lightTextSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'مبلغ: ${request.formattedAmount}',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (request.hasPenalty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'جریمه: ${request.formattedPenaltyAmount}',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (request.penaltyReason != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'دلیل: ${request.penaltyReason}',
                          style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ],
                    if (request.finalAmount != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'مبلغ نهایی: ${request.formattedFinalAmount}',
                        style: TextStyle(
                          color: AppTheme.goldColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Color(int.parse(
                          request.statusColor.replaceFirst('#', '0xFF')))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.statusText,
                  style: TextStyle(
                    color: Color(int.parse(
                        request.statusColor.replaceFirst('#', '0xFF'))),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(
            color: isDark
                ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
                : AppTheme.lightDividerColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            'شماره کارت: ${request.maskedCardNumber}',
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                  : AppTheme.lightTextSecondary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'صاحب کارت: ${request.cardOwnerName}',
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                  : AppTheme.lightTextSecondary,
              fontSize: 14.sp,
            ),
          ),
          if (request.bankName != null) ...[
            SizedBox(height: 4.h),
            Text(
              'بانک: ${request.bankName}',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                    : AppTheme.lightTextSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
          SizedBox(height: 4.h),
          Text(
            'تاریخ درخواست: ${_formatDate(request.createdAt)}',
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                  : AppTheme.lightTextSecondary.withValues(alpha: 0.7),
              fontSize: 12.sp,
            ),
          ),
          if (request.adminNotes != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBackgroundColor
                    : AppTheme.lightBackgroundColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'یادداشت: ${request.adminNotes}',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                      : AppTheme.lightTextSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          
          // دکمه‌های عملیات
          if (request.status == PayoutRequestStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('رد'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('تایید'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (request.status == PayoutRequestStatus.approved) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completePayout(request),
                icon: const Icon(LucideIcons.checkCircle, size: 16),
                label: const Text('تکمیل پرداخت'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(PayoutRequestStatus status) {
    switch (status) {
      case PayoutRequestStatus.pending:
        return 'در انتظار';
      case PayoutRequestStatus.approved:
        return 'تایید شده';
      case PayoutRequestStatus.rejected:
        return 'رد شده';
      case PayoutRequestStatus.completed:
        return 'پرداخت شده';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

