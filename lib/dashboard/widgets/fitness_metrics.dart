// Flutter imports
import 'package:flutter/material.dart';

// Third-party imports

// App imports
import 'package:gymaipro/services/fitness_calculator.dart';

class FitnessMetrics extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const FitnessMetrics({
    Key? key,
    required this.profileData,
  }) : super(key: key);

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color cardColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    final height = double.tryParse(profileData['height'] ?? '') ?? 0;
    final weight = double.tryParse(profileData['weight'] ?? '') ?? 0;
    final birthDateStr = profileData['birth_date'];
    final isMale = profileData['gender'] == 'male';

    int age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        final now = DateTime.now();
        age = now.year -
            birthDate.year -
            ((now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day))
                ? 1
                : 0);
      } catch (_) {}
    }

    final neck = double.tryParse(profileData['neck_circumference'] ?? '') ??
        (isMale ? 35 : 32);
    final waist =
        double.tryParse(profileData['waist_circumference'] ?? '') ?? 0;
    final hip = double.tryParse(profileData['hip_circumference'] ?? '') ?? 0;

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
      bmrVal = FitnessCalculator.calculateBMR(
        weight,
        height,
        age,
        isMale,
      );
    }

    double tdeeVal = 0;
    if (bmrVal > 0) {
      tdeeVal = bmrVal * 1.55;
    }

    return SizedBox(
      height: 220,
      child: Column(
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 12),
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
              const SizedBox(width: 16),
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
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              cardColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(42.5), // کاملاً گرد
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // آیکون گرد
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22.5), // کاملاً گرد
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // محتوا
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // نوار پیشرفت کوچک
              Container(
                width: 5,
                height: 55,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.8),
                          color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
              // آیکون راهنمایی
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: color.withOpacity(0.7),
                  size: 16,
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
        break;
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
        break;
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
        break;
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
        break;
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                _getIconForTitle(title),
                color: goldColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  persianTitle,
                  style: const TextStyle(
                    color: goldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      goldColor.withOpacity(0.2),
                      goldColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: goldColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazir',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontFamily: 'Vazir',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // توضیحات
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'متوجه شدم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
