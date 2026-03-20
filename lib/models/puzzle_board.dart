import 'cell.dart';
import 'pen.dart';

/// The immutable layout of a Bullpen puzzle: grid dimensions, cells, and pens.
///
/// This is the "template" that never changes. Mutable game state (placed bulls,
/// counters) lives in [PuzzleState].
class PuzzleBoard {
  /// Grid dimension (rows = cols = size). Must be between 8 and 16.
  final int size;

  /// The pen regions that partition the grid.
  final List<Pen> pens;

  /// Internal 2D array for O(1) cell lookup by (row, col).
  late final List<List<Cell>> _cells;

  /// Map from penId → Pen for O(1) lookup.
  late final Map<int, Pen> _penMap;

  PuzzleBoard({
    required this.size,
    required this.pens,
  }) {
    if (size < 8 || size > 16) {
      throw ArgumentError('Grid size must be between 8 and 16, got $size');
    }

    _cells = List.generate(
      size,
      (r) => List.generate(size, (c) => Cell(row: r, col: c, penId: -1)),
    );

    _penMap = {};
    for (final pen in pens) {
      _penMap[pen.id] = pen;
      for (final cell in pen.cells) {
        _cells[cell.row][cell.col] = cell;
      }
    }
  }

  /// Returns the cell at the given (row, col).
  Cell cellAt(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) {
      throw RangeError('($row, $col) is out of bounds for grid of size $size');
    }
    return _cells[row][col];
  }

  /// Returns the pen with the given [penId].
  Pen penById(int penId) {
    final pen = _penMap[penId];
    if (pen == null) {
      throw ArgumentError('No pen found with id $penId');
    }
    return pen;
  }

  /// Returns the pen that contains the given [cell].
  Pen penForCell(Cell cell) => penById(cell.penId);
}
