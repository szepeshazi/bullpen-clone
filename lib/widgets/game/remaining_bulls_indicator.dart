import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RemainingBullsIndicator extends StatelessWidget {
  const RemainingBullsIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameCubit, GameState, ({int remaining, bool visible})>(
        selector: _select,
        builder: (context, s) {
          if (!s.visible) return const SizedBox.shrink();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Remaining bulls',
                style: TextStyle(
                  color: bullpenAccentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: List.generate(s.remaining, (_) => const _BullDot()),
                ),
              ),
            ],
          );
        },
      );

  ({int remaining, bool visible}) _select(GameState state) {
    if (state is GamePlaying && !state.solved) {
      final total = 2 * state.board.size;
      var placed = 0;
      for (final row in state.marks) {
        for (final cell in row) {
          if (cell == CellMark.bull) placed++;
        }
      }
      return (remaining: total - placed, visible: true);
    }
    return (remaining: 0, visible: false);
  }
}

class _BullDot extends StatelessWidget {
  const _BullDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: bullpenAccentColor, width: 1.5),
    ),
  );
}
