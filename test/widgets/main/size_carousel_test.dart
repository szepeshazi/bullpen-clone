import 'package:bullpen/logic/puzzle_config.dart';
import 'package:bullpen/widgets/main/size_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SizeCarousel', () {
    testWidgets('emits new size when user swipes', (tester) async {
      int? lastSize;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 160,
              child: SizeCarousel(
                selectedSize: 8,
                onSizeChanged: (size) => lastSize = size,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.fling(
        find.byType(SizeCarousel),
        const Offset(-300, 0),
        1000,
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(lastSize, isNotNull);
      expect(lastSize, isNot(8));
    });

    test('supported sizes are 8, 10, 12', () {
      expect(puzzleSupportedSizes, [8, 10, 12]);
    });
  });
}
