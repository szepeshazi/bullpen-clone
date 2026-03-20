import 'cell.dart';

/// Represents a pen (region/paddock) on the Bullpen game grid.
///
/// A pen is a contiguous group of cells. In hard mode, each pen
/// must contain exactly 2 bulls.
class Pen {
  final int id;
  final List<Cell> cells;

  const Pen({
    required this.id,
    required this.cells,
  });

  /// Whether this pen contains the given cell.
  bool containsCell(Cell cell) =>
      cells.any((c) => c.row == cell.row && c.col == cell.col);

  /// Number of cells in this pen.
  int get size => cells.length;

  @override
  String toString() => 'Pen(id: $id, cells: ${cells.length})';
}
