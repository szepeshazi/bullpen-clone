import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/widgets/game/back_to_main_button.dart';
import 'package:bullpen/widgets/game/grid_area.dart';
import 'package:bullpen/widgets/game/remaining_bulls_indicator.dart';
import 'package:bullpen/widgets/game/undo_redo_row.dart';
import 'package:bullpen/widgets/grid_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GamePage extends StatelessWidget {
  final int gridSize;

  const GamePage({required this.gridSize, super.key});

  /// Route that injects a fresh [GameCubit] for the given size.
  static Route<void> route(int gridSize) => PageRouteBuilder(
    pageBuilder: (_, _, _) => GamePage(gridSize: gridSize),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: pageTransitionDuration,
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('gridSize', gridSize));
  }
}
