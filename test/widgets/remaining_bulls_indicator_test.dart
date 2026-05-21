import 'dart:async';

import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/widgets/game/remaining_bulls_indicator.dart';
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
            child: const RemainingBullsIndicator(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('RemainingBullsIndicator', () {
    testWidgets('shows total count for a fresh 8×8 game', (tester) async {
      final cubit = makePlayingCubit();
      await pump(tester, cubit);

      expect(find.text('Remaining bulls'), findsOneWidget);
      unawaited(cubit.close());
    });

    testWidgets('decrements after placing a bull', (tester) async {
      final cubit = makePlayingCubit();
      await pump(tester, cubit);

      cubit.toggleBull(0, 0);
      await tester.pump();

      expect(find.text('Remaining bulls'), findsOneWidget);
      unawaited(cubit.close());
    });

    testWidgets('is hidden when not playing', (tester) async {
      final cubit = GameCubit(skipGenerate: true);
      await pump(tester, cubit);

      expect(find.text('Remaining bulls'), findsNothing);
      unawaited(cubit.close());
    });
  });
}
