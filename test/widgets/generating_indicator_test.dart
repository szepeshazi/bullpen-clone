import 'package:bullpen/widgets/game/generating_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeneratingIndicator', () {
    testWidgets('shows label with grid size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneratingIndicator(gridSize: 10)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Building 10×10 pen'),
        findsOneWidget,
      );
    });

    testWidgets('animates without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneratingIndicator(gridSize: 12)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1600));

      expect(tester.takeException(), isNull);
    });
  });
}
