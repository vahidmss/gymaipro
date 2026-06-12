import 'package:flutter/material.dart';

/// Utility functions for responsive dialogs in meal_log
/// همه محاسبات بر اساس اندازه واقعی صفحه (MediaQuery) انجام می‌شود
class ResponsiveDialogUtils {
  /// محاسبه insetPadding استاندارد برای دیالوگ‌ها
  /// این تابع تضمین می‌کند که همه دیالوگ‌ها در همه صفحات یکسان نمایش داده شوند
  static EdgeInsets getStandardInsetPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final safePadding = mediaQuery.padding;
    
    // محاسبه insetPadding به صورت responsive و یکسان
    // استفاده از درصد ثابت برای همه دستگاه‌ها
    final horizontalInset = screenWidth > 600
        ? (screenWidth * 0.12).clamp(20.0, 40.0) // تبلت: 12% با حداقل 20 و حداکثر 40
        : (screenWidth * 0.06).clamp(12.0, 20.0); // موبایل: 6% با حداقل 12 و حداکثر 20
    
    final verticalInset = (screenHeight * 0.08).clamp(16.0, 32.0); // 8% با حداقل 16 و حداکثر 32
    
    return EdgeInsets.only(
      left: horizontalInset,
      right: horizontalInset,
      top: safePadding.top + verticalInset,
      bottom: safePadding.bottom + verticalInset,
    );
  }
  
  /// محاسبه maxWidth استاندارد برای دیالوگ‌ها
  static double getStandardMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return screenWidth > 600
        ? (screenWidth * 0.7).clamp(500.0, 700.0) // تبلت: 70% با حداقل 500 و حداکثر 700
        : (screenWidth * 0.9).clamp(300.0, 450.0); // موبایل: 90% با حداقل 300 و حداکثر 450
  }
  
  /// محاسبه border radius استاندارد برای دیالوگ‌ها
  static double getStandardBorderRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // استفاده از نسبت ثابت برای همه دستگاه‌ها
    return screenWidth > 600 ? 24.0 : 20.0;
  }
  
  /// محاسبه padding استاندارد برای محتوای دیالوگ‌ها
  static EdgeInsets getStandardDialogPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final padding = screenWidth > 600
        ? (screenWidth * 0.04).clamp(24.0, 32.0) // تبلت: 4% با حداقل 24 و حداکثر 32
        : (screenWidth * 0.053).clamp(16.0, 24.0); // موبایل: 5.3% با حداقل 16 و حداکثر 24
    
    return EdgeInsets.all(padding);
  }
  
  /// محاسبه padding استاندارد برای Container ها
  static EdgeInsets getStandardContainerPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final padding = screenWidth > 600
        ? (screenWidth * 0.03).clamp(16.0, 24.0) // تبلت: 3% با حداقل 16 و حداکثر 24
        : (screenWidth * 0.032).clamp(12.0, 16.0); // موبایل: 3.2% با حداقل 12 و حداکثر 16
    
    return EdgeInsets.all(padding);
  }
  
  /// محاسبه margin استاندارد برای Container ها
  static EdgeInsets getStandardContainerMargin(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final verticalMargin = screenWidth > 600 ? 12.0 : 8.0;
    
    return EdgeInsets.symmetric(vertical: verticalMargin);
  }
  
  /// محاسبه border radius استاندارد برای Container ها
  static double getStandardContainerBorderRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return screenWidth > 600 ? 20.0 : 16.0;
  }
}

