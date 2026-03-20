import 'dart:math';

import 'puzzle_board.dart';
import 'puzzle_state.dart';

/// Solves a Bullpen hard-mode grid by placing exactly 2 bulls per row, column,
/// and pen with no two bulls adjacent (including diagonals).
///
/// Key optimisations over naive backtracking:
/// 1. O(1) counters for row / column / pen checks (in [PuzzleState]).
/// 2. O(1) adjacency check via the occupied grid (in [PuzzleState]).
/// 3. **Forward checking**: after every placement we verify that every
///    unfilled column and pen still has enough reachable cells in the
///    remaining rows. This prunes huge dead-end sub-trees early.
/// 4. **Randomised column-pair ordering** so that different `solve()` calls
///    explore different parts of the search space, making the retry loop
///    in the UI much more effective.
class GridSolver {
  GridSolver._();

  /// Maximum number of backtracking nodes before giving up on a single grid.
  /// This prevents the solver from spending too long on an unlucky pen layout;
  /// the caller can simply try a different random grid instead.
  static const _maxNodes = 50000;

  /// Attempts to solve the given [board].
  ///
  /// Returns a [PuzzleState] with bulls placed if a valid solution was found,
  /// or `null` if the board is unsolvable within the node budget.
  static PuzzleState? solve(PuzzleBoard board, {Random? random}) {
    final rng = random ?? Random();
    final state = PuzzleState(board: board);
    final size = board.size;

    // Pre-compute shuffled column-pairs for every row.
    final pairsPerRow = List.generate(size, (r) {
      final pairs = <(int, int)>[];
      for (int c1 = 0; c1 < size - 1; c1++) {
        for (int c2 = c1 + 2; c2 < size; c2++) {
          pairs.add((c1, c2));
        }
      }
      pairs.shuffle(rng);
      return pairs;
    });

    // Pre-index: for each pen, cells grouped by row.
    final penCellsByRow = <int, Map<int, List<int>>>{};
    for (final pen in board.pens) {
      final byRow = <int, List<int>>{};
      for (final cell in pen.cells) {
        byRow.putIfAbsent(cell.row, () => []).add(cell.col);
      }
      penCellsByRow[pen.id] = byRow;
    }

    int nodeCount = 0;

    bool solveRow(int row) {
      if (++nodeCount > _maxNodes) return false;
      if (row == size) return state.isSolved;

      for (final (c1, c2) in pairsPerRow[row]) {
        if (nodeCount > _maxNodes) return false;

        // --- Incremental constraint checks (all O(1)) ---
        if (state.bullsInCol(c1) >= 2) continue;
        if (state.bullsInCol(c2) >= 2) continue;

        final cell1 = board.cellAt(row, c1);
        final cell2 = board.cellAt(row, c2);

        final pen1 = cell1.penId;
        final pen2 = cell2.penId;

        if (state.bullsInPen(pen1) >= 2) continue;
        if (state.bullsInPen(pen2) >= 2) continue;
        if (pen1 == pen2 && state.bullsInPen(pen1) > 0) continue;

        if (state.hasAdjacentBull(cell1)) continue;
        if (state.hasAdjacentBull(cell2)) continue;

        // --- Place ---
        state.placeBull(cell1);
        state.placeBull(cell2);

        // --- Forward check ---
        if (_forwardCheck(board, state, row + 1, penCellsByRow)) {
          if (solveRow(row + 1)) return true;
        }

        // --- Backtrack ---
        state.removeBull(cell2);
        state.removeBull(cell1);
      }

      return false;
    }

    return solveRow(0) ? state : null;
  }

  /// Returns `false` if the current partial placement is provably unsolvable.
  ///
  /// Checks:
  /// 1. **Column feasibility**: every column that still needs bulls has enough
  ///    reachable cells in remaining rows.
  /// 2. **Pen feasibility**: every pen that still needs bulls has enough
  ///    available cells in rows >= [startRow].
  static bool _forwardCheck(
    PuzzleBoard board,
    PuzzleState state,
    int startRow,
    Map<int, Map<int, List<int>>> penCellsByRow,
  ) {
    final size = board.size;

    // --- Column feasibility ---
    for (int col = 0; col < size; col++) {
      final need = 2 - state.bullsInCol(col);
      if (need <= 0) continue;

      int available = 0;
      for (int r = startRow; r < size; r++) {
        final cell = board.cellAt(r, col);
        if (!state.hasAdjacentBull(cell)) {
          if (++available >= need) break;
        }
      }
      if (available < need) return false;
    }

    // --- Pen feasibility ---
    for (final pen in board.pens) {
      final need = 2 - state.bullsInPen(pen.id);
      if (need <= 0) continue;

      final byRow = penCellsByRow[pen.id]!;
      int available = 0;

      for (int r = startRow; r < size; r++) {
        final cols = byRow[r];
        if (cols == null) continue;
        for (final c in cols) {
          if (state.bullsInCol(c) < 2 &&
              !state.hasAdjacentBull(board.cellAt(r, c))) {
            if (++available >= need) break;
          }
        }
        if (available >= need) break;
      }
      if (available < need) return false;
    }

    return true;
  }
}
