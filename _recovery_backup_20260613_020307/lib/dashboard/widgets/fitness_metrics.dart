// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// App imports
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/services/fitness_calculator.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:responsive_framework/responsive_framework.dart';
// Third-party imports
import 'package:supabase_flutter/supabase_flutter.dart';

class FitnessMetrics extends StatefulWidget {
  const FitnessMetrics({required this.profileData, super.key});
  final Map<String, dynamic> profileData;

  @override
  State<FitnessMetrics> createState() => _FitnessMetricsState();
}

class _FitnessMetricsState extends State<FitnessMetrics> {
  double? _latestWeight;
  final DashboardCacheService _cacheService = DashboardCacheService();

  @override
  void initState() {
    super.initState();
    _loadLatestWeight();
  }

  @override
  void didUpdateWidget(FitnessMetrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    // اگر ویجت rebuild شد، وزن را دوباره لود کن
    if (oldWidget.profileData != widget.profileData) {
      _loadLatestWeight();
    }
  }

  Future<void> _loadLatestWeight() async {
    try {
      // بررسی کش
      final cachedWeight = _cacheService.getLatestWeight();
      if (cachedWeight != null) {
        if (mounted) {
          setState(() {
            _latestWeight = cachedWeight;
          });
        }
        return;
      }

      // بارگذاری از API
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final latestWeight = await WeeklyWeightService.getLatestWeight(user.id);
        if (latestWeight != null) {
          // ذخیره در کش
          _cacheService.setLatestWeight(latestWeight);
        }
        if (mounted) {
          setState(() {
            _latestWeight = latestWeight;
          });
        }
      }
    } catch (e) {
      // Error handled silently
    }
  }

  static const Color goldColor = AppTheme.goldColor;

  // تبدیل BMI category به فارسی
  static String _getPersianBMICategory(String category) {
    switch (category) {
      case 'Underweight':
        return 'کم‌وزن';
      case 'Normal':
        return 'نرمال';
      case 'Overweight':
        return 'اضافه وزن';
      case 'Obese':
        return 'چاق';
      default:
        return category;
    }
  }

  // تبدیل Body Fat category به فارسی
  static String _getPersianBodyFatCategory(String category) {
    switch (category) {
      case 'Low':
        return 'پایین';
      case 'Excellent':
        return 'عالی';
      case 'Good':
        return 'خوب';
      case 'Average':
        return 'متوسط';
      case 'High':
        return 'بالا';
      case 'Normal':
        return 'نرمال';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height =
        double.tryParse((widget.profileData['height'] as String?) ?? '') ?? 0;
    // استفاده از آخرین وزن ثبت شده یا وزن پروفایل
    final weight =
        _latestWeight ??
        double.tryParse((widget.profileData['weight'] as String?) ?? '') ??
        0;
    final birthDateStr = widget.profileData['birth_date'] as String?;
    final isMale = (widget.profileData['gender'] as String?) == 'male';

    int age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        final now = DateTime.now();
        age =
            now.year -
            birthDate.year -
            ((now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day))
                ? 1
                : 0);
      } catch (_) {}
    }

    final neck =
        double.tryParse(
          (widget.profileData['neck_circumference'] as String?) ?? '',
        ) ??
        (isMale ? 35 : 32);
    final waist =
        double.tryParse(
          (widget.profileData['waist_circumference'] as String?) ?? '',
        ) ??
        0;
    final hip =
        double.tryParse(
          (widget.profileData['hip_circumference'] as String?) ?? '',
        ) ??
        0;

    double bmi = 0;
    String bmiCategory = 'Normal';
    if (height > 0 && weight > 0) {
      bmi = FitnessCalculator.calculateBMI(weight, height);
      bmiCategory = FitnessCalculator.getBMICategory(bmi);
    }

    double bodyFatVal = 0;
    String bodyFatCategory = 'Normal';
    if (height > 0 && weight > 0 && waist > 0) {
      bodyFatVal = FitnessCalculator.calculateBodyFatPercentage(
        waist,
        neck,
        height,
        isMale,
        hip,
      );

      if (bodyFatVal > 0) {
        if (isMale) {
          if (bodyFatVal < 6) {
            bodyFatCategory = 'Low';
          } else if (bodyFatVal < 14)
            bodyFatCategory = 'Excellent';
          else if (bodyFatVal < 18)
            bodyFatCategory = 'Good';
          else if (bodyFatVal < 25)
            bodyFatCategory = 'Average';
          else
            bodyFatCategory = 'High';
        } else {
          if (bodyFatVal < 16) {
            bodyFatCategory = 'Low';
          } else if (bodyFatVal < 24)
            bodyFatCategory = 'Excellent';
          else if (bodyFatVal < 30)
            bodyFatCategory = 'Good';
          else if (bodyFatVal < 35)
            bodyFatCategory = 'Average';
          else
            bodyFatCategory = 'High';
        }
      }
    }

    double bmrVal = 0;
    if (height > 0 && weight > 0 && age > 0) {
      bmrVal = FitnessCalculator.calculateBMR(weight, height, age, isMale);
    }

    double tdeeVal = 0;
    if (bmrVal > 0) {
      // استفاده از activity_level واقعی از پروفایل
      final activityLevelStr =
          (widget.profileData['activity_level'] as String?) ?? 'moderate';
      final activityLevel = activityLevelStr.toActivityLevel();
      tdeeVal = FitnessCalculator.calculateTDEE(bmrVal, activityLevel);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: ResponsiveValue(
          context,
          defaultValue: 275.h,
          conditionalValues: [
            Condition.smallerThan(name: MOBILE, value: 260.h),
            Condition.largerThan(name: TABLET, value: 290.h),
          ],
        ).value,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ردیف اول - BMI, Body Fat, BMR
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final spacing = 8.w;
              final cardWidth = (availableWidth - (spacing * 2)) / 3;
              return Row(
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMinimalCard(
                      context,
                      'BMI',
                      bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                      _getPersianBMICategory(bmiCategory),
                      Icons.monitor_weight,
                      bmi > 0 ? (bmi / 40).clamp(0.0, 1.0) : 0,
                      AppTheme.goldColor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMinimalCard(
                      context,
                      'Body Fat',
                      bodyFatVal > 0
                          ? '${bodyFatVal.toStringAsFixed(1)}%'
                          : '-',
                      _getPersianBodyFatCategory(bodyFatCategory),
                      Icons.accessibility_new,
                      bodyFatVal > 0 ? (bodyFatVal / 40).clamp(0.0, 1.0) : 0,
                      AppTheme.goldColor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMinimalCard(
                      context,
                      'BMR',
                      bmrVal > 0 ? bmrVal.toStringAsFixed(0) : '-',
                      'cal/day',
                      Icons.local_fire_department,
                      bmrVal > 0 ? (bmrVal / 3000).clamp(0.0, 1.0) : 0,
                      AppTheme.goldColor,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 5.h),
          // ردیف دوم - TDEE, Height, Weight
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final spacing = 8.w;
              final cardWidth = (availableWidth - (spacing * 2)) / 3;
              return Row(
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMinimalCard(
                      context,
                      'TDEE',
                      tdeeVal > 0 ? tdeeVal.toStringAsFixed(0) : '-',
                      'cal/day',
                      Icons.whatshot,
                      tdeeVal > 0 ? (tdeeVal / 4000).clamp(0.0, 1.0) : 0,
                      AppTheme.goldColor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMinimalCard(
                      context,
                      'Height',
                      height > 0 ? '${height.toStringAsFixed(0)}' : '-',
                      'cm',
                      Icons.straighten,
                      height > 0 ? (height / 220).clamp(0.0, 1.0) : 0,
                      AppTheme.goldColor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMinimalCard(
                      context,
                      'Weight',
                      weight > 0 ? '${weight.toStringAsFixed(1)}' : '-',
                      'kg',
                      Icons.monitor_weight,
                      weight > 0 ? (weight / 150).clamp(0.0, 1.0) : 0,
                      AppTheme.goldColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    double percent,
    Color color,
  ) {
    final circleSize = ResponsiveValue(
      context,
      defaultValue: 56.w,
      conditionalValues: [
        Condition.smallerThan(name: MOBILE, value: 52.w),
        Condition.largerThan(name: TABLET, value: 60.w),
      ],
    ).value;

    final strokeWidth = ResponsiveValue(
      context,
      defaultValue: 1.8.w,
      conditionalValues: [
        Condition.smallerThan(name: MOBILE, value: 1.5.w),
        Condition.largerThan(name: TABLET, value: 2.w),
      ],
    ).value;

    return GestureDetector(
      onTap: () {
        _showMetricDetails(context, title, value, subtitle);
      },

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // دایره با gradient border
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                startAngle: 3.14159, // شروع از سمت راست (180 درجه)
                endAngle: 3.14159 * 3, // 540 درجه
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.25),
                  AppTheme.goldColor.withValues(alpha: 0.25),
                  AppTheme.goldColor.withValues(alpha: 0.35),
                  AppTheme.goldColor.withValues(alpha: 0.55),
                  AppTheme.goldColor.withValues(alpha: 0.75),
                  AppTheme.goldColor,
                  AppTheme.goldColor.withValues(alpha: 0.75),
                  AppTheme.goldColor.withValues(alpha: 0.55),
                  AppTheme.goldColor.withValues(alpha: 0.35),
                  AppTheme.goldColor.withValues(alpha: 0.25),
                  AppTheme.goldColor.withValues(alpha: 0.25),
                ],
                stops: const [
                  0.0,
                  0.05,
                  0.2,
                  0.35,
                  0.45,
                  0.5,
                  0.55,
                  0.65,
                  0.8,
                  0.95,
                  1.0,
                ],
              ),
            ),
            child: Container(
              margin: EdgeInsets.all(strokeWidth),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.cardColor,
                          AppTheme.goldColor.withValues(alpha: 0.05),
                        ],
                      ),
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.backgroundColor
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // آیکون
                  Icon(
                    icon,
                    color: context.textColor,
                    size: ResponsiveValue(
                      context,
                      defaultValue: 17.sp,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 15.sp),
                        Condition.largerThan(name: TABLET, value: 19.sp),
                      ],
                    ).value,
                  ),
                  SizedBox(height: 2.5.h),
                  // مقدار عددی
                  Text(
                    value,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: ResponsiveValue(
                        context,
                        defaultValue: 12.sp,
                        conditionalValues: [
                          Condition.smallerThan(name: MOBILE, value: 10.sp),
                          Condition.largerThan(name: TABLET, value: 14.sp),
                        ],
                      ).value,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5.h),
          // عنوان زیر دایره
          Text(
            title,
            style: TextStyle(
              color: context.textColor.withValues(alpha: 0.9),
              fontSize: ResponsiveValue(
                context,
                defaultValue: 9.sp,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 8.sp),
                  Condition.largerThan(name: TABLET, value: 10.sp),
                ],
              ).value,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.5.h),
          // واحد یا وضعیت زیر عنوان
          Text(
            subtitle,
            style: TextStyle(
              color: context.textColor,
              fontSize: ResponsiveValue(
                context,
                defaultValue: 8.sp,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 7.sp),
                  Condition.largerThan(name: TABLET, value: 9.sp),
                ],
              ).value,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.05,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showMetricDetails(
    BuildContext context,
    String title,
    String value,
    String subtitle,
  ) {
    String description = '';
    String persianTitle = '';
    String shortDescription = '';
    List<String> keyPoints = [];

    // توضیحات و عناوین فارسی برای هر معیار
    switch (title) {
      case 'BMI':
        persianTitle = 'شاخص توده بدنی';
        shortDescription = 'نسبت وزن به قد شما';
        description =
            'شاخص توده بدنی (BMI) یک معیار استاندارد برای ارزیابی تناسب وزن نسبت به قد است. این شاخص به شما کمک می‌کند تا وضعیت وزن خود را بهتر درک کنید.';
        keyPoints = [
          'کم‌وزن: کمتر از ۱۸.۵',
          'طبیعی: ۱۸.۵ تا ۲۴.۹',
          'اضافه وزن: ۲۵ تا ۲۹.۹',
          'چاق: ۳۰ و بالاتر',
        ];
      case 'Body Fat':
        persianTitle = 'درصد چربی بدن';
        shortDescription = 'نسبت چربی به کل وزن بدن';
        description =
            'درصد چربی بدن یکی از مهم‌ترین معیارهای سلامت و تناسب اندام است. این شاخص به شما نشان می‌دهد که چه مقدار از وزن شما را چربی تشکیل می‌دهد.';
        final isMale = (widget.profileData['gender'] as String?) == 'male';
        if (isMale) {
          keyPoints = [
            'ورزشکار: ۶ تا ۱۳ درصد',
            'مناسب: ۱۴ تا ۱۷ درصد',
            'قابل قبول: ۱۸ تا ۲۴ درصد',
            'بالا: ۲۵ درصد و بیشتر',
          ];
        } else {
          keyPoints = [
            'ورزشکار: ۱۴ تا ۲۰ درصد',
            'مناسب: ۲۱ تا ۲۴ درصد',
            'قابل قبول: ۲۵ تا ۳۱ درصد',
            'بالا: ۳۲ درصد و بیشتر',
          ];
        }
      case 'BMR':
        persianTitle = 'میزان متابولیسم پایه';
        shortDescription = 'کالری مصرفی در حالت استراحت';
        description =
            'میزان متابولیسم پایه (BMR) حداقل کالری مورد نیاز بدن برای حفظ عملکردهای حیاتی در حالت استراحت کامل است. این مقدار پایه برای محاسبه کل انرژی مصرفی روزانه استفاده می‌شود.';
        keyPoints = [
          'حداقل کالری برای زنده ماندن',
          'بدون فعالیت بدنی محاسبه می‌شود',
          'پایه محاسبه TDEE است',
          'با افزایش سن کاهش می‌یابد',
        ];
      case 'TDEE':
        persianTitle = 'کل انرژی مصرفی روزانه';
        shortDescription = 'مجموع کالری مصرفی در طول روز';
        description =
            'کل انرژی مصرفی روزانه (TDEE) مجموع تمام کالری‌هایی است که بدن شما در طول یک روز کامل می‌سوزاند. این شامل متابولیسم پایه، فعالیت‌های روزانه و ورزش می‌شود.';
        keyPoints = [
          'کاهش وزن: کمتر از TDEE مصرف کنید',
          'افزایش وزن: بیشتر از TDEE مصرف کنید',
          'حفظ وزن: برابر TDEE مصرف کنید',
          'BMR حدود ۶۰-۷۰٪ از TDEE را تشکیل می‌دهد',
        ];
      case 'Height':
        persianTitle = 'قد';
        shortDescription = 'ارتفاع شما';
        description =
            'قد یکی از فاکتورهای مهم در محاسبه شاخص‌های سلامت و تناسب اندام است. این معیار در کنار وزن برای محاسبه BMI و سایر شاخص‌ها استفاده می‌شود.';
        keyPoints = [
          'در محاسبه BMI استفاده می‌شود',
          'بر روی BMR و TDEE تأثیر دارد',
          'برای محاسبه وزن ایده‌آل مهم است',
        ];
      case 'Weight':
        persianTitle = 'وزن';
        shortDescription = 'وزن فعلی شما';
        description =
            'وزن یکی از اساسی‌ترین معیارهای سلامت است. ردیابی منظم وزن به شما کمک می‌کند تا پیشرفت خود را در مسیر رسیدن به اهداف تناسب اندام مشاهده کنید.';
        keyPoints = [
          'برای محاسبه BMI ضروری است',
          'مستقیماً بر BMR تأثیر می‌گذارد',
          'ردیابی هفتگی توصیه می‌شود',
        ];
    }

    showDialog<void>(
      context: context,
      barrierColor: Theme.of(context).brightness == Brightness.dark
          ? context.backgroundColor.withValues(alpha: 0.85)
          : AppTheme.lightTextColor.withValues(alpha: 0.4),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 420.w,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: context.cardColor, // رنگ solid برای عدم شفافیت
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: goldColor.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.2
                      : 0.3,
                ),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: goldColor.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.1
                        : 0.2,
                  ),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                  offset: Offset(0.w, 6.h),
                ),
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.backgroundColor.withValues(alpha: 0.4)
                      : AppTheme.lightTextColor.withValues(alpha: 0.06),
                  blurRadius: 15.r,
                  offset: Offset(0.w, 3.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // هدر با گرادیانت
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                goldColor.withValues(alpha: 0.25),
                                goldColor.withValues(alpha: 0.1),
                              ]
                            : [
                                context.goldGradientColors[0].withValues(
                                  alpha: 0.3,
                                ),
                                context.goldGradientColors[1].withValues(
                                  alpha: 0.15,
                                ),
                              ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // آیکون با پس‌زمینه
                        Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? [
                                      goldColor.withValues(alpha: 0.25),
                                      goldColor.withValues(alpha: 0.12),
                                    ]
                                  : [
                                      context.goldGradientColors[0].withValues(
                                        alpha: 0.25,
                                      ),
                                      context.goldGradientColors[1].withValues(
                                        alpha: 0.15,
                                      ),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: goldColor.withValues(
                                alpha:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.35
                                    : 0.45,
                              ),
                              width: 1.w,
                            ),
                          ),
                          child: Icon(
                            _getIconForTitle(title),
                            color: context.textColor,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                persianTitle,
                                style: AppTheme.dialogTitleStyle.copyWith(
                                  color: context.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                shortDescription,
                                style: AppTheme.dialogSubtitleStyle.copyWith(
                                  color: context.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // دکمه بستن
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                color: context.textColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: context.textColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  width: 1.w,
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: context.textColor.withValues(
                                  alpha: 0.75,
                                ),
                                size: 18.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // محتوای اصلی
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // کارت مقدار اصلی
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 24.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  goldColor.withValues(alpha: 0.2),
                                  goldColor.withValues(alpha: 0.1),
                                  goldColor.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: goldColor.withValues(
                                  alpha:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.25
                                      : 0.35,
                                ),
                                width: 1.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: goldColor.withValues(
                                    alpha:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.08
                                        : 0.15,
                                  ),
                                  blurRadius: 12.r,
                                  offset: Offset(0.w, 4.h),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'مقدار فعلی',
                                  style: AppTheme.dialogValueLabelStyle
                                      .copyWith(color: context.textSecondary),
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      value,
                                      style: AppTheme.dialogValueStyle.copyWith(
                                        color: context.textColor,
                                        fontSize: ResponsiveValue(
                                          context,
                                          defaultValue: 32.sp,
                                          conditionalValues: [
                                            Condition.smallerThan(
                                              name: MOBILE,
                                              value: 28.sp,
                                            ),
                                            Condition.largerThan(
                                              name: TABLET,
                                              value: 36.sp,
                                            ),
                                          ],
                                        ).value,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4.h),
                                      child: Text(
                                        subtitle,
                                        style: AppTheme.dialogUnitStyle
                                            .copyWith(
                                              color: context.textColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // توضیحات
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              gradient:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.goldColor.withValues(
                                          alpha: 0.05,
                                        ),
                                        AppTheme.goldColor.withValues(
                                          alpha: 0.02,
                                        ),
                                      ],
                                    ),
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? context.textColor.withValues(alpha: 0.025)
                                  : null,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? context.textColor.withValues(alpha: 0.06)
                                    : AppTheme.goldColor.withValues(
                                        alpha: 0.12,
                                      ),
                                width: 1.w,
                              ),
                            ),
                            child: Text(
                              description,
                              style: AppTheme.dialogDescriptionStyle.copyWith(
                                color: context.textColor.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),

                          SizedBox(height: 18.h),

                          // نکات کلیدی
                          if (keyPoints.isNotEmpty) ...[
                            Text(
                              'نکات مهم',
                              style: AppTheme.dialogKeyPointsTitleStyle
                                  .copyWith(color: context.textColor),
                            ),
                            SizedBox(height: 10.h),
                            ...keyPoints.map(
                              (point) => Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? null
                                      : LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            goldColor.withValues(alpha: 0.08),
                                            goldColor.withValues(alpha: 0.04),
                                          ],
                                        ),
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? goldColor.withValues(alpha: 0.06)
                                      : null,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: goldColor.withValues(
                                      alpha:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? 0.15
                                          : 0.2,
                                    ),
                                    width: 1.w,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5.w,
                                      height: 5.h,
                                      decoration: BoxDecoration(
                                        color: goldColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: AppTheme.dialogKeyPointStyle
                                            .copyWith(
                                              color: context.textColor
                                                  .withValues(alpha: 0.85),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // دکمه پایین
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? context.textColor.withValues(alpha: 0.08)
                              : AppTheme.goldColor.withValues(alpha: 0.15),
                          width: 1.w,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          foregroundColor: AppTheme.onGoldColor,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'فهمیدم',
                          style: AppTheme.dialogButtonStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'BMI':
        return Icons.monitor_weight;
      case 'Body Fat':
        return Icons.accessibility_new;
      case 'BMR':
        return Icons.local_fire_department;
      case 'TDEE':
        return Icons.whatshot;
      case 'Height':
        return Icons.straighten;
      case 'Weight':
        return Icons.monitor_weight;
      default:
        return Icons.info_outline;
    }
  }
}
