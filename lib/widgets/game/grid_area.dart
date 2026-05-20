import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/game_cubit.dart';
import '../../cubit/game_state.dart';
import '../../logic/hint_finder.dart';
import '../../pages/main_page.dart';
import '../../theme.dart';
import '../bullpen_grid.dart';
import '../celebration_overlay.dart';
import 'hint_arrow_overlay.dart';
import 'hint_reason_banner.dart';

class GridArea extends StatelessWidget {
  const GridArea({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listenWhen: (prev, curr) => curr is GameError,
      listener: _onError,
      builder: (context, state) {
        if (state is GameGenerating) {
          return const Center(
            child: CircularProgressIndicator(color: bullpenAccentColor),
          );
        }
        if (state is GamePlaying) {
          return _PlayingArea(state: state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _onError(BuildContext context, GameState state) {
    if (state is! GameError) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

class _PlayingArea extends StatelessWidget {
  final GamePlaying state;
  const _PlayingArea({required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: BullpenGrid(gameState: state),
            ),
            if (state.hasHint)
              HintArrowOverlay(
                hintCell: state.hintCell!,
                hintType: state.hintType ?? HintType.exclude,
                boardSize: state.board.size,
                areaWidth: constraints.maxWidth,
                areaHeight: constraints.maxHeight,
              ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HintReasonBanner(),
            ),
            if (state.solved)
              Positioned.fill(
                child: CelebrationOverlay(
                  onDismiss: () => Navigator.of(context)
                      .pushReplacement(MainPage.route()),
                ),
              ),
          ],
        );
      },
    );
  }
}
