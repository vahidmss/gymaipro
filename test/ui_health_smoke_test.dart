import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fast automated checks for keyboard overlap and scroll safety patterns.
void main() {
  group('UI health smoke', () {
    testWidgets('keyboard does not overflow scrollable form', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            resizeToAvoidBottomInset: true,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < 12; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Field $i'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      await tester.showKeyboard(find.byType(TextFormField).first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ListView.builder handles large list without exception', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 200,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('eager ListView children still scrolls without exception', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: List.generate(
                30,
                (index) => ListTile(title: Text('Static $index')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
