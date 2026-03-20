import 'adjacency.dart';
import 'bull_location.dart';
import 'cell.dart';
import 'puzzle_board.dart';

/// Mutable game state for a Bullpen puzzle.
///
/// Tracks placed bulls with O(1) counters for row, column, and pen counts,
/// plus a 2D occupied grid for O(1) adjacency checks.
///
/// The immutable puzzle layout lives in [PuzzleBoard]; this class only manages
/// the bulls placed on top of it.
class PuzzleState {
  final PuzzleBoard board;

  /// Stack of placed bulls — last-in-first-out for efficient backtracking.
  final List<BullLocation> _bulls = [];

  /// O(1) counters.
  late final List<int> _rowCounts;
  late final List<int> _colCounts;
  late final Map<int, int> _penCounts;

  /// 2D boolean grid: true if a bull occupies (row, col).
  late final List<List<bool>> _occupied;

  PuzzleState({required this.board}) {
    final s = board.size;
    _rowCounts = List.filled(s, 0);
    _colCounts = List.filled(s, 0);
    _penCounts = {for (final pen in board.pens) pen.id: 0};
    _occupied = List.generate(s, (_) => List.filled(s, false));
  }

  /// Unmodifiable view of currently placed bulls.
  List<BullLocation> get bulls => List.unmodifiable(_bulls);

  /// Number of currently placed bulls.
  int get bullCount => _bulls.length;

  // ---------------------------------------------------------------------------
  // Placement
  // ---------------------------------------------------------------------------

  /// Places a bull at the given [cell]. Returns `true` if placed.
  bool placeBull(Cell cell) {
    final r = cell.row, c = cell.col;
    if (_occupied[r][c]) return false;
    _bulls.add(BullLocation(cell: board.cellAt(r, c)));
    _occupied[r][c] = true;
    _rowCounts[r]++;
    _colCounts[c]++;
    _penCounts[cell.penId] = (_penCounts[cell.penId] ?? 0) + 1;
    return true;
  }

  /// Removes the bull at the given [cell]. Returns `true` if removed.
  ///
  /// Uses stack-discipline optimisation: if the cell matches the last-placed
  /// bull we use `removeLast()` (O(1)) instead of a linear scan.
  bool removeBull(Cell cell) {
    final r = cell.row, c = cell.col;
    if (!_occupied[r][c]) return false;

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

  /// Removes all placed bulls, resetting state to empty.
  void clear() {
    _bulls.clear();
    for (int i = 0; i < board.size; i++) {
      _rowCounts[i] = 0;
      _colCounts[i] = 0;
      _occupied[i].fillRange(0, board.size, false);
    }
    for (final key in _penCounts.keys) {
      _penCounts[key] = 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Queries (all O(1))
  // ---------------------------------------------------------------------------

  bool hasBullAt(int row, int col) => _occupied[row][col];
  int bullsInRow(int row) => _rowCounts[row];
  int bullsInCol(int col) => _colCounts[col];
  int bullsInPen(int penId) => _penCounts[penId] ?? 0;

  /// Whether any placed bull is adjacent (including diagonals) to [cell].
  bool hasAdjacentBull(Cell cell) {
    return hasAdjacentMatch(
      cell.row,
      cell.col,
      board.size,
      (nr, nc) => _occupied[nr][nc],
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Whether the current placement violates no constraints.
  ///
  /// Uses the O(1) counters — no adjacency re-check because the solver
  /// enforces adjacency incrementally. The adjacency check is only included
  /// in [isSolved] as a safety net.
  bool get isValid {
    for (int i = 0; i < board.size; i++) {
      if (_rowCounts[i] > 2) return false;
      if (_colCounts[i] > 2) return false;
    }
    for (final pen in board.pens) {
      if (bullsInPen(pen.id) > 2) return false;
    }
    return true;
  }

  /// Whether the puzzle is fully and correctly solved.
  bool get isSolved {
    final s = board.size;
    if (_bulls.length != 2 * s) return false;

    for (int i = 0; i < s; i++) {
      if (_rowCounts[i] != 2) return false;
      if (_colCounts[i] != 2) return false;
    }
    for (final pen in board.pens) {
      if (bullsInPen(pen.id) != 2) return false;
    }

    // Safety-net adjacency check (O(bulls × 8) = O(n)).
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
