import 'package:bullpen/cubit/game_cubit.dart';
import 'package:bullpen/models/cell.dart';
import 'package:bullpen/models/pen.dart';
import 'package:bullpen/models/puzzle_board.dart';
import 'package:bullpen/models/puzzle_state.dart';

/// Builds an N×N board where row r is pen r — enough for any UI test that
/// doesn't depend on specific pen geometry.
PuzzleBoard makeRowPenBoard({int size = 8}) {
  final pens = <Pen>[];
  for (int penId = 0; penId < size; penId++) {
    final cells = List.generate(
      size,
      (col) => Cell(row: penId, col: col, penId: penId),
    );
    pens.add(Pen(id: penId, cells: cells));
  }
  return PuzzleBoard(size: size, pens: pens);
}

GameCubit makePlayingCubit({int size = 8}) {
  final board = makeRowPenBoard(size: size);
  final solution = PuzzleState(board: board);
  final cubit = GameCubit(skipGenerate: true);
  cubit.startPlaying(board: board, solution: solution);
  return cubit;
}
