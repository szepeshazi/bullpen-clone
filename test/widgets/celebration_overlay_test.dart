import 'package:bullpen/widgets/celebration_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CelebrationOverlay', () {
    testWidgets('renders congratulations message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(onDismiss: () {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Congratulations!'), findsOneWidget);
      expect(find.text('All bulls are in their pens!'), findsOneWidget);
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
    });

    testWidgets('calls onDismiss when tapped', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(onDismiss: () => dismissed = true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Congratulations!'));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
