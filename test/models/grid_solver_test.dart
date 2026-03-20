import 'dart:math';

import 'package:bullpen/models/cell.dart';
import 'package:bullpen/models/grid_generator.dart';
import 'package:bullpen/models/grid_solver.dart';
import 'package:bullpen/models/pen.dart';
import 'package:bullpen/models/puzzle_board.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a simple 8×8 board where each pen is one row.
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
  group('GridSolver', () {
    test('solves a simple row-based 8×8 board', () {
      final board = _makeRowBasedBoard();
      final state = GridSolver.solve(board, random: Random(42));
      expect(state, isNotNull);
      expect(state!.isSolved, isTrue);
      expect(state.bullCount, 16); // 2 per row × 8 rows
    });

    test('solution has exactly 2 bulls per row', () {
      final board = _makeRowBasedBoard();
      final state = GridSolver.solve(board, random: Random(42))!;
      for (int r = 0; r < 8; r++) {
        expect(state.bullsInRow(r), 2, reason: 'Row $r should have 2 bulls');
      }
    });

    test('solution has exactly 2 bulls per column', () {
      final board = _makeRowBasedBoard();
      final state = GridSolver.solve(board, random: Random(42))!;
      for (int c = 0; c < 8; c++) {
        expect(state.bullsInCol(c), 2, reason: 'Col $c should have 2 bulls');
      }
    });

    test('solution has exactly 2 bulls per pen', () {
      final board = _makeRowBasedBoard();
      final state = GridSolver.solve(board, random: Random(42))!;
      for (final pen in board.pens) {
        expect(state.bullsInPen(pen.id), 2,
            reason: 'Pen ${pen.id} should have 2 bulls');
      }
    });

    test('no two bulls are adjacent in the solution', () {
      final board = _makeRowBasedBoard();
      final state = GridSolver.solve(board, random: Random(42))!;
      for (final bull in state.bulls) {
        // Check all 8 neighbors.
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final nr = bull.row + dr;
            final nc = bull.col + dc;
            if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
              expect(state.hasBullAt(nr, nc), isFalse,
                  reason:
                      'Bull at (${bull.row},${bull.col}) is adjacent to '
                      'bull at ($nr,$nc)');
            }
          }
        }
      }
    });

    test('solves randomly generated 8×8 boards with retry', () {
      // Mirrors production: generate multiple boards and solve each.
      // A single board may not be solvable within the node budget, but
      // retrying with different layouts succeeds quickly.
      // With variable pen sizes (including small 3–5 cell pens), more
      // attempts may be needed.
      bool solved = false;
      for (int attempt = 0; attempt < 500 && !solved; attempt++) {
        final board = GridGenerator.generate(8, random: Random(attempt));
        final state = GridSolver.solve(board, random: Random(attempt));
        if (state != null && state.isSolved) solved = true;
      }
      expect(solved, isTrue, reason: 'Should solve at least one 8×8 board in 500 attempts');
    });

    test('solves randomly generated 10×10 boards with retry', () {
      bool solved = false;
      for (int attempt = 0; attempt < 500 && !solved; attempt++) {
        final board = GridGenerator.generate(10, random: Random(attempt));
        final state = GridSolver.solve(board, random: Random(attempt));
        if (state != null && state.isSolved) solved = true;
      }
      expect(solved, isTrue, reason: 'Should solve at least one 10×10 board in 500 attempts');
    });

    test('returns null for unsolvable board within node budget', () {
      // Create a degenerate 8×8 board: one huge pen and 7 single-cell pens.
      // This is extremely unlikely to be solvable with the constraint that
      // each pen needs exactly 2 bulls.
      final cells = <Cell>[];
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          // Assign most cells to pen 0.
          cells.add(Cell(row: r, col: c, penId: 0));
        }
      }
      // Override 7 cells to be their own pens.
      final penCells = <int, List<Cell>>{0: []};
      for (int i = 1; i < 8; i++) {
        penCells[i] = [Cell(row: 0, col: i, penId: i)];
      }
      // All other cells go to pen 0.
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (r == 0 && c >= 1 && c < 8) continue;
          penCells[0]!.add(Cell(row: r, col: c, penId: 0));
        }
      }

      final pens = penCells.entries
          .map((e) => Pen(id: e.key, cells: e.value))
          .toList();
      final board = PuzzleBoard(size: 8, pens: pens);

      // Single-cell pens can never have 2 bulls → unsolvable.
      final state = GridSolver.solve(board, random: Random(0));
      expect(state, isNull);
    });

    test('different random seeds can produce different solutions', () {
      final board = _makeRowBasedBoard();
      final state1 = GridSolver.solve(board, random: Random(1));
      final state2 = GridSolver.solve(board, random: Random(999));

      expect(state1, isNotNull);
      expect(state2, isNotNull);

      // Compare bull positions — they should differ for different seeds
      // (not guaranteed, but extremely likely).
      final pos1 = state1!.bulls.map((b) => (b.row, b.col)).toSet();
      final pos2 = state2!.bulls.map((b) => (b.row, b.col)).toSet();
      // At least one position should differ.
      expect(pos1 == pos2, isFalse,
          reason: 'Different seeds should usually produce different solutions');
    });
  });
}
