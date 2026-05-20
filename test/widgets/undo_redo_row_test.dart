import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/widgets/game/undo_redo_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_board.dart';

void main() {
  Future<void> pump(WidgetTester tester, GameCubit cubit) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const UndoRedoRow(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('UndoRedoRow', () {
    testWidgets('undo is disabled with no history', (tester) async {
      final cubit = makePlayingCubit();
      await pump(tester, cubit);

      final undo = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.undo),
          matching: find.byType(IconButton),
        ),
      );
      expect(undo.onPressed, isNull);
      cubit.close();
    });

    testWidgets('undo is enabled after a move', (tester) async {
      final cubit = makePlayingCubit();
      cubit.toggleDot(0, 0);
      await pump(tester, cubit);

      final undo = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.undo),
          matching: find.byType(IconButton),
        ),
      );
      expect(undo.onPressed, isNotNull);
      cubit.close();
    });

    testWidgets('tapping hint requests a hint', (tester) async {
      final cubit = makePlayingCubit();
      // Place 2 bulls in row 0 to make a hint available.
      cubit.toggleBull(0, 0);
      cubit.toggleBull(0, 2);
      await pump(tester, cubit);

      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      await tester.pump();

      final state = cubit.state as GamePlaying;
      expect(state.hasHint, isTrue);
      cubit.close();
    });
  });
}
