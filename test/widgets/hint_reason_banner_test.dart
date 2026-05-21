import 'dart:async';

import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/widgets/game/hint_reason_banner.dart';
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
            child: const HintReasonBanner(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('HintReasonBanner', () {
    testWidgets('renders nothing when no hint is set', (tester) async {
      final cubit = makePlayingCubit();
      await pump(tester, cubit);

      expect(find.byIcon(Icons.lightbulb), findsNothing);
      unawaited(cubit.close());
    });

    testWidgets('shows reason once a hint is requested', (tester) async {
      final cubit = makePlayingCubit()
        ..toggleBull(0, 0)
        ..toggleBull(0, 2)
        ..requestHint();
      await pump(tester, cubit);
      await tester.pump(const Duration(milliseconds: 350));

      final state = cubit.state as GamePlaying;
      expect(find.text(state.hintReason!), findsOneWidget);
      unawaited(cubit.close());
    });

    testWidgets('apply button triggers applyHint', (tester) async {
      final cubit = makePlayingCubit()
        ..toggleBull(0, 0)
        ..toggleBull(0, 2)
        ..requestHint();
      await pump(tester, cubit);
      await tester.pump(const Duration(milliseconds: 350));

      final stateBefore = cubit.state as GamePlaying;
      final (hintRow, hintCol) = stateBefore.hintCell!;

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();

      final stateAfter = cubit.state as GamePlaying;
      // The hint cell should have been filled (dot for exclude).
      expect(stateAfter.markAt(hintRow, hintCol), isNot(CellMark.empty));
      unawaited(cubit.close());
    });
  });
}
