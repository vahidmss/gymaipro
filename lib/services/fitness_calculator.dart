import 'package:flutter/material.dart';
import 'dart:math';

class FitnessCalculator {
  static double calculateBMI(double weight, double height) {
    // تبدیل قد از سانتی‌متر به متر
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'کمبود وزن';
    } else if (bmi < 25) {
      return 'نرمال';
    } else if (bmi < 30) {
      return 'اضافه وزن';
    } else {
      return 'چاقی';
    }
  }

  static String getBMIDescription(double bmi) {
    if (bmi < 18.5) {
      return 'شما نیاز به افزایش وزن دارید';
    } else if (bmi < 25) {
      return 'وزن شما در محدوده سالم قرار دارد';
    } else if (bmi < 30) {
      return 'شما نیاز به کاهش وزن دارید';
    } else {
      return 'شما نیاز به کاهش وزن جدی دارید';
    }
  }

  static Color getBMIColor(double bmi) {
    if (bmi < 18.5) {
      return const Color(0xFFFFA726); // نارنجی
    } else if (bmi < 25) {
      return const Color(0xFF66BB6A); // سبز
    } else if (bmi < 30) {
      return const Color(0xFFEF5350); // قرمز روشن
    } else {
      return const Color(0xFFD32F2F); // قرمز تیره
    }
  }

  static double calculateBMR(
      double weight, double height, int age, bool isMale) {
    if (isMale) {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  static double calculateTDEE(double bmr, ActivityLevel activityLevel) {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return bmr * 1.2;
      case ActivityLevel.lightlyActive:
        return bmr * 1.375;
      case ActivityLevel.moderatelyActive:
        return bmr * 1.55;
      case ActivityLevel.veryActive:
        return bmr * 1.725;
      case ActivityLevel.extraActive:
        return bmr * 1.9;
    }
  }

  static double calculateBodyFatPercentage(
    double waist,
    double neck,
    double height,
    bool isMale,
    double? hip,
  ) {
    if (isMale) {
      return 495 /
              (1.0324 -
                  0.19077 * log10(waist - neck) +
                  0.15456 * log10(height)) -
          450;
    } else {
      if (hip == null) return 0;
      return 495 /
              (1.29579 -
                  0.35004 * log10(waist + hip - neck) +
                  0.22100 * log10(height)) -
          450;
    }
  }

  static double log10(double x) {
    return log(x) / ln10;
  }
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

extension ActivityLevelExtension on ActivityLevel {
  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'کم تحرک (کار پشت میز)';
      case ActivityLevel.lightlyActive:
        return 'کم فعال (ورزش سبک 1-3 روز در هفته)';
      case ActivityLevel.moderatelyActive:
        return 'نسبتاً فعال (ورزش متوسط 3-5 روز در هفته)';
      case ActivityLevel.veryActive:
        return 'خیلی فعال (ورزش سنگین 6-7 روز در هفته)';
      case ActivityLevel.extraActive:
        return 'فوق فعال (ورزش خیلی سنگین و کار فیزیکی)';
    }
  }
}
