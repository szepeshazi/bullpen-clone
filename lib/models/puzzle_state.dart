import 'package:bullpen/models/adjacency.dart';
import 'package:bullpen/models/bull_location.dart';
import 'package:bullpen/models/cell.dart';
import 'package:bullpen/models/puzzle_board.dart';

/// Mutable bull placement tracked over an immutable [PuzzleBoard], with
/// O(1) row/column/pen counters and a 2D occupancy grid for fast adjacency.
class PuzzleState {
  final PuzzleBoard board;

  /// Stack of placed bulls — LIFO so the solver can pop on backtrack.
  final List<BullLocation> _bulls = [];

  late final List<int> _rowCounts;
  late final List<int> _colCounts;
  late final Map<int, int> _penCounts;
  late final List<List<bool>> _occupied;

  PuzzleState({required this.board}) {
    final s = board.size;
    _rowCounts = List.filled(s, 0);
    _colCounts = List.filled(s, 0);
    _penCounts = {for (final pen in board.pens) pen.id: 0};
    _occupied = List.generate(s, (_) => List.filled(s, false));
  }

  List<BullLocation> get bulls => List.unmodifiable(_bulls);
  int get bullCount => _bulls.length;

  bool placeBull(Cell cell) {
    final r = cell.row;
    final c = cell.col;
    if (_occupied[r][c]) {
      return false;
    }
    _bulls.add(BullLocation(cell: board.cellAt(r, c)));
    _occupied[r][c] = true;
    _rowCounts[r]++;
    _colCounts[c]++;
    _penCounts[cell.penId] = (_penCounts[cell.penId] ?? 0) + 1;
    return true;
  }

  /// Stack-discipline optimisation: backtracking almost always pops the
  /// last-placed bull, so we shortcut to O(1) `removeLast()` in that case.
  bool removeBull(Cell cell) {
    final r = cell.row;
    final c = cell.col;
    if (!_occupied[r][c]) {
      return false;
    }

    // Fast path: backtracking almost always removes the most recent bull.
    if (_bulls.isNotEmpty && _bulls.last.row == r && _bulls.last.col == c) {
      _bulls.removeLast();
    } else {
      _bulls.removeWhere((b) => b.row == r && b.col == c);
    }

    _occupied[r][c] = false;
    _rowCounts[r]--;
    _colCounts[c]--;
    _penCounts[cell.penId] = (_penCounts[cell.penId] ?? 1) - 1;
    return true;
  }

  void clear() {
    _bulls.clear();
    for (var i = 0; i < board.size; i++) {
      _rowCounts[i] = 0;
      _colCounts[i] = 0;
      _occupied[i].fillRange(0, board.size, false);
    }
    for (final key in _penCounts.keys) {
      _penCounts[key] = 0;
    }
  }

  bool hasBullAt(int row, int col) => _occupied[row][col];
  int bullsInRow(int row) => _rowCounts[row];
  int bullsInCol(int col) => _colCounts[col];
  int bullsInPen(int penId) => _penCounts[penId] ?? 0;

  bool hasAdjacentBull(Cell cell) => hasAdjacentMatch(
    cell.row,
    cell.col,
    board.size,
    (nr, nc) => _occupied[nr][nc],
  );

  /// Skips adjacency — the solver enforces adjacency incrementally.
  /// [isSolved] still re-checks adjacency as a safety net.
  bool get isValid {
    for (var i = 0; i < board.size; i++) {
      if (_rowCounts[i] > 2) {
        return false;
      }
      if (_colCounts[i] > 2) {
        return false;
      }
    }
    for (final pen in board.pens) {
      if (bullsInPen(pen.id) > 2) {
        return false;
      }
    }
    return true;
  }

  bool get isSolved {
    final s = board.size;
    if (_bulls.length != 2 * s) {
      return false;
    }

    for (var i = 0; i < s; i++) {
      if (_rowCounts[i] != 2) {
        return false;
      }
      if (_colCounts[i] != 2) {
        return false;
      }
    }
    for (final pen in board.pens) {
      if (bullsInPen(pen.id) != 2) {
        return false;
      }
    }

    for (final bull in _bulls) {
      if (hasAdjacentMatch(
        bull.row,
        bull.col,
        s,
        (nr, nc) => _occupied[nr][nc],
      )) {
        return false;
      }
    }
    return true;
  }
}
