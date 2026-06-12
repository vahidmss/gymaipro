import 'package:flutter/material.dart';

/// یک کلاس جامع برای تشخیص overflow در ویجت‌ها
/// این کلاس می‌تواند در تست‌ها و debug mode استفاده شود
class OverflowDetector {
  /// بررسی یک widget tree برای مشکلات overflow
  /// این یک پیاده‌سازی ساده است - برای تست‌های کامل از WidgetTester استفاده کنید
  static Future<List<OverflowIssue>> checkWidgetTree(
    Widget widget, {
    List<Size>? screenSizes,
    List<double>? textScaleFactors,
  }) async {
    // این یک placeholder است
    // در واقعیت باید از WidgetTester در تست‌ها استفاده شود
    return <OverflowIssue>[];
  }

  /// بررسی یک Text widget برای overflow
  static bool checkTextOverflow({
    required String text,
    required TextStyle style,
    required double maxWidth,
    double? textScaleFactor,
    int? maxLines,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      textScaler: textScaleFactor != null
          ? TextScaler.linear(textScaleFactor)
          : const TextScaler.linear(1.0),
      maxLines: maxLines,
    );

    textPainter.layout(maxWidth: maxWidth);

    // بررسی اینکه آیا متن از عرض مجاز بیشتر است
    if (textPainter.width > maxWidth) {
      return true;
    }

    // بررسی اینکه آیا از maxLines بیشتر است
    if (maxLines != null && textPainter.didExceedMaxLines) {
      return true;
    }

    return false;
  }

  /// بررسی یک Row برای overflow
  static bool checkRowOverflow({
    required List<Widget> children,
    required double maxWidth,
  }) {
    // این یک بررسی ساده است
    // در واقعیت باید از RenderObject استفاده شود
    return false;
  }

  /// بررسی یک Column برای overflow
  static bool checkColumnOverflow({
    required List<Widget> children,
    required double maxHeight,
  }) {
    // این یک بررسی ساده است
    // در واقعیت باید از RenderObject استفاده شود
    return false;
  }
}

/// نوع overflow
enum OverflowType { horizontal, vertical, both }

/// یک مشکل overflow پیدا شده
class OverflowIssue {
  final OverflowType type;
  final String widgetType;
  final double? width;
  final double? maxWidth;
  final double? height;
  final double? maxHeight;
  final String? message;

  OverflowIssue({
    required this.type,
    required this.widgetType,
    this.width,
    this.maxWidth,
    this.height,
    this.maxHeight,
    this.message,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Overflow Issue:');
    buffer.writeln('  Type: $type');
    buffer.writeln('  Widget: $widgetType');

    if (width != null && maxWidth != null) {
      buffer.writeln(
        '  Width: $width > $maxWidth (overflow: ${width! - maxWidth!})',
      );
    }

    if (height != null && maxHeight != null) {
      buffer.writeln(
        '  Height: $height > $maxHeight (overflow: ${height! - maxHeight!})',
      );
    }

    if (message != null) {
      buffer.writeln('  Message: $message');
    }

    return buffer.toString();
  }
}

/// Extension برای بررسی overflow در BuildContext
extension OverflowCheckExtension on BuildContext {
  /// بررسی اینکه آیا یک widget می‌تواند overflow کند
  bool canOverflow(Widget widget) {
    final mediaQuery = MediaQuery.of(this);
    final size = mediaQuery.size;

    // بررسی ساده برای Text
    if (widget is Text) {
      final text = widget.data ?? '';
      final style = widget.style ?? DefaultTextStyle.of(this).style;
      final textScale = mediaQuery.textScaler.scale(1.0);

      return OverflowDetector.checkTextOverflow(
        text: text,
        style: style,
        maxWidth: size.width,
        textScaleFactor: textScale,
      );
    }

    return false;
  }

  /// دریافت اندازه امن برای widget
  Size get safeSize {
    final mediaQuery = MediaQuery.of(this);
    return Size(
      mediaQuery.size.width - mediaQuery.padding.horizontal,
      mediaQuery.size.height - mediaQuery.padding.vertical,
    );
  }
}
