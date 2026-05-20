import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/game_cubit.dart';
import '../widgets/game/back_to_main_button.dart';
import '../widgets/game/grid_area.dart';
import '../widgets/game/remaining_bulls_indicator.dart';
import '../widgets/game/undo_redo_row.dart';

class GamePage extends StatelessWidget {
  final int gridSize;

  const GamePage({super.key, required this.gridSize});

  /// Route that injects a fresh [GameCubit] for the given size.
  static Route<void> route(int gridSize) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => GamePage(gridSize: gridSize),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameCubit(initialSize: gridSize),
      child: const Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 12),
              Expanded(child: GridArea()),
              SizedBox(height: 8),
              RemainingBullsIndicator(),
              UndoRedoRow(),
              SizedBox(height: 8),
              BackToMainButton(),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
