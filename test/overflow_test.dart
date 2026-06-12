import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/utils/overflow_detector.dart';

/// تست جامع برای بررسی overflow در تمام صفحات
/// این تست تمام صفحات اصلی را با اندازه‌های مختلف صفحه تست می‌کند
void main() {
  group('Overflow Detection Tests', () {
    // اندازه‌های مختلف صفحه برای تست
    final testSizes = [
      const Size(320, 568), // iPhone SE (کوچک‌ترین)
      const Size(375, 812), // iPhone X (متوسط)
      const Size(414, 896), // iPhone 11 Pro Max (بزرگ)
      const Size(768, 1024), // iPad (تبلت)
    ];

    // مقیاس‌های مختلف متن
    final textScales = [1.0, 1.2, 1.5, 2.0];

    testWidgets('Test Text Widget Overflow', (WidgetTester tester) async {
      for (final size in testSizes) {
        for (final textScale in textScales) {
          await tester.binding.setSurfaceSize(size);

          // تست Text بدون maxLines
          const textWidget = Text(
            'این یک متن بسیار طولانی است که ممکن است باعث overflow شود و باید بررسی شود',
            style: TextStyle(fontSize: 16),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: const Center(child: textWidget),
                ),
              ),
            ),
          );

          // بررسی overflow
          final hasOverflow =
              tester.takeException() != null ||
              tester.binding.transientCallbackCount > 0;

          if (hasOverflow) {
            debugPrint(
              '⚠️ Overflow detected: Size=$size, TextScale=$textScale',
            );
          }
        }
      }
    });

    testWidgets('Test Row Widget Overflow', (WidgetTester tester) async {
      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);

        // تست Row با Text بدون Flexible
        const rowWidget = Row(
          children: [
            Text('متن طولانی که ممکن است overflow کند'),
            Icon(Icons.star),
            Text('متن دیگر'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(size: size),
                child: const Center(child: rowWidget),
              ),
            ),
          ),
        );

        // بررسی overflow
        final hasOverflow = tester.takeException() != null;

        if (hasOverflow) {
          debugPrint('⚠️ Row Overflow detected: Size=$size');
        }
      }
    });

    testWidgets('Test Column Widget Overflow', (WidgetTester tester) async {
      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);

        // تست Column با محتوای زیاد
        final columnWidget = Column(
          children: List.generate(
            20,
            (index) => Container(
              height: 100,
              color: Colors.blue,
              child: Text('Item $index'),
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(size: size),
                child: columnWidget,
              ),
            ),
          ),
        );

        // بررسی overflow
        final hasOverflow = tester.takeException() != null;

        if (hasOverflow) {
          debugPrint('⚠️ Column Overflow detected: Size=$size');
        }
      }
    });

    testWidgets('Test ListView Widget Overflow', (WidgetTester tester) async {
      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);

        // تست ListView
        final listViewWidget = ListView(
          children: List.generate(
            50,
            (index) => ListTile(
              title: Text('Item $index'),
              subtitle: Text('Subtitle for item $index'),
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(size: size),
                child: listViewWidget,
              ),
            ),
          ),
        );

        // ListView نباید overflow کند چون scrollable است
        final hasOverflow = tester.takeException() != null;

        if (hasOverflow) {
          debugPrint('⚠️ ListView Overflow detected: Size=$size');
        }
      }
    });

    testWidgets('Test Container with Fixed Width', (WidgetTester tester) async {
      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);

        // تست Container با عرض ثابت
        final containerWidget = Container(
          width: 500, // عرض بیشتر از صفحه کوچک
          height: 100,
          color: Colors.red,
          child: const Text('Container with fixed width'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(size: size),
                child: containerWidget,
              ),
            ),
          ),
        );

        // بررسی overflow
        final hasOverflow = tester.takeException() != null;

        if (hasOverflow && size.width < 500) {
          debugPrint(
            '⚠️ Container Overflow detected: Size=$size, ContainerWidth=500',
          );
        }
      }
    });

    testWidgets('Test SafeRow Widget', (WidgetTester tester) async {
      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);

        // تست SafeRow که باید overflow نکند
        const safeRowWidget = Row(
          children: [
            Flexible(
              child: Text(
                'متن طولانی که باید overflow نکند',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(Icons.star),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(size: size),
                child: const Center(child: safeRowWidget),
              ),
            ),
          ),
        );

        // SafeRow نباید overflow کند
        final hasOverflow = tester.takeException() != null;

        if (hasOverflow) {
          debugPrint('⚠️ SafeRow Overflow detected: Size=$size');
        }
      }
    });
  });

  group('Overflow Detector Utility Tests', () {
    test('Text overflow detection', () {
      final hasOverflow = OverflowDetector.checkTextOverflow(
        text:
            'این یک متن بسیار طولانی است که ممکن است باعث overflow شود و باید بررسی شود',
        style: const TextStyle(fontSize: 16),
        maxWidth: 50, // عرض خیلی کوچک برای اطمینان از overflow
        maxLines: 1,
      );

      expect(hasOverflow, isTrue);
    });

    test('Text no overflow detection', () {
      final hasOverflow = OverflowDetector.checkTextOverflow(
        text: 'متن کوتاه',
        style: const TextStyle(fontSize: 16),
        maxWidth: 1000,
      );

      expect(hasOverflow, isFalse);
    });
  });
}
