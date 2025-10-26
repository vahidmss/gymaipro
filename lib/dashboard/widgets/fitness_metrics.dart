// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// App imports
import 'package:gymaipro/services/fitness_calculator.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLatestWeight();
  }

  Future<void> _loadLatestWeight() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final latestWeight = await WeeklyWeightService.getLatestWeight(user.id);
        if (mounted) {
          setState(() {
            _latestWeight = latestWeight;
          });
        }
      }
    } catch (e) {
      print('خطا در بارگذاری آخرین وزن: $e');
      // Error handled silently
    }
  }

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color cardColor = Color(0xFF1E1E1E);

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
      tdeeVal = bmrVal * 1.55;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: ResponsiveValue(
          context,
          defaultValue: 180.h,
          conditionalValues: [
            Condition.smallerThan(name: MOBILE, value: 160.h),
            Condition.largerThan(name: TABLET, value: 200.h),
          ],
        ).value,
        maxHeight: ResponsiveValue(
          context,
          defaultValue: 210.h,
          conditionalValues: [
            Condition.smallerThan(name: MOBILE, value: 180.h),
            Condition.largerThan(name: TABLET, value: 240.h),
          ],
        ).value,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ردیف اول
          Row(
            children: [
              Expanded(
                child: _buildMinimalCard(
                  context,
                  'BMI',
                  bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                  bmiCategory,
                  Icons.monitor_weight,
                  bmi > 0 ? (bmi / 40).clamp(0.0, 1.0) : 0,
                  bmi > 0 ? FitnessCalculator.getBMIColor(bmi) : Colors.grey,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildMinimalCard(
                  context,
                  'Body Fat',
                  bodyFatVal > 0 ? '${bodyFatVal.toStringAsFixed(1)}%' : '-',
                  bodyFatCategory,
                  Icons.accessibility_new,
                  bodyFatVal > 0 ? (bodyFatVal / 40).clamp(0.0, 1.0) : 0,
                  bodyFatVal > 0 ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // ردیف دوم
          Row(
            children: [
              Expanded(
                child: _buildMinimalCard(
                  context,
                  'BMR',
                  bmrVal > 0 ? bmrVal.toStringAsFixed(0) : '-',
                  'cal/day',
                  Icons.local_fire_department,
                  bmrVal > 0 ? (bmrVal / 3000).clamp(0.0, 1.0) : 0,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildMinimalCard(
                  context,
                  'TDEE',
                  tdeeVal > 0 ? tdeeVal.toStringAsFixed(0) : '-',
                  'cal/day',
                  Icons.whatshot,
                  tdeeVal > 0 ? (tdeeVal / 4000).clamp(0.0, 1.0) : 0,
                  Colors.purple,
                ),
              ),
            ],
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
    return GestureDetector(
      onTap: () {
        _showMetricDetails(context, title, value, subtitle);
      },
      child: Container(
        height: ResponsiveValue(
          context,
          defaultValue: 95.h,
          conditionalValues: [
            Condition.smallerThan(name: MOBILE, value: 80.h),
            Condition.largerThan(name: TABLET, value: 110.h),
          ],
        ).value,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor, cardColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(42.5.r), // کاملاً گرد
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // آیکون گرد
              Container(
                width: ResponsiveValue(
                  context,
                  defaultValue: 40.w,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 35.w),
                    Condition.largerThan(name: TABLET, value: 45.w),
                  ],
                ).value,
                height: ResponsiveValue(
                  context,
                  defaultValue: 40.h,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 35.h),
                    Condition.largerThan(name: TABLET, value: 45.h),
                  ],
                ).value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20.r), // کاملاً گرد
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 14.w),
              // محتوا
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color,
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // نوار پیشرفت کوچک
              Container(
                width: 5.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withOpacity(0.8), color],
                      ),
                      borderRadius: BorderRadius.circular(2.5.r),
                    ),
                  ),
                ),
              ),
              // آیکون راهنمایی
              SizedBox(width: 10.w),
              Container(
                width: ResponsiveValue(
                  context,
                  defaultValue: 24.w,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 20.w),
                    Condition.largerThan(name: TABLET, value: 28.w),
                  ],
                ).value,
                height: ResponsiveValue(
                  context,
                  defaultValue: 24.h,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 20.h),
                    Condition.largerThan(name: TABLET, value: 28.h),
                  ],
                ).value,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: color.withOpacity(0.7),
                  size: 14.sp,
                ),
              ),
            ],
          ),
        ),
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

    // توضیحات و عناوین فارسی برای هر معیار
    switch (title) {
      case 'BMI':
        persianTitle = 'شاخص توده بدنی';
        description =
            'شاخص توده بدنی (BMI) معیاری برای ارزیابی وزن نسبت به قد است. این شاخص با تقسیم وزن (کیلوگرم) بر مجذور قد (متر) محاسبه می‌شود.\n\n'
            '• کمتر از ۱۸.۵: کم‌وزن\n'
            '• ۱۸.۵ تا ۲۴.۹: طبیعی\n'
            '• ۲۵ تا ۲۹.۹: اضافه وزن\n'
            '• ۳۰ و بالاتر: چاق';
      case 'Body Fat':
        persianTitle = 'درصد چربی بدن';
        description =
            'درصد چربی بدن نشان‌دهنده نسبت چربی به کل وزن بدن است. این معیار برای ارزیابی سلامت و تناسب اندام مهم است.\n\n'
            'مردان:\n'
            '• ۶-۱۳٪: ورزشکار\n'
            '• ۱۴-۱۷٪: مناسب\n'
            '• ۱۸-۲۴٪: قابل قبول\n'
            '• ۲۵٪ و بالاتر: بالا\n\n'
            'زنان:\n'
            '• ۱۴-۲۰٪: ورزشکار\n'
            '• ۲۱-۲۴٪: مناسب\n'
            '• ۲۵-۳۱٪: قابل قبول\n'
            '• ۳۲٪ و بالاتر: بالا';
      case 'BMR':
        persianTitle = 'میزان متابولیسم پایه';
        description =
            'میزان متابولیسم پایه (BMR) تعداد کالری‌ای است که بدن در حالت استراحت کامل برای حفظ عملکردهای حیاتی می‌سوزاند.\n\n'
            'این شامل:\n'
            '• تنفس\n'
            '• گردش خون\n'
            '• تولید سلول‌ها\n'
            '• پردازش مواد مغذی\n'
            '• سنتز پروتئین\n'
            '• انتقال یون‌ها';
      case 'TDEE':
        persianTitle = 'کل انرژی مصرفی روزانه';
        description =
            'کل انرژی مصرفی روزانه (TDEE) مجموع کالری‌هایی است که بدن در طول روز می‌سوزاند. این شامل:\n\n'
            '• BMR (۶۰-۷۰٪)\n'
            '• فعالیت‌های روزانه (۲۰-۳۰٪)\n'
            '• ورزش و فعالیت بدنی (۱۰-۲۰٪)\n\n'
            'برای کاهش وزن: کمتر از TDEE بخورید\n'
            'برای افزایش وزن: بیشتر از TDEE بخورید\n'
            'برای حفظ وزن: برابر TDEE بخورید';
    }

    showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(
                _getIconForTitle(title),
                color: goldColor,
                size: ResponsiveValue(
                  context,
                  defaultValue: 24.sp,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 22.sp),
                    Condition.largerThan(name: TABLET, value: 26.sp),
                  ],
                ).value,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  persianTitle,
                  style: TextStyle(
                    color: goldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    fontFamily: 'Vazir',
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // کانتینر مقدار
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      goldColor.withOpacity(0.2),
                      goldColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: goldColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 28.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 24.sp),
                            Condition.largerThan(name: TABLET, value: 32.sp),
                          ],
                        ).value,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazir',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16.sp,
                        fontFamily: 'Vazir',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // توضیحات
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: ResponsiveValue(
                      context,
                      defaultValue: 14.sp,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 12.sp),
                        Condition.largerThan(name: TABLET, value: 16.sp),
                      ],
                    ).value,
                    height: 1.6,
                    fontFamily: 'Vazir',
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'متوجه شدم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        fontFamily: 'Vazir',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      default:
        return Icons.info_outline;
    }
  }
}
