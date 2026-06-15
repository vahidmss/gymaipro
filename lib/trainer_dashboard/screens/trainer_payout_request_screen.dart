import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/payout_request.dart';
import 'package:gymaipro/payment/services/payout_service.dart';
import 'package:gymaipro/payment/utils/card_input_formatter.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحه درخواست برداشت مربی
class TrainerPayoutRequestScreen extends StatefulWidget {
  const TrainerPayoutRequestScreen({super.key});

  @override
  State<TrainerPayoutRequestScreen> createState() =>
      _TrainerPayoutRequestScreenState();
}

class _TrainerPayoutRequestScreenState
    extends State<TrainerPayoutRequestScreen> {
  final PayoutService _payoutService = PayoutService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardOwnerController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  
  int _withdrawable = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<PayoutRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _cardOwnerController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final withdrawable = await _payoutService.getTrainerWithdrawable(user.id);
        final requests = await _payoutService.getTrainerPayoutRequests(user.id);
        
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () {
            _withdrawable = withdrawable;
            _requests = requests;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگذاری اطلاعات: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    final amount = int.tryParse(_amountController.text);
    
    if (amount == null || amount <= 0) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'لطفاً مبلغ معتبری وارد کنید',
        backgroundColor: Colors.red,
      );
      return;
    }

    final amountInRial = amount * 10; // تبدیل به ریال

    // بررسی حداقل مبلغ
    if (amountInRial < PaymentConstants.minWithdrawalAmount) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'حداقل مبلغ برداشت ${PaymentConstants.formatAmount(PaymentConstants.minWithdrawalAmount)} است',
        backgroundColor: Colors.red,
      );
      return;
    }

    // بررسی حداکثر مبلغ
    if (amountInRial > PaymentConstants.maxWithdrawalAmount) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'حداکثر مبلغ برداشت ${PaymentConstants.formatAmount(PaymentConstants.maxWithdrawalAmount)} است',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (amountInRial > _withdrawable) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'مبلغ درخواستی بیشتر از موجودی قابل برداشت است (${PaymentConstants.formatAmount(_withdrawable)})',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_cardNumberController.text.trim().isEmpty) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'لطفاً شماره کارت را وارد کنید',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_cardOwnerController.text.trim().isEmpty) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'لطفاً نام صاحب کارت را وارد کنید',
        backgroundColor: Colors.red,
      );
      return;
    }

    WidgetSafetyUtils.safeSetState(this, () => _isSubmitting = true);
    try {
      final result = await _payoutService.createPayoutRequest(
        amount: amountInRial,
        cardNumber: _cardNumberController.text.trim(),
        cardOwnerName: _cardOwnerController.text.trim(),
        bankName: _bankNameController.text.trim().isNotEmpty
? _bankNameController.text.trim()
            : null,
      );

      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isSubmitting = false);
        
        if (result['success'] == true) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'درخواست با موفقیت ثبت شد',
            backgroundColor: Colors.green,
          );
          
          // پاک کردن فرم
          _amountController.clear();
          _cardNumberController.clear();
          _cardOwnerController.clear();
          _bankNameController.clear();
          
          _loadData();
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            result['error'] as String? ?? 'خطا در ثبت درخواست',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isSubmitting = false);
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در ثبت درخواست: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'درخواست برداشت',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.goldColor,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // کارت موجودی قابل برداشت
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.2),
                              AppTheme.goldColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.wallet,
                              color: AppTheme.goldColor,
                              size: 32.sp,
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'موجودی قابل برداشت',
                                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                          : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    PaymentConstants.formatAmount(_withdrawable),
                                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppTheme.darkTextColor
                                          : AppTheme.lightTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // فرم درخواست
                      Text(
                        'فرم درخواست برداشت',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextColor
                              : AppTheme.lightTextColor,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      // مبلغ
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'مبلغ (تومان)',
                          hintText: 'مثال: 100000',
                          helperText: 'حداقل: ${PaymentConstants.formatAmount(PaymentConstants.minWithdrawalAmount)}',
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.maximize2),
                            onPressed: () {
                              final maxAmount = (_withdrawable ~/ 10).clamp(
                                PaymentConstants.minWithdrawalAmount ~/ 10,
                                PaymentConstants.maxWithdrawalAmount ~/ 10,
                              );
                              _amountController.text = maxAmount.toString();
                            },
                            tooltip: 'حداکثر',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBackgroundColor
                              : AppTheme.lightBackgroundColor,
                        ),
                      ),
                      if (_withdrawable < PaymentConstants.minWithdrawalAmount) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                color: Colors.orange,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'موجودی شما کمتر از حداقل مبلغ برداشت است. حداقل ${PaymentConstants.formatAmount(PaymentConstants.minWithdrawalAmount)} نیاز است.',
                                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12.sp,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),
                      
                      // شماره کارت
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19), // حداکثر 19 رقم
                          CardNumberInputFormatter(), // فرمت خودکار با فاصله
                        ],
                        decoration: InputDecoration(
                          labelText: 'شماره کارت',
                          hintText: '1234 5678 9012 3456',
                          helperText: '16 رقم شماره کارت خود را وارد کنید',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBackgroundColor
                              : AppTheme.lightBackgroundColor,
                        ),
                        onChanged: (value) {
                          // اعتبارسنجی real-time (برای آینده می‌تونیم indicator اضافه کنیم)
                        },
                      ),
                      SizedBox(height: 16.h),
                      
                      // نام صاحب کارت
                      TextField(
                        controller: _cardOwnerController,
                        decoration: InputDecoration(
                          labelText: 'نام صاحب کارت',
                          hintText: 'نام و نام خانوادگی',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBackgroundColor
                              : AppTheme.lightBackgroundColor,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      // نام بانک (اختیاری)
                      TextField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'نام بانک (اختیاری)',
                          hintText: 'مثال: ملی، صادرات، ...',
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
                      
                      // دکمه ارسال
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _withdrawable == 0
                              ? null
                              : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            disabledBackgroundColor: AppTheme.goldColor.withValues(alpha: 0.5),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'ارسال درخواست',
                                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // تاریخچه درخواست‌ها
                      if (_requests.isNotEmpty) ...[
                        Text(
                          'تاریخچه درخواست‌ها',
                          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ..._requests.map((request) => _buildRequestCard(
                              context,
                              request,
                              isDark,
                            )),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    PayoutRequest request,
    bool isDark,
  ) {
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
                      PaymentConstants.formatAmount(request.amount),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                      ),
                    ),
                    if (request.hasPenalty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'جریمه: ${request.formattedPenaltyAmount}',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 14.sp,
                          color: Colors.red,
                        ),
                      ),
                    ],
                    if (request.finalAmount != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'مبلغ نهایی: ${request.formattedFinalAmount}',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldColor,
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
    fontFamily: AppTheme.fontFamily,
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
    fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                  : AppTheme.lightTextSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'تاریخ: ${_formatDate(request.createdAt)}',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                  : AppTheme.lightTextSecondary.withValues(alpha: 0.7),
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
    fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: isDark
                      ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

