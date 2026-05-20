import 'cell.dart';

/// A contiguous group of cells that must contain exactly 2 bulls.
class Pen {
  final int id;
  final List<Cell> cells;

  const Pen({required this.id, required this.cells});

  bool containsCell(Cell cell) =>
      cells.any((c) => c.row == cell.row && c.col == cell.col);

  int get size => cells.length;

  @override
  String toString() => 'Pen(id: $id, cells: ${cells.length})';
}
