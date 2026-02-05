import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/commission_settings.dart';
import 'package:gymaipro/payment/services/commission_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه تنظیمات کمیسیون
class AdminCommissionSettingsScreen extends StatefulWidget {
  const AdminCommissionSettingsScreen({super.key});

  @override
  State<AdminCommissionSettingsScreen> createState() =>
      _AdminCommissionSettingsScreenState();
}

class _AdminCommissionSettingsScreenState
    extends State<AdminCommissionSettingsScreen> {
  final CommissionService _commissionService = CommissionService();
  final TextEditingController _percentageController = TextEditingController();
  final TextEditingController _holdDaysController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  List<CommissionSettings> _history = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _percentageController.dispose();
    _holdDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final active = await _commissionService.getActiveSettings();
      final all = await _commissionService.getAllSettings();
      
      if (mounted) {
        setState(() {
          _history = all;
          if (active != null) {
            _percentageController.text = active.commissionPercentage.toString();
            _holdDaysController.text = active.holdDays.toString();
          } else {
            _percentageController.text = '20.0';
            _holdDaysController.text = '3';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری تنظیمات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final percentage = double.tryParse(_percentageController.text);
    final holdDays = int.tryParse(_holdDaysController.text);

    if (percentage == null || percentage < 0 || percentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('درصد کمیسیون باید بین 0 تا 100 باشد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (holdDays == null || holdDays < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعداد روزهای انتظار باید عدد مثبت باشد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await _commissionService.createSettings(
        commissionPercentage: percentage,
        holdDays: holdDays,
      );

      if (mounted) {
        if (saved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تنظیمات با موفقیت ذخیره شد'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSettings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطا در ذخیره تنظیمات'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره تنظیمات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSettings,
      color: AppTheme.goldColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // کارت تنظیمات فعلی
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
                      : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.settings,
                        color: AppTheme.goldColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'تنظیمات کمیسیون',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor
                              : AppTheme.lightTextColor,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // درصد کمیسیون
                  Text(
                    'درصد کمیسیون پلتفرم',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                          : AppTheme.lightTextSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _percentageController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'مثال: 20.0',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkBackgroundColor
                          : AppTheme.lightBackgroundColor,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // روزهای انتظار
                  Text(
                    'تعداد روزهای انتظار قبل از قابل برداشت شدن',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                          : AppTheme.lightTextSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _holdDaysController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'مثال: 3',
                      suffixText: 'روز',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkBackgroundColor
                          : AppTheme.lightBackgroundColor,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // دکمه ذخیره
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'ذخیره تنظیمات',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // تاریخچه تنظیمات
            if (_history.isNotEmpty) ...[
              Text(
                'تاریخچه تنظیمات',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextColor
                      : AppTheme.lightTextColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ..._history.map((settings) => Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkCardColor
                          : AppTheme.lightCardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: settings.isActive
                            ? AppTheme.goldColor
                            : (isDark
                                ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
                                : AppTheme.lightDividerColor.withValues(alpha: 0.5)),
                        width: settings.isActive ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'کمیسیون: ${settings.formattedPercentage}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextColor
                                      : AppTheme.lightTextColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'روزهای انتظار: ${settings.holdDays} روز',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                      : AppTheme.lightTextSecondary,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'تاریخ ایجاد: ${_formatDate(settings.createdAt)}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                      : AppTheme.lightTextSecondary.withValues(alpha: 0.7),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (settings.isActive)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'فعال',
                              style: TextStyle(
                                color: AppTheme.goldColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

