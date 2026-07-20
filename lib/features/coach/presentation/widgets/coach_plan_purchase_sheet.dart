import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/payment/models/ai_coach_plan_price.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/services/ai_coach_plan_price_service.dart';
import 'package:gymaipro/payment/services/coach_plan_payment_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/payment/widgets/purchase_success_dialog.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/external_url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// شیت جزئیات / امکانات / خرید پلن مربی هوشمند
Future<bool?> showCoachPlanPurchaseSheet(
  BuildContext context, {
  required CoachSubscriptionPlan currentPlan,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CoachPlanPurchaseSheet(currentPlan: currentPlan),
  );
}

class CoachPlanPurchaseSheet extends StatefulWidget {
  const CoachPlanPurchaseSheet({required this.currentPlan, super.key});

  final CoachSubscriptionPlan currentPlan;

  @override
  State<CoachPlanPurchaseSheet> createState() => _CoachPlanPurchaseSheetState();
}

enum _PayPhase { idle, processing, success, error }

class _CoachPlanPurchaseSheetState extends State<CoachPlanPurchaseSheet> {
  final AiCoachPlanPriceService _priceService = AiCoachPlanPriceService();
  final CoachPlanPaymentService _paymentService = CoachPlanPaymentService();
  final WalletService _walletService = WalletService();
  final TextEditingController _discountController = TextEditingController();

  List<AiCoachPlanPrice> _prices = const [];
  String? _selectedPlanId;
  int _walletBalance = 0;
  bool _loading = true;
  _PayPhase _phase = _PayPhase.idle;
  String? _errorMessage;
  String? _tappedMethod;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prices = await _priceService.getActiveSellablePrices();
      final wallet = await _walletService.getUserWallet();
      if (!mounted) return;

      final currentId = CoachPlanCatalog.idFromPlan(widget.currentPlan);
      String? selected;
      for (final p in prices) {
        if (p.planId != currentId) {
          selected = p.planId;
          break;
        }
      }
      selected ??= prices.isNotEmpty ? prices.first.planId : null;

      setState(() {
        _prices = prices;
        _selectedPlanId = selected;
        _walletBalance = wallet?.availableBalance ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطا در بارگذاری پلن‌ها: $e';
        _phase = _PayPhase.error;
      });
    }
  }

  AiCoachPlanPrice? get _selectedPrice {
    final id = _selectedPlanId;
    if (id == null) return null;
    for (final p in _prices) {
      if (p.planId == id) return p;
    }
    return null;
  }

  Future<void> _pay(String method) async {
    final price = _selectedPrice;
    if (price == null || _phase == _PayPhase.processing) return;

    final currentId = CoachPlanCatalog.idFromPlan(widget.currentPlan);
    if (price.planId == currentId) {
      setState(() {
        _phase = _PayPhase.error;
        _errorMessage = 'شما همین پلن را فعال دارید';
      });
      return;
    }

    setState(() {
      _phase = _PayPhase.processing;
      _tappedMethod = method;
      _errorMessage = null;
    });
    await HapticFeedback.lightImpact();

    final result = await _paymentService.purchasePlan(
      planId: price.planId,
      paymentMethod: method,
      discountCode: _discountController.text.trim().isEmpty
          ? null
          : _discountController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      if (method == 'wallet') {
        await HapticFeedback.heavyImpact();
        setState(() => _phase = _PayPhase.success);
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.of(context).pop(true);
        await PurchaseSuccessDialog.show(
          context,
          serviceName: price.title,
          trainerName: 'مربی هوشمند',
          onViewPrograms: () {},
        );
      } else {
        final paymentUrl = result['payment_url']?.toString();
        Navigator.of(context).pop(false);
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          await ExternalUrlLauncher.openPaymentUrl(paymentUrl);
        }
      }
    } else {
      await HapticFeedback.heavyImpact();
      setState(() {
        _phase = _PayPhase.error;
        _errorMessage = result['error']?.toString() ?? 'خطا در پردازش پرداخت';
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _phase = _PayPhase.idle;
        _errorMessage = null;
        _tappedMethod = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.gymCard,
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
                            color: context.gymTextSecondary.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'پلن مربی هوشمند',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.gymTextPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'پلن فعلی: ${CoachPlanCatalog.persianTitle(widget.currentPlan)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.gymTextSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        CoachPlanCatalog.descriptionForPlan(widget.currentPlan),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.gymTextSecondary,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      ..._prices.map(_buildPlanCard),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: _discountController,
                        enabled: _phase == _PayPhase.idle,
                        decoration: InputDecoration(
                          labelText: 'کد تخفیف (اختیاری)',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            LucideIcons.ticket,
                            color: context.gymTextSecondary,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'موجودی کیف پول: ${PaymentConstants.formatAmount(_walletBalance)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.gymTextSecondary,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),
                      if (_phase == _PayPhase.success)
                        Center(
                          child: Icon(
                            LucideIcons.circleCheck,
                            color: Colors.green,
                            size: 48.sp,
                          ),
                        )
                      else ...[
                        _PayButton(
                          label: 'پرداخت از کیف پول',
                          icon: LucideIcons.wallet,
                          loading:
                              _phase == _PayPhase.processing &&
                              _tappedMethod == 'wallet',
                          enabled: _phase == _PayPhase.idle,
                          onTap: () => _pay('wallet'),
                        ),
                        SizedBox(height: 10.h),
                        _PayButton(
                          label: 'پرداخت از درگاه',
                          icon: LucideIcons.creditCard,
                          loading:
                              _phase == _PayPhase.processing &&
                              _tappedMethod == 'direct',
                          enabled: _phase == _PayPhase.idle,
                          outlined: true,
                          onTap: () => _pay('direct'),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(AiCoachPlanPrice price) {
    final selected = price.planId == _selectedPlanId;
    final isCurrent =
        price.planId == CoachPlanCatalog.idFromPlan(widget.currentPlan);
    final features = price.features.isNotEmpty
        ? price.features
        : CoachPlanCatalog.featureLabelsForPlan(
            CoachPlanCatalog.planFromId(price.planId),
          );

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: selected
            ? context.gymPrimary.withValues(alpha: 0.12)
            : context.gymSurface,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: _phase == _PayPhase.idle
              ? () => setState(() => _selectedPlanId = price.planId)
              : null,
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: selected
                    ? context.gymPrimary
                    : context.gymTextSecondary.withValues(alpha: 0.2),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        price.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: context.gymTextPrimary,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'فعال',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  price.description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.gymTextSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${PaymentConstants.formatAmount(price.priceRial)} / ${price.validityDays} روز',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: context.gymPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                ...features.take(6).map(
                  (f) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 14.sp,
                          color: context.gymPrimary,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.gymTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.loading,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? context.gymPrimary : Colors.black,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp),
              SizedBox(width: 8.w),
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.gymPrimary,
          side: BorderSide(color: context.gymPrimary),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.goldColor,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: child,
    );
  }
}
