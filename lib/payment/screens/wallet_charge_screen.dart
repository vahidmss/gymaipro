import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/services/payment_session_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحه شارژ کیف پول
class WalletChargeScreen extends StatefulWidget {
  const WalletChargeScreen({super.key});

  @override
  State<WalletChargeScreen> createState() => _WalletChargeScreenState();
}

class _WalletChargeScreenState extends State<WalletChargeScreen> {
  final PaymentSessionService _sessionService = PaymentSessionService();
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();

  // مقادیر پیش‌فرض برای شارژ (به تومان)
  final List<int> _presetAmounts = [50000, 100000, 200000, 500000, 1000000];

  int _selectedAmount = 0;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text;
    // حذف تمام کاراکترهای غیرعددی به جز کاما
    final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(cleanText) ?? 0;

    if (kDebugMode) {
      print('=== AMOUNT PARSING DEBUG ===');
      print('Original text: "$text"');
      print('Clean text: "$cleanText"');
      print('Parsed amount: $amount');
      print('Current selected: $_selectedAmount');
      print('===========================');
    }

    // فقط اگر مقدار تغییر کرده باشد، state را به‌روزرسانی کن
    if (amount != _selectedAmount) {
      setState(() {
        _selectedAmount = amount;
        _errorMessage = null;
      });
    }
  }

  void _selectPresetAmount(int amount) {
    if (kDebugMode) {
      print('=== SELECT PRESET AMOUNT ===');
      print('Selected amount: $amount');
      print('Previous amount: $_selectedAmount');
      print('Formatted: ${PaymentConstants.formatAmount(amount)}');
      print('==========================');
    }

    // ابتدا listener را حذف کن تا تداخل نداشته باشد
    _amountController.removeListener(_onAmountChanged);

    setState(() {
      _selectedAmount = amount;
      _amountController.text = PaymentConstants.formatAmount(amount);
      _errorMessage = null;
    });

    // دوباره listener را اضافه کن
    _amountController.addListener(_onAmountChanged);
  }

  bool _isValidAmount() {
    final isValid =
        _selectedAmount > 0 &&
        _selectedAmount >= PaymentConstants.minWalletCharge &&
        _selectedAmount <= PaymentConstants.maxWalletCharge;

    if (kDebugMode) {
      print('=== VALIDATION DEBUG ===');
      print('Selected Amount: $_selectedAmount');
      print('Min Required: ${PaymentConstants.minWalletCharge}');
      print('Max Allowed: ${PaymentConstants.maxWalletCharge}');
      print('Is Valid: $isValid');
      print('=======================');
    }

    return isValid;
  }

  Future<void> _processCharge() async {
    if (!_isValidAmount() || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // ایجاد جلسه پرداخت - ارسال مبلغ به تومان (وردپرس با IRT ×10 می‌کند)
      final amountInToman = (_selectedAmount / 10).round();
      final sessionId = await _sessionService.createPaymentSession(
        amount: amountInToman,
        expirationMinutes: 30, // 30 دقیقه
      );

      if (sessionId == null) {
        throw Exception('خطا در ایجاد جلسه پرداخت');
      }

      // آدرس سایت وردپرس (باید با آدرس واقعی جایگزین شود)
      const wordpressUrl = 'https://gymaipro.ir'; // آدرس واقعی سایت شما
      final paymentUrl = '$wordpressUrl/pay/topup?session_id=$sessionId';

      if (kDebugMode) {
        print(
          'Amount (rial): $_selectedAmount | Amount (toman): $amountInToman',
        );
        print('آدرس پرداخت: $paymentUrl');
      }

      // هدایت به سایت پرداخت
      final uri = Uri.parse(paymentUrl);

      if (kDebugMode) {
        print('تلاش برای باز کردن URL: $paymentUrl');
        print('canLaunchUrl result: ${await canLaunchUrl(uri)}');
      }

      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (kDebugMode) {
          print('URL launched successfully: $launched');
        }

        // نمایش پیام موفقیت
        if (mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        if (kDebugMode) {
          print('خطا در launchUrl: $e');
        }

        // تلاش با mode متفاوت
        try {
          await launchUrl(uri);

          if (mounted) {
            _showSuccessDialog();
          }
        } catch (e2) {
          if (kDebugMode) {
            print('خطا در launchUrl با platformDefault: $e2');
          }
          throw Exception('خطا در باز کردن صفحه پرداخت: $e2');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('هدایت به پرداخت'),
        content: const Text(
          'صفحه پرداخت در مرورگر باز شد. پس از تکمیل پرداخت، به اپلیکیشن بازگردید.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // بازگشت به صفحه قبلی
            },
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطا'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.backgroundColor,
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              _buildHeader(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // کارت اطلاعات کیف پول
                      _buildWalletInfoCard(),
                      const SizedBox(height: 32),

                      // انتخاب مبلغ
                      _buildAmountSection(),
                      const SizedBox(height: 32),

                      // مبالغ پیش‌فرض
                      _buildPresetAmounts(),
                      const SizedBox(height: 32),

                      // دکمه پرداخت
                      _buildPaymentButton(),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        _buildErrorMessage(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شارژ کیف پول',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'موجودی خود را افزایش دهید',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(LucideIcons.wallet, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfoCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(LucideIcons.wallet, color: Colors.white, size: 28.sp),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موجودی فعلی',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16.sp,
                    color: Colors.white.withValues(alpha: 0.1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: _walletService.getUserWallet(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final wallet = snapshot.data!;
                      return Text(
                        PaymentConstants.formatAmount(wallet.availableBalance),
                        style: GoogleFonts.vazirmatn(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }
                    return Text(
                      'در حال بارگذاری...',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 20.sp,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'تومان',
              style: GoogleFonts.vazirmatn(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  LucideIcons.dollarSign,
                  color: AppTheme.primaryColor,
                  size: 24.sp,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مبلغ شارژ',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مبلغ مورد نظر خود را وارد کنید',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _selectedAmount > 0
                    ? AppTheme.primaryColor
                    : Colors.grey[200]!,
                width: 2.w,
              ),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'مبلغ مورد نظر را وارد کنید',
                hintStyle: GoogleFonts.vazirmatn(
                  color: Colors.grey[500],
                  fontSize: 16.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 20.h,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 16),
                  child: Icon(
                    LucideIcons.dollarSign,
                    color: AppTheme.primaryColor,
                    size: 20.sp,
                  ),
                ),
                suffixText: 'تومان',
                suffixStyle: GoogleFonts.vazirmatn(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              style: GoogleFonts.vazirmatn(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.info, size: 16.sp, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                'حداقل: ${PaymentConstants.formatAmount(PaymentConstants.minWalletCharge)} تومان',
                style: GoogleFonts.vazirmatn(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetAmounts() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  LucideIcons.creditCard,
                  color: AppTheme.primaryColor,
                  size: 24.sp,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مبالغ پیشنهادی',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'یکی از مبالغ زیر را انتخاب کنید',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presetAmounts.asMap().entries.map((entry) {
              final index = entry.key;
              final amount = entry.value;
              final isSelected = _selectedAmount == amount;

              return SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (kDebugMode) {
                        print('=== PRESET AMOUNT DEBUG ===');
                        print('Clicked amount: $amount');
                        print('Index: $index');
                        print('Current selected: $_selectedAmount');
                        print('========================');
                      }
                      _selectPresetAmount(amount);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[200]!,
                          width: 2.w,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 12.r,
                                  offset: Offset(0.w, 4.h),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 4.r,
                                  offset: Offset(0.w, 2.h),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              PaymentConstants.formatAmount(amount),
                              style: GoogleFonts.vazirmatn(
                                fontSize: 16.sp,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'تومان',
                              style: GoogleFonts.vazirmatn(
                                fontSize: 12.sp,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final isValid = _isValidAmount();

    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
        gradient: isValid && !_isProcessing
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: isValid && !_isProcessing ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isValid && !_isProcessing
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 12.r,
                  offset: Offset(0.w, 4.h),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isValid && !_isProcessing ? _processCharge : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing) ...[
                  SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                ] else ...[
                  Icon(
                    LucideIcons.creditCard,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _isProcessing ? 'در حال پردازش...' : 'ادامه پرداخت',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.vazirmatn(
                fontSize: 14.sp,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
