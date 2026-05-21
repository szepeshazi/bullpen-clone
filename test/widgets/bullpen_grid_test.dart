import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/widgets/bullpen_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_board.dart';

final Duration _drain =
    BullpenGrid.longPressDuration + const Duration(milliseconds: 100);

void main() {
  Future<void> pumpGrid(WidgetTester tester, GameCubit cubit) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: BlocBuilder<GameCubit, GameState>(
              builder: (_, state) {
                if (state is! GamePlaying) return const SizedBox();
                return SizedBox(
                  width: 400,
                  height: 400,
                  child: BullpenGrid(gameState: state),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('BullpenGrid gestures', () {
    testWidgets('short tap places a dot', (tester) async {
      final cubit = makePlayingCubit();
      await pumpGrid(tester, cubit);

      final center = tester.getCenter(find.byType(BullpenGrid));
      await tester.tapAt(center);
      // Wait past the 400ms long-press timer to let it fire harmlessly.
      await tester.pump(_drain);

      final state = cubit.state as GamePlaying;
      final hasAnyDot = state.marks.any((row) => row.contains(CellMark.dot));
      expect(
        hasAnyDot,
        isTrue,
        reason: 'A short tap should place at least one dot',
      );

      cubit.close();
    });

    testWidgets('long press places a bull', (tester) async {
      final cubit = makePlayingCubit();
      await pumpGrid(tester, cubit);

      final center = tester.getCenter(find.byType(BullpenGrid));
      final gesture = await tester.startGesture(center);
      // Long-press threshold is 400ms in the widget.
      await tester.pump(_drain);
      await gesture.up();
      await tester.pump();

      final state = cubit.state as GamePlaying;
      final hasAnyBull = state.marks.any((row) => row.contains(CellMark.bull));
      expect(hasAnyBull, isTrue, reason: 'A long press should place a bull');

      cubit.close();
    });

    testWidgets('drag streams dots across cells', (tester) async {
      final cubit = makePlayingCubit();
      await pumpGrid(tester, cubit);

      final gridRect = tester.getRect(find.byType(BullpenGrid));
      // Walk along the first column, stepping cell-by-cell.
      final cellStep = gridRect.height / 10; // larger than one cell
      final start = Offset(gridRect.left + 20, gridRect.top + 20);

      final gesture = await tester.startGesture(start);
      await tester.pump();
      // Move past 8px threshold first.
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(Offset(0, cellStep));
        await tester.pump();
      }
      await gesture.up();
      // Drain the long-press timer.
      await tester.pump(_drain);

      final state = cubit.state as GamePlaying;
      final dotCount = state.marks
          .expand((row) => row)
          .where((m) => m == CellMark.dot)
          .length;
      expect(
        dotCount,
        greaterThanOrEqualTo(2),
        reason: 'Drag should mark multiple cells',
      );

      cubit.close();
    });
  });
}
