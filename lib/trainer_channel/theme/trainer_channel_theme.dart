import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رنگ‌ها و پس‌زمینه کانال — الهام از تلگرام
class TrainerChannelTheme {
  TrainerChannelTheme._();

  // ─── scaffold / appbar ───────────────────────────────────
  static Color scaffoldBackground(bool isDark) =>
      isDark ? const Color(0xFF0E1621) : const Color(0xFFCBD8E0);

  static Color appBarBackground(bool isDark) =>
      isDark ? const Color(0xFF17212B) : const Color(0xFFF4F4F4);

  // ─── حباب ────────────────────────────────────────────────
  static Color bubbleColor(bool isDark) =>
      isDark ? const Color(0xFF1C2B3A) : Colors.white;

  static List<BoxShadow> bubbleShadow(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.07),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  // ─── نوار ارسال ─────────────────────────────────────────
  static Color composeBarBackground(bool isDark) =>
      isDark ? const Color(0xFF17212B) : const Color(0xFFF4F4F4);

  static Color composeFieldBackground(bool isDark) =>
      isDark ? const Color(0xFF2A3A4A) : const Color(0xFFFFFFFF);

  // ─── chip تاریخ ─────────────────────────────────────────
  static Color dateChipBackground(bool isDark) => isDark
      ? Colors.black.withValues(alpha: 0.40)
      : Colors.black.withValues(alpha: 0.14);

  // ─── پس‌زمینه الگودار ────────────────────────────────────
  static Widget wallpaper({required bool isDark, required Widget child}) {
    return ColoredBox(
      color: scaffoldBackground(isDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _TelegramPatternPainter(isDark: isDark),
          ),
          child,
        ],
      ),
    );
  }

  // ─── گوشه‌های حباب (دم پایین راست) ─────────────────────
  static BorderRadius channelBubbleRadius({
    bool isFirst = true,
    bool isLast = true,
  }) {
    final r = 14.r;
    final inner = 6.r;
    return BorderRadius.only(
      topRight: Radius.circular(isFirst ? r : inner),
      topLeft: Radius.circular(r),
      bottomLeft: Radius.circular(r),
      bottomRight: Radius.circular(isLast ? 3.r : inner),
    );
  }
}

/// نقش‌برگ پس‌زمینه شبیه تلگرام — لوزی‌های کوچک
class _TelegramPatternPainter extends CustomPainter {
  _TelegramPatternPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final color = isDark
        ? Colors.white.withValues(alpha: 0.022)
        : Colors.black.withValues(alpha: 0.04);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const step = 24.0;
    const dotR = 1.4;

    for (var y = 0.0; y < size.height + step; y += step) {
      for (var x = 0.0; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), dotR, paint);
        canvas.drawCircle(Offset(x + step / 2, y + step / 2), dotR, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TelegramPatternPainter old) =>
      old.isDark != isDark;
}
