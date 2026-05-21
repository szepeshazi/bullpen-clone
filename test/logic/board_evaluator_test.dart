import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/logic/board_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_board.dart';

// Known-valid 8×8 solution (verified in game_grid_test.dart).
const _solved = [
  (0, 1), (0, 3),
  (1, 5), (1, 7),
  (2, 1), (2, 3),
  (3, 5), (3, 7),
  (4, 0), (4, 2),
  (5, 4), (5, 6),
  (6, 0), (6, 2),
  (7, 4), (7, 6),
];

List<List<CellMark>> _marksFrom(List<(int, int)> placements, {int size = 8}) {
  final marks = List.generate(size, (_) => List.filled(size, CellMark.empty));
  for (final (r, c) in placements) {
    marks[r][c] = CellMark.bull;
  }
  return marks;
}

void main() {
  group('BoardEvaluator.isSolved', () {
    test('empty board is not solved', () {
      final board = makeRowPenBoard();
      expect(BoardEvaluator.isSolved(board, _marksFrom([])), isFalse);
    });

    test('board with fewer than 2*size bulls is not solved', () {
      final board = makeRowPenBoard();
      expect(BoardEvaluator.isSolved(board, _marksFrom([(0, 0)])), isFalse);
    });

    test('correctly solved board is solved', () {
      final board = makeRowPenBoard();
      expect(
        BoardEvaluator.isSolved(board, _marksFrom(_solved.toList())),
        isTrue,
      );
    });

    test('board with adjacency violation is not solved', () {
      // Take the valid solution and introduce an adjacency: move (1,5) to (1,4)
      // so (1,4) and (2,3) are diagonally adjacent.
      final broken = _solved.toList()
        ..remove((1, 5))
        ..add((1, 4));
      final board = makeRowPenBoard();
      expect(BoardEvaluator.isSolved(board, _marksFrom(broken)), isFalse);
    });
  });
}
