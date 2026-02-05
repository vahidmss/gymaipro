import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/referral_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه راهنمای نحوه دعوت دوستان
class ReferralGuideScreen extends StatefulWidget {
  const ReferralGuideScreen({super.key});

  @override
  State<ReferralGuideScreen> createState() => _ReferralGuideScreenState();
}

class _ReferralGuideScreenState extends State<ReferralGuideScreen> {
  String? _myUsername;
  int _totalReferrals = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile != null) {
        setState(() {
          _myUsername = profile['username'] as String?;
          _totalReferrals = (profile['total_referrals'] as int?) ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }

      // بارگذاری تعداد referrals از سرویس
      final referralService = ReferralService();
      final referrals = await referralService.getTotalReferrals();
      setState(() {
        _totalReferrals = referrals;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyReferralCode() async {
    if (_myUsername == null || _myUsername!.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _myUsername!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'کد معرف کپی شد: $_myUsername',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
            ),
          ),
          backgroundColor: context.cardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            'دعوت دوستان',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // کارت کد معرف
                    _buildReferralCodeCard(),
                    SizedBox(height: 24.h),

                    // آمار دعوت‌ها
                    _buildStatsCard(),
                    SizedBox(height: 24.h),

                    // راهنمای استفاده
                    _buildGuideSection(),
                    SizedBox(height: 24.h),

                    // مزایای دعوت
                    _buildBenefitsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.2),
            AppTheme.goldColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1.5.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                LucideIcons.gift,
                color: AppTheme.goldColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'کد معرف شما',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_myUsername != null && _myUsername!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _myUsername!,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: _copyReferralCode,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        LucideIcons.copy,
                        color: AppTheme.goldColor,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'این کد معرف شماست. آن را با دوستان خود به اشتراک بگذارید!',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textSecondary,
              ),
            ),
          ] else
            Text(
              'نام کاربری یافت نشد',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                color: context.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.separatorColor,
          width: 1,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: LucideIcons.users,
            label: 'تعداد دعوت‌ها',
            value: '$_totalReferrals',
          ),
          Container(
            width: 1.w,
            height: 40.h,
            color: context.separatorColor,
          ),
          _buildStatItem(
            icon: LucideIcons.trophy,
            label: 'دستاوردها',
            value: _totalReferrals >= 10
                ? '3'
                : _totalReferrals >= 3
                    ? '2'
                    : _totalReferrals >= 1
                        ? '1'
                        : '0',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.goldColor,
          size: 24.sp,
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGuideSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.separatorColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                LucideIcons.bookOpen,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'نحوه دعوت دوستان',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildGuideStep(
            number: 1,
            title: 'کد معرف خود را کپی کنید',
            description: 'کد معرف شما همان نام کاربری شماست. روی دکمه کپی کلیک کنید.',
          ),
          SizedBox(height: 16.h),
          _buildGuideStep(
            number: 2,
            title: 'کد را با دوستان خود به اشتراک بگذارید',
            description:
                'کد معرف را از طریق پیام، شبکه‌های اجتماعی یا هر روش دیگری برای دوستان خود ارسال کنید.',
          ),
          SizedBox(height: 16.h),
          _buildGuideStep(
            number: 3,
            title: 'دوستان شما ثبت‌نام می‌کنند',
            description:
                'وقتی دوستان شما در بخش "کد معرف" نام کاربری شما را وارد کنند، شما امتیاز دریافت می‌کنید.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required int number,
    required String title,
    required String description,
  }) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.15),
            AppTheme.goldColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                LucideIcons.star,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'مزایای دعوت دوستان',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildBenefitItem('دعوت 1 نفر', '20 امتیاز'),
          SizedBox(height: 12.h),
          _buildBenefitItem('دعوت 3 نفر', '60 امتیاز + دستاورد نقره‌ای'),
          SizedBox(height: 12.h),
          _buildBenefitItem('دعوت 10 نفر', '200 امتیاز + دستاورد طلایی'),
          SizedBox(height: 12.h),
          _buildBenefitItem('دعوت 30 نفر', '600 امتیاز + دستاورد پلاتینی'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String title, String reward) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(
          LucideIcons.checkCircle,
          color: AppTheme.goldColor,
          size: 18.sp,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: context.textColor,
            ),
          ),
        ),
        Text(
          reward,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
      ],
    );
  }
}

