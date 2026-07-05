import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// دستهٔ محصولات فروشگاه (فیزیکی — مدل همکاری در فروش).
enum StoreCategory {
  supplement('مکمل', LucideIcons.pill),
  apparel('پوشاک', LucideIcons.shirt),
  equipment('تجهیزات', LucideIcons.dumbbell),
  accessory('اکسسوری', LucideIcons.backpack);

  const StoreCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// مدل سادهٔ محصول برای نمایشِ teaser فروشگاه (مدل همکاری در فروش / پورسانتی).
class StoreProduct {
  const StoreProduct({
    required this.title,
    required this.subtitle,
    required this.partner,
    required this.category,
    required this.priceLabel,
    required this.experienceLabel,
    required this.ratingLabel,
    required this.highlight,
    required this.icon,
    this.badge = 'به‌زودی',
    this.originalPriceLabel,
    this.accent,
  });

  final String title;
  final String subtitle;
  final String partner;
  final StoreCategory category;
  final String priceLabel;
  final String? originalPriceLabel;
  final String experienceLabel;
  final String ratingLabel;
  final String highlight;
  final String badge;
  final Color? accent;

  /// آیکون اختصاصی محصول (نمایشی تا عکس واقعی اضافه شود).
  final IconData icon;

  static const List<StoreProduct> samples = [
    StoreProduct(
      title: 'پروتئین وی ایزوله',
      subtitle: 'ایزوله پریمیوم با طعم وانیل بوربن',
      partner: 'جیم‌ای‌آی سلکت',
      category: StoreCategory.supplement,
      priceLabel: '۲,۴۹۰,۰۰۰ تومان',
      originalPriceLabel: '۲,۸۹۰,۰۰۰',
      experienceLabel: 'ارسال سریع',
      ratingLabel: '۴.۹',
      highlight: '۲۵ سروینگ پروتئین خالص',
      badge: 'پرفروش',
      icon: LucideIcons.milk,
      accent: Color(0xFFD8A84E),
    ),
    StoreProduct(
      title: 'کراتین میکرونایز',
      subtitle: 'کراتین خالص با جذب سریع و بسته‌بندی شیک',
      partner: 'آزمایشگاه رزرو',
      category: StoreCategory.supplement,
      priceLabel: '۸۹۰,۰۰۰ تومان',
      originalPriceLabel: '۱,۰۵۰,۰۰۰',
      experienceLabel: 'پیشنهاد مربی',
      ratingLabel: '۴.۸',
      highlight: 'بدون طعم، جذب سریع',
      badge: 'انتخاب مربی',
      icon: LucideIcons.zap,
      accent: Color(0xFF63D2A2),
    ),
    StoreProduct(
      title: 'تیشرت تمرین اورسایز',
      subtitle: 'پارچه تنفسی، برش راحت و لوگوی مینیمال',
      partner: 'جیم‌ای‌آی استودیو',
      category: StoreCategory.apparel,
      priceLabel: '۷۹۰,۰۰۰ تومان',
      originalPriceLabel: '۹۲۰,۰۰۰',
      experienceLabel: 'موجودی محدود',
      ratingLabel: '۴.۷',
      highlight: 'فیت آزاد باشگاهی',
      badge: 'محدود',
      icon: LucideIcons.shirt,
      accent: Color(0xFFEC6A9E),
    ),
    StoreProduct(
      title: 'ست تمرین یکپارچه',
      subtitle: 'ست ورزشی سبک با ساپورت بالا و دوخت بدون درز',
      partner: 'آرا فیت',
      category: StoreCategory.apparel,
      priceLabel: '۱,۶۹۰,۰۰۰ تومان',
      originalPriceLabel: '۱,۹۵۰,۰۰۰',
      experienceLabel: 'کیفیت پریمیوم',
      ratingLabel: '۴.۹',
      highlight: 'ساپورت بالا، بدون لغزش',
      badge: 'پریمیوم',
      icon: LucideIcons.layers,
      accent: Color(0xFF9F7AEA),
    ),
    StoreProduct(
      title: 'کیت کش مقاومتی',
      subtitle: 'کیت تمرین خانگی با کیف چرمی و دستگیره فلزی',
      partner: 'فورج گیر',
      category: StoreCategory.equipment,
      priceLabel: '۱,۲۹۰,۰۰۰ تومان',
      originalPriceLabel: '۱,۵۸۰,۰۰۰',
      experienceLabel: 'پک کامل',
      ratingLabel: '۴.۸',
      highlight: '۵ سطح مقاومت',
      badge: 'حرفه‌ای',
      icon: LucideIcons.dumbbell,
      accent: Color(0xFF4FA3FF),
    ),
    StoreProduct(
      title: 'شیکر هوشمند استیل',
      subtitle: 'شیکر استیل با محفظه مکمل و درب ضدنشت',
      partner: 'هیدرا کلاب',
      category: StoreCategory.accessory,
      priceLabel: '۶۹۰,۰۰۰ تومان',
      originalPriceLabel: '۸۲۰,۰۰۰',
      experienceLabel: 'مناسب روزمره',
      ratingLabel: '۴.۶',
      highlight: 'حفظ دما تا ۱۲ ساعت',
      badge: 'جدید',
      icon: LucideIcons.cupSoda,
      accent: Color(0xFF00C2B8),
    ),
  ];
}
