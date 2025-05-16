import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/fitness_calculator.dart';

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
    final isMale = profileData['gender'] == 'male'; // استفاده از فیلد جنسیت

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
    String bmiCategory = 'داده‌ای وارد نشده';
    String bmiTip = '';
    if (height > 0 && weight > 0) {
      bmi = FitnessCalculator.calculateBMI(weight, height);
      bmiCategory = FitnessCalculator.getBMICategory(bmi);
      bmiTip = FitnessCalculator.getBMIDescription(bmi);
    }

    double bodyFatVal = 0;
    String bodyFatCategory = '';
    String bodyFatTip = '';
    if (waist > 0 && neck > 0 && height > 0) {
      bodyFatVal = FitnessCalculator.calculateBodyFatPercentage(
        waist,
        neck,
        height,
        isMale,
        hip,
      );

      if (isMale) {
        if (bodyFatVal < 6) {
          bodyFatCategory = 'خیلی کم';
          bodyFatTip = 'چربی بدن شما بسیار پایین است، برای سلامتی مناسب نیست';
        } else if (bodyFatVal < 14) {
          bodyFatCategory = 'عالی';
          bodyFatTip = 'درصد چربی ایده‌آل برای ورزشکاران';
        } else if (bodyFatVal < 18) {
          bodyFatCategory = 'خوب';
          bodyFatTip = 'درصد چربی مناسب برای افراد فعال';
        } else if (bodyFatVal < 25) {
          bodyFatCategory = 'متوسط';
          bodyFatTip = 'چربی بدن متوسط، با تمرین می‌توانید آن را بهبود بخشید';
        } else {
          bodyFatCategory = 'زیاد';
          bodyFatTip = 'چربی بدن بالا، نیاز به کاهش با ورزش و رژیم غذایی';
        }
      } else {
        // معیارهای زنان
        if (bodyFatVal < 16) {
          bodyFatCategory = 'خیلی کم';
          bodyFatTip = 'چربی بدن شما بسیار پایین است، برای سلامتی مناسب نیست';
        } else if (bodyFatVal < 24) {
          bodyFatCategory = 'عالی';
          bodyFatTip = 'درصد چربی ایده‌آل برای ورزشکاران';
        } else if (bodyFatVal < 30) {
          bodyFatCategory = 'خوب';
          bodyFatTip = 'درصد چربی مناسب برای افراد فعال';
        } else if (bodyFatVal < 35) {
          bodyFatCategory = 'متوسط';
          bodyFatTip = 'چربی بدن متوسط، با تمرین می‌توانید آن را بهبود بخشید';
        } else {
          bodyFatCategory = 'زیاد';
          bodyFatTip = 'چربی بدن بالا، نیاز به کاهش با ورزش و رژیم غذایی';
        }
      }
    }

    double bmrVal = 0;
    String bmrTip = '';
    if (weight > 0 && height > 0) {
      bmrVal = FitnessCalculator.calculateBMR(
        weight,
        height,
        age,
        isMale,
      );
      bmrTip = 'میزان کالری مورد نیاز بدن در حالت استراحت';
    }

    double tdeeVal = 0;
    String tdeeTip = '';
    if (weight > 0 && height > 0) {
      tdeeVal = FitnessCalculator.calculateTDEE(
        bmrVal,
        ActivityLevel.moderatelyActive,
      );
      tdeeTip = 'میزان کالری مورد نیاز روزانه با توجه به فعالیت بدنی';
    }

    return SizedBox(
      height: 210,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildCardWithGauge(
            context,
            'BMI',
            bmi > 0 ? bmi.toStringAsFixed(1) : '-',
            bmiCategory,
            bmiTip,
            Icons.monitor_weight,
            bmi > 0 ? (bmi / 40).clamp(0.0, 1.0) : 0,
            bmi > 0 ? FitnessCalculator.getBMIColor(bmi) : Colors.grey,
          ),
          _buildCardWithGauge(
            context,
            'درصد چربی',
            bodyFatVal > 0 ? '${bodyFatVal.toStringAsFixed(1)}%' : '-',
            bodyFatCategory,
            bodyFatTip,
            Icons.accessibility_new,
            bodyFatVal > 0 ? (bodyFatVal / 40).clamp(0.0, 1.0) : 0,
            bodyFatVal > 0 ? Colors.blue : Colors.grey,
          ),
          _buildCardWithGauge(
            context,
            'کالری پایه (BMR)',
            bmrVal > 0 ? bmrVal.toStringAsFixed(0) : '-',
            'کالری در روز',
            bmrTip,
            Icons.local_fire_department,
            bmrVal > 0 ? (bmrVal / 3000).clamp(0.0, 1.0) : 0,
            Colors.orange,
          ),
          _buildCardWithGauge(
            context,
            'کالری روزانه (TDEE)',
            tdeeVal > 0 ? tdeeVal.toStringAsFixed(0) : '-',
            'کالری در روز',
            tdeeTip,
            Icons.whatshot,
            tdeeVal > 0 ? (tdeeVal / 4000).clamp(0.0, 1.0) : 0,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCardWithGauge(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    String tip,
    IconData icon,
    double percent,
    Color color,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: goldColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (tip.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: goldColor, width: 1),
                  ),
                  title: Row(
                    children: [
                      Icon(icon, color: goldColor),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: goldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    tip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: goldColor,
                      ),
                      child: const Text('باشه'),
                    ),
                  ],
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                CircularPercentIndicator(
                  radius: 45,
                  lineWidth: 8.0,
                  animation: true,
                  animationDuration: 1200,
                  percent: percent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.15),
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'راهنمایی',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                        ),
                      ),
                    ],
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
