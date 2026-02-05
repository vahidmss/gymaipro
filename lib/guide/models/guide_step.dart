import 'package:flutter/material.dart';

/// مدل یک مرحله از راهنما
class GuideStep {
  /// شناسه یکتا
  final String id;

  /// عنوان
  final String title;

  /// توضیحات
  final String description;

  /// آیکون
  final IconData? icon;

  /// تصویر (اختیاری)
  final String? imageAsset;

  /// رنگ اصلی
  final Color? primaryColor;

  /// رنگ پس‌زمینه
  final Color? backgroundColor;

  /// GlobalKey برای highlight کردن ویجت مقصد در feature tour
  final GlobalKey? targetKey;

  /// موقعیت tooltip نسبت به target
  final TooltipPosition tooltipPosition;

  /// آیا باید از انیمیشن pulse استفاده شود
  final bool usePulseAnimation;

  /// دکمه عمل اختیاری
  final GuideStepAction? action;

  const GuideStep({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.imageAsset,
    this.primaryColor,
    this.backgroundColor,
    this.targetKey,
    this.tooltipPosition = TooltipPosition.bottom,
    this.usePulseAnimation = true,
    this.action,
  });

  GuideStep copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    String? imageAsset,
    Color? primaryColor,
    Color? backgroundColor,
    GlobalKey? targetKey,
    TooltipPosition? tooltipPosition,
    bool? usePulseAnimation,
    GuideStepAction? action,
  }) {
    return GuideStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageAsset: imageAsset ?? this.imageAsset,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      targetKey: targetKey ?? this.targetKey,
      tooltipPosition: tooltipPosition ?? this.tooltipPosition,
      usePulseAnimation: usePulseAnimation ?? this.usePulseAnimation,
      action: action ?? this.action,
    );
  }
}

/// موقعیت نمایش tooltip
enum TooltipPosition {
  top,
  bottom,
  left,
  right,
  center,
}

/// عمل اختیاری برای یک مرحله
class GuideStepAction {
  final String label;
  final VoidCallback onTap;

  const GuideStepAction({
    required this.label,
    required this.onTap,
  });
}

