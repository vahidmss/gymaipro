import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/services/pending_direct_payment_tracker.dart';
import 'package:gymaipro/payment/services/program_renewal_service.dart';
import 'package:gymaipro/payment/services/trainer_payment_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/payment/widgets/purchase_success_dialog.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/utils/external_url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// شیت تمدید برنامه با ۵۰٪ — کیف پول یا زیبال
Future<bool?> showProgramRenewalSheet(
  BuildContext context, {
  required String programId,
  VoidCallback? onRenewed,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProgramRenewalSheet(
      programId: programId,
      onRenewed: onRenewed,
    ),
  );
}

class _ProgramRenewalSheet extends StatefulWidget {
  const _ProgramRenewalSheet({
    required this.programId,
    this.onRenewed,
  });

  final String programId;
  final VoidCallback? onRenewed;

  @override
  State<_ProgramRenewalSheet> createState() => _ProgramRenewalSheetState();
}

class _ProgramRenewalSheetState extends State<_ProgramRenewalSheet> {
  final ProgramRenewalService _renewalService = ProgramRenewalService();
  final TrainerPaymentService _paymentService = TrainerPaymentService();
  final WalletService _walletService = WalletService();

  ProgramRenewalQuote? _quote;
  int _walletBalance = 0;
  bool _loading = true;
  bool _processing = false;
  String? _error;
  String? _busyMethod;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authUserId = await AuthHelper.getCurrentUserId();
      if (authUserId == null) {
        setState(() {
          _loading = false;
          _error = 'لطفاً دوباره وارد حساب شوید';
        });
        return;
      }

      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = (profile?['id'] as String?)?.trim();
      final effectiveUserId =
          (profileId != null && profileId.isNotEmpty) ? profileId : authUserId;

      final wallet = await _walletService.getUserWallet();
      var quote = await _renewalService.quote(
        programId: widget.programId,
        userId: effectiveUserId,
      );
      // بعضی ردیف‌های قدیمی ممکن است با auth uid ذخیره شده باشند
      quote ??= await _renewalService.quote(
        programId: widget.programId,
        userId: authUserId,
      );

      if (!mounted) return;
      if (quote == null) {
        setState(() {
          _loading = false;
          _error =
              'امکان تمدید این برنامه نیست. اگر مربی دارد با پشتیبانی تماس بگیر.';
        });
        return;
      }

      setState(() {
        _quote = quote;
        _walletBalance = wallet?.availableBalance ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'خطا در محاسبه تمدید: $e';
      });
    }
  }

  String _formatJalali(DateTime d) {
    final j = Jalali.fromDateTime(d);
    final f = j.formatter;
    return '${f.d} ${f.mN} ${f.yyyy}';
  }

  Future<void> _pay(String method) async {
    final quote = _quote;
    if (quote == null || _processing) return;

    setState(() {
      _processing = true;
      _busyMethod = method;
      _error = null;
    });
    await HapticFeedback.lightImpact();

    final result = await _paymentService.processProgramRenewal(
      quote: quote,
      paymentMethod: method,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      if (method == 'wallet') {
        await HapticFeedback.heavyImpact();
        widget.onRenewed?.call();
        if (!mounted) return;
        Navigator.of(context).pop(true);
        if (!mounted) return;
        await PurchaseSuccessDialog.show(
          context,
          serviceName: 'تمدید ${quote.programName}',
          trainerName: quote.trainerName,
          onViewPrograms: () {},
        );
      } else {
        final paymentUrl = result['payment_url']?.toString();
        final trackId = result['track_id']?.toString();
        final transactionId = result['transaction_id']?.toString();
        if (!mounted) return;
        Navigator.of(context).pop(false);
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          if (transactionId != null &&
              trackId != null &&
              transactionId.isNotEmpty &&
              trackId.isNotEmpty) {
            await PendingDirectPaymentTracker.instance.track(
              type: 'trainer',
              transactionId: transactionId,
              trackId: trackId,
            );
          }
          await ExternalUrlLauncher.openPaymentUrl(paymentUrl);
        }
      }
      return;
    }

    await HapticFeedback.heavyImpact();
    setState(() {
      _processing = false;
      _busyMethod = null;
      _error = result['error']?.toString() ?? 'پرداخت ناموفق بود';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final quote = _quote;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? Padding(
                  padding: EdgeInsets.all(32.w),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: context.textSecondary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'تمدید با ۵۰٪ وفاداری',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'همان برنامه، همان مربی — فقط دسترسی را برای یک دورهٔ جدید باز می‌کنیم.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5.sp,
                          color: context.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (_error != null) ...[
                        SizedBox(height: 14.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppTheme.fatColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: AppTheme.fatColor,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                      if (quote != null) ...[
                        SizedBox(height: 18.h),
                        _infoRow('برنامه', quote.programName),
                        _infoRow('مربی', quote.trainerName),
                        _infoRow(
                          'قیمت کامل',
                          quote.fullPriceLabel,
                          strikethrough: true,
                        ),
                        _infoRow(
                          'مبلغ تمدید (۵۰٪)',
                          quote.renewPriceLabel,
                          emphasize: true,
                        ),
                        _infoRow(
                          'اعتبار تا',
                          _formatJalali(quote.newExpiry),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'موجودی کیف پول: ${PaymentConstants.formatAmount(_walletBalance)}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: context.textSecondary,
                          ),
                        ),
                        SizedBox(height: 18.h),
                        ElevatedButton.icon(
                          onPressed: _processing ||
                                  _walletBalance < quote.renewPriceRial
                              ? null
                              : () => _pay('wallet'),
                          icon: _busyMethod == 'wallet'
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.wallet),
                          label: Text(
                            _walletBalance >= quote.renewPriceRial
                                ? 'پرداخت از کیف پول'
                                : 'موجودی کیف پول کافی نیست',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: AppTheme.onGoldColor,
                            disabledBackgroundColor:
                                AppTheme.goldColor.withValues(alpha: 0.35),
                            minimumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        OutlinedButton.icon(
                          onPressed: _processing
                              ? null
                              : () => _pay('direct'),
                          icon: _busyMethod == 'direct'
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.creditCard),
                          label: const Text(
                            'پرداخت آنلاین (زیبال)',
                            style: TextStyle(fontFamily: AppTheme.fontFamily),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.goldColor,
                            side: const BorderSide(color: AppTheme.goldColor),
                            minimumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool emphasize = false,
    bool strikethrough = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: emphasize ? 15.sp : 13.sp,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? AppTheme.goldColor : context.textColor,
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
