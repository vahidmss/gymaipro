import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/payment/services/payment_resume_tracker.dart';
import 'package:gymaipro/payment/services/payment_session_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/external_url_launcher.dart';
import 'package:gymaipro/utils/payment_guard.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// شیت شارژ کیف پول — الگوی Revolut / Apple Cash
class WalletTopUpSheet extends StatefulWidget {
  const WalletTopUpSheet({super.key});

  /// مبالغ پیشنهادی (ریال)
  static const presetAmounts = [50000, 100000, 200000, 500000, 1000000];

  static Future<bool> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WalletTopUpSheet(),
    ).then((value) => value ?? false);
  }

  @override
  State<WalletTopUpSheet> createState() => _WalletTopUpSheetState();
}

class _WalletTopUpSheetState extends State<WalletTopUpSheet> {
  final _sessionService = PaymentSessionService();
  final _amountController = TextEditingController();

  int _selectedAmount = 100000;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _amountController.text = _formatInputAmount(_selectedAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  String _formatInputAmount(int rial) {
    final toman = (rial / 10).round();
    return toman.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void _onAmountChanged() {
    if (!_amountController.isSafe) return;
    final clean = _amountController.safeText.replaceAll(RegExp(r'[^\d]'), '');
    final toman = int.tryParse(clean) ?? 0;
    final rial = toman * 10;
    if (rial == _selectedAmount) return;
    setState(() {
      _selectedAmount = rial;
      _errorMessage = null;
    });
  }

  void _selectPreset(int rial) {
    _amountController.removeListener(_onAmountChanged);
    setState(() {
      _selectedAmount = rial;
      if (_amountController.isSafe) {
        _amountController.safeSetText(_formatInputAmount(rial));
      }
      _errorMessage = null;
    });
    _amountController.addListener(_onAmountChanged);
  }

  bool get _isValid =>
      _selectedAmount >= PaymentConstants.minWalletCharge &&
      _selectedAmount <= PaymentConstants.maxWalletCharge;

  Future<void> _pay() async {
    if (!_isValid || _isProcessing) return;
    if (PaymentGuard.blocksOnlineCheckout) {
      if (mounted) await PaymentGuard.showManualPaymentDialog(context);
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final amountInToman = (_selectedAmount / 10).round();
      final sessionId = await _sessionService.createPaymentSession(
        amount: amountInToman,
        expirationMinutes: 30,
      );
      if (sessionId == null) throw Exception('خطا در ایجاد جلسه پرداخت');

      PaymentResumeTracker.instance.track(sessionId);
      final url =
          '${AppConfig.wordpressApiOrigin}/pay/topup?session_id=$sessionId';

      final launched = await ExternalUrlLauncher.openPaymentUrl(url);
      if (!launched) {
        await ExternalUrlLauncher.copyToClipboard(url);
        throw Exception('مرورگر باز نشد — لینک کپی شد.');
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درگاه پرداخت باز شد. پس از پرداخت به اپ برگردید.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.separatorColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'شارژ کیف پول',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  PaymentConstants.formatAmount(_selectedAmount),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: _isValid ? AppTheme.goldColor : context.textSecondary,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'مبلغ دلخواه یا یکی از گزینه‌ها را انتخاب کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    color: context.textSecondary,
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'مبلغ به تومان',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                    ),
                    filled: true,
                    fillColor: context.backgroundColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  height: 42.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: WalletTopUpSheet.presetAmounts.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, i) {
                      final amount = WalletTopUpSheet.presetAmounts[i];
                      final selected = _selectedAmount == amount;
                      return GestureDetector(
                        onTap: () => _selectPreset(amount),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.goldColor
                                : context.backgroundColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.goldColor
                                  : context.separatorColor,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            PaymentConstants.formatAmount(amount),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppTheme.onGoldColor
                                  : context.textColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
                SizedBox(height: 18.h),
                SizedBox(
                  height: 52.h,
                  child: FilledButton(
                    onPressed: _isValid && !_isProcessing ? _pay : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      disabledBackgroundColor:
                          AppTheme.goldColor.withValues(alpha: 0.3),
                      foregroundColor: AppTheme.onGoldColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.onGoldColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.lock, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'ادامه به درگاه امن',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'پرداخت از طریق درگاه بانکی زیبال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
