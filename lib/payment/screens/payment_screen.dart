import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/discount_code.dart';
import 'package:gymaipro/payment/models/payment_plan.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/services/discount_service.dart';
import 'package:gymaipro/payment/services/payment_gateway_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/payment/widgets/discount_input.dart';
import 'package:gymaipro/payment/widgets/payment_method_card.dart';
import 'package:gymaipro/payment/widgets/payment_summary.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({required this.plan, super.key, this.metadata});
  final PaymentPlan plan;
  final Map<String, dynamic>? metadata;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentGatewayService _paymentService = PaymentGatewayService();
  final WalletService _walletService = WalletService();
  final DiscountService _discountService = DiscountService();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.direct;
  PaymentGateway _selectedGateway = PaymentGateway.zibal;

  int _originalAmount = 0;
  int _discountAmount = 0;
  int _finalAmount = 0;

  DiscountCode? _appliedDiscount;
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  bool _hasWalletBalance = false;
  int _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _originalAmount = widget.plan.price;
    _finalAmount = _originalAmount;
    _loadWalletInfo();
  }

  Future<void> _loadWalletInfo() async {
    try {
      final wallet = await _walletService.getUserWallet();
      if (wallet != null && mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _hasWalletBalance = wallet.availableBalance > 0;
          _walletBalance = wallet.availableBalance;
        });
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری اطلاعات کیف پول: $e');
    }
  }

  void _onDiscountApplied(Map<String, dynamic> discountResult) {
    if (discountResult['valid'] == true) {
      setState(() {
        _appliedDiscount = DiscountCode.fromJson(
          discountResult['discount_code'] as Map<String, dynamic>,
        );
        _discountAmount = discountResult['discount_amount'] as int;
        _finalAmount = discountResult['final_amount'] as int;
      });
    }
  }

  void _onDiscountRemoved() {
    setState(() {
      _appliedDiscount = null;
      _discountAmount = 0;
      _finalAmount = _originalAmount;
    });
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    WidgetSafetyUtils.safeSetState(this, () {
      _isProcessing = true;
    });

    try {
      // ایجاد تراکنش
      final transaction = PaymentTransaction(
        id: PaymentConstants.generateTransactionId(),
        userId: 'current_user_id', // باید از AuthHelper دریافت شود
        amount: _originalAmount,
        finalAmount: _finalAmount,
        discountAmount: _discountAmount,
        discountCode: _appliedDiscount?.code,
        type: _getTransactionType(),
        status: TransactionStatus.pending,
        paymentMethod: _selectedPaymentMethod,
        gateway: _selectedGateway,
        description: _getTransactionDescription(),
        metadata: widget.metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: PaymentConstants.getTransactionExpiry(),
      );

      Map<String, dynamic>? result;

      if (_selectedPaymentMethod == PaymentMethod.wallet) {
        // پرداخت از کیف پول
        result = await _processWalletPayment(transaction);
      } else if (_selectedPaymentMethod == PaymentMethod.mixed) {
        // پرداخت ترکیبی
        result = await _processMixedPayment(transaction);
      } else {
        // پرداخت مستقیم
        result = await _processDirectPayment(transaction);
      }

      if (result != null && result['success'] == true) {
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () {
            _paymentSuccess = true;
            _isProcessing = false;
          });
          await Future<void>.delayed(const Duration(milliseconds: 650));
          if (!mounted) return;
          _showSuccessDialog(
            (result['message'] as String?) ?? 'پرداخت با موفقیت انجام شد',
          );
        }
      } else {
        _showErrorDialog(
          (result?['error'] as String?) ?? 'خطا در پردازش پرداخت',
        );
      }
    } catch (e) {
      _showErrorDialog('خطا در پردازش پرداخت: $e');
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isProcessing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _processWalletPayment(
    PaymentTransaction transaction,
  ) async {
    final success = await _walletService.payFromWallet(
      amount: _finalAmount,
      description: transaction.description,
      referenceId: transaction.id,
      metadata: transaction.metadata ?? {},
    );

    if (success) {
      // اعمال کد تخفیف در صورت وجود
      if (_appliedDiscount != null) {
        await _discountService.applyDiscountCode(
          code: _appliedDiscount!.code,
          userId: transaction.userId,
          transactionId: transaction.id,
          originalAmount: _originalAmount,
          discountAmount: _discountAmount,
        );
      }

      return {
        'success': true,
        'message': PaymentConstants.paymentSuccess,
        'method': 'wallet',
      };
    } else {
      return {'success': false, 'error': PaymentConstants.insufficientBalance};
    }
  }

  Future<Map<String, dynamic>?> _processMixedPayment(
    PaymentTransaction transaction,
  ) async {
    // محاسبه مبلغ قابل پرداخت از کیف پول
    final walletAmount = _walletBalance < _finalAmount
        ? _walletBalance
        : _finalAmount;
    final remainingAmount = _finalAmount - walletAmount;

    if (remainingAmount > 0) {
      // پرداخت باقی‌مانده از درگاه
      final gatewayResult = await _paymentService.processPayment(
        transaction: transaction.copyWith(finalAmount: remainingAmount),
        gateway: _selectedGateway,
        callbackUrl: 'https://app.gymaipro.ir/payment/callback',
      );

      return gatewayResult;
    } else {
      // تمام مبلغ از کیف پول
      return _processWalletPayment(transaction);
    }
  }

  Future<Map<String, dynamic>?> _processDirectPayment(
    PaymentTransaction transaction,
  ) async {
    return _paymentService.processPayment(
      transaction: transaction,
      gateway: _selectedGateway,
      callbackUrl: 'https://app.gymaipro.ir/payment/callback',
    );
  }

  TransactionType _getTransactionType() {
    switch (widget.plan.type) {
      case PaymentPlanType.aiProgram:
        return TransactionType.aiProgram;
      case PaymentPlanType.subscription:
        return TransactionType.subscription;
      case PaymentPlanType.trainerService:
        return TransactionType.trainerService;
      case PaymentPlanType.walletCharge:
        return TransactionType.walletCharge;
      default:
        return TransactionType.payment;
    }
  }

  String _getTransactionDescription() {
    return 'خرید ${widget.plan.name}';
  }

  void _showSuccessDialog(String message) {
    WidgetSafetyUtils.safeShowDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'پرداخت موفق',
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
        content: Text(message, style: TextStyle(
    fontFamily: AppTheme.fontFamily,fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              WidgetSafetyUtils.safePop(context);
              WidgetSafetyUtils.safePop(context); // بازگشت به صفحه قبلی
            },
            child: Text(
              'باشه',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'خطا در پرداخت',
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
        content: Text(message, style: TextStyle(
    fontFamily: AppTheme.fontFamily,fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => WidgetSafetyUtils.safePop(context),
            child: Text(
              'متوجه شدم',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'پرداخت',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldColor,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
            onPressed: () => WidgetSafetyUtils.safePop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اطلاعات طرح
              _buildPlanInfo(),
              const SizedBox(height: 24),

              // کد تخفیف
              DiscountInput(
                originalAmount: _originalAmount,
                onDiscountApplied: _onDiscountApplied,
                onDiscountRemoved: _onDiscountRemoved,
              ),
              const SizedBox(height: 24),

              // روش پرداخت
              _buildPaymentMethods(),
              const SizedBox(height: 24),

              // خلاصه پرداخت
              PaymentSummary(
                originalAmount: _originalAmount,
                discountAmount: _discountAmount,
                finalAmount: _finalAmount,
                appliedDiscount: _appliedDiscount,
              ),
              const SizedBox(height: 32),

              // دکمه پرداخت
              _buildPaymentButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getPlanIcon(), color: AppTheme.goldColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.plan.name,
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldColor,
                  ),
                ),
              ),
              if (widget.plan.isPopular)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'محبوب',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.plan.shortDescription,
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قیمت:',
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.plan.hasDiscount) ...[
                    Text(
                      widget.plan.formattedOriginalPrice,
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        color: Colors.white54,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    widget.plan.formattedPrice,
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'روش پرداخت',
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
        const SizedBox(height: 16),

        // پرداخت مستقیم
        PaymentMethodCard(
          title: 'پرداخت مستقیم',
          subtitle: 'پرداخت از طریق کارت بانکی',
          icon: LucideIcons.creditCard,
          isSelected: _selectedPaymentMethod == PaymentMethod.direct,
          onTap: () {
            setState(() {
              _selectedPaymentMethod = PaymentMethod.direct;
            });
          },
        ),
        const SizedBox(height: 12),

        // پرداخت از کیف پول
        if (_hasWalletBalance)
          PaymentMethodCard(
            title: 'کیف پول',
            subtitle:
                'موجودی: ${PaymentConstants.formatAmount(_walletBalance)}',
            icon: LucideIcons.wallet,
            isSelected: _selectedPaymentMethod == PaymentMethod.wallet,
            isEnabled: _walletBalance >= _finalAmount,
            onTap: () {
              setState(() {
                _selectedPaymentMethod = PaymentMethod.wallet;
              });
            },
          ),

        if (_hasWalletBalance) const SizedBox(height: 12),

        // پرداخت ترکیبی
        if (_hasWalletBalance && _walletBalance < _finalAmount)
          PaymentMethodCard(
            title: 'پرداخت ترکیبی',
            subtitle: 'کیف پول + کارت بانکی',
            icon: LucideIcons.shuffle,
            isSelected: _selectedPaymentMethod == PaymentMethod.mixed,
            onTap: () {
              setState(() {
                _selectedPaymentMethod = PaymentMethod.mixed;
              });
            },
          ),

        // انتخاب درگاه پرداخت
        if (_selectedPaymentMethod == PaymentMethod.direct ||
            _selectedPaymentMethod == PaymentMethod.mixed) ...[
          const SizedBox(height: 24),
          Text(
            'درگاه پرداخت',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGatewayOption(
                  PaymentGateway.zibal,
                  'زیبال',
                  'assets/images/zibal_logo.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGatewayOption(
                  PaymentGateway.zarinpal,
                  'زرین‌پال',
                  'assets/images/zarinpal_logo.png',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGatewayOption(
    PaymentGateway gateway,
    String name,
    String logoPath,
  ) {
    final isSelected = _selectedGateway == gateway;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGateway = gateway;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldColor.withValues(alpha: 0.1)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppTheme.goldColor : Colors.white24,
            width: 2.w,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                color: isSelected ? AppTheme.goldColor : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final isProcessing = _isProcessing && !_paymentSuccess;
    final isSuccess = _paymentSuccess;

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: isProcessing || isSuccess ? null : _processPayment,
        icon: isSuccess
            ? Icon(LucideIcons.check, size: 22.sp, color: Colors.white)
            : isProcessing
                ? SizedBox(
                    width: 22.w,
                    height: 22.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const SizedBox.shrink(),
        label: Text(
          isSuccess
              ? 'موفق'
              : isProcessing
                  ? 'لطفا صبر کنید...'
                  : 'پرداخت ${PaymentConstants.formatAmount(_finalAmount)}',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSuccess
              ? const Color(0xFF4CAF50)
              : AppTheme.goldColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  IconData _getPlanIcon() {
    switch (widget.plan.type) {
      case PaymentPlanType.aiProgram:
        return LucideIcons.brain;
      case PaymentPlanType.subscription:
        return LucideIcons.crown;
      case PaymentPlanType.trainerService:
        return LucideIcons.userCheck;
      case PaymentPlanType.walletCharge:
        return LucideIcons.wallet;
      default:
        return LucideIcons.package;
    }
  }
}
