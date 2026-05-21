import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/models/adjacency.dart';
import 'package:bullpen/models/puzzle_board.dart';

class BullCounts {
  final List<(int, int)> bulls;
  final List<int> rowCounts;
  final List<int> colCounts;
  final Map<int, int> penCounts;

  const BullCounts({
    required this.bulls,
    required this.rowCounts,
    required this.colCounts,
    required this.penCounts,
  });
}

/// Pure rules engine for the Bullpen board: counts, violations, win check.
class BoardEvaluator {
  BoardEvaluator._();

  static BullCounts countBulls(
    PuzzleBoard board,
    List<List<CellMark>> marks,
  ) {
    final size = board.size;
    final bulls = <(int, int)>[];
    final rowCounts = List.filled(size, 0);
    final colCounts = List.filled(size, 0);
    final penCounts = <int, int>{};

    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (marks[r][c] != CellMark.bull) continue;
        bulls.add((r, c));
        rowCounts[r]++;
        colCounts[c]++;
        final penId = board.cellAt(r, c).penId;
        penCounts[penId] = (penCounts[penId] ?? 0) + 1;
      }
    }

    return BullCounts(
      bulls: bulls,
      rowCounts: rowCounts,
      colCounts: colCounts,
      penCounts: penCounts,
    );
  }

  /// Returns every bull involved in a rule violation: over-capacity rows,
  /// columns, or pens, plus any bull with an adjacent bull (including diagonals).
  static Set<(int, int)> findViolations(
    PuzzleBoard board,
    List<List<CellMark>> marks,
  ) {
    final size = board.size;
    final violations = <(int, int)>{};
    final counts = countBulls(board, marks);

    for (final (r, c) in counts.bulls) {
      if (counts.rowCounts[r] > 2) violations.add((r, c));
      if (counts.colCounts[c] > 2) violations.add((r, c));
      final penId = board.cellAt(r, c).penId;
      if ((counts.penCounts[penId] ?? 0) > 2) violations.add((r, c));
    }

    for (final (r, c) in counts.bulls) {
      final hasNeighbour = hasAdjacentMatch(
        r,
        c,
        size,
        (nr, nc) => marks[nr][nc] == CellMark.bull,
      );
      if (hasNeighbour) violations.add((r, c));
    }

    return violations;
  }

  /// Exactly 2 bulls per row, column, and pen; no adjacency.
  static bool isSolved(PuzzleBoard board, List<List<CellMark>> marks) {
    final size = board.size;
    final counts = countBulls(board, marks);

    if (counts.bulls.length != 2 * size) return false;

    for (var i = 0; i < size; i++) {
      if (counts.rowCounts[i] != 2) return false;
      if (counts.colCounts[i] != 2) return false;
    }
    for (final pen in board.pens) {
      if ((counts.penCounts[pen.id] ?? 0) != 2) return false;
    }

    for (final (r, c) in counts.bulls) {
      final hasNeighbour = hasAdjacentMatch(
        r,
        c,
        size,
        (nr, nc) => marks[nr][nc] == CellMark.bull,
      );
      if (hasNeighbour) return false;
    }

    return true;
  }
}
