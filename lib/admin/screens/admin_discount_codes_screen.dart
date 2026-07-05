import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه مدیریت کدهای تخفیف
class AdminDiscountCodesScreen extends StatefulWidget {
  const AdminDiscountCodesScreen({super.key});

  @override
  State<AdminDiscountCodesScreen> createState() => _AdminDiscountCodesScreenState();
}

class _AdminDiscountCodesScreenState extends State<AdminDiscountCodesScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _codes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _isLoading = true);
    try {
      final codes = await _adminService.getAllDiscountCodes();
      if (mounted) {
        setState(() {
          _codes = codes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری کدهای تخفیف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createDiscountCode() async {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final maxUsageController = TextEditingController();
    String selectedType = 'percentage';
    bool isActive = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ایجاد کد تخفیف جدید'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'کد تخفیف',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'نوع تخفیف',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('درصدی')),
                    DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: selectedType == 'percentage' ? 'درصد تخفیف' : 'مبلغ تخفیف',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: maxUsageController,
                  decoration: const InputDecoration(
                    labelText: 'حداکثر استفاده (اختیاری)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.h),
                SwitchListTile(
                  title: const Text('فعال'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            TextButton(
              onPressed: () {
                if (codeController.text.isNotEmpty && valueController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('ایجاد'),
            ),
          ],
        ),
      ),
    );

    final codeData = <String, dynamic>{
      'code': codeController.text.trim(),
      'type': selectedType,
      'value': int.tryParse(valueController.text) ?? 0,
      'max_usage': maxUsageController.text.isNotEmpty
          ? int.tryParse(maxUsageController.text)
          : null,
      'is_active': isActive,
    };
    codeController.dispose();
    valueController.dispose();
    maxUsageController.dispose();

    if (confirmed != true) return;

    final success = await _adminService.createDiscountCode(codeData);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کد تخفیف با موفقیت ایجاد شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCodes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در ایجاد کد تخفیف'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCodeStatus(String codeId, bool currentStatus) async {
    final success = await _adminService.updateDiscountCode(
      codeId,
      {'is_active': !currentStatus},
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'کد تخفیف فعال شد' : 'کد تخفیف غیرفعال شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCodes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در تغییر وضعیت'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCode(String codeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کد تخفیف'),
        content: const Text('آیا مطمئن هستید که می‌خواهید این کد تخفیف را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _adminService.deleteDiscountCode(codeId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کد تخفیف با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCodes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در حذف کد تخفیف'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createDiscountCode,
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('ایجاد کد تخفیف جدید'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: AppTheme.onGoldColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _codes.isEmpty
                  ? Center(
                      child: Text(
                        'کد تخفیفی یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCodes,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _codes.length,
                        itemBuilder: (context, index) {
                          final code = _codes[index];
                          final codeText = code['code'] as String? ?? '';
                          final type = code['type'] as String? ?? 'percentage';
                          final value = code['value'] as int? ?? 0;
                          final maxUsage = code['max_usage'] as int?;
                          final usedCount = code['used_count'] as int? ?? 0;
                          final isActive = code['is_active'] as bool? ?? true;

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                                child: const Icon(LucideIcons.ticket),
                              ),
                              title: Text(
                                codeText,
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type == 'percentage'
                                        ? '$value% تخفیف'
                                        : '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} تومان تخفیف',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                          : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    maxUsage != null
                                        ? 'استفاده شده: $usedCount / $maxUsage'
                                        : 'استفاده شده: $usedCount',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  if (!isActive)
                                    Chip(
                                      label: const Text('غیرفعال'),
                                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<void>(
                                icon: const Icon(LucideIcons.moreVertical),
                                itemBuilder: (context) => [
                                  PopupMenuItem<void>(
                                    child: Row(
                                      children: [
                                        Icon(
                                          isActive ? LucideIcons.pause : LucideIcons.play,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(isActive ? 'غیرفعال کردن' : 'فعال کردن'),
                                      ],
                                    ),
                                    onTap: () => _toggleCodeStatus(
                                      code['id'] as String,
                                      isActive,
                                    ),
                                  ),
                                  PopupMenuItem<void>(
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                        SizedBox(width: 8.w),
                                        const Text(
                                          'حذف',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _deleteCode(code['id'] as String),
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
}

