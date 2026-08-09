import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/legal/legal_copy.dart';
import 'package:gymaipro/features/legal/navigation/legal_routes.dart';
import 'package:gymaipro/payment/models/payment_plan.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/payment/screens/payment_screen.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/payment/widgets/subscription_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/support_launcher.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
    });

    try {
      final subscriptions = await _subscriptionService.getUserSubscriptions();
      final plans = PredefinedPlans.subscriptions;

      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _subscriptions = subscriptions;
          _availablePlans = plans;
        });
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری داده‌های اشتراک: $e');
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = false;
      });
    }
  }

  void _onPurchasePlan(PaymentPlan plan) {
    WidgetSafetyUtils.safeNavigate(
      context,
      () => PaymentScreen(
        plan: plan,
        metadata: {'subscription_type': plan.accessLevel.toString()},
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

        if (!mounted) return;
        if (success) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'اشتراک با موفقیت لغو شد',
            backgroundColor: Colors.green,
          );
          _loadSubscriptionData();
        }
      } catch (e) {
        if (!mounted) return;
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در لغو اشتراک: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _onRenewSubscription(Subscription subscription) {
    final plan = _availablePlans.firstWhere(
      (p) => p.type == PaymentPlanType.subscription,
      orElse: () => _availablePlans.first,
    );

    WidgetSafetyUtils.safeNavigate(
      context,
      () => PaymentScreen(
        plan: plan,
        metadata: {'renewal': true, 'subscription_id': subscription.id},
      ),
    );
  }

  Future<bool?> _showCancelConfirmDialog() {
    return WidgetSafetyUtils.safeShowDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'لغو اشتراک',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید اشتراک خود را لغو کنید؟',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => WidgetSafetyUtils.safePop(context, false),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => WidgetSafetyUtils.safePop(context, true),
            child: const Text(
              'لغو اشتراک',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.red,
              ),
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
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            'اشتراک ویژه',
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadSubscriptionData,
                color: AppTheme.goldColor,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
                  children: [
                    _DemoNoticeCard(
                      onContact: () =>
                          Navigator.pushNamed(context, LegalRoutes.about),
                      onCall: () => SupportLauncher.openPhone(context),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'اشتراک یعنی چه؟',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'با اشتراک، مربی هوشمند و امکانات پیشرفته‌تر باز می‌شود. '
                      'بدون اشتراک هم می‌توانی اپ را ببینی و تمرین ثبت کنی؛ '
                      'ولی سقف گفتگو و بعضی تحلیل‌ها محدود است.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        height: 1.65,
                        color: context.textSecondary,
                      ),
                    ),
                    if (_subscriptions.isNotEmpty) ...[
                      SizedBox(height: 22.h),
                      Text(
                        'وضعیت فعلی تو',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.goldColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ..._subscriptions.map(
                        (subscription) => SubscriptionCard(
                          subscription: subscription,
                          onCancel: subscription.isActive
                              ? () => _onCancelSubscription(subscription)
                              : null,
                          onRenew: subscription.status ==
                                  SubscriptionStatus.expired
                              ? () => _onRenewSubscription(subscription)
                              : null,
                        ),
                      ),
                    ],
                    SizedBox(height: 22.h),
                    Text(
                      'انتخاب پلن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.goldColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'هر دو ماهانه هستند. Ultimate همان Coach Pro است به‌علاوه سقف بالاتر و اولویت پشتیبانی.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        height: 1.5,
                        color: context.textSecondary,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ..._availablePlans.map(_buildPlanCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlanCard(PaymentPlan plan) {
    final popular = plan.isPopular;
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: popular
              ? AppTheme.goldColor.withValues(alpha: 0.55)
              : context.separatorColor,
          width: popular ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldColor,
                  ),
                ),
              ),
              if (popular)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'پیشنهادی',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            plan.shortDescription,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              height: 1.45,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (plan.hasDiscount) ...[
                Text(
                  plan.formattedOriginalPrice,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: context.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Text(
                plan.formattedPrice,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                ),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: Text(
                  'در ماه',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...plan.features.map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.check,
                    color: Colors.green,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        height: 1.4,
                        color: context.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () => _onPurchasePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                popular ? 'انتخاب Ultimate AI' : 'انتخاب Coach Pro',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNoticeCard extends StatelessWidget {
  const _DemoNoticeCard({
    required this.onContact,
    required this.onCall,
  });

  final VoidCallback onContact;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.flaskConical, color: AppTheme.goldColor, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'نسخه دمو — خرید ممکن است محدود باشد',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                    color: context.textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'اگر می‌خواهی پلن را آزمایش کنی، باگ دیدی، یا نظری درباره قیمت/امکانات داری، '
            'مستقیم بگو. شماره: ${LegalCopy.supportPhoneDisplay}',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.5.sp,
              height: 1.55,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCall,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textColor,
                    side: BorderSide(color: context.separatorColor),
                  ),
                  child: Text(
                    'تماس',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: FilledButton(
                  onPressed: onContact,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.actionFill,
                    foregroundColor: context.actionOnFill,
                  ),
                  child: Text(
                    'بازخورد',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
