import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/payment_plan.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/payment/screens/payment_screen.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/payment/widgets/subscription_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<Subscription> _subscriptions = [];
  List<PaymentPlan> _availablePlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptions = await _subscriptionService.getUserSubscriptions();
      final plans = PredefinedPlans.subscriptions;

      setState(() {
        _subscriptions = subscriptions;
        _availablePlans = plans;
      });
    } catch (e) {
      debugPrint('خطا در بارگذاری داده‌های اشتراک: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPurchasePlan(PaymentPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          plan: plan,
          metadata: {'subscription_type': plan.accessLevel.toString()},
        ),
      ),
    );
  }

  Future<void> _onCancelSubscription(Subscription subscription) async {
    final confirmed = await _showCancelConfirmDialog();
    if (confirmed ?? false) {
      try {
        final success = await _subscriptionService.cancelSubscription(
          subscriptionId: subscription.id,
          reason: 'لغو توسط کاربر',
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'اشتراک با موفقیت لغو شد',
                style: GoogleFonts.vazirmatn(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadSubscriptionData();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در لغو اشتراک: $e',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onRenewSubscription(Subscription subscription) {
    // پیدا کردن طرح مربوطه
    final plan = _availablePlans.firstWhere(
      (p) => p.type == PaymentPlanType.subscription,
      orElse: () => _availablePlans.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          plan: plan,
          metadata: {'renewal': true, 'subscription_id': subscription.id},
        ),
      ),
    );
  }

  Future<bool?> _showCancelConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'لغو اشتراک',
          style: GoogleFonts.vazirmatn(
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید اشتراک خود را لغو کنید؟',
          style: GoogleFonts.vazirmatn(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'انصراف',
              style: GoogleFonts.vazirmatn(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'لغو اشتراک',
              style: GoogleFonts.vazirmatn(color: Colors.red),
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
            'اشتراک‌ها',
            style: GoogleFonts.vazirmatn(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldColor,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadSubscriptionData,
                color: AppTheme.goldColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اشتراک‌های فعلی
                      if (_subscriptions.isNotEmpty) ...[
                        Text(
                          'اشتراک‌های شما',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._subscriptions.map(
                          (subscription) => SubscriptionCard(
                            subscription: subscription,
                            onCancel: subscription.isActive
                                ? () => _onCancelSubscription(subscription)
                                : null,
                            onRenew:
                                subscription.status ==
                                    SubscriptionStatus.expired
                                ? () => _onRenewSubscription(subscription)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // طرح‌های موجود
                      Text(
                        'طرح‌های اشتراک',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ..._availablePlans.map(_buildPlanCard),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPlanCard(PaymentPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: plan.isPopular
              ? AppTheme.goldColor.withValues(alpha: 0.1)
              : Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر طرح
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.shortDescription,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (plan.isPopular)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'محبوب',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12.sp,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // قیمت
          Row(
            children: [
              if (plan.hasDiscount) ...[
                Text(
                  plan.formattedOriginalPrice,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16.sp,
                    color: Colors.white54,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                plan.formattedPrice,
                style: GoogleFonts.vazirmatn(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ ماه',
                style: GoogleFonts.vazirmatn(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ویژگی‌ها
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // دکمه خرید
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () => _onPurchasePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isPopular
                    ? AppTheme.goldColor
                    : AppTheme.goldColor.withValues(alpha: 0.1),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'خرید اشتراک',
                style: GoogleFonts.vazirmatn(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
