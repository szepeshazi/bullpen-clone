import 'package:bullpen/models/cell.dart';
import 'package:bullpen/models/pen.dart';
import 'package:bullpen/models/puzzle_board.dart';
import 'package:bullpen/models/puzzle_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper: creates a simple 8×8 board with 8 pens, each pen being one row.
PuzzleBoard _makeRowBasedBoard({int size = 8}) {
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

void main() {
  group('PuzzleBoard construction', () {
    test('rejects size below 8', () {
      expect(
        () => PuzzleBoard(size: 7, pens: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects size above 16', () {
      expect(
        () => PuzzleBoard(size: 17, pens: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid sizes', () {
      for (final size in [8, 10, 16]) {
        final board = _makeRowBasedBoard(size: size);
        expect(board.size, size);
        expect(board.pens, hasLength(size));
      }
    });
  });

  group('PuzzleBoard cell access', () {
    test('cellAt returns correct cell', () {
      final board = _makeRowBasedBoard();
      final cell = board.cellAt(3, 5);
      expect(cell.row, 3);
      expect(cell.col, 5);
      expect(cell.penId, 3); // row-based pens
    });

    test('cellAt throws on out-of-bounds', () {
      final board = _makeRowBasedBoard();
      expect(() => board.cellAt(-1, 0), throwsA(isA<RangeError>()));
      expect(() => board.cellAt(0, 8), throwsA(isA<RangeError>()));
    });

    test('penForCell returns correct pen', () {
      final board = _makeRowBasedBoard();
      final cell = board.cellAt(2, 0);
      final pen = board.penForCell(cell);
      expect(pen.id, 2);
    });

    test('penById returns correct pen', () {
      final board = _makeRowBasedBoard();
      final pen = board.penById(5);
      expect(pen.id, 5);
      expect(pen.cells, hasLength(8));
    });

    test('penById throws on invalid id', () {
      final board = _makeRowBasedBoard();
      expect(() => board.penById(99), throwsA(isA<ArgumentError>()));
    });
  });

  group('PuzzleState bull placement', () {
    test('placeBull adds a bull', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      final cell = state.board.cellAt(0, 0);
      expect(state.placeBull(cell), isTrue);
      expect(state.bullCount, 1);
      expect(state.hasBullAt(0, 0), isTrue);
    });

    test('placeBull returns false if bull already placed', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      final cell = state.board.cellAt(0, 0);
      state.placeBull(cell);
      expect(state.placeBull(cell), isFalse);
      expect(state.bullCount, 1);
    });

    test('removeBull removes a bull', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      final cell = state.board.cellAt(0, 0);
      state.placeBull(cell);
      expect(state.removeBull(cell), isTrue);
      expect(state.bullCount, 0);
      expect(state.hasBullAt(0, 0), isFalse);
    });

    test('removeBull returns false if no bull at location', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      expect(state.removeBull(state.board.cellAt(0, 0)), isFalse);
    });

    test('clear removes all bulls', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(1, 3));
      state.clear();
      expect(state.bullCount, 0);
      expect(state.hasBullAt(0, 0), isFalse);
      expect(state.hasBullAt(1, 3), isFalse);
    });
  });

  group('PuzzleState counting', () {
    test('bullsInRow returns correct count', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(0, 3));
      expect(state.bullsInRow(0), 2);
      expect(state.bullsInRow(1), 0);
    });

    test('bullsInCol returns correct count', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 2));
      state.placeBull(state.board.cellAt(5, 2));
      expect(state.bullsInCol(2), 2);
      expect(state.bullsInCol(0), 0);
    });

    test('bullsInPen returns correct count', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(0, 4));
      expect(state.bullsInPen(0), 2);
      expect(state.bullsInPen(1), 0);
    });
  });

  group('PuzzleState adjacency', () {
    test('hasAdjacentBull detects orthogonal neighbors', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(3, 3));

      expect(state.hasAdjacentBull(state.board.cellAt(2, 3)), isTrue);
      expect(state.hasAdjacentBull(state.board.cellAt(4, 3)), isTrue);
      expect(state.hasAdjacentBull(state.board.cellAt(3, 2)), isTrue);
      expect(state.hasAdjacentBull(state.board.cellAt(3, 4)), isTrue);
    });

    test('hasAdjacentBull detects diagonal neighbors', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(3, 3));

      expect(state.hasAdjacentBull(state.board.cellAt(2, 2)), isTrue);
      expect(state.hasAdjacentBull(state.board.cellAt(2, 4)), isTrue);
      expect(state.hasAdjacentBull(state.board.cellAt(4, 2)), isTrue);
      expect(state.hasAdjacentBull(state.board.cellAt(4, 4)), isTrue);
    });

    test('hasAdjacentBull returns false for non-adjacent cells', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(3, 3));

      expect(state.hasAdjacentBull(state.board.cellAt(0, 0)), isFalse);
      expect(state.hasAdjacentBull(state.board.cellAt(5, 5)), isFalse);
      expect(state.hasAdjacentBull(state.board.cellAt(1, 3)), isFalse);
    });

    test('hasAdjacentBull returns false for the bull cell itself', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(3, 3));
      expect(state.hasAdjacentBull(state.board.cellAt(3, 3)), isFalse);
    });
  });

  group('PuzzleState isValid', () {
    test('empty state is valid', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      expect(state.isValid, isTrue);
    });

    test('valid partial placement is valid', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(0, 5));
      expect(state.isValid, isTrue);
    });

    test('three bulls in same row is invalid', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(0, 3));
      state.placeBull(state.board.cellAt(0, 6));
      expect(state.isValid, isFalse);
    });

    test('three bulls in same column is invalid', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(3, 0));
      state.placeBull(state.board.cellAt(6, 0));
      expect(state.isValid, isFalse);
    });
  });

  group('PuzzleState isSolved', () {
    test('empty state is not solved', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      expect(state.isSolved, isFalse);
    });

    test('correctly solved grid returns true', () {
      final validPlacements = [
        (0, 1), (0, 3),
        (1, 5), (1, 7),
        (2, 1), (2, 3),
        (3, 5), (3, 7),
        (4, 0), (4, 2),
        (5, 4), (5, 6),
        (6, 0), (6, 2),
        (7, 4), (7, 6),
      ];

      final state = PuzzleState(board: _makeRowBasedBoard());
      for (final (r, c) in validPlacements) {
        state.placeBull(state.board.cellAt(r, c));
      }

      expect(state.isSolved, isTrue);
    });

    test('isSolved false when not enough bulls', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      expect(state.isSolved, isFalse);
    });

    test('isSolved false when row has only 1 bull', () {
      final incompletePlacements = [
        (0, 1), (0, 3),
        (1, 5), (1, 7),
        (2, 1), (2, 3),
        (3, 5), (3, 7),
        (4, 0), (4, 2),
        (5, 4), (5, 6),
        (6, 0), (6, 2),
        (7, 4), // only 1 in row 7
      ];
      final state = PuzzleState(board: _makeRowBasedBoard());
      for (final (r, c) in incompletePlacements) {
        state.placeBull(state.board.cellAt(r, c));
      }
      expect(state.isSolved, isFalse);
    });
  });

  group('PuzzleState removeBull stack optimization', () {
    test('removeLast path works when removing most recent bull', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(1, 3));
      // Remove in reverse order (backtracking pattern).
      expect(state.removeBull(state.board.cellAt(1, 3)), isTrue);
      expect(state.bullCount, 1);
      expect(state.hasBullAt(1, 3), isFalse);
      expect(state.hasBullAt(0, 0), isTrue);
    });

    test('removeWhere path works when removing non-last bull', () {
      final state = PuzzleState(board: _makeRowBasedBoard());
      state.placeBull(state.board.cellAt(0, 0));
      state.placeBull(state.board.cellAt(1, 3));
      // Remove first placed (not the last) — exercises the fallback path.
      expect(state.removeBull(state.board.cellAt(0, 0)), isTrue);
      expect(state.bullCount, 1);
      expect(state.hasBullAt(0, 0), isFalse);
      expect(state.hasBullAt(1, 3), isTrue);
    });
  });
}
