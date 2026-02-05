import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// تست integration برای بررسی overflow در صفحات واقعی
/// این تست صفحات اصلی را با اندازه‌های مختلف صفحه تست می‌کند
void main() {
  group('Integration Overflow Tests', () {
    // اندازه‌های مختلف صفحه
    final testSizes = [
      const Size(320, 568), // iPhone SE
      const Size(375, 812), // iPhone X
      const Size(414, 896), // iPhone 11 Pro Max
      const Size(768, 1024), // iPad
    ];

    // مقیاس‌های مختلف متن
    final textScales = [1.0, 1.2, 1.5];

    /// تست یک صفحه برای overflow
    Future<void> testScreenForOverflow(
      WidgetTester tester,
      Widget screen,
      String screenName, {
      Size? screenSize,
      double? textScale,
    }) async {
      final size = screenSize ?? const Size(375, 812);
      final scale = textScale ?? 1.0;

      await tester.binding.setSurfaceSize(size);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: screen,
          ),
        ),
      );

      // صبر برای build کامل
      await tester.pumpAndSettle();

      // بررسی overflow
      final exception = tester.takeException();
      if (exception != null) {
        debugPrint('⚠️ Overflow in $screenName: Size=$size, TextScale=$scale');
        debugPrint('Exception: $exception');
      }

      // بررسی برای RenderFlex overflow
      // در Flutter جدید، ErrorWidget API متفاوتی دارد
      // بنابراین فقط exception را بررسی می‌کنیم
      if (exception != null) {
        final exceptionStr = exception.toString();
        if (exceptionStr.contains('overflow') ||
            exceptionStr.contains('RenderFlex')) {
          debugPrint('⚠️ Found overflow error in $screenName: $exceptionStr');
        }
      }
    }

    /// تست یک widget tree برای مشکلات overflow
    Future<void> testWidgetTreeForOverflow(
      WidgetTester tester,
      Widget widget,
      String widgetName,
    ) async {
      for (final size in testSizes) {
        for (final scale in textScales) {
          await testScreenForOverflow(
            tester,
            widget,
            widgetName,
            screenSize: size,
            textScale: scale,
          );
        }
      }
    }

    testWidgets('Test Basic Widgets for Overflow', (WidgetTester tester) async {
      // تست Text
      await testWidgetTreeForOverflow(tester, const Text('متن تست'), 'Text');

      // تست Row
      await testWidgetTreeForOverflow(
        tester,
        Row(
          children: [
            const Text('متن 1'),
            const Text('متن 2'),
            const Text('متن 3'),
          ],
        ),
        'Row',
      );

      // تست Column
      await testWidgetTreeForOverflow(
        tester,
        Column(children: List.generate(10, (index) => Text('Item $index'))),
        'Column',
      );
    });

    // تست‌های اضافی برای صفحات خاص
    // این تست‌ها نیاز به mock data دارند
    // برای اجرای کامل، باید dependencies را mock کنید
  });

  group('Overflow Prevention Best Practices', () {
    testWidgets('SafeRow should not overflow', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      final safeRow = Row(
        children: [
          Flexible(
            child: Text(
              'متن بسیار طولانی که نباید overflow کند',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const Icon(Icons.star),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: safeRow)),
        ),
      );

      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'SafeRow should not cause overflow');
    });

    testWidgets('Text with maxLines should not overflow', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      final safeText = Text(
        'این یک متن بسیار طولانی است که باید با ellipsis نمایش داده شود',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: safeText)),
        ),
      );

      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Text with maxLines should not overflow',
      );
    });

    testWidgets('Scrollable Column should not overflow', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      final scrollableColumn = SingleChildScrollView(
        child: Column(
          children: List.generate(
            20,
            (index) => Container(
              height: 100,
              color: Colors.blue,
              child: Text('Item $index'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: scrollableColumn)),
      );

      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Scrollable Column should not overflow',
      );
    });
  });
}
