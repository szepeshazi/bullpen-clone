import 'package:bullpen/cubit/game_state.dart';
import 'package:bullpen/models/puzzle_board.dart';

/// Shared, pre-computed data used by every hint rule.
class HintContext {
  final PuzzleBoard board;
  final List<List<CellMark>> marks;

  final List<int> rowCounts;
  final List<int> colCounts;
  final Map<int, int> penCounts;

  /// `valid[r][c]` ≡ empty (and, post adjacency-rule, also non-adjacent).
  final List<List<bool>> valid;

  final Map<int, Set<int>> penValidRows;
  final Map<int, Set<int>> penValidCols;
  final List<int> activeRows;
  final List<int> activeCols;
  final Map<int, Set<int>> rowToPens;
  final Map<int, Set<int>> colToPens;

  /// Cells whose exclusion would break some group's feasibility.
  /// Rules must not return exclusion hints on these; they surface as
  /// mustPlace hints later.
  final Set<(int, int)> essential;

  HintContext._({
    required this.board,
    required this.marks,
    required this.rowCounts,
    required this.colCounts,
    required this.penCounts,
    required this.valid,
    required this.penValidRows,
    required this.penValidCols,
    required this.activeRows,
    required this.activeCols,
    required this.rowToPens,
    required this.colToPens,
    required this.essential,
  });

  factory HintContext.build(PuzzleBoard board, List<List<CellMark>> marks) {
    final size = board.size;
    final rowCounts = List.filled(size, 0);
    final colCounts = List.filled(size, 0);
    final penCounts = <int, int>{};

    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (marks[r][c] != CellMark.bull) {
          continue;
        }
        rowCounts[r]++;
        colCounts[c]++;
        final penId = board.cellAt(r, c).penId;
        penCounts[penId] = (penCounts[penId] ?? 0) + 1;
      }
    }

    final valid = List.generate(
      size,
      (r) => List.generate(size, (c) => marks[r][c] == CellMark.empty),
    );

    final penValidRows = <int, Set<int>>{};
    final penValidCols = <int, Set<int>>{};
    for (final pen in board.pens) {
      final rows = <int>{};
      final cols = <int>{};
      for (final cell in pen.cells) {
        if (valid[cell.row][cell.col]) {
          rows.add(cell.row);
          cols.add(cell.col);
        }
      }
      penValidRows[pen.id] = rows;
      penValidCols[pen.id] = cols;
    }

    final activeRows = [
      for (int r = 0; r < size; r++)
        if (rowCounts[r] < 2) r,
    ];
    final activeCols = [
      for (int c = 0; c < size; c++)
        if (colCounts[c] < 2) c,
    ];

    final rowToPens = <int, Set<int>>{};
    for (final r in activeRows) {
      final pens = <int>{};
      for (var c = 0; c < size; c++) {
        if (valid[r][c]) {
          pens.add(board.cellAt(r, c).penId);
        }
      }
      rowToPens[r] = pens;
    }
    final colToPens = <int, Set<int>>{};
    for (final c in activeCols) {
      final pens = <int>{};
      for (var r = 0; r < size; r++) {
        if (valid[r][c]) {
          pens.add(board.cellAt(r, c).penId);
        }
      }
      colToPens[c] = pens;
    }

    return HintContext._(
      board: board,
      marks: marks,
      rowCounts: rowCounts,
      colCounts: colCounts,
      penCounts: penCounts,
      valid: valid,
      penValidRows: penValidRows,
      penValidCols: penValidCols,
      activeRows: activeRows,
      activeCols: activeCols,
      rowToPens: rowToPens,
      colToPens: colToPens,
      essential: <(int, int)>{},
    ).._populateEssential();
  }

  int get size => board.size;

  /// Whether [candidates] can supply [needed] non-adjacent bulls without
  /// busting any row/col/pen cap.
  bool groupFeasible(List<(int, int)> candidates, int needed) {
    if (candidates.length < needed) {
      return false;
    }
    if (needed <= 1) {
      return true;
    }
    for (var i = 0; i < candidates.length; i++) {
      final (r1, c1) = candidates[i];
      for (var j = i + 1; j < candidates.length; j++) {
        final (r2, c2) = candidates[j];
        if (!_pairFeasible(r1, c1, r2, c2)) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  bool _pairFeasible(int r1, int c1, int r2, int c2) {
    if ((r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1) {
      return false;
    }
    if (r1 == r2 && rowCounts[r1] + 2 > 2) {
      return false;
    }
    if (r1 != r2 && (rowCounts[r1] >= 2 || rowCounts[r2] >= 2)) {
      return false;
    }
    if (c1 == c2 && colCounts[c1] + 2 > 2) {
      return false;
    }
    if (c1 != c2 && (colCounts[c1] >= 2 || colCounts[c2] >= 2)) {
      return false;
    }
    final p1 = board.cellAt(r1, c1).penId;
    final p2 = board.cellAt(r2, c2).penId;
    if (p1 == p2 && (penCounts[p1] ?? 0) + 2 > 2) {
      return false;
    }
    if (p1 != p2 &&
        ((penCounts[p1] ?? 0) >= 2 || (penCounts[p2] ?? 0) >= 2)) {
      return false;
    }
    return true;
  }

  /// Pre-computes [essential] cells: those whose removal makes some group
  /// infeasible. Only checked once at construction.
  void _populateEssential() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (!valid[r][c]) {
          continue;
        }
        if (_isEssentialFor(r, c)) {
          essential.add((r, c));
        }
      }
    }
  }

  bool _isEssentialFor(int r, int c) {
    final pid = board.cellAt(r, c).penId;
    final rn = 2 - rowCounts[r];
    if (rn > 0 && _essentialInRow(r, c, rn)) {
      return true;
    }
    final cn = 2 - colCounts[c];
    if (cn > 0 && _essentialInCol(r, c, cn)) {
      return true;
    }
    final pn = 2 - (penCounts[pid] ?? 0);
    if (pn > 0 && _essentialInPen(r, c, pid, pn)) {
      return true;
    }
    return false;
  }

  bool _essentialInRow(int r, int c, int needed) {
    final all = <(int, int)>[
      for (int c2 = 0; c2 < size; c2++)
        if (valid[r][c2]) (r, c2),
    ];
    final others = all.where((e) => e.$2 != c).toList();
    return groupFeasible(all, needed) && !groupFeasible(others, needed);
  }

  bool _essentialInCol(int r, int c, int needed) {
    final all = <(int, int)>[
      for (int r2 = 0; r2 < size; r2++)
        if (valid[r2][c]) (r2, c),
    ];
    final others = all.where((e) => e.$1 != r).toList();
    return groupFeasible(all, needed) && !groupFeasible(others, needed);
  }

  bool _essentialInPen(int r, int c, int penId, int needed) {
    final pen = board.penById(penId);
    final all = <(int, int)>[
      for (final cell in pen.cells)
        if (valid[cell.row][cell.col]) (cell.row, cell.col),
    ];
    final others = all.where((e) => !(e.$1 == r && e.$2 == c)).toList();
    return groupFeasible(all, needed) && !groupFeasible(others, needed);
  }
}
