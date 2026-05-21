import 'package:bullpen/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainPage', () {
    testWidgets('renders title and start button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BULLPEN'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
      expect(find.text('SELECT GRID SIZE'), findsOneWidget);
      expect(find.text('8 × 8'), findsOneWidget);
    });

    testWidgets('size label updates when carousel reports a new size',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pump(const Duration(milliseconds: 300));

      // Trigger a swipe on the page view inside SizeCarousel.
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      // Drive the scroll animation without waiting for the infinite pulse.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Title should no longer show 8×8.
      expect(find.text('8 × 8'), findsNothing);
    });
  });
}
