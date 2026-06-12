import 'package:flutter/material.dart';

/// صفحه onboarding
class OnboardingPage {

  const OnboardingPage({
    required this.id,
    required this.title,
    required this.description,
    required this.primaryColor, this.imagePath,
    this.icon,
    this.gradientStartColor,
    this.gradientEndColor,
    this.customWidget,
  });
  /// شناسه
  final String id;

  /// عنوان
  final String title;

  /// توضیحات
  final String description;

  /// تصویر یا لاتی
  final String? imagePath;

  /// آیکون (جایگزین تصویر)
  final IconData? icon;

  /// رنگ اصلی
  final Color primaryColor;

  /// رنگ گرادیانت شروع
  final Color? gradientStartColor;

  /// رنگ گرادیانت پایان
  final Color? gradientEndColor;

  /// ویجت سفارشی (اختیاری)
  final Widget? customWidget;

  bool get hasImage => imagePath != null;
  bool get hasIcon => icon != null;
  bool get hasGradient =>
      gradientStartColor != null && gradientEndColor != null;

  OnboardingPage copyWith({
    String? id,
    String? title,
    String? description,
    String? imagePath,
    IconData? icon,
    Color? primaryColor,
    Color? gradientStartColor,
    Color? gradientEndColor,
    Widget? customWidget,
  }) {
    return OnboardingPage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      icon: icon ?? this.icon,
      primaryColor: primaryColor ?? this.primaryColor,
      gradientStartColor: gradientStartColor ?? this.gradientStartColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      customWidget: customWidget ?? this.customWidget,
    );
  }
}

