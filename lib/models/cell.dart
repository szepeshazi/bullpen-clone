/// Represents a single cell on the Bullpen game grid.
///
/// Equality is based solely on grid position ([row], [col]), NOT on [penId].
/// Two cells at the same position are considered equal even if they belong to
/// different pens. This is intentional: a cell's identity is its coordinate.
class Cell {
  final int row;
  final int col;
  final int penId;

  const Cell({
    required this.row,
    required this.col,
    required this.penId,
  });

  /// Creates a copy of this cell with a different penId.
  Cell copyWith({int? penId}) {
    return Cell(
      row: row,
      col: col,
      penId: penId ?? this.penId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ (col.hashCode << 16);

  @override
  String toString() => 'Cell(row: $row, col: $col, pen: $penId)';
}
